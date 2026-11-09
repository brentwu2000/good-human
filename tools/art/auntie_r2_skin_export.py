import bpy,os,json,math
ROOT=r'C:/Users/b/Documents/good-human';OUT=ROOT+'/build/market_auntie_refine_r2';DST=ROOT+'/assets/art_previews/humans/market_auntie_r2'
bpy.ops.wm.open_mainfile(filepath=OUT+'/03_export.blend')
rig=bpy.data.objects['OwnerSkeleton'];o=bpy.data.objects['Character'];names={g.name:g.index for g in o.vertex_groups}
def smooth(t):t=max(0,min(1,t));return t*t*(3-2*t)
changed=0;body_ids=set(v for p in o.data.polygons if p.material_index==0 for v in p.vertices)
for v in o.data.vertices:
 if v.index not in body_ids:continue
 x,y,z=v.co
 # Inspected apron/torso volume: taper at sleeves and hem, exclude hands/head.
 a=0.0 # Torso trial rejected after motion review: restore original body weights.
 if a<1e-5:continue
 old={g.group:g.weight for g in v.groups};upper=smooth((z-.70)/.20);target={names['pelvis']:1-upper,names['spine_03']:upper}
 values={k:(1-a)*old.get(k,0)+a*target.get(k,0) for k in set(old)|set(target)}
 for g in o.vertex_groups:g.remove([v.index])
 total=sum(values.values())
 for k,w in values.items():
  if w>1e-6:o.vertex_groups[k].add([v.index],w/total,'REPLACE')
 changed+=1
bag=bpy.data.objects['Auntie_Satchel'];sp=bag.vertex_groups.get('spine_03');pel=bag.vertex_groups.get('pelvis')
strap_count=0
for v in bag.data.vertices:
 if any(g.group==sp.index and g.weight>.9 for g in v.groups):
  world=bag.matrix_world@v.co;t=smooth((world.z-.65)/.29)
  sp.add([v.index],t,'REPLACE');pel.add([v.index],1-t,'REPLACE');strap_count+=1
rig.data.pose_position='POSE';selected=[rig,o,bag]
for ob in bpy.context.view_layer.objects:ob.select_set(ob in selected)
bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/04_skin_refined.blend')
with bpy.context.temp_override(window=bpy.context.window_manager.windows[0],active_object=rig,object=rig,selected_objects=selected,selected_editable_objects=selected):
 bpy.ops.export_scene.gltf(filepath=DST+'/market_auntie.glb',export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_apply=True)
json.dump({'torso_vertices_reweighted':changed,'strap_vertices_blended':strap_count,'rig_bones':len(rig.data.bones)},open(OUT+'/skin.json','w'),indent=2)
print('SKIN_REFINED',changed,strap_count)
