import bpy,json,numpy as np
from pathlib import Path
OUT=Path(r'C:/Users/b/Documents/good-human/build/dog_delivery')
a=bpy.data.objects['Shiba_Rig_Delivery'];s=bpy.context.scene
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'before_export_prepare.blend'))
a.animation_data.action=None
for p in a.pose.bones:p.matrix_basis.identity()
s.frame_set(0)
meshes=[o for o in bpy.data.objects if o.type=='MESH' and o.parent==a]
for act in bpy.data.actions:
 if act.name.startswith('Refined_'):act.use_fake_user=True
# Joining a coloured neck patch must not introduce zero colours on the other surfaces.
for ob in meshes:
 if not ob.data.color_attributes.get('Coat'):
  attr=ob.data.color_attributes.new(name='Coat',type='FLOAT_COLOR',domain='POINT')
  for datum in attr.data:datum.color=(1,1,1,1)
# Limit portable skinning to the four strongest deform influences per vertex.
trimmed=0
for o in meshes:
 for v in o.data.vertices:
  weights=sorted([(g.group,g.weight) for g in v.groups if g.weight>1e-8],key=lambda p:-p[1]);keep=weights[:4];total=sum(w for _,w in keep);assert total>0,(o.name,v.index)
  if len(weights)>4:trimmed+=1
  for idx,_ in weights:o.vertex_groups[idx].remove([v.index])
  for idx,w in keep:o.vertex_groups[idx].add([v.index],w/total,'REPLACE')
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 for m in list(o.modifiers):
  if m.type!='ARMATURE':bpy.ops.object.modifier_apply(modifier=m.name)
# Bake tongue's small colour gradient, so the export has no procedural dependency.
o=bpy.data.objects['ChihuahuaTongue'];n=o.active_material.node_tree.nodes;l=o.active_material.node_tree.links;bs=n.get('Principled BSDF');out=n.get('Material Output');col=bs.inputs['Base Color'].links[0].from_socket
bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
im=bpy.data.images.new('Tongue_Albedo',width=256,height=256,alpha=False);tex=n.new('ShaderNodeTexImage');tex.image=im;n.active=tex;em=n.new('ShaderNodeEmission');l.new(col,em.inputs[0]);l.new(em.outputs[0],out.inputs[0]);s.render.engine='CYCLES';s.cycles.samples=1;s.cycles.device='CPU';s.render.bake.margin=8;bpy.ops.object.bake(type='EMIT');im.pack();l.new(bs.outputs[0],out.inputs[0]);l.new(tex.outputs[0],bs.inputs['Base Color']);s.render.engine='BLENDER_EEVEE'
# One skinned mesh, retaining material slots, UVs and named deform groups.
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:o.select_set(True)
bpy.context.view_layer.objects.active=bpy.data.objects['ChihuahuaBodyTopology'];bpy.ops.object.join();body=bpy.context.object;body.name='DogBody_Delivery'
body.data.calc_loop_triangles();print('EXPORT_TRIANGLES',len(body.data.loop_triangles),'TRIMMED_SKIN_VERTICES',trimmed)
report={'triangles':len(body.data.loop_triangles),'bones':len(a.data.bones),'vertices':len(body.data.vertices),'trimmed_weights':trimmed,'clips':{}}
for label in ['Run','Sneak','Fetch','Bark','Alert','Jump','Howl','Sit','Idle','Walk']:
 act=bpy.data.actions['Refined_'+label];a.animation_data.action=act;lows=[];highs=[];bad=0
 for frame in range(int(act.frame_range[1])+1):
  s.frame_set(frame);dg=bpy.context.evaluated_depsgraph_get();e=body.evaluated_get(dg);co=np.empty(len(e.data.vertices)*3,dtype=np.float32);e.data.vertices.foreach_get('co',co);co=co.reshape(-1,3);bad+=int(not np.isfinite(co).all());lows.append(float(co[:,2].min()));highs.append(float(co[:,2].max()))
 report['clips'][label]={'frames':len(lows),'lowest':min(lows),'highest_lowest':max(lows),'height_max':max(highs),'nonfinite_frames':bad}
 print('AUDITED',label,round(min(lows),6),round(max(lows),6))
assert report['triangles']<=15000
assert all(v['nonfinite_frames']==0 and v['lowest']>-.002 for v in report['clips'].values())
(OUT/'delivery_skin_audit.json').write_text(json.dumps(report,indent=2))
a.animation_data.action=None
for p in a.pose.bones:p.matrix_basis.identity()
s.frame_set(0);bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_export_ready.blend'))
print('EXPORT_PREPARED')
