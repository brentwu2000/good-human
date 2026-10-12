"""Register one continuous Poodle nose projection over original r6 geometry."""
from pathlib import Path
script=Path(__file__).with_name('bake_corgi_r20.py')
source=script.read_text(encoding='utf-8-sig').replace('corgi','poodle').replace('r20','r26').replace('R20','R26').replace('candidates/r19/','candidates/r26/')
start=source.index("    uv=n.new('ShaderNodeCombineXYZ')")
end=source.index("    bridge=n.new",start)
source=source[:start]+'''    uv=n.new('ShaderNodeCombineXYZ')
    l.new(mathnode('DIVIDE',mathnode('ADD',390,mathnode('MULTIPLY',x,500)),768),uv.inputs['X'])
    nv=mathnode('ADD',mathnode('MULTIPLY',mathnode('SUBTRACT',z,.676),700),mathnode('MULTIPLY',mathnode('ADD',y,.480),200))
    l.new(mathnode('DIVIDE',mathnode('ADD',498,nv),768),uv.inputs['Y'])
    tex=n.new('ShaderNodeTexImage');tex.image=ref;l.new(uv.outputs[0],tex.inputs['Vector'])
    mask=mathnode('SUBTRACT',1,ramp(mathnode('ABSOLUTE',x),.037,.063))
    for factor in [ramp(z,.64,.653),mathnode('SUBTRACT',1,ramp(z,.705,.72)),mathnode('SUBTRACT',1,ramp(y,-.46,-.435))]:
        mask=mathnode('MULTIPLY',mask,factor)
''' + source[end:]
source=source.replace("l.new(chin,mix.inputs[0])","mix.inputs[0].default_value=0")
exec(compile(source,str(script),'exec'))
