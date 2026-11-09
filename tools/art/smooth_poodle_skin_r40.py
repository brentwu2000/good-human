"""Continuous spatial skin field across newly joined ear surfaces."""
import bpy,math,json
from mathutils.kdtree import KDTree
from pathlib import Path
OUT=Path('C:/Users/b/Documents/good-human/build/poodle_refine_r40');obj=bpy.data.objects['DogBody'];donor=bpy.data.objects['R40_SurfaceSource']
kd=KDTree(len(donor.data.vertices))
for v in donor.data.vertices:kd.insert(v.co,v.index)
kd.balance()
def fade(a,b,x):
    t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
changed=0
for v in obj.data.vertices:
    x,y,z=v.co;mask=fade(.060,.090,abs(x))*fade(.230,.270,z)
    if mask==0:continue
    near=kd.find_range(v.co,.030);field={};total=0
    for _,idx,dist in near:
        factor=math.exp(-.5*(dist/.010)**2);total+=factor
        for g in donor.data.vertices[idx].groups:field[g.group]=field.get(g.group,0)+g.weight*factor
    if total==0:continue
    old={g.group:g.weight for g in v.groups};mixed={i:(1-mask)*old.get(i,0)+mask*field.get(i,0)/total for i in set(old)|set(field)}
    weights=sorted(mixed.items(),key=lambda q:-q[1])[:8];norm=sum(w for i,w in weights)
    for g in list(v.groups):obj.vertex_groups[g.group].remove([v.index])
    for i,w in weights:
        if w>1e-8:obj.vertex_groups[i].add([v.index],w/norm,'REPLACE')
    changed+=1
(OUT/'skin_smoothing.json').write_text(json.dumps({'vertices':changed,'radius_m':.030,'sigma_m':.010,'mask':'ears and lateral head, fades into unchanged neck and central face'},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_r40_14_continuous_skin.blend'));print('continuous_skin_vertices',changed)
