use std::collections::HashMap;
use std::ops::DerefMut;

use crate::dynamic_mesh::{DynamicMesh, MetaIndexId, decompose_meta_index};
use godot::prelude::*;

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

                // Update the old faces to use the new vertex
                mesh.indices[start_a + (offset_a + 1) % 3] = new_index as i32;
                mesh.indices[start_b + (offset_b + 1) % 3] = new_index as i32;

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
                        meta_index as i32,
                        conn_a[(offset_a + 1) % 3],
                        conn_a[(offset_a + 2) % 3],
                        (start_b + offset_b) as i32,
                        conn_b[(offset_b + 1) % 3],
                        conn_b[(offset_b + 2) % 3],
                    ],
                );
            }
            Command::Pull => {}
        };
    }
}

type CommandId = i32;

#[derive(GodotClass)]
#[class(init, base=Node)]
struct Interpreter {
    commands: Vec<Command>,
    command_map: HashMap<CommandId, usize>,
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

    fn get_new_command_id(&mut self) -> CommandId {
        let index = self.index;
        self.command_map.insert(index, self.commands.len() - 1);
        self.index += 1;
        return index;
    }

    #[func]
    fn reset(&mut self) {
        self.mesh.bind_mut().deref_mut().clear();
        self.selections.clear();
        self.selections
            .push(self.mesh.bind_mut().deref_mut().track_index(0));

        self.call_commands();
        self.mesh.bind_mut().deref_mut().submit_new_geometry();
    }

    fn call_commands(&mut self) {
        for command in self.commands.iter() {
            command.call(self.mesh.bind_mut().deref_mut(), &mut self.selections);
        }
    }

    #[func]
    fn push_selection(&mut self) {
        let command = Command::PushSelection;
        command.call(self.mesh.bind_mut().deref_mut(), &mut self.selections);
        self.commands.push(command);
        self.to_gd().signals().command_executed().emit(
            self.get_new_command_id(),
            "Push Selection",
            &vdict! {},
        );
    }
    #[func]
    fn pop_selection(&mut self) {
        let command = Command::PopSelection;
        command.call(self.mesh.bind_mut().deref_mut(), &mut self.selections);
        self.commands.push(command);
        self.to_gd().signals().command_executed().emit(
            self.get_new_command_id(),
            "Pop Selection",
            &vdict! {},
        );
    }
    #[func]
    fn move_face_selection(&mut self) {
        let command = Command::MoveFaceSelection;
        command.call(self.mesh.bind_mut().deref_mut(), &mut self.selections);
        self.commands.push(command);
        self.to_gd().signals().command_executed().emit(
            self.get_new_command_id(),
            "Move Face Selection",
            &vdict! {},
        );
    }
    #[func]
    fn move_edge_selection(&mut self) {
        let command = Command::MoveEdgeSelection;
        command.call(self.mesh.bind_mut().deref_mut(), &mut self.selections);
        self.commands.push(command);
        self.to_gd().signals().command_executed().emit(
            self.get_new_command_id(),
            "Move Edge Selection",
            &vdict! {},
        );
    }
    #[func]
    fn translate(&mut self, delta: Vector3) {
        let command = Command::Translate(delta);
        command.call(self.mesh.bind_mut().deref_mut(), &mut self.selections);
        self.commands.push(command);
        self.to_gd().signals().command_executed().emit(
            self.get_new_command_id(),
            "Translate",
            &vdict! {"delta": delta},
        );

        let mut mesh = self.mesh.bind_mut();
        let len = mesh.deref_mut().positions.len();
        mesh.deref_mut().submit_updated_positions(0, len as i32);
    }
    #[func]
    fn split(&mut self, amount: f32) {
        let command = Command::Split(amount);
        command.call(self.mesh.bind_mut().deref_mut(), &mut self.selections);
        self.commands.push(command);
        self.to_gd().signals().command_executed().emit(
            self.get_new_command_id(),
            "Split",
            &vdict! {"amount": amount},
        );

        self.mesh.bind_mut().deref_mut().submit_new_geometry();
    }
    #[func]
    fn pull(&mut self) {
        let command = Command::Pull;
        command.call(self.mesh.bind_mut().deref_mut(), &mut self.selections);
        self.commands.push(command);
        self.to_gd().signals().command_executed().emit(
            self.get_new_command_id(),
            "Pull",
            &vdict! {},
        );

        self.mesh.bind_mut().deref_mut().submit_new_geometry();
    }

    #[func]
    fn update_command(&mut self, id: CommandId, args: VariantArray) {
        assert!(self.command_map.contains_key(&id));
        let command_index = self.command_map.get(&id).unwrap();
        match self.commands[*command_index] {
            Command::Translate(_) => {
                self.commands[*command_index] = Command::Translate(args.at(0).to());
            }
            Command::Split(_) => {
                self.commands[*command_index] = Command::Split(args.at(0).to());
            }
            _ => (),
        };
        self.reset();
    }
}
