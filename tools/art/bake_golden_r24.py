"""Golden Retriever-specific rear-mouth cleanup over unchanged r6 mesh."""
from pathlib import Path
script=Path(__file__).with_name('bake_corgi_r20.py')
source=script.read_text(encoding='utf-8-sig').replace('corgi','golden').replace('r20','r24').replace('R20','R24').replace('candidates/r19/','candidates/r24/')
for axis in ['X','Y','Z']:source=source.replace("sep.outputs['"+axis+"'],.45","sep.outputs['"+axis+"'],.75")
source=source.replace("bridge=n.new('ShaderNodeMixRGB');l.new(mask,bridge.inputs[0])","bridge=n.new('ShaderNodeMixRGB');bridge.inputs[0].default_value=0")
source=source.replace('chin=ramp(y,-.425,-.385)','chin=ramp(y,-.430,-.385)')
source=source.replace('ramp(z,.45,.48)','ramp(z,.59,.625)').replace('ramp(z,.60,.635)','ramp(z,.700,.735)')
source=source.replace("mathnode('ADD',495,","mathnode('ADD',382,").replace("mathnode('ABSOLUTE',x),240","mathnode('ABSOLUTE',x),90").replace("mathnode('ADD',365,","mathnode('ADD',310,").replace("mathnode('SUBTRACT',z,.55)","mathnode('SUBTRACT',z,.74)")
source=source.replace("exec(compile(source,'golden_r24_material','exec'))", "source=source.replace('t=Vector((0,-.1215,.3105))','t=Vector((0,-.27,.62))').replace('ortho_scale=.315','ortho_scale=.40')\nexec(compile(source,'golden_r24_material','exec'))")
exec(compile(source,str(script),'exec'))
