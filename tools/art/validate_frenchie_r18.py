"""Validate r18 depth-only repair and byte-identical textures, UV and skin."""
from pathlib import Path
script=Path(__file__).with_name('validate_frenchie_r14.py')
source=script.read_text(encoding='utf-8-sig').replace('frenchie_face_r14','frenchie_face_r18').replace('candidates/r13/','candidates/r17/')
source=source.replace("['POSITION','NORMAL','JOINTS_0','WEIGHTS_0']","['TEXCOORD_0','JOINTS_0','WEIGHTS_0']")
source=source.replace('R13_ALL_TRIANGLE_CORNER_GEOMETRY_NORMALS_AND_SKIN_UNCHANGED','R17_UV_AND_SKIN_UNCHANGED')
exec(compile(source,str(script),'exec'))
for a,b in zip(approved['meshes'][0]['primitives'],after['meshes'][0]['primitives']):
    old=accessor(approved,approved_data,a['attributes']['POSITION'])
    new=accessor(after,ab,b['attributes']['POSITION'])
    assert np.array_equal(old[:,:2],new[:,:2])
    assert np.array_equal(old[old[:,1]/.45<=.752],new[old[:,1]/.45<=.752])
    assert np.abs(old[:,2]-new[:,2]).max()<=.00801
for a,b in zip(approved['images'],after['images']):
    av=approved['bufferViews'][a['bufferView']];bv=after['bufferViews'][b['bufferView']]
    ao=av.get('byteOffset',0);bo=bv.get('byteOffset',0)
    assert approved_data[ao:ao+av['byteLength']]==ab[bo:bo+bv['byteLength']]
report.update(all_frontal_coordinates_unchanged=True,lower_face_positions_unchanged=True,texture_bytes_unchanged=True,uv_and_skin_unchanged=True,max_depth_change_below_8mm=True)
(OUT/'validation.json').write_text(json.dumps(report,indent=2))
print('R18_DEPTH_ONLY_AND_TEXTURE_RETENTION_PASS')
