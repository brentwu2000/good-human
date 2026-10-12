"""Ucupaint cheek-fur transition over the r35 surface candidate."""
import bpy, importlib
from pathlib import Path
ROOT=Path(r'C:\Users\b\Documents\good-human');OUT=ROOT/'build/dog_polish_r35'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_03_before_paint.blend'))
dog=bpy.data.objects['DogBody'];mat=dog.active_material
nt=mat.node_tree;n=nt.nodes;l=nt.links
bs=next(v for v in n if v.type=='BSDF_PRINCIPLED')
output=next(v for v in n if v.type=='OUTPUT_MATERIAL' and v.is_active_output)
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
geo=n.new('ShaderNodeNewGeometry');xyz=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Position'],xyz.inputs[0]);x,y,z=xyz.outputs
norm=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Normal'],norm.inputs[0])
dy=m('DIVIDE',m('ADD',y,.120),.042);dz=m('DIVIDE',m('SUBTRACT',z,.198),.032)
radius=m('SQRT',m('ADD',m('MULTIPLY',dy,dy),m('MULTIPLY',dz,dz)))
mask=m('SUBTRACT',1,ramp(radius,.62,1.20))
mask=m('MULTIPLY',mask,ramp(m('ABSOLUTE',x),.014,.027))
mask=m('MULTIPLY',mask,ramp(m('ABSOLUTE',norm.outputs['X']),.18,.60))
px=m('ADD',210,m('MULTIPLY',m('ADD',y,.120),700))
py=m('SUBTRACT',350,m('MULTIPLY',m('SUBTRACT',z,.195),900))
uv=n.new('ShaderNodeCombineXYZ');l.new(m('DIVIDE',px,768),uv.inputs['X']);l.new(m('SUBTRACT',1,m('DIVIDE',py,768)),uv.inputs['Y'])
donor=n.new('ShaderNodeTexImage');donor.image=ref;l.new(uv.outputs[0],donor.inputs['Vector'])
bpy.ops.object.select_all(action='DESELECT');dog.select_set(True);bpy.context.view_layer.objects.active=dog
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
scene.render.bake.margin=12;scene.render.bake.use_clear=True
em=n.new('ShaderNodeEmission');l.new(em.outputs[0],output.inputs['Surface'])
images=[]
for name,socket,noncolor in [('cheek_color',donor.outputs['Color'],False),('cheek_mask',mask,True)]:
    im=bpy.data.images.new('R35_'+name,width=2048,height=2048,alpha=False)
    if noncolor:im.colorspace_settings.name='Non-Color'
    target=n.new('ShaderNodeTexImage');target.image=im;n.active=target
    l.new(socket,em.inputs['Color']);bpy.ops.object.bake(type='EMIT')
    im.filepath_raw=str(OUT/(name+'.png'));im.file_format='PNG';im.save();images.append(im)
l.new(bs.outputs[0],output.inputs['Surface'])
bpy.ops.wm.y_quick_ypaint_node_setup(tree_name='Chihuahua_R35_CheekFur',target_bsdf_name=bs.name,color=True,alpha=False,ao=False,metallic=False,roughness=False,normal=False)
group=n.active;tree=group.node_tree
Layer=importlib.import_module('bl_ext.blender_org.ucupaint.Layer');uvname=dog.data.uv_layers.active.name
Layer.add_new_layer(tree,'R34 retained base','IMAGE',0,'MIX','MIX','BUMP_MAP','UV',uv_name=uvname,image=base)
Layer.add_new_layer(tree,'R35 continuous cheek fur','IMAGE',0,'MIX','MIX','BUMP_MAP','UV',uv_name=uvname,image=images[0],add_mask=True,mask_type='IMAGE',mask_image=images[1],mask_uv_name=uvname)
tree.yp.halt_update=False;tree.yp.halt_reconnect=False;Layer.reconnect_yp_nodes(tree)
for im in [base]+images:im.pack()
final=bpy.data.images.new('R35_body_baked',width=2048,height=2048,alpha=False)
target=n.new('ShaderNodeTexImage');target.image=final;n.active=target
l.new(group.outputs['Color'],em.inputs['Color']);l.new(em.outputs[0],output.inputs['Surface'])
bpy.ops.object.bake(type='EMIT');final.filepath_raw=str(OUT/'body_baked.png');final.file_format='PNG';final.save();final.pack()
l.new(bs.outputs[0],output.inputs['Surface']);scene.render.engine='BLENDER_EEVEE'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'chihuahua_04_ucupaint.blend'))
print('R35_UCUPAINT_BAKED',[(a.name,len(a.masks)) for a in tree.yp.layers])
