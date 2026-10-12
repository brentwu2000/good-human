"""Package continuous temple chart; retain all r15 corner geometry and rig."""
from pathlib import Path
script=Path(__file__).with_name('package_frenchie_r14.py')
source=script.read_text(encoding='utf-8-sig').replace('r14','r17')
source=source.replace('candidates/r13/frenchie.glb','candidates/r15/frenchie.glb')
exec(compile(source,str(script),'exec'))
