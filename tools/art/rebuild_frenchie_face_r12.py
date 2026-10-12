"""Extend the Frenchie face repair through the old mouth corners and chin."""
from rebuild_frenchie_face_r11 import CONFIG as BASE, surface, project
from rebuild_breed_face import main

CONFIG = dict(BASE, output_dir=BASE['output_dir'].parent/'frenchie_face_r12',
              center=(-.009, .63), radius=(.270, .25), cut_depth=-.165,
              chart=(-.309, .291, .36, .93), rings=20, blend_start=.79,
              absorb_cut_islands=True)

if __name__ == '__main__':
    main(CONFIG)
