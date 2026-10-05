"""French bulldog: broad cranium, short paired muzzle pads, nose near the eyes."""
import pathlib,numpy as np
from rebuild_breed_face import main
ROOT=pathlib.Path(__file__).resolve().parents[2]
CX=-.009

def surface(x,z):
    x=x-CX
    base=-.215-.185*np.sqrt(np.maximum(.06,1-(x/.265)**2-((z-.675)/.225)**2))
    pads=sum(.064*np.exp(-((x-s*.073)/.085)**2-((z-.642)/.051)**2) for s in [-1,1])
    nose=.052*np.exp(-(x/.050)**4-((z-.686)/.029)**4)
    mouth=.042*np.exp(-(x/.143)**4-((z-.552)/.065)**4)
    tongue=.112*np.exp(-(x/.061)**6-((z-.505)/.049)**6)
    cheeks=sum(.025*np.exp(-((x-s*.17)/.060)**2-((z-.605)/.077)**2) for s in [-1,1])
    return base-pads-nose+mouth-tongue-cheeks

def project(x,z):
    u=331+(x-CX)*750
    v=245-(z-.687)*780
    v=np.where(v>429,429+(v-429)*.2,v)
    return u,v

CONFIG={
    'breed':'frenchie','source':ROOT/'assets/art_previews/dogs/candidates/r11/frenchie_r6.glb',
    'reference':pathlib.Path(r'C:\Users\b\Documents\good_human_stylized_factory\references\dogs\frenchie_front.png'),
    'output_dir':ROOT/'build/frenchie_face_r11','center':(CX,.65),'radius':(.25,.23),
    'cut_depth':-.165,'chart':(CX-.28,CX+.28,.40,.92),'rings':20,
    'surface':surface,'project':project,'blend_start':.76,
}

if __name__=='__main__':main(CONFIG)
