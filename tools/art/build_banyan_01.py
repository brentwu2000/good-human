"""Original Blender mesh authoring for D5-01. No downloaded tree assets."""
import bpy, math, random, os
from mathutils import Vector
random.seed(517)
WORK=r'C:\Users\b\Documents\good-human-3d-pipeline\blender\environment\banyan_01'
os.makedirs(WORK,exist_ok=True)
scene=bpy.data.scenes.new('Banyan_Workshop');bpy.context.window.scene=scene
bpy.ops.wm.save_as_mainfile(filepath=WORK+'/banyan_00_start.blend')
def material(name,color,roughness):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=roughness
 return m
bark=material('Banyan_Bark',(.19,.14,.095),.94);leaf=material('Banyan_Leaf',(.08,.18,.045),.8);scar=material('Banyan_Scar',(.46,.35,.23),.93)
leaf.use_backface_culling=False
buffers={'Bark':([],[],[]),'Foliage':([],[],[]),'Scar':([],[],[])}
def tube(points,radii,sides=12,flute=.1):
 vs,fs,colors=buffers['Bark'];start=len(vs)
 for i,p in enumerate(points):
  p=Vector(p);axis=(Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])).normalized();u=axis.cross(Vector((0,1,0)))
  if u.length<.01:u=axis.cross(Vector((1,0,0)))
  u.normalize();v=axis.cross(u)
  for j in range(sides):
   a=j*math.tau/sides;radius=radii[i]*(1+flute*math.sin(a*5+i*.25)+flute*.45*math.sin(a*9))
   co=p+radius*(math.cos(a)*u+math.sin(a)*v);vs.append(tuple(co))
   f=.78+.24*random.random()+.12*math.sin(a*5);colors.append((.19*f,.145*f,.103*f,1))
 for k in range(len(points)-1):
  for j in range(sides):fs.append((start+k*sides+j,start+k*sides+(j+1)%sides,start+(k+1)*sides+(j+1)%sides,start+(k+1)*sides+j))
 fs.extend([tuple(start+j for j in reversed(range(sides))),tuple(start+(len(points)-1)*sides+j for j in range(sides))])
# Three coalescing trunks; buttresses radiate into soil instead of forming a ring.
for x,y,lean in [(-.36,.02,-.48),(.32,.10,.5),(0,.43,.1)]:
 pts=[(x,y,0),(x,y,.45),(x*.8,y,.95),(x*.8+lean*.15,y,1.65),(x+lean*.35,y+.06,2.5),(x+lean*.8,y+.15,3.5),(x+lean*1.4,y+.35,4.55)]
 tube(pts,[.57,.52,.40,.34,.29,.20,.12],24,.15)
for i in range(14):
 a=math.tau*i/14+.17;r=random.uniform(1.4,2.05);x,y=math.cos(a),math.sin(a)
 tube([(x*.28,y*.28,.8),(x*.62,y*.62,.38),(x*1.02,y*1.02,.13),(x*r,y*r,.035),(x*(r+.22),y*(r+.22),-.015)],[.24,.19,.12,.045,.008],10,.18)
 # Secondary surface roots fork outside major buttresses.
 if i%2==0:tube([(x*.8,y*.8,.18),(x*1.15-.15*y,y*1.15+.15*x,.075),(x*1.9-.25*y,y*1.9+.25*x,.012)],[.085,.046,.005],7)
lobes=[]
for i in range(11):
 a=i*math.tau/11;r=random.uniform(1.8,2.8);end=Vector((math.cos(a)*r,math.sin(a)*r,random.uniform(4.1,5.2)))
 start=Vector((math.cos(a)*.35,math.sin(a)*.35,2.7+random.random()*.65));mid=start.lerp(end,.48);mid.z+=.32
 tube([start,mid,end],[.19,.125,.035],12,.1)
 for j in range(3):
  tip=end+Vector((random.uniform(-.8,.8),random.uniform(-.8,.8),random.uniform(.0,.8)))
  tube([mid,mid.lerp(tip,.7),tip],[.06,.035,.006],7,.08)
 lobes.append((end+Vector((0,0,.45)),Vector((1.15,1.05,.78))))
