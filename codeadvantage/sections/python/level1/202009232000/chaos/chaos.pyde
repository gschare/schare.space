framerate = 600
w = 1280
h = 720
scale_factor = 6
stroke_weight = 0.5
t = 0
dt = 0.001
x, y, z = 0.1, 0.1, 0.1
a, b, c = 12.0, 8.0/3.0, 28.0

def equation(x, y, z, a, b, c):
     x += (a*(y-x))*dt
     y += (x*(c-z)-y)*dt
     z += (x*y - b*z)*dt
     return (x,y,z)

def setup():
    size(w, h)
    frameRate(framerate)
    background(0) # r,g,b
    colorMode(HSB, 360, 100, 100) # Hue, Saturation, Brightness
    
def draw():
    global t, x, y, z, points
    
    x, y, z = equation(x, y, z, a, b, c)
    
    translate(width/2, height/2)
    scale(scale_factor)
    
    noFill()
    strokeWeight(stroke_weight)
    stroke((t*(1/dt)*0.2) % 360,50,100)
    
    point(z, x)
    t += dt
