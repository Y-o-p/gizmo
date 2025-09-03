use std::collections::HashMap;

use godot::classes::StandardMaterial3D;
use godot::classes::{RenderingServer, base_material_3d::Flags, rendering_server::PrimitiveType};
use godot::prelude::*;

pub type MetaIndexId = i32;

// The idea is to maximize performance by leveraging Godot's RenderingServer
// and minimizing memory allocations.
//
// DynamicMesh works by overestimated the resources needed. It allocates a bunch of memory upfront,
// gives it to Godot, and then subsequent updates to the mesh are done through RenderingServer.mesh_surface_update_*_region.
#[derive(GodotClass)]
#[class(init, base=Node3D)]
pub struct DynamicMesh {
    #[var]
    pub positions: PackedVector3Array,
    #[var]
    pub colors: PackedColorArray,
    deleted_vertices: Vec<usize>,
    #[var]
    pub indices: PackedInt32Array,
    #[var]
    pub connections: PackedInt32Array,
    mesh_rid: Option<Rid>,
    instance_rid: Option<Rid>,
    #[init(val = StandardMaterial3D::new_gd())]
    material: Gd<StandardMaterial3D>,
    index: usize,
    pub tracked_indices: HashMap<MetaIndexId, i32>,
    last_meta_index_id: MetaIndexId,
    base: Base<Node3D>,
}

#[godot_api]
impl INode3D for DynamicMesh {
    fn ready(&mut self) {
        self.clear();

        let mut rs = RenderingServer::singleton();
        let mesh_rid = rs.mesh_create();
        let instance_rid = rs.instance_create();
        rs.instance_set_base(instance_rid, mesh_rid);
        rs.instance_set_scenario(
            instance_rid,
            self.base().get_world_3d().unwrap().get_scenario(),
        );

        self.mesh_rid = Some(mesh_rid);
        self.instance_rid = Some(instance_rid);

        self.submit_new_geometry();
        self.material
            .set_flag(Flags::ALBEDO_FROM_VERTEX_COLOR, true);
        rs.mesh_surface_set_material(mesh_rid, 0, self.material.get_rid());
    }
}

#[godot_api]
pub impl DynamicMesh {
    pub const BLOCK_SIZE: usize = 64;

    #[func]
    pub fn clear(&mut self) {
        self.positions.resize(DynamicMesh::BLOCK_SIZE);
        self.positions.as_mut_slice()[0..4].copy_from_slice(&[
            Vector3::new(0.0, 0.0, 0.0),
            Vector3::new(0.0, 0.0, 1.0),
            Vector3::new(0.0, 1.0, 0.0),
            Vector3::new(1.0, 0.0, 0.0),
        ]);
        self.colors.resize(DynamicMesh::BLOCK_SIZE);

        self.indices = PackedInt32Array::from(&[0, 2, 1, 0, 1, 3, 0, 3, 2, 3, 1, 2]);
        self.connections = PackedInt32Array::from(&[8, 10, 3, 2, 9, 6, 5, 11, 0, 4, 1, 7]);
        self.index = 4;
        self.tracked_indices.clear();
        self.last_meta_index_id = 0;
    }

    // TODO: Test to make sure this works
    pub fn clean(&mut self) {
        if self.deleted_vertices.is_empty() {
            return;
        }
        self.deleted_vertices.sort();
        let mut deleted_start_index = 0;
        let mut deleted_end_index = self.deleted_vertices.len() - 1;
        let mut used_end = self.index - 1;

        while used_end == self.deleted_vertices[deleted_end_index] {
            if deleted_end_index == 0 {
                break;
            }

            used_end -= 1;
            deleted_end_index -= 1;
        }

        while used_end > self.deleted_vertices[deleted_start_index] {
            // Move it to the first deleted element
            self.positions[self.deleted_vertices[deleted_start_index]] = self.positions[used_end];

            // Update indices
            for i in 0..self.indices.len() {
                if self.indices[i] == used_end as i32 {
                    self.indices[i] = self.deleted_vertices[deleted_start_index] as i32;
                }
            }

            // Move the starting index forward
            deleted_start_index += 1;

            // Find the final element that isn't deleted
            while used_end == self.deleted_vertices[deleted_end_index] {
                if deleted_end_index == 0 {
                    break;
                }
                used_end -= 1;
                deleted_end_index -= 1;
            }
        }

        self.index = used_end;
        self.deleted_vertices.clear();
        let new_size = (self.index as f32 / DynamicMesh::BLOCK_SIZE as f32).ceil() as usize
            * DynamicMesh::BLOCK_SIZE;
        self.positions.resize(new_size);
    }

    pub fn request_more_memory(&mut self) {
        let new_size = self.positions.len() + DynamicMesh::BLOCK_SIZE;
        self.positions.resize(new_size);
        self.colors.resize(new_size);
    }

