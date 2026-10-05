"""Validate the delivered candidate against the immutable r6 skeleton/animation."""
import pathlib,sys,json,numpy as np
sys.path.insert(0,str(pathlib.Path(__file__).parent))
from reshape_pomeranian_r9 import unpack,accessor
from rebuild_pomeranian_face_r10 import SOURCE,OUT
before,bb=unpack(SOURCE);after,ab=unpack(OUT/'pomeranian.glb')
assert before['nodes']==after['nodes']
assert len(before['skins'])==len(after['skins'])
for a,b in zip(before['skins'],after['skins']):
    assert a['joints']==b['joints']
    assert np.array_equal(accessor(before,bb,a['inverseBindMatrices']),accessor(after,ab,b['inverseBindMatrices']))
assert len(before['animations'])==len(after['animations'])
for a,b in zip(before['animations'],after['animations']):
    assert a['name']==b['name'] and a['channels']==b['channels']
    for sa,sb in zip(a['samplers'],b['samplers']):
        assert sa.get('interpolation')==sb.get('interpolation')
        for key in ['input','output']:assert np.array_equal(accessor(before,bb,sa[key]),accessor(after,ab,sb[key]))
records=[]
for m in after['meshes']:
    for primitive in m['primitives']:
        at=primitive['attributes'];p=accessor(after,ab,at['POSITION']);n=accessor(after,ab,at['NORMAL'])
        t=accessor(after,ab,primitive['indices']).reshape(-1,3);used=np.unique(t)
        w=accessor(after,ab,at['WEIGHTS_0']);j=accessor(after,ab,at['JOINTS_0'])
        assert np.isfinite(p[used]).all() and np.isfinite(n[used]).all()
        assert np.allclose(w[used].sum(1),1,atol=1e-5) and j[used].max()<len(after['skins'][0]['joints'])
        area=np.linalg.norm(np.cross(p[t[:,1]]-p[t[:,0]],p[t[:,2]]-p[t[:,0]]),axis=1)
        records.append({'triangles':len(t),'degenerate_triangles':int((area<1e-12).sum()),'normal_min_length':float(np.linalg.norm(n[used],axis=1).min())})
        assert not (area<1e-12).any()
        assert np.linalg.norm(n[used],axis=1).min()>.99
report={'skeleton_nodes_and_bind_matrices_equal':True,'animation_channels_keyframes_and_interpolation_equal':True,'finite_used_geometry':True,'weights_normalized_and_joint_indices_valid':True,'primitives':records}
(OUT/'validation.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
