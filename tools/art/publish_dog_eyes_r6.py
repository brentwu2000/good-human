"""Publish reviewed r6 atlases with immutable r5 backup and hash receipts."""
import pathlib,shutil,json,hashlib,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
STAGE=ROOT/'build/dogs_eye_r6'
FACTORY=ROOT.parent/'good_human_stylized_factory'
BREEDS=['chihuahua','pomeranian','poodle','frenchie','corgi','shiba','golden']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    external='--factory' in sys.argv
    receipt=STAGE/('published_factory.json' if external else 'published_preview.json')
    old=ROOT/'build/dogs_face_repair_r5'/receipt.name
    known=json.loads(old.read_text())
    delivered=json.loads(receipt.read_text()) if receipt.exists() else {}
    jobs=[]
    for breed in BREEDS:
        src=STAGE/'texture_candidate'/breed
        record=json.loads((src/'verification.json').read_text())
        glb=src/f'{breed}_game_codex.glb'
        assert sha(glb)==record['result_sha256']
        assert sha(FACTORY/'export/dogs'/f'{breed}_game.glb')==record['source_sha256']
        pairs=[(glb,ROOT/'assets/art_previews/dogs/models'/f'{breed}.glb')]
        if external:pairs=[(glb,FACTORY/'export/dogs'/glb.name),(src/'basecolor_codex.png',FACTORY/'texture_work/dogs'/breed/'projection/basecolor_codex.png')]
        for source,dest in pairs:
            assert sha(dest) in [known.get(str(dest)),delivered.get(str(dest)),sha(source)],str(dest)
            backup=STAGE/'previous'/('factory' if external else 'preview')/breed/dest.name
            jobs.append((source,dest,backup))
    for source,dest,backup in jobs:
        backup.parent.mkdir(parents=True,exist_ok=True)
        if not backup.exists():shutil.copy2(dest,backup)
        shutil.copy2(source,dest);assert sha(source)==sha(dest)
        delivered[str(dest)]=sha(dest)
        receipt.write_text(json.dumps(delivered,indent=2))
        print('VERIFIED',dest)
if __name__=='__main__':main()
