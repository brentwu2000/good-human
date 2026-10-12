"""Localized Golden nasal-bridge cleanup, retaining r24 chin repair."""
from pathlib import Path
script=Path(__file__).with_name('bake_golden_r24.py')
source=script.read_text(encoding='utf-8-sig').replace('r24','r25').replace('R24','R25')
# Keep immutable r6 source in r24, and enable a Golden-specific bridge mask.
source=source.replace(".replace('candidates/r19/','candidates/r25/')",".replace('candidates/r19/','candidates/r24/')")
source=source.replace("bridge=n.new('ShaderNodeMixRGB');bridge.inputs[0].default_value=0","bridge=n.new('ShaderNodeMixRGB');l.new(mask,bridge.inputs[0])")
at=source.index("exec(compile(source,str(script),'exec'))")
source=source[:at]+'''source=source.replace("mathnode('ADD',403,", "mathnode('ADD',309,").replace("x,790", "x,150").replace("1-198/768", "1-123/768")
source=source.replace("x),.035,.072", "x),.065,.125")
source=source.replace('ramp(z,.695,.708)','ramp(z,.818,.845)').replace('ramp(z,.75,.775)','ramp(z,.865,.889)')
source=source.replace('ramp(y,-.505,-.465)','ramp(y,-.545,-.50)').replace('ramp(y,-.39,-.32)','ramp(y,-.425,-.38)')
''' + source[at:]
exec(compile(source,str(script),'exec'))