    pub fn add_vertex(&mut self, position: Vector3) -> usize {
        if self.index % DynamicMesh::BLOCK_SIZE == 0 {
            self.request_more_memory();
        }

        let index = self.index;
        self.positions[index] = position;
        self.index += 1;
        return index;
    }

    #[func]
    pub fn add_faces(&mut self, indices: [i32; 6], connections: [i32; 6]) {
        self.indices.extend_array(&PackedInt32Array::from(&indices));

        let connections_length = self.connections.len();
        self.connections
            .extend_array(&PackedInt32Array::from(&connections));

        for (offset, connection) in connections.iter().enumerate() {
            if *connection > (connections_length - 1) as i32 {
                continue;
            }
            self.connections[*connection as usize] = (connections_length + offset) as i32;
        }
    }

    #[func]
    pub fn submit_new_geometry(&self) {
        let mut rs = RenderingServer::singleton();
        rs.mesh_clear(self.mesh_rid.unwrap());
        let surface = varray!(
            self.positions.clone(), // Positions (Vector3)
            Variant::nil(),
            Variant::nil(),
            self.colors.clone(),
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
        rs.mesh_add_surface_from_arrays(self.mesh_rid.unwrap(), PrimitiveType::TRIANGLES, &surface);
    }

    #[func]
    pub fn submit_updated_positions(&self, index: i32, size: i32) {
        let i: usize = index.try_into().unwrap();
        let s: usize = size.try_into().unwrap();
        let positions_as_bytes = self.positions.subarray(i, i + s).to_byte_array();

        let mut rs = RenderingServer::singleton();
        rs.mesh_surface_update_vertex_region(
            self.mesh_rid.unwrap(),
            0,
            3 * 4 * index,
            &positions_as_bytes,
        );
    }

    #[func]
    pub fn track_index(&mut self, meta_index: i32) -> MetaIndexId {
        let new_meta_index_id = self.last_meta_index_id;
        self.last_meta_index_id += 1;

        if meta_index > (self.indices.len() - 1).try_into().unwrap() {
            panic!("meta_index can't be larger than the number of indices.");
        }

        self.tracked_indices.insert(new_meta_index_id, meta_index);

        new_meta_index_id
    }

    #[func]
    pub fn traverse_connection(&mut self, meta_index_id: MetaIndexId) {
        self.tracked_indices.insert(
            meta_index_id,
            self.connections[self.tracked_indices[&meta_index_id].try_into().unwrap()],
        );
    }

    #[func]
    pub fn get_meta_index(&self, meta_index_id: MetaIndexId) -> i32 {
        *self.tracked_indices.get(&meta_index_id).unwrap()
    }

    #[func]
    fn get_face_positions(&self, meta_index_id: MetaIndexId) -> PackedVector3Array {
        let (start, offset) = decompose_meta_index(self.get_meta_index(meta_index_id) as usize);
        let mut indices = self.indices.subarray(start, start + 3);
        let indices_rotated = indices.as_mut_slice();
        indices_rotated.rotate_left(offset);
        PackedVector3Array::from([
            self.positions[indices_rotated[0] as usize],
            self.positions[indices_rotated[1] as usize],
            self.positions[indices_rotated[2] as usize],
        ])
    }

    #[func]
    pub fn modify_vertex(&mut self, meta_index_id: MetaIndexId, position: Vector3) {
        // It's not enough to update a single vertex
        // Some vertices are "tied," they have the same position but different attributes
        // This algorithm navigates all tied vertices and updates them.
        // Traverse the shape until we arrive where we started.

        let starting_meta_index = *self.tracked_indices.get(&meta_index_id).unwrap();
        let mut next_meta_index = starting_meta_index;
        let mut update_next_vertex = || {
            self.positions[self.indices[next_meta_index as usize] as usize] = position;
            next_meta_index = self.connections[next_meta_index as usize];
            let (start, offset) = decompose_meta_index(next_meta_index as usize);
            next_meta_index = (start + (offset + 1) % 3) as i32;
            return next_meta_index;
        };
        let mut next = update_next_vertex();
        while next != starting_meta_index {
            next = update_next_vertex();
        }
    }
}

impl Drop for DynamicMesh {
    fn drop(&mut self) {
        let mut rs = RenderingServer::singleton();
        match self.mesh_rid {
            Some(rid) => {
                rs.free_rid(rid);
            }
            None => {
                godot_error!("No RID to free.");
            }
        }
        match self.instance_rid {
            Some(rid) => {
                rs.free_rid(rid);
            }
            None => {
                godot_error!("No RID to free.");
            }
        }
        godot_print!("Freed mesh");
    }
}

pub fn decompose_meta_index(meta_index: usize) -> (usize, usize) {
    let offset = meta_index % 3;
    let start = meta_index - offset;
    return (start, offset);
}
