"""Local nasal-bridge texture repair on immutable r6 geometry, Blender bake."""
from pathlib import Path
import bpy,os
scripts=Path(r'C:\Users\b\Documents\good-human\tools\art')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.environ['TEMP'],'corgi_r20_00_before.blend'))
source=(scripts/'frenchie_side_material_r14.py').read_text(encoding='utf-8-sig')
source=source.replace('build/frenchie_face_r13/frenchie.glb','assets/art_previews/dogs/candidates/r19/corgi_r6.glb').replace('frenchie_face_r14','corgi_face_r20').replace('R14','R20').replace('frenchie_r14','corgi_r20')
start=source.index('side=bpy.data.images.load');end=source.index('s=bpy.context.scene',start)
source=source[:start]+'''ref=bpy.data.images.load(r'C:\\Users\\b\\Documents\\good_human_stylized_factory\\references\\dogs\\corgi_front.png',check_existing=True)
for mat in dog.data.materials:
    nt=mat.node_tree;n=nt.nodes;l=nt.links
    bs=next(a for a in n if a.type=='BSDF_PRINCIPLED');original=bs.inputs['Base Color'].links[0].from_socket
    def mathnode(op,a,b=0):
        node=n.new('ShaderNodeMath');node.operation=op
        for i,v in enumerate([a,b]):
            if isinstance(v,(int,float)):node.inputs[i].default_value=v
            else:l.new(v,node.inputs[i])
        return node.outputs[0]
    def ramp(a,lo,hi):
        node=n.new('ShaderNodeMapRange');node.interpolation_type='SMOOTHSTEP';node.clamp=True
        l.new(a,node.inputs['Value']);node.inputs['From Min'].default_value=lo;node.inputs['From Max'].default_value=hi
        return node.outputs[0]
    geo=n.new('ShaderNodeNewGeometry');sep=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Position'],sep.inputs[0])
    x=mathnode('DIVIDE',sep.outputs['X'],.45);y=mathnode('DIVIDE',sep.outputs['Y'],.45);z=mathnode('DIVIDE',sep.outputs['Z'],.45)
    uv=n.new('ShaderNodeCombineXYZ')
    l.new(mathnode('DIVIDE',mathnode('ADD',403,mathnode('MULTIPLY',x,790)),768),uv.inputs['X'])
    uv.inputs['Y'].default_value=1-198/768
    tex=n.new('ShaderNodeTexImage');tex.image=ref;l.new(uv.outputs[0],tex.inputs['Vector'])
    mask=mathnode('SUBTRACT',1,ramp(mathnode('ABSOLUTE',x),.035,.072))
    for factor in [ramp(z,.695,.708),mathnode('SUBTRACT',1,ramp(z,.75,.775)),ramp(y,-.505,-.465),mathnode('SUBTRACT',1,ramp(y,-.39,-.32))]:
        mask=mathnode('MULTIPLY',mask,factor)
    bridge=n.new('ShaderNodeMixRGB');l.new(mask,bridge.inputs[0]);l.new(original,bridge.inputs[1]);l.new(tex.outputs['Color'],bridge.inputs[2])
    # Remove the second painted mouth on the rear chin surface, behind the real tongue.
    chin=ramp(y,-.425,-.385)
    for factor in [mathnode('SUBTRACT',1,ramp(y,-.24,-.19)),ramp(z,.45,.48),mathnode('SUBTRACT',1,ramp(z,.60,.635)),mathnode('SUBTRACT',1,ramp(mathnode('ABSOLUTE',x),.11,.16))]:
        chin=mathnode('MULTIPLY',chin,factor)
    cheekuv=n.new('ShaderNodeCombineXYZ');l.new(mathnode('DIVIDE',mathnode('ADD',495,mathnode('MULTIPLY',mathnode('ABSOLUTE',x),240)),768),cheekuv.inputs['X'])
    l.new(mathnode('DIVIDE',mathnode('SUBTRACT',768,mathnode('ADD',365,mathnode('MULTIPLY',mathnode('SUBTRACT',z,.55),120))),768),cheekuv.inputs['Y'])
    cheek=n.new('ShaderNodeTexImage');cheek.image=ref;l.new(cheekuv.outputs[0],cheek.inputs['Vector'])
    mix=n.new('ShaderNodeMixRGB');mix.name='R20_SIDE_COLOR';l.new(chin,mix.inputs[0]);l.new(bridge.outputs[0],mix.inputs[1]);l.new(cheek.outputs['Color'],mix.inputs[2]);l.new(mix.outputs[0],bs.inputs['Base Color'])
''' + source[end:]
exec(compile(source,'corgi_r20_material','exec'))
source=(scripts/'bake_frenchie_r14.py').read_text(encoding='utf-8-sig').replace('frenchie_face_r14','corgi_face_r20').replace('R14','R20').replace('frenchie_r14','corgi_r20')
exec(compile(source,'corgi_r20_bake','exec'))
