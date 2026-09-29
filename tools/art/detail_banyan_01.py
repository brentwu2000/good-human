import bpy, os, math, numpy as np
from mathutils import Vector
WORK=r'C:\Users\b\Documents\good-human-3d-pipeline\blender\environment\banyan_01'
OUT=r'C:\Users\b\Documents\good-human\assets\environment\territory\models\banyan_01'
bpy.ops.wm.save_as_mainfile(filepath=WORK+'/banyan_02_before_union.blend')
tree=bpy.data.objects['Banyan_Bark'];bpy.ops.object.select_all(action='DESELECT');tree.select_set(True);bpy.context.view_layer.objects.active=tree
rem=tree.modifiers.new('Fuse roots and trunks','REMESH');rem.mode='VOXEL';rem.voxel_size=.052;rem.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=rem.name)
sm=tree.modifiers.new('Organic junctions','SMOOTH');sm.factor=.7;sm.iterations=3;bpy.ops.object.modifier_apply(modifier=sm.name)
de=tree.modifiers.new('Mobile bark topology','DECIMATE');de.ratio=.28;bpy.ops.object.modifier_apply(modifier=de.name)
# Vertical object-space UV projection, with per-face seams on back-facing branches.
uv=tree.data.uv_layers.new(name='BarkUV')
for p in tree.data.polygons:
 for li in p.loop_indices:
  co=tree.data.vertices[tree.data.loops[li].vertex_index].co
  uv.data[li].uv=(co.x*.65+co.y*.47,co.z*.35)
w,h=512,1024;yy,xx=np.mgrid[0:h,0:w];rng=np.random.default_rng(7)
noise=rng.random((h,w));streak=np.sin(xx*.28+np.sin(yy*.018)*1.2+np.sin(xx*.035)*2)
grain=.74+.14*streak+.06*np.sin(xx*.9+yy*.02)+.06*noise
rgba=np.ones((h,w,4),dtype=np.float32)
for i,c in enumerate([.37,.29,.215]):rgba[:,:,i]=c*grain
im=bpy.data.images.new('Banyan_Bark_Albedo',width=w,height=h);im.pixels.foreach_set(rgba.ravel());im.filepath_raw=OUT+'/bark_albedo.png';im.file_format='PNG';im.save();im.pack()
mat=tree.data.materials[0];nodes=mat.node_tree.nodes;links=mat.node_tree.links;p=nodes.get('Principled BSDF')
tex=nodes.new('ShaderNodeTexImage');tex.image=im;links.new(tex.outputs['Color'],p.inputs['Base Color'])
# A matching tangent-space micro-normal is fully embedded in the GLB.
gx=np.gradient(grain,axis=1)*2;gy=np.gradient(grain,axis=0)*2;norm=np.stack([-gx,-gy,np.ones_like(gx)],axis=2);norm/=np.linalg.norm(norm,axis=2,keepdims=True)
rgba[:,:,:3]=norm*.5+.5;nm=bpy.data.images.new('Banyan_Bark_Normal',width=w,height=h);nm.colorspace_settings.name='Non-Color';nm.pixels.foreach_set(rgba.ravel());nm.filepath_raw=OUT+'/bark_normal.png';nm.file_format='PNG';nm.save();nm.pack()
tn=nodes.new('ShaderNodeTexImage');tn.image=nm;normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.45;links.new(tn.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],p.inputs['Normal'])
# Place the scar on actual fused bark rather than hanging in the trunk gap.
scar=bpy.data.objects['Banyan_Scar']
for v in scar.data.vertices:
 x=v.co.x-.24;hit,loc,no,idx=tree.ray_cast(Vector((x,-5,v.co.z)),Vector((0,1,0)))
 if hit:v.co=loc+no*.012
for o in bpy.context.scene.objects:
 if o.type=='MESH':o.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=WORK+'/banyan_03_material.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/banyan_01.glb',export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
print('TRIANGLES',sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons))
