import bpy,math,json,bmesh
from mathutils import Vector
ROOT=r'C:/Users/b/Documents/good-human';OUT=ROOT+'/build/market_auntie_refine_r2'
bpy.ops.wm.open_mainfile(filepath=OUT+'/01_head_and_towel.blend')
rig=bpy.data.objects['OwnerSkeleton'];added=[]
def mat(name,col,rough=.7,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True;n=m.node_tree.nodes.get('Principled BSDF');n.inputs['Base Color'].default_value=(*col,1);n.inputs['Roughness'].default_value=rough;n.inputs['Metallic'].default_value=metal;return m
leather=mat('Satchel warm leather',(.105,.047,.023),.68);edge=mat('Rolled leather edge',(.047,.019,.011),.72);thread=mat('Warm linen stitching',(.46,.30,.13),.85);brass=mat('Aged brass',(.34,.22,.075),.38,.7)
# Restrained microstructure: material bump is baked/exported as geometry-free finish only in Blender.
# Game material stays plain PBR; visible stitching and flap volume are real geometry.
def bind(o,bone='pelvis'):
 o.name='R2_'+o.name;vg=o.vertex_groups.new(name=bone);vg.add(list(range(len(o.data.vertices))),1,'REPLACE');m=o.modifiers.new('Original skeleton','ARMATURE');m.object=rig;o.parent=rig;added.append(o)
def box(name,loc,scale,material,bevel=.008):
 bm=bmesh.new();bmesh.ops.create_cube(bm,size=1)
 for v in bm.verts:
  for k in range(3):v.co[k]=v.co[k]*scale[k]+loc[k]
 bmesh.ops.bevel(bm,geom=list(bm.edges),offset=bevel,segments=3,affect='EDGES')
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 me=bpy.data.meshes.new(name);bm.to_mesh(me);bm.free();o=bpy.data.objects.new(name,me);bpy.context.scene.collection.objects.link(o)
 for p in o.data.polygons:p.use_smooth=True
 o.data.materials.append(material);bind(o);return o
# Satchel sits behind the right hand with its flap facing outwards (+X).
box('Satchel body',(.318,.108,.565),(.118,.232,.205),leather,.018)
box('Satchel flap',(.384,.108,.623),(.020,.237,.107),leather,.012)
box('Flap hem',(.396,.108,.580),(.008,.207,.010),edge,.004)
for yy in [.046,.168]:
 box('Closure tongue',(.400,yy,.563),(.010,.025,.085),edge,.004)
 box('Brass clasp',(.409,yy,.565),(.012,.036,.026),brass,.004)
 # Individual stitches are large enough to survive gameplay resolution.
 for zz in [.598,.614,.630,.646]:box('Flap stitch',(.398,yy,zz),(.003,.007,.0025),thread,.001)
for yy in [-.001,.217]:
 for zz in [.510,.526,.542,.558,.574,.590,.606]:box('Side stitch',(.379,yy,zz),(.003,.006,.0025),thread,.001)
# Flat crossbody leather strap, routed over the actual torso surface rather than painted on.
path=[(-.18,-.12,.98),(-.14,-.205,.92),(-.07,-.249,.86),(.02,-.270,.79),(.11,-.266,.72),(.20,-.218,.66),(.29,-.08,.62),(.35,.02,.63)]
verts=[]
for i,p in enumerate(path):
 p=Vector(p);direction=Vector(path[min(i+1,len(path)-1)])-Vector(path[max(0,i-1)]);side=direction.cross(Vector((0,-1,0))).normalized()*.017
 verts.extend([p-side,p+side])
faces=[]
for i in range(len(path)-1):faces.append((i*2,i*2+1,i*2+3,i*2+2))
m=bpy.data.meshes.new('Crossbody strap');m.from_pydata(verts,[],faces);m.update();o=bpy.data.objects.new('Crossbody strap',m);bpy.context.collection.objects.link(o);o.data.materials.append(edge)
bpy.context.view_layer.objects.active=o;o.select_set(True);solid=o.modifiers.new('Leather thickness','SOLIDIFY');solid.thickness=.003;bind(o,'spine_03')
# Save a rebuildable checkpoint before export.
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/02_satchel.blend')
print('SATCHEL_OBJECTS',len(added),'TRIANGLES',sum(sum(len(p.vertices)-2 for p in ob.data.polygons) for ob in added))
