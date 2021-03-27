const dt = 0.0005;
const SCALE_FACTOR = 20;
const POINTS_PER_FRAME = 100;
const TRAIL_LENGTH = 1000;
const a = 10.0;
const b = 8.0 / 3.0;
const c = 28.0;

var t = 0;
const n = 5;
var attractors = new Array();

function init() {
    const x = 5.1;
    const y = 7.1;
    const z = 9.1;

    var canvas = document.getElementById('background');

    for (let i=0; i<n; i++) {
        attractors.push({ x: pertubate(x),
                          y: pertubate(y),
                          z: pertubate(z),
                          a: a,
                          b: b,
                          c: c,
                          scale: 20,
                          points: new Array(),
                          canvasX: (Math.random() - 0.1) * canvas.width * 0.8,
                          canvasY: (Math.random() - 0.1) * canvas.height * 0.8 });
    }

    window.requestAnimationFrame(draw);
}

function equation(x, y, z, a, b, c) {
  x += (a * (y - x)) * dt;
  y += (x * (c - z) - y) * dt;
  z += (x * y - b * z) * dt;
  return [x, y, z];
}

function pertubate(v) {
    return Math.random() * 2 * v;
}

function draw() {
    var canvas = document.getElementById('background');
    var ctx = canvas.getContext('2d');

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    ctx.fillStyle = "#1d1d1d";
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    for (let i=0; i<attractors.length; i++) {
        for (let _=0; _<POINTS_PER_FRAME; _++) {
            [x,y,z] = equation(attractors[i].x, attractors[i].y, attractors[i].z, attractors[i].a, attractors[i].b, attractors[i].c);
            attractors[i].x = x;
            attractors[i].y = y;
            attractors[i].z = z;
            attractors[i].points.push([x,y,z]);
            if (attractors[i].points.length > TRAIL_LENGTH) {
                attractors[i].points.splice(0, attractors[i].points.length - TRAIL_LENGTH);
            }
        }
        for (let p=0; p<attractors[i].points.length; p++) {
            ctx.fillStyle = 'hsl(' + (Math.floor(p * 0.2) % 360) + ',50%,50%)';
            [x,y,z] = attractors[i].points[p];
            ctx.fillRect((z * attractors[i].scale) + attractors[i].canvasX, (x * attractors[i].scale) + attractors[i].canvasY, 2, 2);
        }
    }

    //console.log(x,y,z);

    window.requestAnimationFrame(draw);
}

init();
