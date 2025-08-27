use std::collections::HashMap;
use std::hash::{Hash, Hasher, DefaultHasher};

use godot::prelude::*;
use godot::classes::*;
use godot::classes::rendering_server::PrimitiveType;


// The idea is to maximize performance by leveraging Godot's RenderingServer
// and minimizing memory allocations.
//
// DynamicMesh works by overestimated the resources needed. It allocates a bunch of memory upfront,
// gives it to Godot, and then subsequent updates to the mesh are done through RenderingServer.mesh_surface_update_*_region.
#[derive(GodotClass)]
#[class(base=RefCounted)]
struct DynamicMesh {
    #[var]
    positions: PackedVector3Array,
    #[var]
    indices: PackedInt32Array,
    connections: PackedInt32Array,
    #[var]
    mesh_rid: Rid,
    index: usize,
}


#[godot_api]
impl IRefCounted for DynamicMesh {
    fn init(base: Base<RefCounted>) -> Self {
        let mut rs = RenderingServer::singleton();

        let mut new_self = Self {
            positions: PackedVector3Array::new(),
            indices: PackedInt32Array::new(),
            connections: PackedInt32Array::new(),
            mesh_rid: rs.mesh_create(),
            index: 0,
        };

        new_self.positions.resize(64);


        new_self
    }
}

#[godot_api]
impl DynamicMesh {
    #[func]
    fn add_vertex(&mut self, position: Vector3) {
        self.positions[self.index] = position;
        self.index += 1;
    }

    #[func]
    fn add_face(&mut self, index_a: i32, index_b: i32, index_c: i32, conn_a: i32, conn_b: i32, conn_c: i32) {
        self.indices.extend_array(&PackedInt32Array::from(&[index_a, index_b, index_c]));
        self.connections.extend_array(&PackedInt32Array::from(&[conn_a, conn_b, conn_c]));
    }

    #[func]
    fn submit(&mut self) {
        let mut rs = RenderingServer::singleton();
        //rs.mesh_clear(self.mesh_rid);
        let mut surface = varray!(
            self.positions.clone(), // Positions (Vector3)
            Variant::nil(),
            Variant::nil(),
            Variant::nil(),
            Variant::nil(),
            Variant::nil(),
            Variant::nil(),
            Variant::nil(),
            Variant::nil(),
            Variant::nil(),
            Variant::nil(),
            Variant::nil(),
            self.indices.clone() // Indices (Vector3)
        );
        self.mesh_rid = rs.mesh_create();
        rs.mesh_add_surface_from_arrays(self.mesh_rid, PrimitiveType::TRIANGLES, &surface);
    }
//    #[func]
//    fn submit(&self) {
//        let mut surface_arrays = Array::new();
//        surface_arrays.resize(Mesh.ARRAY_MAX);
//        surface_arrays[Mesh.ARRAY_VERTEX].resize(3 * self.faces.len());
//        for (face_id, vertex_ids) in &self.faces {
//            for vertex_id in &vertex_ids {
//
//            }
//        }
//    }
}

impl Drop for DynamicMesh {
    fn drop(&mut self) {
        let mut rs = RenderingServer::singleton();
        rs.mesh_clear(self.mesh_rid);
        godot_print!("Bye bye Gizmo");
    }
}
