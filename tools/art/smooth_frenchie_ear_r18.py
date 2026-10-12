"""Smooth ear-root depth over r17 while retaining all frontal coordinates."""
from pathlib import Path
script=Path(__file__).with_name('smooth_frenchie_seam_r15.py')
source=script.read_text(encoding='utf-8-sig')
source=source.replace('candidates/r14/','candidates/r17/').replace('frenchie_face_r15','frenchie_face_r18')
start=source.index('distance=dijkstra')
end=source.index('delta=np.linalg.norm',start)
source=source[:start]+'''x=q[:,0]/.45+.009;z=q[:,1]/.45
rad=np.sqrt((x/.270)**2+((z-.63)/.25)**2)
adj=coo_matrix((np.ones(len(row)),(row,col)),shape=(len(q),len(q))).tocsr()
avg=diags(1/np.maximum(np.asarray(adj.sum(1)).ravel(),1))@adj
# Depth only: retain the exact front silhouette and protect eyes and muzzle.
mask=smooth(.752,.815,z)*smooth(.035,.085,np.abs(x))
mask*=1-smooth(.85,.94,z)
brow=np.zeros_like(mask)
for _ in range(70):
    q[:,2]+=(avg@q[:,2]-q[:,2])*(.44*mask)
q[:,2]=original[:,2]+.008*np.tanh((q[:,2]-original[:,2])/.008)
''' + source[end:]
exec(compile(source,str(script),'exec'))
