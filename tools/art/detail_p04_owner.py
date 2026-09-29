import bpy, math, random, bmesh
from mathutils import Vector
from mathutils.kdtree import KDTree
random.seed(41)
WORK=r'C:\Users\b\Documents\good-human-3d-pipeline\blender\human\p04_owner'
bpy.ops.wm.save_as_mainfile(filepath=WORK+'/owner_03_before_detail.blend')
rig=bpy.data.objects['OwnerSkeleton']; top=bpy.data.objects['Top_Jacket']
def mat(name,c,rough=.75):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*c,1)
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=rough;return m
trim=mat('GH_Seam',(.14,.115,.08));metal=mat('GH_Zip',(.23,.21,.18),.4)
hair=bpy.data.materials['GH_Hair'];iris=bpy.data.materials.get('GH_Iris') or mat('GH_Iris',(.047,.028,.015),.28);pupil=mat('GH_Pupil',(.004,.003,.002),.23)
skin=bpy.data.materials['GH_Skin']; cotton=bpy.data.materials['GH_Cotton']
kd=KDTree(len(top.data.vertices))
for v in top.data.vertices:kd.insert(v.co,v.index)
kd.balance()
def bind(o,bone=None):
 o.parent=rig
 if bone:
  g=o.vertex_groups.new(name=bone);g.add(list(range(len(o.data.vertices))),1,'REPLACE')
 else:
  for b in rig.data.bones:o.vertex_groups.new(name=b.name)
  for v in o.data.vertices:
   _,idx,_=kd.find(v.co)
   for g in top.data.vertices[idx].groups:
    n=top.vertex_groups[g.group].name
    if n in o.vertex_groups:o.vertex_groups[n].add([v.index],g.weight,'REPLACE')
 a=o.modifiers.new('Skin','ARMATURE');a.object=rig
 for p in o.data.polygons:p.use_smooth=True
 return o
def tube(name,pts,radii,material,bone=None,sides=6):
 vs=[];fs=[]
 for i,p in enumerate(pts):
  p=Vector(p);t=Vector(pts[min(i+1,len(pts)-1)])-Vector(pts[max(0,i-1)])
  t.normalize();u=t.cross(Vector((0,1,0)))
  if u.length<.01:u=t.cross(Vector((1,0,0)))
  u.normalize();v=t.cross(u).normalized()
  for j in range(sides):vs.append(p+radii[i]*(math.cos(j*math.tau/sides)*u+math.sin(j*math.tau/sides)*v))
 for k in range(len(pts)-1):
  for j in range(sides):fs.append((k*sides+j,k*sides+(j+1)%sides,(k+1)*sides+(j+1)%sides,(k+1)*sides+j))
 fs.extend([tuple(reversed(range(sides))),tuple((len(pts)-1)*sides+j for j in range(sides))])
 me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.materials.append(material)
 o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);return bind(o,bone)
def front(x,z):
 vs=[v.co for v in top.data.vertices if abs(v.co.x-x)<.04 and abs(v.co.z-z)<.035]
 return min(v.y for v in vs)-.006 if vs else -.17

# Jacket zip, collar fold and pocket welts are actual geometry.
pts=[(0,front(0,z),z) for z in [1.0,1.08,1.16,1.24,1.32,1.39,1.45]]
tube('Jacket_Zipper',pts,[.0035]*len(pts),metal)
for side in [-1,1]:
 pts=[(side*.11,front(side*.11,z),z) for z in [1.01,1.045,1.085,1.12]]
 tube('Pocket_Welt',pts,[.005]*4,trim)
 pts=[(side*.055,-.12,1.48),(side*.085,-.128,1.46),(side*.11,-.15,1.40),(side*.05,-.172,1.415)]
 tube('Collar_Fold',pts,[.011,.014,.013,.006],bpy.data.materials['GH_Jacket'])
 # Ribbed hem and cuffs use continuous contours rather than detached blocks.
pts=[(.2*math.cos(a),.145*math.sin(a)-.015,.966+.008*math.cos(2*a)) for a in [i*math.tau/32 for i in range(33)]]
tube('Jacket_Hem',pts,[.01]*len(pts),trim)
for side in ['l','r']:
 b=rig.data.bones['lowerarm_'+side];p=b.tail_local;axis=(b.tail_local-b.head_local).normalized();u=axis.cross(Vector((0,1,0))).normalized();v=axis.cross(u)
 pts=[p-axis*.035+.041*(math.cos(i*math.tau/20)*u+math.sin(i*math.tau/20)*v) for i in range(21)]
 tube('Cuff_'+side,pts,[.009]*21,trim,'lowerarm_'+side)
 # Irises/pupils follow the head, with a slight front-facing convex surface.
 eye=bpy.data.objects['Eye_'+side];c=sum((v.co for v in eye.data.vertices),Vector())/len(eye.data.vertices)
 for name,radius,depth,m in [('Iris',.0088,-.158,iris),('Pupil',.0042,-.160,pupil)]:
  bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=1,location=(c.x,depth,c.z));o=bpy.context.view_layer.objects.active;o.name=name+'_'+side;o.scale=(radius,.002,radius)
  bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);o.data.materials.append(m);bind(o,'head')

# Short layered hair locks give a swept silhouette; no expensive strand system.
for i in range(34):
 a=random.uniform(-2.7,.5);x=random.uniform(-.074,.074);z=1.735+random.uniform(-.009,.015);y=random.uniform(-.092,.035)
 pts=[(x,y,z),(x+.012,y-.008,z+.018),(x+.028,y-.025,z+.016),(x+.04,y-.044,z-.009)]
 tube('Hair_Lock_%02d'%i,pts,[.012,.014,.009,.0015],hair,'head')
for side in [-1,1]:
 tube('Eyebrow',[(side*.015,-.157,1.665),(side*.031,-.164,1.67),(side*.049,-.157,1.666)],[.0025,.0035,.0018],hair,'head')

# Exportable vertex variation: subtle cloth/skin tones rather than unsupported shader noise.
for name in ['Top_Jacket','Bottom_Jeans','Body_HeadHands','Hair_Short']:
 o=bpy.data.objects[name];attr=o.data.color_attributes.new(name='ArtTone',type='FLOAT_COLOR',domain='POINT')
 base=o.data.materials[0].diffuse_color
 for v in o.data.vertices:
  f=.96+.04*math.sin(v.co.z*64+v.co.x*19)*math.sin(v.co.y*72+v.co.z*21)
  attr.data[v.index].color=(base[0]*f,base[1]*f,base[2]*f,1)
 m=o.data.materials[0].copy();m.name=m.name+'_Vertex';o.data.materials[0]=m
 n=m.node_tree.nodes.new('ShaderNodeVertexColor');n.layer_name='ArtTone';m.node_tree.links.new(n.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
bpy.ops.wm.save_as_mainfile(filepath=WORK+'/owner_04_detail.blend')
print('DETAIL_COMPLETE')

