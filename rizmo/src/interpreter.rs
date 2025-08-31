use crate::dynamic_mesh::{DynamicMesh, MetaIndexId};
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
    fn call(&self, mesh: &mut DynamicMesh, selections: &mut Vec<MetaIndexId>) {
        assert!(selections.len() > 0);
        let selection = *selections.last().unwrap();
        let meta_index = mesh.get_meta_index(selection) as usize;
        fn decompose_meta_index(meta_index: usize) -> (usize, usize) {
            let offset = meta_index % 3;
            let start = meta_index - offset;
            return (start, offset);
        }
        match self {
            Command::PushSelection => selections.push(*selections.last().unwrap()),
            Command::PopSelection => {
                selections.pop();
            }
            Command::MoveFaceSelection => mesh.traverse_connection(*selections.last().unwrap()),
            Command::MoveEdgeSelection => {
                assert!(
                    mesh.tracked_indices
                        .contains_key(selections.last().unwrap())
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

#[derive(GodotClass)]
#[class(init, base=Node)]
struct Interpreter {
    commands: Vec<Command>,
    selections: Vec<MetaIndexId>,
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
    #[func]
    fn call_commands(&self) {}
}
