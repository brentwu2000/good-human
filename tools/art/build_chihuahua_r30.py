"""R30: Ucupaint masked cheek repair on the unchanged r29 mesh."""
import bpy,os,importlib,json
from pathlib import Path
ROOT=Path(r'C:\Users\b\Documents\good-human');OUT=ROOT/'build/chihuahua_mouth_r30';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'chihuahua_r30_01_before_layers.blend'))
for ob in list(bpy.data.objects):bpy.data.objects.remove(ob,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/art_previews/dogs/candidates/r29/chihuahua.glb'))
dog=bpy.data.objects['DogBody'];bpy.context.view_layer.objects.active=dog;dog.select_set(True)
mat=dog.active_material;nt=mat.node_tree;n=nt.nodes;l=nt.links
bs=next(a for a in n if a.type=='BSDF_PRINCIPLED');output=next(a for a in n if a.type=='OUTPUT_MATERIAL')
base=bs.inputs['Base Color'].links[0].from_node.image
ref=bpy.data.images.load(r'C:\Users\b\Documents\good_human_stylized_factory\references\dogs\chihuahua_side.png',check_existing=True)
def m(op,a,b=0):
 node=n.new('ShaderNodeMath');node.operation=op
 for i,v in enumerate([a,b]):
  if isinstance(v,(int,float)):node.inputs[i].default_value=v
  else:l.new(v,node.inputs[i])
 return node.outputs[0]
def ramp(a,lo,hi):
 node=n.new('ShaderNodeMapRange');node.interpolation_type='SMOOTHSTEP';node.clamp=True
 l.new(a,node.inputs['Value']);node.inputs['From Min'].default_value=lo;node.inputs['From Max'].default_value=hi
 return node.outputs[0]
geo=n.new('ShaderNodeNewGeometry');sep=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Position'],sep.inputs[0]);x,y,z=sep.outputs
ax=m('ABSOLUTE',x)
mask=ramp(y,-.151,-.142)
for f in [m('SUBTRACT',1,ramp(y,-.085,-.065)),ramp(z,.175,.181),m('SUBTRACT',1,ramp(z,.211,.219)),ramp(ax,.014,.024),m('SUBTRACT',1,ramp(ax,.045,.057))]:mask=m('MULTIPLY',mask,f)
luma=n.new('ShaderNodeRGBToBW');l.new(bs.inputs['Base Color'].links[0].from_socket,luma.inputs[0])
mask=m('MULTIPLY',mask,m('SUBTRACT',1,ramp(luma.outputs[0],.18,.60)))
px=m('ADD',220,m('MULTIPLY',m('ADD',y,.125),800))
py=m('SUBTRACT',348,m('MULTIPLY',m('SUBTRACT',z,.195),950))
uv=n.new('ShaderNodeCombineXYZ');l.new(m('DIVIDE',px,768),uv.inputs['X']);l.new(m('SUBTRACT',1,m('DIVIDE',py,768)),uv.inputs['Y'])
tex=n.new('ShaderNodeTexImage');tex.image=ref;l.new(uv.outputs[0],tex.inputs['Vector'])
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
scene.render.bake.margin=8;scene.render.bake.use_clear=True
bpy.ops.object.select_all(action='DESELECT');dog.select_set(True);bpy.context.view_layer.objects.active=dog
em=n.new('ShaderNodeEmission');l.new(em.outputs[0],output.inputs['Surface'])
images=[]
for name,socket,noncolor in [('cheek_color',tex.outputs['Color'],False),('cheek_mask',mask,True)]:
 im=bpy.data.images.new('R30_'+name,width=2048,height=2048,alpha=False)
 if noncolor:im.colorspace_settings.name='Non-Color'
 target=n.new('ShaderNodeTexImage');target.image=im;n.active=target
 l.new(socket,em.inputs['Color']);bpy.ops.object.bake(type='EMIT')
 im.filepath_raw=str(OUT/(name+'.png'));im.file_format='PNG';im.save();images.append(im)
l.new(bs.outputs[0],output.inputs['Surface'])
# Ucupaint owns the editable base/repair stack and mask composition.
bpy.ops.wm.y_quick_ypaint_node_setup(tree_name='Chihuahua_R30_Cheek_Repair',target_bsdf_name=bs.name,color=True,alpha=False,ao=False,metallic=False,roughness=False,normal=False)
group=mat.node_tree.nodes.active;tree=group.node_tree
Layer=importlib.import_module('bl_ext.blender_org.ucupaint.Layer')
uvname=dog.data.uv_layers.active.name
base_layer=Layer.add_new_layer(tree,'R29 preserved base','IMAGE',0,'MIX','MIX','BUMP_MAP','UV',uv_name=uvname,image=base)
repair=Layer.add_new_layer(tree,'R30 remove duplicate side mouth','IMAGE',0,'MIX','MIX','BUMP_MAP','UV',uv_name=uvname,image=images[0],add_mask=True,mask_type='IMAGE',mask_image=images[1],mask_uv_name=uvname)
tree.yp.halt_update=False;tree.yp.halt_reconnect=False
Layer.reconnect_yp_nodes(tree)
scene.render.engine='BLENDER_EEVEE'
for im in [base]+images:im.pack()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'chihuahua_r30_02_ucupaint.blend'))
(OUT/'plugin_workflow.json').write_text(json.dumps({'blender':bpy.app.version_string,'enabled_addons':list(bpy.context.preferences.addons.keys()),'ucupaint_tree':tree.name,'layers':[a.name for a in tree.yp.layers],'masks':[(a.name,[q.name for q in a.masks]) for a in tree.yp.layers]},indent=2))
print('R30_UCUPAINT_READY',[(a.name,len(a.masks)) for a in tree.yp.layers])



