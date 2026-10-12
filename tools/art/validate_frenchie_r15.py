"""Validate skin/animation retention plus unchanged central facial geometry."""
from pathlib import Path
script=Path(__file__).with_name('validate_frenchie_r14.py')
source=script.read_text(encoding='utf-8-sig')
source=source.replace("parent/'frenchie_face_r14'","parent/'frenchie_face_r15'")
source=source.replace('candidates/r13/frenchie.glb','candidates/r14/frenchie.glb')
source=source.replace("['POSITION','NORMAL','JOINTS_0','WEIGHTS_0']","['JOINTS_0','WEIGHTS_0']")
source=source.replace('R13_ALL_TRIANGLE_CORNER_GEOMETRY_NORMALS_AND_SKIN_UNCHANGED','R14_TRIANGLE_CORNER_SKIN_UNCHANGED')
exec(compile(source,str(script),'exec'))
for old_pr,new_pr in zip(approved['meshes'][0]['primitives'],after['meshes'][0]['primitives']):
    oi=accessor(approved,approved_data,old_pr['indices']).reshape(-1)
    ni=accessor(after,ab,new_pr['indices']).reshape(-1)
    old_p=accessor(approved,approved_data,old_pr['attributes']['POSITION'])[oi]
    new_p=accessor(after,ab,new_pr['attributes']['POSITION'])[ni]
    x=old_p[:,0]/.45+.009;z=old_p[:,1]/.45
    core=(x/.270)**2+((z-.63)/.25)**2<=.68**2
    assert np.array_equal(old_p[core,:2],new_p[core,:2])
    facial_features=core&(z<=.752)
    assert np.array_equal(old_p[facial_features],new_p[facial_features])
report['r14_central_face_frontal_coordinates_equal']=True
report['r14_eyes_nose_mouth_positions_equal']=True
report['r14_skin_values_per_triangle_corner_equal']=True
(OUT/'validation.json').write_text(json.dumps(report,indent=2))
print('CENTRAL_FRONTAL_COORDINATES_AND_FACIAL_FEATURES_UNCHANGED')
