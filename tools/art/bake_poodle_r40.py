"""Rebake r40 from the high-detail source and repair only proven ray misses."""
import bpy,json
import numpy as np
from pathlib import Path
ROOT=Path('C:/Users/b/Documents/good-human');OUT=ROOT/'build/poodle_refine_r40'
obj=bpy.data.objects['DogBody'];high=bpy.data.objects['R39_BakeSource'];scene=bpy.context.scene
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_r40_07_before_final_bake.blend'))
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.012);bpy.ops.object.mode_set(mode='OBJECT')
size=2048
albedo=bpy.data.images.new('Poodle_R40_Albedo',width=size,height=size,alpha=False)
mat=bpy.data.materials.new('Poodle_R40_Baked');mat.use_nodes=True;nt=mat.node_tree
tex=nt.nodes.new('ShaderNodeTexImage');tex.image=albedo;nt.nodes.active=tex
bs=nt.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.85
obj.data.materials.clear();obj.data.materials.append(mat)
for p in obj.data.polygons:p.material_index=0
high.hide_render=False;high.hide_set(False);high.select_set(True);obj.select_set(True)
scene.render.engine='CYCLES';scene.cycles.samples=1
scene.render.bake.use_selected_to_active=True;scene.render.bake.cage_extrusion=.012;scene.render.bake.max_ray_distance=.035;scene.render.bake.margin=24
bpy.ops.object.bake(type='EMIT')
# White-source bake distinguishes a missed ray from genuine black eyes/mouth.
white=bpy.data.materials.new('R40_CoverageWhite');white.use_nodes=True;wn=white.node_tree;wn.nodes.clear();we=wn.nodes.new('ShaderNodeEmission');we.inputs['Color'].default_value=(1,1,1,1);wo=wn.nodes.new('ShaderNodeOutputMaterial');wn.links.new(we.outputs[0],wo.inputs[0])
oldm=list(high.data.materials)
for i in range(len(high.data.materials)):high.data.materials[i]=white
valid=bpy.data.images.new('R40_RayValidity',width=size,height=size,alpha=False);tex.image=valid;scene.render.bake.margin=0
bpy.ops.object.bake(type='EMIT')
for i,m in enumerate(oldm):high.data.materials[i]=m
high.select_set(False);high.hide_render=True;high.hide_set(True)
coverage=bpy.data.images.new('R40_UVCoverage',width=size,height=size,alpha=False);tex.image=coverage
em=nt.nodes.new('ShaderNodeEmission');em.inputs['Color'].default_value=(1,1,1,1);output=nt.nodes.get('Material Output');nt.links.new(em.outputs[0],output.inputs['Surface'])
scene.render.bake.use_selected_to_active=False;bpy.ops.object.bake(type='EMIT')
def pixels(image):
    arr=np.empty(size*size*4,dtype=np.float32);image.pixels.foreach_get(arr);return arr.reshape(size,size,4)
a=pixels(albedo);v=pixels(valid)[:,:,0]>.5;c=pixels(coverage)[:,:,0]>.5
missing=c & ~v;initial=int(missing.sum());known=v.copy()
# Spread only valid source color; never replace valid dark facial texels.
for iteration in range(64):
    sums=np.zeros_like(a);count=np.zeros((size,size),dtype=np.float32)
    for dy,dx in [(1,0),(-1,0),(0,1),(0,-1)]:
        k=np.roll(known,(dy,dx),(0,1));val=np.roll(a,(dy,dx),(0,1));sums+=val*k[:,:,None];count+=k
    fill=missing & (count>0)
    if not fill.any():break
    a[fill]=sums[fill]/count[fill,None];known[fill]=True;missing[fill]=False
    if not missing.any():break
albedo.pixels.foreach_set(a.ravel());albedo.update();albedo.filepath_raw=str(OUT/'albedo.png');albedo.file_format='PNG';albedo.save();albedo.pack()
tex.image=albedo;nt.links.new(tex.outputs['Color'],bs.inputs['Base Color']);nt.links.new(bs.outputs[0],output.inputs['Surface']);nt.nodes.remove(em)
scene.render.bake.margin=24;scene.cycles.samples=24
report={'verified_missed_ray_texels':initial,'unrepaired_covered_texels':int(missing.sum()),'texture_size':size};(OUT/'bake.json').write_text(json.dumps(report,indent=2));print(report)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_r40_08_final_baked.blend'))
scene.render.filepath=str(OUT/'refined_front.png');bpy.ops.render.render(write_still=True)