lobes.append((Vector((0,0,5.55)),Vector((1.55,1.5,.88))))
# Real leaf silhouettes, lightly folded with a visible midrib; no canopy spheres.
vs,fs,cols=buffers['Foliage']
for center,spread in lobes:
 for i in range(270):
  p=center+Vector((random.gauss(0,.53)*spread.x,random.gauss(0,.53)*spread.y,random.gauss(0,.40)*spread.z))
  angle=random.random()*math.tau;axis=Vector((math.cos(angle),math.sin(angle),random.uniform(-.55,.6))).normalized();cross=axis.cross(Vector((0,0,1))).normalized()
  length=random.uniform(.13,.24);width=length*.42;k=len(vs)
  points=[p-axis*length,p-axis*length*.22+cross*width,p+Vector((0,0,.022)),p+axis*length*.65+cross*width*.62,p+axis*length,p+axis*length*.65-cross*width*.62,p-axis*length*.22-cross*width]
  vs.extend(tuple(q) for q in points);fs.extend([(k,k+1,k+2),(k+1,k+3,k+2),(k+3,k+4,k+2),(k+4,k+5,k+2),(k+5,k+6,k+2),(k+6,k,k+2)])
  f=random.uniform(.65,1.35);cols.extend([(.075*f,.17*f,.036*f,1)]*7)
# Aerial roots concentrated beside/back of approach; central front lane remains open.
for i in range(28):
 a=random.uniform(-.1,math.pi*1.1);r=random.uniform(1.0,2.2);x,y=math.cos(a)*r,math.sin(a)*r
 z=random.uniform(3.6,4.8);bottom=random.uniform(.7,2.5)
 tube([(x,y,z),(x+.04,y,z-1),(x-.035,y+.03,bottom)],[.018,.012,.005],5,.1)
# Long irregular pale scar on front-facing trunk, slightly proud of bark.
vs,fs,cs=buffers['Scar']
for i in range(10):
 z=.9+i*.13;width=.075*math.sin((i+1)*math.pi/11)+.018;y=-.365+.036*i
 vs.extend([(-.07-width,y,z),(-.07+width,y-.008,z)]);cs.extend([(.43,.33,.22,1)]*2)
 if i:fs.append((2*i-2,2*i-1,2*i+1,2*i))
for key,m in [('Bark',bark),('Foliage',leaf),('Scar',scar)]:
 vs,fs,cs=buffers[key];me=bpy.data.meshes.new('Banyan_'+key);me.from_pydata(vs,[],fs);me.materials.append(m);me.update()
 o=bpy.data.objects.new('Banyan_'+key,me);scene.collection.objects.link(o)
 attr=me.color_attributes.new(name='ArtTone',type='FLOAT_COLOR',domain='POINT')
 for i,c in enumerate(cs):attr.data[i].color=c
 n=m.node_tree.nodes.new('ShaderNodeVertexColor');n.layer_name='ArtTone';m.node_tree.links.new(n.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
 for p in me.polygons:p.use_smooth=key!='Foliage'
scene['asset_grade']='B implementation candidate; original geometry'
bpy.ops.wm.save_as_mainfile(filepath=WORK+'/banyan_01_geometry.blend')
for a in bpy.context.screen.areas:
 if a.type=='VIEW_3D':
  from mathutils import Quaternion
  a.spaces.active.shading.type='MATERIAL';a.spaces.active.overlay.show_overlays=False;a.spaces.active.region_3d.view_location=(0,0,2.7);a.spaces.active.region_3d.view_distance=10;a.spaces.active.region_3d.view_rotation=Quaternion((1,0,0),1.37)
print('TREE',[(o.name,len(o.data.polygons)) for o in scene.objects])
