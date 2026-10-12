"""Preserve the approved frontal chart; refine depth for a short bulldog profile."""
import numpy as np
from rebuild_frenchie_face_r12 import CONFIG as BASE
from rebuild_frenchie_face_r11 import surface as previous_surface, CX
from rebuild_breed_face import main
from reshape_pomeranian_r9 import smooth

def surface(x,z):
    q=x-CX
    y=previous_surface(x,z)
    # Retract the slab-like tongue and fill the excessive cheek concavity.
    y += .040*np.exp(-(q/.065)**6-((z-.505)/.049)**6)
    y -= .025*np.exp(-(q/.15)**4-((z-.554)/.055)**4)
    y -= sum(.030*np.exp(-((q-s*.125)/.075)**2-((z-.57)/.09)**2)
             for s in [-1,1])
    # Round the brow-to-muzzle transition without moving frontal landmarks.
    y -= .020*np.exp(-(q/.145)**4-((z-.738)/.062)**2)
    return y

def texture_blend(x,z,blend):
    # Prevent the front reference's pink ears from projecting onto the temples.
    temple=smooth(.13,.22,np.abs(x-CX))*smooth(.70,.80,z)
    return np.maximum(blend,temple)

CONFIG=dict(BASE, output_dir=BASE['output_dir'].parent/'frenchie_face_r13',
            surface=surface, texture_blend=texture_blend)

if __name__=='__main__':
    main(CONFIG)
