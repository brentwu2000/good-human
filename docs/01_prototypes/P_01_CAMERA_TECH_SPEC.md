# P-01 Camera Tech Spec
Use isolated Godot 4.x 3D prototype with primitives. Suggested folder `prototypes/dog_eye_camera/`.
Camera rig: pivot/boom, smooth interpolation, collision. Runtime parameters: height, distance, pitch, yaw sensitivity, smoothing, FOV, collision margin.
Dog must remain visible; not true first-person. Read dog direction, leash, owner often enough, forward world and opponents.
Avoid head-bob/roll and rigid attachment to animation bones.
Debug overlay: variant/context, height, distance, pitch, FOV, dog speed, owner distance, conflict/disengage distance.
