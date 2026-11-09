"""Bake retained high-resolution appearance onto the reduced r39 mesh."""
import bpy, traceback
from pathlib import Path
ROOT=Path('C:/Users/b/Documents/good-human');OUT=ROOT/'build/poodle_budget_r39'
obj=bpy.data.objects['DogBody']
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_04_before_bake.blend'))
with bpy.data.libraries.load(str(OUT/'poodle_01_review.blend'),link=False) as (src,dst):dst.meshes=['out']
high=bpy.data.objects.new('R39_BakeSource',dst.meshes[0]);bpy.context.collection.objects.link(high);high.matrix_world=obj.matrix_world.copy()
# Use emission so lighting and shadows cannot enter the albedo.
for i,mat in enumerate(high.data.materials):
    mat=mat.copy();high.data.materials[i]=mat;nt=mat.node_tree
    bs=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED')
    output=next(n for n in nt.nodes if n.type=='OUTPUT_MATERIAL')
    emission=nt.nodes.new('ShaderNodeEmission')
    socket=bs.inputs['Base Color']
    if socket.is_linked:nt.links.new(socket.links[0].from_socket,emission.inputs['Color'])
    else:emission.inputs['Color'].default_value=socket.default_value
    nt.links.new(emission.outputs[0],output.inputs['Surface'])
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.008);bpy.ops.object.mode_set(mode='OBJECT')
img=bpy.data.images.new('Poodle_R39_Albedo',width=2048,height=2048,alpha=False)
mat=bpy.data.materials.new('Poodle_R39_Baked');mat.use_nodes=True
nt=mat.node_tree;tex=nt.nodes.new('ShaderNodeTexImage');tex.image=img;nt.nodes.active=tex
bs=nt.nodes.get('Principled BSDF');nt.links.new(tex.outputs['Color'],bs.inputs['Base Color']);bs.inputs['Roughness'].default_value=.85
obj.data.materials.clear();obj.data.materials.append(mat)
for p in obj.data.polygons:p.material_index=0
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1
scene.render.bake.use_selected_to_active=True;scene.render.bake.cage_extrusion=.005;scene.render.bake.max_ray_distance=.025;scene.render.bake.margin=16
high.select_set(True);obj.select_set(True);bpy.context.view_layer.objects.active=obj
bpy.ops.object.bake(type='EMIT')
img.filepath_raw=str(OUT/'albedo.png');img.file_format='PNG';img.save();img.pack()
high.hide_render=True;high.hide_set(True)
for e in obj.data.edges:e.use_edge_sharp=False
obj.data.normals_split_custom_set([(0,0,0)]*len(obj.data.loops))
scene.cycles.samples=16;scene.render.filepath=str(OUT/'rebaked.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_05_rebaked.blend'))
print('R39_BAKE_COMPLETE')
