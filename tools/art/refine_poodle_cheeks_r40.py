"""Soften retained cheek rim in depth without moving frontal facial landmarks."""
import bpy,math,json
from pathlib import Path
OUT=Path('C:/Users/b/Documents/good-human/build/poodle_refine_r40');obj=bpy.data.objects['DogBody']
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_r40_10_before_cheeks.blend'))
original=[v.co.copy() for v in obj.data.vertices];adj=[set() for v in obj.data.vertices]
for e in obj.data.edges:
    a,b=e.vertices;adj[a].add(b);adj[b].add(a)
for iteration in range(12):
    coords=[v.co.copy() for v in obj.data.vertices]
    for v in obj.data.vertices:
        x,y,z=coords[v.index];xx=abs(x)
        if not (.040<xx<.105 and .270<z<.345 and y<-.085) or not adj[v.index]:continue
        eye=((xx-.052)/.023)**2+((z-.348)/.025)**2
        protect=max(0,min(1,(eye-.90)/.7))
        edge=max(0,min(1,(xx-.040)/.018))*max(0,min(1,(-y-.085)/.025))
        weight=math.exp(-((xx-.075)/.022)**2-((z-.324)/.044)**2)*protect*edge*max(0,min(1,(.345-z)/.018))
        dy=(sum(coords[j].y for j in adj[v.index])/len(adj[v.index])-y)*.35*weight
        v.co.y=max(original[v.index].y-.0035,min(original[v.index].y+.0035,y+dy))
obj.data.normals_split_custom_set([(0,0,0)]*len(obj.data.loops));obj.data.update()
report={'max_depth_shift_m':max(abs(v.co.y-original[v.index].y) for v in obj.data.vertices),'frontal_x_z_preserved':all(v.co.x==original[v.index].x and v.co.z==original[v.index].z for v in obj.data.vertices)}
(OUT/'cheeks.json').write_text(json.dumps(report,indent=2));print(report)
bpy.context.scene.render.filepath=str(OUT/'cheeks_front.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_r40_11_cheeks.blend'))
