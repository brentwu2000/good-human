"""Restore boolean-created vertex weights by barycentric source-surface transfer."""
import bpy,json
from mathutils.bvhtree import BVHTree
from pathlib import Path
OUT=Path('C:/Users/b/Documents/good-human/build/poodle_refine_r40')
obj=bpy.data.objects['DogBody'];donor=bpy.data.objects['R40_SurfaceSource'];donor.data.calc_loop_triangles()
tris=[tuple(t.vertices) for t in donor.data.loop_triangles];coords=[v.co.copy() for v in donor.data.vertices];tree=BVHTree.FromPolygons(coords,tris,all_triangles=True)
fixed=0;max_dist=0
for v in obj.data.vertices:
    for entry in list(v.groups):obj.vertex_groups[entry.group].remove([v.index])
    p,normal,idx,dist=tree.find_nearest(v.co);assert idx is not None
    ia,ib,ic=tris[idx];a,b,c=coords[ia],coords[ib],coords[ic];ab=b-a;ac=c-a;ap=p-a
    aa=ab.dot(ab);cc=ac.dot(ac);cross=ab.dot(ac);den=aa*cc-cross*cross
    if abs(den)<1e-18:weights=[1,0,0]
    else:
        wb=(cc*ap.dot(ab)-cross*ap.dot(ac))/den;wc=(aa*ap.dot(ac)-cross*ap.dot(ab))/den;weights=[1-wb-wc,wb,wc]
    accum={}
    for vertex,coef in zip([ia,ib,ic],weights):
        for g in donor.data.vertices[vertex].groups:accum[g.group]=accum.get(g.group,0)+max(0,coef)*g.weight
    influences=sorted(accum.items(),key=lambda q:-q[1])[:8];total=sum(w for _,w in influences);assert total>0
    for gi,w in influences:
        if w>0:obj.vertex_groups[donor.vertex_groups[gi].name].add([v.index],w/total,'REPLACE')
    fixed+=1;max_dist=max(max_dist,dist)
assert all(sum(g.weight for g in v.groups)>0 for v in obj.data.vertices)
report={'surface_vertices_reweighted':fixed,'max_source_surface_distance_m':max_dist,'method':'nearest triangle barycentric interpolation; all weights restored by source bone name after boolean operations'}
(OUT/'skin_transfer.json').write_text(json.dumps(report,indent=2));print(report)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'poodle_r40_13_surface_weights.blend'))
