"""Validate Corgi rig/animation preservation and rebuilt face mesh integrity."""
from pathlib import Path
script=Path(__file__).with_name('validate_frenchie_r14.py')
source=script.read_text(encoding='utf-8-sig')
source=source.replace('from rebuild_frenchie_face_r13 import CONFIG as BASE_CONFIG','from rebuild_corgi_face_r19 import CONFIG as BASE_CONFIG')
source=source.replace('frenchie_face_r14','corgi_face_r22').replace("OUT/'frenchie.glb'","OUT/'corgi.glb'")
start=source.index('approved, approved_data=')
end=source.index("for m in after['meshes']:",start)
source=source[:start]+source[end:]
exec(compile(source,str(script),'exec'))
previous,pd=unpack(OUT.parent.parent/'assets/art_previews/dogs/candidates/r21/corgi.glb')
oldpr=previous['meshes'][0]['primitives'][0];newpr=after['meshes'][0]['primitives'][0]
for name in ['TEXCOORD_0','JOINTS_0','WEIGHTS_0']:
    assert np.array_equal(accessor(previous,pd,oldpr['attributes'][name]),accessor(after,ab,newpr['attributes'][name]))
oldp=accessor(previous,pd,oldpr['attributes']['POSITION']);newp=accessor(after,ab,newpr['attributes']['POSITION'])
assert np.array_equal(oldp[:,0],newp[:,0])
y=-oldp[:,2]/.45;z=oldp[:,1]/.45
protected=(y<=-.448)|(y>=-.28)|(z<=.495)|(z>=.635)|(np.abs(oldp[:,0]/.45)>=.16)
assert np.array_equal(oldp[protected],newp[protected])
assert np.array_equal(accessor(previous,pd,oldpr['indices']),accessor(after,ab,newpr['indices']))
for a,b in zip(previous['images'],after['images']):
    av=previous['bufferViews'][a['bufferView']];bv=after['bufferViews'][b['bufferView']]
    ao=av.get('byteOffset',0);bo=bv.get('byteOffset',0)
    assert pd[ao:ao+av['byteLength']]==ab[bo:bo+bv['byteLength']]
report.update(uv_skin_topology_and_textures_retained=True,positions_outside_local_web_unchanged=True,all_horizontal_coordinates_unchanged=True)
(OUT/'validation.json').write_text(json.dumps(report,indent=2))
print('LOCAL_WEB_ONLY_PASS')


