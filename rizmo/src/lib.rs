use godot::prelude::*;
use godot::classes::*;

mod gizmo;
mod dynamic_mesh;

struct RizmoExtension;

#[gdextension]
unsafe impl ExtensionLibrary for RizmoExtension {}
