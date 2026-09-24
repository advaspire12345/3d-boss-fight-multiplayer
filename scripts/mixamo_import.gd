@tool
extends EditorScenePostImport
## Runs every time a Mixamo FBX in character/mixamo/ is imported.
## Saves its animation as character/animations/<file name>.res for the Player to play.

## Animations that repeat forever instead of playing once.
const LOOPING := ["idle", "run"]
## Animations whose hips must also stay at one height, because player.gd already moves the body up and down.
const LOCK_HEIGHT := ["jump"]


func _post_import(scene: Node) -> Object:
	var anim_name := get_source_file().get_file().get_basename()
	var anim_player: AnimationPlayer = scene.get_node("AnimationPlayer")
	var anim: Animation = anim_player.get_animation("mixamo_com").duplicate()

	if anim_name in LOOPING:
		anim.loop_mode = Animation.LOOP_LINEAR
	_keep_in_place(anim, anim_name in LOCK_HEIGHT)

	DirAccess.make_dir_recursive_absolute("res://character/animations")
	ResourceSaver.save(anim, "res://character/animations/%s.res" % anim_name)

	_pose_first_frame(scene.get_node("Skeleton3D"), anim)

	# The Player has its own AnimationPlayer, and Tinkercad leaves some empty meshes behind.
	for child in scene.get_children():
		if child is AnimationPlayer or (child is MeshInstance3D and child.mesh == null):
			scene.remove_child(child)
			child.free()
	return scene


## Stands the model in the clip's first pose. Otherwise the editor shows Mixamo's T-pose, half in the floor.
func _pose_first_frame(skeleton: Skeleton3D, anim: Animation) -> void:
	for track in anim.get_track_count():
		var bone := skeleton.find_bone(String(anim.track_get_path(track).get_subname(0)))
		if bone == -1:
			continue
		var value = anim.track_get_key_value(track, 0)
		match anim.track_get_type(track):
			Animation.TYPE_POSITION_3D:
				skeleton.set_bone_pose_position(bone, value)
			Animation.TYPE_ROTATION_3D:
				skeleton.set_bone_pose_rotation(bone, value)
			Animation.TYPE_SCALE_3D:
				skeleton.set_bone_pose_scale(bone, value)


## Pins the hips over the same spot so the model never walks away from its collider.
func _keep_in_place(anim: Animation, lock_height: bool) -> void:
	var track := anim.find_track(^"Skeleton3D:mixamorig_Hips", Animation.TYPE_POSITION_3D)
	var start: Vector3 = anim.track_get_key_value(track, 0)
	for i in anim.track_get_key_count(track):
		var pos: Vector3 = anim.track_get_key_value(track, i)
		pos.x = start.x
		pos.z = start.z
		if lock_height:
			pos.y = start.y
		anim.track_set_key_value(track, i, pos)
