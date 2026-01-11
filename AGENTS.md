# Agent Guidelines for Nautilus (Godot 4.6)

## Build/Run/Lint
- Run project: `make r` (requires GODOT_PROGRAM env var in .env)
- Open editor: `make e`
- Lint/format: `make l` (runs gdformat + gdlint + clang-format)
- Export web build: `make x`
- CI runs: `gdformat --check .` and `gdlint .`

## Code Style
- **GDScript**: Follow gdformat conventions (auto-formatted via pre-commit)
- **Shaders**: Use clang-format with tabs (width 4, LLVM style)
- **Typing**: Always type function returns (-> void, -> float, etc.) and variables where possible
- **Exports**: Use @export for tunable parameters with sensible defaults
- **Naming**: snake_case for variables/functions, PascalCase for classes/nodes
- **Onready**: Use @onready for node references and settings: `@onready var gravity: float = ProjectSettings.get_setting(...)`
- **Tool scripts**: Use @tool decorator when script needs editor functionality

## Physics/Game Conventions
- Extends RigidBody3D for physics objects with _physics_process and _integrate_forces
- Use probes (Marker3D children) for multi-point buoyancy calculations
- Apply forces with apply_force(force, offset) and torque with apply_torque(vector)
- Access sibling nodes via $"../" pattern: `$"../Wind"`, `$"../Ocean"`
