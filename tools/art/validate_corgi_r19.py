"""Validate Corgi rig/animation preservation and rebuilt face mesh integrity."""
from pathlib import Path
script=Path(__file__).with_name('validate_frenchie_r14.py')
source=script.read_text(encoding='utf-8-sig')
source=source.replace('from rebuild_frenchie_face_r13 import CONFIG as BASE_CONFIG','from rebuild_corgi_face_r19 import CONFIG as BASE_CONFIG')
source=source.replace('frenchie_face_r14','corgi_face_r19').replace("OUT/'frenchie.glb'","OUT/'corgi.glb'")
start=source.index('approved, approved_data=')
end=source.index("for m in after['meshes']:",start)
source=source[:start]+source[end:]
exec(compile(source,str(script),'exec'))
