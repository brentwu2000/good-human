"""Publish reviewed texture-only dog candidates; never overwrite factory originals."""
import hashlib,json,pathlib,shutil,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
STAGE=ROOT/'build/dogs_texture_codex'
FACTORY=ROOT.parent/'good_human_stylized_factory'
BREEDS=['chihuahua','pomeranian','poodle','frenchie','corgi','shiba','golden']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def copy_new(source,target):
    target.parent.mkdir(parents=True,exist_ok=True)
    if target.exists():
        # A prior Codex pass may be refreshed; factory originals never carry this suffix.
        assert target.name.endswith('_codex.glb') or target.name.endswith('basecolor_codex.png'), target
        if sha(source)==sha(target): return
    shutil.copy2(source,target)
def main():
    external='--factory' in sys.argv
    for breed in BREEDS:
        stage=STAGE/breed
        check=json.loads((stage/'verification.json').read_text())
        tex=json.loads((stage/'material_repair.json').read_text())
        source=FACTORY/'export/dogs'/f'{breed}_game.glb'
        assert sha(source)==check['source_sha256']
        assert sha(FACTORY/'texture_work/dogs'/breed/'projection/basecolor.png')==tex['source_sha256']
        candidate=stage/f'{breed}_game_codex.glb'
        assert sha(candidate)==check['result_sha256']
        if external:
            copy_new(candidate,FACTORY/'export/dogs'/candidate.name)
            copy_new(stage/'basecolor_codex.png',FACTORY/'texture_work/dogs'/breed/'projection/basecolor_codex.png')
        else:
            preview=ROOT/'assets/art_previews/dogs/models'/f'{breed}.glb'
            backup=STAGE/'preview_originals'/preview.name
            if not backup.exists():copy_new(preview,backup)
            shutil.copy2(candidate,preview)
            evidence=ROOT/'docs/06_art/dog_texture_review_2026-10-01'/breed
            evidence.mkdir(parents=True,exist_ok=True)
            for path in (stage/'renders').glob('*.png'):shutil.copy2(path,evidence/path.name)
            for name in ['verification.json','material_repair.json']:shutil.copy2(stage/name,evidence/name)
        print(breed,'FACTORY_COPY' if external else 'PREVIEW_UPDATED',check['bytes'])
if __name__=='__main__':main()
