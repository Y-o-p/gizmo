use std::collections::HashMap;

use godot::prelude::*;
use godot::classes::{RenderingServer, rendering_server::PrimitiveType};


type MetaIndexId = i32;

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
    tracked_indices: HashMap<MetaIndexId, i32>,
    last_meta_index_id: MetaIndexId,
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
            tracked_indices: HashMap::new(),
            last_meta_index_id: 0,
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
    fn submit_new_geometry(&self) {
        let mut rs = RenderingServer::singleton();
        rs.mesh_clear(self.mesh_rid);
        let surface = varray!(
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

    #[func]
    fn submit_updated_positions(&self, index: i32, size: i32) {
        let i: usize = index.try_into().unwrap();
        let s: usize = size.try_into().unwrap();
        let positions_as_bytes = self.positions.subarray(i, i + s).to_byte_array();

        let mut rs = RenderingServer::singleton();
        rs.mesh_surface_update_vertex_region(self.mesh_rid, 0, 3 * 4 * index, &positions_as_bytes);
    }

    #[func]
    fn track_index(&mut self, meta_index: i32) -> MetaIndexId {
        let new_meta_index_id = self.last_meta_index_id;
        self.last_meta_index_id += 1;

        if meta_index > (self.indices.len() - 1).try_into().unwrap() {
            panic!("meta_index can't be larger than the number of indices.");
        }

        self.tracked_indices.insert(new_meta_index_id, meta_index);

        new_meta_index_id
    }

    #[func]
    fn traverse_connection(&mut self, meta_index_id: MetaIndexId) {
        self.tracked_indices.insert(meta_index_id, self.connections[self.tracked_indices[&meta_index_id].try_into().unwrap()]);
    }

    #[func]
    fn get_meta_index(&self, meta_index_id: MetaIndexId) -> i32 {
        *self.tracked_indices.get(&meta_index_id).unwrap()
    }

    #[func]
    fn modify_vertex(&mut self, meta_index_id: MetaIndexId) {

    }
}

impl Drop for DynamicMesh {
    fn drop(&mut self) {
        let mut rs = RenderingServer::singleton();
        rs.free_rid(self.mesh_rid);
        rs.free_rid(self.instance_rid);
        godot_print!("Bye bye Gizmo");
    }
}
