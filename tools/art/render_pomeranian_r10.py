"""Use identical light and camera settings to compare the rebuilt face."""
import pathlib
p=pathlib.Path(__file__).with_name('render_pomeranian_r9.py')
code=p.read_text(encoding='utf-8').replace('r9','r10').replace('R9','R10')
exec(compile(code,str(p),'exec'))
