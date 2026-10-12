"""Shiba-specific rear-chin texture cleanup; original geometry is immutable."""
from pathlib import Path
script=Path(__file__).with_name('bake_corgi_r20.py')
source=script.read_text(encoding='utf-8-sig').replace('corgi','shiba').replace('r20','r23').replace('R20','R23').replace('candidates/r19/','candidates/r23/')
source=source.replace("sep.outputs['X'],.45","sep.outputs['X'],.55").replace("sep.outputs['Y'],.45","sep.outputs['Y'],.55").replace("sep.outputs['Z'],.45","sep.outputs['Z'],.55")
# Do not apply the Corgi nasal-bridge recipe to this breed.
source=source.replace("bridge=n.new('ShaderNodeMixRGB');l.new(mask,bridge.inputs[0])","bridge=n.new('ShaderNodeMixRGB');bridge.inputs[0].default_value=0")
source=source.replace("chin=ramp(y,-.425,-.385)","chin=ramp(y,-.405,-.365)")
source=source.replace('ramp(z,.45,.48)','ramp(z,.565,.595)').replace('ramp(z,.60,.635)','ramp(z,.635,.665)')
source=source.replace("mathnode('ADD',495,","mathnode('ADD',418,").replace("mathnode('ADD',365,","mathnode('ADD',295,").replace("mathnode('SUBTRACT',z,.55)","mathnode('SUBTRACT',z,.64)")
source=source.replace("t=Vector((0,-.1215,.3105))","t=Vector((0,-.15,.405))").replace("ortho_scale=.315","ortho_scale=.34")
source=source.replace("exec(compile(source,'shiba_r23_material','exec'))", "source=source.replace('t=Vector((0,-.1215,.3105))','t=Vector((0,-.15,.405))').replace('ortho_scale=.315','ortho_scale=.37')\nexec(compile(source,'shiba_r23_material','exec'))")
exec(compile(source,str(script),'exec'))
