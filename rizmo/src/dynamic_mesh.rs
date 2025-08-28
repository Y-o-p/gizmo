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
#[class(base=Node3D)]
struct DynamicMesh {
    #[var]
    positions: PackedVector3Array,
    #[var]
    indices: PackedInt32Array,
    #[var]
    connections: PackedInt32Array,
    #[var]
    mesh_rid: Rid,
    #[var]
    instance_rid: Rid,
    index: usize,
    base: Base<Node3D>,
}


#[godot_api]
impl INode3D for DynamicMesh {
    fn init(base: Base<Node3D>) -> Self {
        let mut rs = RenderingServer::singleton();

        let mesh_rid = rs.mesh_create();
        let instance_rid = rs.instance_create();
        rs.instance_set_base(instance_rid, mesh_rid);
        let mut new_self = Self {
            positions: PackedVector3Array::new(),
            indices: PackedInt32Array::new(),
            connections: PackedInt32Array::new(),
            mesh_rid: mesh_rid,
            instance_rid: instance_rid,
            index: 0,
            base: base,
        };

        new_self.positions.resize(64);
        new_self
    }

    fn ready(&mut self) {
        let mut rs = RenderingServer::singleton();
        rs.instance_set_scenario(self.instance_rid, self.base().get_world_3d().unwrap().get_scenario());

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
        rs.mesh_clear(self.mesh_rid);
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
        rs.mesh_add_surface_from_arrays(self.mesh_rid, PrimitiveType::TRIANGLES, &surface);
    }
}

impl Drop for DynamicMesh {
    fn drop(&mut self) {
        let mut rs = RenderingServer::singleton();
        rs.mesh_clear(self.mesh_rid);
        godot_print!("Bye bye Gizmo");
    }
}
