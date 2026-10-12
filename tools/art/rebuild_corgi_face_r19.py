"""Corgi-specific continuous face from the owner's original front reference."""
import pathlib,numpy as np
from rebuild_breed_face import main
ROOT=pathlib.Path(__file__).resolve().parents[2]
def surface(x,z):
    base=-.225-.195*np.sqrt(np.maximum(.05,1-(x/.275)**2-((z-.68)/.25)**2))
    pads=sum(.065*np.exp(-((x-s*.053)/.071)**2-((z-.660)/.049)**2) for s in [-1,1])
    nose=.047*np.exp(-(x/.042)**4-((z-.692)/.025)**4)
    mouth=.055*np.exp(-(x/.113)**4-((z-.603)/.054)**4)
    tongue=.045*np.exp(-(x/.049)**6-((z-.557)/.039)**6)
    return base-pads-nose+mouth-tongue
def project(x,z):
    from reshape_pomeranian_r9 import smooth
    u=403+x*790
    v=252-(z-.692)*900
    return u,np.clip(v,140,425)
CONFIG={'breed':'corgi','source':ROOT/'assets/art_previews/dogs/candidates/r19/corgi_r6.glb',
 'reference':pathlib.Path(r'C:\Users\b\Documents\good_human_stylized_factory\references\dogs\corgi_front.png'),
 'output_dir':ROOT/'build/corgi_face_r19','center':(0,.630),'radius':(.258,.205),
 'cut_depth':-.20,'chart':(-.29,.29,.39,.93),'rings':22,'surface':surface,'project':project,
 'blend_start':.80,'absorb_cut_islands':True}
if __name__=='__main__':main(CONFIG)
