import bpy
from pathlib import Path
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'before_neck_skin_refine.blend'))
def sm(t):
 t=max(0,min(1,t));return t*t*(3-2*t)
for name in ['ChihuahuaBodyTopology','ChihuahuaCollar']:
 ob=bpy.data.objects[name];head=ob.vertex_groups.get('head') or ob.vertex_groups.new(name='head')
 for v in ob.data.vertices:
  x,y,z=v.co
  if name=='ChihuahuaBodyTopology' and not(z>.153 and y<-.026):continue
  w=.8*sm((z-.156)/.040)
  if w<.001:continue
  for idx,weight in [(g.group,g.weight) for g in v.groups]:ob.vertex_groups[idx].add([v.index],weight*(1-w),'REPLACE')
  head.add([v.index],w,'REPLACE')
h=bpy.data.objects['ChihuahuaHead']
for v in h.data.vertices:
 if v.co.y>-.04 and v.co.z<.193:v.co.y-=.006*sm((.193-v.co.z)/.025)
h.data.update()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_neck_skin_refined.blend'))
