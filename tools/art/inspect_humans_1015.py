import bpy,sys,json,os,numpy as np
from mathutils import Vector
ROOT=r'C:/Users/b/Documents/good-human'
os.chdir(ROOT)
sys.path.insert(0,ROOT+'/art_pipeline/scripts')
import inspect_asset as ia
out={}
for name in ['office_worker','market_auntie','retired_fisher','delivery_rider','gym_coach','xiaomi']:
 bpy.ops.wm.open_mainfile(filepath=ROOT+'/art_pipeline/assets/work/'+name+'_E_baked.blend')
 o=bpy.data.objects['Character'];m=o.data
 pos=np.array([o.matrix_world@v.co for v in m.vertices])
 rid=np.array([d.value for d in m.attributes['region_id'].data])
 cfg=json.load(open('art_pipeline/config/characters/'+name+'.json'))
 regs={}
 for r in cfg['regions']:
  ids=set(v for p in m.polygons if rid[p.index]==r['id'] for v in p.vertices)
  pts=pos[list(ids)]
  regs[r['name']]={'faces':int((rid==r['id']).sum()),'bounds':[pts.min(0).tolist(),pts.max(0).tolist()] if len(pts) else None}
 out[name]={'mesh':ia.mesh_report(o),'matrix':[list(x) for x in o.matrix_world],'bounds':[pos.min(0).tolist(),pos.max(0).tolist()],'regions':regs,'bones':[{b.name:list(b.head_local) for b in x.data.bones} for x in bpy.data.objects if x.type=='ARMATURE'],'images':[(i.name,list(i.size)) for i in bpy.data.images]}
json.dump(out,open('build/human_refine_2026_10_15/inspection.json','w'),indent=2)
print('HUMAN_INSPECTION_COMPLETE')
