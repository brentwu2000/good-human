import bpy,bmesh,math
from pathlib import Path
from mathutils import Vector
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'before_neck_collar.blend'))
head=bpy.data.objects['ChihuahuaHead'];body=bpy.data.objects['ChihuahuaBodyTopology'];arm=body.parent
# Tuck only the hanging neck rim under the new collar; preserve the muzzle.
for v in head.data.vertices:
 p=v.co
 if p.y>-.055 and p.z<.197:
  t=max(0,min(1,(.197-p.z)/.032));t=t*t*(3-2*t)
  y0=p.y+.055;r=math.sqrt((p.x/.035)**2+(y0/.032)**2)
  if r>1:
   p.x+=(p.x/r-p.x)*t;p.y+=((-.055+y0/r)-p.y)*t
# Broad, rounded pads instead of tapering feet. Rest positions stay on the floor.
for v in body.data.vertices:
 p=v.co;t=max(0,min(1,(.038-p.z)/.025));t=t*t*(3-2*t)
 if t>0:
  cx=.027 if p.x>=0 else -.027; cy=-.043 if p.y<.02 else .121
  p.x+=(p.x-cx)*.45*t;p.y-=(.006)*t
  p.z=max(.001,p.z)
# A real elliptical leather strap masks the neck join and receives its own material.
verts=[];faces=[];N=64
for j in range(4):
 outer=j in (0,1);top=j in (1,2)
 for i in range(N):
  a=2*math.pi*i/N;rx=.040 if outer else .037;ry=.035 if outer else .032
  y=-.055+ry*math.sin(a);z=.177+(y+.055)*.28+(.007 if top else -.007)
  verts.append((rx*math.cos(a),y,z))
for j in range(4):
 for i in range(N):
  faces.append((j*N+i,j*N+(i+1)%N,((j+1)%4)*N+(i+1)%N,((j+1)%4)*N+i))
mesh=bpy.data.meshes.new('CollarStrap');mesh.from_pydata(verts,[],faces);mesh.update()
collar=bpy.data.objects.new('ChihuahuaCollar',mesh);bpy.context.collection.objects.link(collar)
mat=bpy.data.materials.new('Collar_RedLeather');mat.diffuse_color=(.27,.018,.012,1);mat.use_nodes=True
bs=mat.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=(.27,.018,.012,1);bs.inputs['Roughness'].default_value=.55
collar.data.materials.append(mat)
bevel=collar.modifiers.new('SoftLeatherEdges','BEVEL');bevel.width=.0008;bevel.segments=1
for p in mesh.polygons:p.use_smooth=True
collar.parent=arm;g=collar.vertex_groups.new(name='neck');g.add(list(range(len(mesh.vertices))),1,'REPLACE');collar.modifiers.new('Rig','ARMATURE').object=arm
scene=bpy.context.scene;cam=scene.camera;cam.location=(.75,-.75,.35);cam.rotation_euler=(Vector((0,.01,.175))-cam.location).to_track_quat('-Z','Y').to_euler()
scene.render.filepath=str(OUT/'collar_paws_candidate.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_detail_01.blend'))
print('NECK_COLLAR_PAWS_CANDIDATE')
