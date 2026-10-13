import bpy
from mathutils import Vector
from pathlib import Path
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
head=bpy.data.objects['ChihuahuaHead']
def smooth(t):
 t=max(0,min(1,t));return t*t*(3-2*t)
changed=0
for v in head.data.vertices:
 x,y,z=v.co
 # Blend the low rear skull into the neck; retain the upper cranium and ears.
 w=smooth((.258-z)/.045)*smooth((y+.032)/.035)
 if w>0:
  v.co.y=y-(y+.031)*w*.9
  changed+=1
head.data.update()
scene=bpy.context.scene;cam=scene.camera
for name,loc in [('side',(1,0,.2)),('threequarter',(.75,-.75,.35))]:
 cam.location=loc;cam.rotation_euler=(Vector((0,.025,.17))-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(OUT/('neck_refined_'+name+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_neck_refined.blend'))
print('REAR_SKULL_VERTICES',changed)
