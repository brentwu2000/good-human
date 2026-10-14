import bpy,bmesh,math,numpy as np
from pathlib import Path
from mathutils import Vector
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
a=bpy.data.objects['Shiba_Rig_Delivery'];verts=[];faces=[];N=20
for z,rx,ry,cy in [(.169,.030,.024,-.055),(.182,.043,.029,-.065),(.205,.048,.029,-.067),(.235,.050,.025,-.060)]:
 for i in range(N):
  angle=2*math.pi*i/N;c=math.cos(angle);blend=max(0,min(1,(c-.3)/.5));blend=blend*blend*(3-2*blend);verts.append((rx*math.sin(angle)*(.72+.28*blend),cy+ry*c,z))
for ring in range(3):
 for i in range(N):j=(i+1)%N;faces.append((ring*N+i,ring*N+j,(ring+1)*N+j,(ring+1)*N+i))
faces.extend([tuple(reversed(range(N))),tuple(range(3*N,4*N))])
mesh=bpy.data.meshes.new('NeckTransition');mesh.from_pydata(verts,[],faces);mesh.update();bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free();ob=bpy.data.objects.new('ChihuahuaNeckTransition',mesh);bpy.context.scene.collection.objects.link(ob);ob.parent=a
head=ob.vertex_groups.new(name='head');neck=ob.vertex_groups.new(name='neck')
col=mesh.color_attributes.new(name='Coat',type='FLOAT_COLOR',domain='POINT')
for v in mesh.vertices:
 w=max(0,min(1,(v.co.z-.163)/.032));head.add([v.index],w,'REPLACE');neck.add([v.index],1-w,'REPLACE');white=max(0,min(1,(.8-math.cos(2*math.pi*(v.index%N)/N))/.4));white=white*white*(3-2*white);tan=(.625,.32,.12);cream=(.67,.60,.49);col.data[v.index].color=tuple(tan[i]*(1-white)+cream[i]*white for i in range(3))+(1,)
for p in mesh.polygons:p.use_smooth=True
ob.modifiers.new('Armature','ARMATURE').object=a
mat=bpy.data.materials.new('NeckTransitionCoat');mat.use_nodes=True;p=mat.node_tree.nodes['Principled BSDF'];p.inputs['Roughness'].default_value=.85;attr=mat.node_tree.nodes.new('ShaderNodeVertexColor');attr.layer_name='Coat';mat.node_tree.links.new(attr.outputs['Color'],p.inputs['Base Color']);ob.data.materials.append(mat)
def sm(t):
 t=max(0,min(1,t));return t*t*(3-2*t)
h=bpy.data.objects['ChihuahuaHead']
for v in h.data.vertices:
 w=sm((.196-v.co.z)/.025)*sm((v.co.y+.085)/.035)
 if w>0:v.co.x*=1-.3*w;v.co.y-=.004*w
for v in h.data.vertices:
 x,y,z=v.co
 if z>=.2 or y<-.08:continue
 rx=float(np.interp(z,[.169,.182,.205],[.03,.043,.056]));ry=float(np.interp(z,[.169,.182,.205],[.024,.029,.029]));cy=float(np.interp(z,[.169,.182,.205],[-.055,-.065,-.067]));r=math.sqrt((x/rx)**2+((y-cy)/ry)**2)
 if r>.93:
  w=sm((.2-z)/.015);fac=1-w+w*.93/r;v.co.x=x*fac;v.co.y=cy+(y-cy)*fac
h.data.update()
s=bpy.context.scene;s.render.filepath=str(OUT/'neck_bridge_back.png');bpy.ops.render.render(write_still=True)
s.camera.location=(.75,-.75,.35);s.camera.data.ortho_scale=.52;s.camera.rotation_euler=(Vector((0,.025,.17))-s.camera.location).to_track_quat('-Z','Y').to_euler();a.animation_data.action=bpy.data.actions['Refined_Howl'];s.frame_set(69);s.render.filepath=str(OUT/'neck_bridge_howl.png');bpy.ops.render.render(write_still=True)
a.animation_data.action=None
for p in a.pose.bones:p.matrix_basis.identity()
s.frame_set(0);bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_neck_bridge.blend'))
