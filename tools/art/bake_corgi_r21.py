"""Restore a bounded inner-mouth material at the pale cheek/tongue junction."""
from pathlib import Path
script=Path(__file__).with_name('bake_corgi_r20.py')
source=script.read_text(encoding='utf-8-sig').replace('r20','r21').replace('R20','R21')
old="l.new(mix.outputs[0],bs.inputs['Base Color'])"
new="""# Symmetric bounded inner-mouth region behind the projecting tongue.
    dx=mathnode('DIVIDE',mathnode('SUBTRACT',mathnode('ABSOLUTE',x),.055),.068)
    dy=mathnode('DIVIDE',mathnode('ADD',y,.410),.052)
    dz=mathnode('DIVIDE',mathnode('SUBTRACT',z,.613),.028)
    dist=mathnode('ADD',mathnode('ADD',mathnode('MULTIPLY',dx,dx),mathnode('MULTIPLY',dy,dy)),mathnode('MULTIPLY',dz,dz))
    cavity=mathnode('SUBTRACT',1,ramp(dist,.55,1.05))
    cavity=mathnode('MULTIPLY',cavity,ramp(y,-.455,-.423))
    inner=n.new('ShaderNodeMixRGB');inner.name='R21_INNER_MOUTH'
    l.new(cavity,inner.inputs[0]);l.new(mix.outputs[0],inner.inputs[1])
    inner.inputs[2].default_value=(.025,.007,.005,1)
    mix.name='R21_CHIN_COLOR';inner.name='R21_SIDE_COLOR'
    l.new(inner.outputs[0],bs.inputs['Base Color'])"""
assert old in source
source=source.replace(old,new)
exec(compile(source,str(script),'exec'))
