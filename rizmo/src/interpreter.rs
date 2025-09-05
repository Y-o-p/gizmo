use std::collections::HashMap;
use std::ops::DerefMut;

use crate::dynamic_mesh::{DynamicMesh, MetaIndexId, decompose_meta_index};
use godot::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
enum Command {
    // Selection stack manipulation
    PushSelection,
    PopSelection,

    // Moving the selection around relatively
    MoveFaceSelection,
    MoveEdgeSelection,

    // Model mutations
    Translate(Vector3),
    Split(f32),
    Pull,

    // Vertex attributes
    Color(Color),
}

impl Command {
    fn call(&self, mesh: &mut DynamicMesh, selections: &mut Array<MetaIndexId>) {
        assert!(selections.len() > 0);
        let selection = selections.back().unwrap();
        let meta_index = mesh.get_meta_index(selection) as usize;
        match self {
            Command::PushSelection => selections.push(selections.back().unwrap()),
            Command::PopSelection => {
                selections.pop();
            }
            Command::MoveFaceSelection => mesh.traverse_connection(selections.back().unwrap()),
            Command::MoveEdgeSelection => {
                assert!(
                    mesh.tracked_indices
                        .contains_key(&selections.back().unwrap())
                );
                let (start, offset) = decompose_meta_index(meta_index);
                mesh.tracked_indices
                    .insert(selection, (start + (offset + 1) % 3) as i32);
            }
            Command::Translate(delta) => {
                mesh.modify_vertex(
                    selection,
                    mesh.positions[mesh.indices[meta_index] as usize] + *delta,
                );
            }
            Command::Split(amount) => {
                assert!(*amount >= 0.0 && *amount <= 1.0);

                // Create new vertex
                let (start_a, offset_a) = decompose_meta_index(meta_index);
                let (start_b, offset_b) =
                    decompose_meta_index(mesh.connections[meta_index] as usize);
                let first_position: Vector3 =
                    mesh.positions[mesh.indices[meta_index as usize] as usize];
                let second_position: Vector3 =
                    mesh.positions[mesh.indices[start_b + offset_b] as usize];
                let new_position = (1.0 - amount) * first_position + *amount * second_position;
                let new_index = mesh.add_vertex(new_position);

                // Add two new faces
                let face_a = &mesh.indices.as_slice()[start_a..start_a + 3];
                let face_b = &mesh.indices.as_slice()[start_b..start_b + 3];
                let conn_a = &mesh.connections.as_slice()[start_a..start_a + 3];
                let conn_b = &mesh.connections.as_slice()[start_b..start_b + 3];
                mesh.add_faces(
                    [
                        new_index as i32,
                        face_a[(offset_a + 1) % 3],
                        face_a[(offset_a + 2) % 3],
                        new_index as i32,
                        face_b[(offset_b + 1) % 3],
                        face_b[(offset_b + 2) % 3],
                    ],
                    [
                        (start_b + offset_b) as i32,
                        conn_a[(offset_a + 1) % 3],
                        (start_a + (offset_a + 1) % 3) as i32,
                        meta_index as i32,
                        conn_b[(offset_b + 1) % 3],
                        (start_b + (offset_b + 1) % 3) as i32,
                    ],
                );
                // Update the old faces to use the new vertex
                mesh.indices[start_a + (offset_a + 1) % 3] = new_index as i32;
                mesh.indices[start_b + (offset_b + 1) % 3] = new_index as i32;
            }
            Command::Pull => {
                // Create new vertex
                let new_index = mesh.add_vertex(
                    mesh.positions
                        .get(mesh.indices.get(meta_index).unwrap() as usize)
                        .unwrap(),
                );

                // Set the old face to use the new index
                let old_index = mesh.indices[meta_index];
                mesh.indices[meta_index] = new_index as i32;

                // Add two new faces
                let (start, offset) = decompose_meta_index(meta_index);
                let num_indices = mesh.indices.len();
                mesh.add_faces(
                    [
                        old_index,
                        new_index as i32,
                        mesh.indices[start + (offset + 2) % 3],
                        new_index as i32,
                        old_index as i32,
                        mesh.indices[start + (offset + 1) % 3],
                    ],
                    [
                        (num_indices + 3) as i32,
                        (start + (offset + 2) % 3) as i32,
                        mesh.connections[start + (offset + 2) % 3],
                        num_indices as i32,
                        mesh.connections[start + (offset + 1) % 3],
                        meta_index as i32,
                    ],
                );
            }
            Command::Color(color) => {
                mesh.colors[mesh.indices[meta_index] as usize] = *color;
            }
        };
    }

