"""Package the relaxed geometry and fresh side-material bakes."""
from pathlib import Path
script=Path(__file__).with_name('package_frenchie_r14.py')
source=script.read_text(encoding='utf-8-sig').replace('r14','r15')
source=source.replace('assets/art_previews/dogs/candidates/r13/frenchie.glb','build/frenchie_face_r15/bake_source.glb')
exec(compile(source,str(script),'exec'))
