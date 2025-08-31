use godot::prelude::*;

mod dynamic_mesh;
mod interpreter;

struct RizmoExtension;

#[gdextension]
unsafe impl ExtensionLibrary for RizmoExtension {}