    fn to_signal_params(&self) -> (GString, Dictionary) {
        match self {
            Command::PushSelection => ("Push Selection".into(), vdict! {}),
            Command::PopSelection => ("Pop Selection".into(), vdict! {}),
            Command::MoveFaceSelection => ("Move Face Selection".into(), vdict! {}),
            Command::MoveEdgeSelection => ("Move Edge Selection".into(), vdict! {}),
            Command::Translate(delta) => ("Translate".into(), vdict! {"delta": *delta}),
            Command::Split(amount) => ("Split".into(), vdict! {"amount": *amount}),
            Command::Pull => ("Pull".into(), vdict! {}),
            Command::Color(color) => ("Color".into(), vdict! {"color": *color}),
        }
    }
}

type CommandId = i32;

#[derive(GodotClass)]
#[class(init, base=Node)]
struct Interpreter {
    commands: HashMap<CommandId, Command>,
    index: CommandId,
    #[var]
    selections: Array<MetaIndexId>,
    #[var]
    #[init(val = DynamicMesh::new_alloc())]
    mesh: Gd<DynamicMesh>,
    base: Base<Node>,
}

#[godot_api]
impl INode for Interpreter {
    fn ready(&mut self) {
        self.to_gd().add_child(&self.mesh);
        godot_print!("Interpreter added DynamicMesh to scene.");
        self.selections.push(self.mesh.bind_mut().track_index(0));
    }
}

#[godot_api]
impl Interpreter {
    #[signal]
    fn command_executed(command_id: CommandId, command_name: GString, params: Dictionary);

    #[func]
    fn reset(&mut self) {
        self.mesh.bind_mut().deref_mut().clear();
        self.selections.clear();
        self.selections
            .push(self.mesh.bind_mut().deref_mut().track_index(0));

        self.call_commands();
        self.mesh.bind_mut().deref_mut().submit_new_geometry();
    }

    #[func]
    fn undo_command(&mut self, id: CommandId) {
        self.commands.remove(&id);
        self.reset();
    }

    #[func]
    fn commands_as_json_string(&self) -> GString {
        // Wow 0_0
        return GString::from(serde_json::to_string(&self.commands).unwrap());
    }

    #[func]
    fn load_commands_from_json_string(&mut self, string: GString) {
        let commands: Vec<Command> = serde_json::from_str(&string.to_string()).unwrap();
        for command in commands.into_iter() {
            let (name, args) = command.to_signal_params();
            command.call(self.mesh.bind_mut().deref_mut(), &mut self.selections);
            let new_id = self.get_new_command_id();
            self.commands.insert(new_id, command);
            self.to_gd()
                .signals()
                .command_executed()
                .emit(new_id, &name, &args);
        }
        self.reset();
    }

    ///////////////////////////////////////////////////////////////////////////
    // Command functions
    ///////////////////////////////////////////////////////////////////////////
    #[func]
    fn push_selection(&mut self) {
        self.add_new_command(Command::PushSelection);
    }
    #[func]
    fn pop_selection(&mut self) {
        self.add_new_command(Command::PopSelection);
    }
    #[func]
    fn move_face_selection(&mut self) {
        self.add_new_command(Command::MoveFaceSelection);
    }
    #[func]
    fn move_edge_selection(&mut self) {
        self.add_new_command(Command::MoveEdgeSelection);
    }
    #[func]
    fn translate(&mut self, delta: Vector3) {
        self.add_new_command(Command::Translate(delta));
    }
    #[func]
    fn split(&mut self, amount: f32) {
        self.add_new_command(Command::Split(amount));
    }
    #[func]
    fn pull(&mut self) {
        self.add_new_command(Command::Pull);
    }
    #[func]
    fn color(&mut self, color: Color) {
        self.add_new_command(Command::Color(color));
    }

    ///////////////////////////////////////////////////////////////////////////////

    #[func]
    fn update_command(&mut self, id: CommandId, args: VariantArray) {
        assert!(self.commands.contains_key(&id));
        let command = self.commands.get(&id).unwrap();
        match command {
            Command::Translate(_) => {
                self.commands
                    .insert(id, Command::Translate(args.at(0).to()));
            }
            Command::Split(_) => {
                self.commands.insert(id, Command::Split(args.at(0).to()));
            }
            Command::Color(_) => {
                self.commands.insert(id, Command::Color(args.at(0).to()));
            }
            _ => (),
        };
        self.reset();
    }

    fn add_new_command(&mut self, command: Command) {
        let new_id = self.get_new_command_id();
        command.call(self.mesh.bind_mut().deref_mut(), &mut self.selections);
        let (name, args) = command.to_signal_params();
        self.commands.insert(new_id, command);
        self.to_gd()
            .signals()
            .command_executed()
            .emit(new_id, &name, &args);
    }

    fn get_new_command_id(&mut self) -> CommandId {
        let index = self.index;
        self.index += 1;
        return index;
    }

    fn call_commands(&mut self) {
        for command in self.commands.values() {
            command.call(self.mesh.bind_mut().deref_mut(), &mut self.selections);
        }
    }
}
