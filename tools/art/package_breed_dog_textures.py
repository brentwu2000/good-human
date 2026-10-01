"""Replace only each embedded base-colour payload; validate all other data verbatim."""
import pathlib,json,struct,hashlib
F=pathlib.Path(r'C:\Users\b\Documents\good_human_stylized_factory')
OUT=pathlib.Path(r'C:\Users\b\Documents\good-human\build\dogs_texture_codex')
def unpack(raw):
    n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n])
    return doc,raw[28+n:]
def main(breed):
    source=F/'export/dogs'/f'{breed}_game.glb';raw=source.read_bytes();doc,bin0=unpack(raw)
    before=json.loads(json.dumps(doc));dest=OUT/breed
    jpg=(dest/'basecolor_codex.jpg').read_bytes()
    assert jpg[:2]==b'\xff\xd8'
    assert len(doc['images'])==1
    vi=doc['images'][0]['bufferView'];view=doc['bufferViews'][vi]
    start=view.get('byteOffset',0);end=(start+view['byteLength']+3)//4*4
    replacement=jpg+b'\0'*(-len(jpg)%4);delta=len(replacement)-(end-start)
    bin1=bin0[:start]+replacement+bin0[end:]
    for i,v in enumerate(doc['bufferViews']):
        if i==vi:v['byteLength']=len(jpg)
        elif v.get('byteOffset',0)>=end:v['byteOffset']=v.get('byteOffset',0)+delta
        else:assert v.get('byteOffset',0)+v['byteLength']<=start
    doc['images'][0]['name']=f'{breed}_basecolor_codex';doc['images'][0]['mimeType']='image/jpeg'
    doc['buffers'][0]['byteLength']=len(bin1)
    for i,(a,b) in enumerate(zip(before['bufferViews'],doc['bufferViews'])):
        if i==vi:continue
        ao=a.get('byteOffset',0);bo=b.get('byteOffset',0)
        assert bin0[ao:ao+a['byteLength']]==bin1[bo:bo+b['byteLength']],i
    for k in ['meshes','skins','nodes','animations','accessors','materials','textures','samplers','scenes']:
        assert doc.get(k)==before.get(k),k
    names=[a['name'] for a in doc['animations']]
    assert set(names)=={'Idle','Walk','Sit'}
    assert len(doc['skins'][0]['joints'])==23
    encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*(-len(encoded)%4)
    result=struct.pack('<III',0x46546C67,2,28+len(encoded)+len(bin1))+struct.pack('<II',len(encoded),0x4E4F534A)+encoded+struct.pack('<II',len(bin1),0x004E4942)+bin1
    assert len(result)<=2500000,(breed,len(result))
    target=dest/f'{breed}_game_codex.glb';target.write_bytes(result)
    record={'source_sha256':hashlib.sha256(raw).hexdigest(),'result_sha256':hashlib.sha256(result).hexdigest(),'bytes':len(result),
       'basecolor':[1024,1024],'format':'JPEG','original_geometry_uv_rig_weights_clips_preserved':True,'unchanged_nonimage_buffer_views':len(doc['bufferViews'])-1,
       'joints':23,'clips':names}
    (dest/'verification.json').write_text(json.dumps(record,indent=2));print(breed,len(result),'VERIFIED')
if __name__=='__main__':
    import sys
    for breed in sys.argv[1:]:main(breed)
