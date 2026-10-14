import bpy,math
from mathutils import Vector
from pathlib import Path
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
h=bpy.data.objects['ChihuahuaHead'];mesh=h.data
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'before_rear_cranium.blend'))
def sm(t):
 t=max(0,min(1,t));return t*t*(3-2*t)
for v in mesh.vertices:
 x,y,z=v.co
 if y<-.055 or z>.294 or z<.19:continue
 r=(x/.086)**2+((z-.251)/.062)**2
 if r>=1:continue
 target=-.062+.075*math.sqrt(1-r);w=sm((y+.055)/.035)*sm((z-.19)/.028)*sm((.294-z)/.016)
 if target>y:v.co.y+=(target-y)*w*.8
mesh.update();keys=[tuple(round(c,6) for c in v.co) for v in mesh.vertices];sums={}
for p in mesh.polygons:
 for idx in p.vertices:sums[keys[idx]]=sums.get(keys[idx],Vector((0,0,0)))+p.normal*p.area
mesh.normals_split_custom_set_from_vertices([sums.get(k,Vector((0,0,1))).normalized() for k in keys]);mesh.update()
collar=bpy.data.objects['ChihuahuaCollar']
for v in collar.data.vertices:
 x,y,z=v.co
 if z>.177+(y+.055)*.28:v.co.z+=.006*sm((y+.060)/.03)
collar.data.update()
for act in bpy.data.actions:
 if act.name.startswith('Refined_'):act.use_fake_user=True
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_r38_editable.blend'))
