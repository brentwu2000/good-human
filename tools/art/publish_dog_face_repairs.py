"""Publish r5 only after review; protect both factory sources and last delivery."""
import pathlib,json,hashlib,shutil,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
STAGE=ROOT/'build/dogs_face_repair_r5'
FACTORY=ROOT.parent/'good_human_stylized_factory'
BREEDS=['chihuahua','pomeranian','poodle','frenchie','corgi','shiba','golden']
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    external='--factory' in sys.argv
    receipt=STAGE/('published_factory.json' if external else 'published_preview.json')
    delivered=json.loads(receipt.read_text()) if receipt.exists() else {}
    for breed in BREEDS:
        candidate=STAGE/'candidate'/breed
        previous=STAGE/'previous'/breed
        check=json.loads((candidate/'verification.json').read_text())
        tex=json.loads((candidate/'material_repair.json').read_text())
        glb=candidate/f'{breed}_game_codex.glb'
        assert sha(glb)==check['result_sha256']
        assert sha(FACTORY/'export/dogs'/f'{breed}_game.glb')==check['source_sha256']
        assert sha(FACTORY/'texture_work/dogs'/breed/'projection/basecolor.png')==tex['source_sha256']
        if external:
            copies=[(glb,FACTORY/'export/dogs'/glb.name,previous/glb.name),
                    (candidate/'basecolor_codex.png',FACTORY/'texture_work/dogs'/breed/'projection/basecolor_codex.png',previous/'basecolor_codex.png')]
        else:
            copies=[(glb,ROOT/'assets/characters/dog/models/breeds'/f'{breed}.glb',previous/glb.name)]
        for source,dest,backup in copies:
            assert sha(dest) in [sha(backup),sha(source),delivered.get(str(dest))],f'Unexpected external edit: {dest}'
            shutil.copy2(source,dest)
            assert sha(source)==sha(dest)
            delivered[str(dest)]=sha(dest)
            receipt.write_text(json.dumps(delivered,indent=2))
        print(breed,'FACTORY_VERIFIED' if external else 'PREVIEW_VERIFIED',check['bytes'])
if __name__=='__main__':main()
