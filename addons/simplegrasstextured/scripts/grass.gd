# grass.gd
# This file is part of: SimpleGrassTextured
# Copyright (c) 2023 IcterusGames
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@tool
extends MultiMeshInstance3D

@export var mesh: Mesh = build_default_mesh():
	set = _on_set_mesh

@export_group("Optimization")
@export var optimization_by_distance := false:
	set = _on_set_optimization_by_distance
@export var optimization_level := 7.0:
	set = _on_set_optimization_level
@export var optimization_dist_min := 10.0:
	set = _on_set_optimization_dist_min
@export var optimization_dist_max := 50.0:
	set = _on_set_optimization_dist_max

var sgt_radius := 2.0
var sgt_density := 25
var sgt_scale := 1.0
var sgt_rotation := 0.0
var sgt_rotation_rand := 1.0
var sgt_dist_min := 0.0
var sgt_follow_normal := false

var _buffer_add: Array[Transform3D] = []
var _force_update_multimesh := false
var _properties = []


func _init():
	if Engine.is_editor_hint():
		for var_i in get_property_list():
			if not var_i.name.begins_with("sgt_"):
				continue
			(
				_properties
				. append(
					{
						"name": var_i.name,
						"type": var_i.type,
						"usage": PROPERTY_USAGE_NO_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
					}
				)
			)


func _ready():
	if Engine.is_editor_hint():
		set_process(true)
	else:
		set_process(false)

	if not has_meta("SimpleGrassTextured"):
		# Update for previous version, 1.0.2 needs vertex color
		set_meta("SimpleGrassTextured", "1.0.2")
		_force_update_multimesh = true

	if multimesh == null:
		multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh

	_on_set_optimization_by_distance(optimization_by_distance)
	_on_set_optimization_level(optimization_level)
	_on_set_optimization_dist_min(optimization_dist_min)
	_on_set_optimization_dist_max(optimization_dist_max)


func _process(_delta: float):
	if _buffer_add.size() != 0 or _force_update_multimesh:
		_force_update_multimesh = false
		update_multimesh()


func _get_property_list() -> Array:
	if _properties == null:
		return []
	return _properties


func _on_set_mesh(value: Mesh):
	mesh = value

	if mesh != null:
		for shader_material in get_shader_materials(mesh):
			shader_material.set_shader_parameter("grass_size_y", mesh.get_aabb().size.y)

	if Engine.is_editor_hint() and is_inside_tree():
		update_multimesh()


func _on_set_optimization_by_distance(value: bool):
	optimization_by_distance = value

	for shader_material in get_shader_materials(mesh):
		shader_material.set_shader_parameter("optimization_by_distance", optimization_by_distance)


func _on_set_optimization_level(value: float):
	optimization_level = value

	for shader_material in get_shader_materials(mesh):
		shader_material.set_shader_parameter("optimization_level", optimization_level)


func _on_set_optimization_dist_min(value: float):
	optimization_dist_min = value

	for shader_material in get_shader_materials(mesh):
		shader_material.set_shader_parameter("optimization_dist_min", optimization_dist_min)


func _on_set_optimization_dist_max(value: float):
	optimization_dist_max = value

	for shader_material in get_shader_materials(mesh):
		shader_material.set_shader_parameter("optimization_dist_max", optimization_dist_max)


func draw(pos: Vector3, normal: Vector3, scale: Vector3, rotated: float):
	var trans := Transform3D()
	if abs(normal.z) == 1:
		trans.basis.x = Vector3(1, 0, 0)
		trans.basis.y = Vector3(0, 0, normal.z)
		trans.basis.z = Vector3(0, normal.z, 0)
		trans.basis = trans.basis.orthonormalized()
	else:
		trans.basis.y = normal
		trans.basis.x = normal.cross(trans.basis.z)
		trans.basis.z = trans.basis.x.cross(normal)
		trans.basis = trans.basis.orthonormalized()
	trans = trans.rotated_local(Vector3.UP, rotated)
	trans = trans.scaled(scale)
	trans = trans.translated(pos)
	if sgt_dist_min > 0:
		for trans_prev in _buffer_add:
			if trans.origin.distance_to(trans_prev.origin) <= sgt_dist_min:
				return
	_buffer_add.append(trans)


func erase(pos: Vector3, radius: float):
	var multi_new := MultiMesh.new()
	var array: Array[Transform3D] = []

	multi_new.transform_format = MultiMesh.TRANSFORM_3D
	if mesh != null:
		multi_new.mesh = mesh

	for i in range(multimesh.instance_count):
		var trans := multimesh.get_instance_transform(i)
		if trans.origin.distance_to(pos) > radius:
			array.append(trans)

	multi_new.instance_count = array.size()
	for i in range(array.size()):
		multi_new.set_instance_transform(i, array[i])

	multimesh = multi_new


func get_shader_materials(mesh: Mesh):
	var shader_materials: Array[ShaderMaterial] = []

	if mesh == null:
		return shader_materials

	for i in mesh.get_surface_count():
		var shader_material := mesh.surface_get_material(i)

		if shader_material is ShaderMaterial:
			shader_materials.append(shader_material)

	return shader_materials


func update_multimesh():
	if multimesh == null:
		return

	var multi_new := MultiMesh.new()
	var count_prev := multimesh.instance_count
	multi_new.transform_format = MultiMesh.TRANSFORM_3D
	if mesh != null:
		multi_new.mesh = mesh

	if _buffer_add.size() > 0 and sgt_dist_min > 0:
		var pos_min := Vector3(10000000, 10000000, 10000000)
		var pos_max := pos_min * -1
		var center := Vector3.ZERO
		var radius := 0.0
		for trans in _buffer_add:
			if pos_min > trans.origin:
				pos_min = trans.origin
			if pos_max < trans.origin:
				pos_max = trans.origin
		center = pos_min + ((pos_max - pos_min) / 2.0)
		radius = center.distance_to(pos_min) + 1.0
		for i in range(multimesh.instance_count):
			var trans := multimesh.get_instance_transform(i)
			if trans.origin.distance_to(center) > radius:
				continue
			for trans_add in _buffer_add:
				if trans_add.origin.distance_to(trans.origin) > sgt_dist_min:
					continue
				_buffer_add.erase(trans_add)
				break

	multi_new.instance_count = count_prev + _buffer_add.size()
	for i in range(multimesh.instance_count):
		multi_new.set_instance_transform(i, multimesh.get_instance_transform(i))
	for i in range(_buffer_add.size()):
		multi_new.set_instance_transform(i + count_prev, _buffer_add[i])

	multimesh = multi_new
	_buffer_add.clear()


func build_default_mesh() -> Mesh:
	return QuadMesh.new()
