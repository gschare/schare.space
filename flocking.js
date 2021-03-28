const N_BOIDS = 200;
var flock = [];
var t = 0;

var mousePos = new Vector(0.0, 0.0);

function setup() {
    for (let i=0; i<N_BOIDS; i++) {
        flock.push(new Boid());
    }

    window.requestAnimationFrame(draw);
}

function draw() {
    var container = document.getElementById('container'); // Boids should avoid the container.
    var containerRect = container.getBoundingClientRect();
    var darkMode = container.classList.contains('dark-mode');

    // Get context.
    var canvas = document.getElementById('background');
    var ctx = canvas.getContext('2d');

    // Update mouse coordinates.
    canvas.addEventListener('mousemove', function(e) {
        mousePos.set(e.clientX, e.clientY);
    });

    // Refresh screen.
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = darkMode ? '#3eb489' : '#fce6fc';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Calculate new boid forces.
    for (let boid of flock) {
        boid.edgeWrap(canvas.width, canvas.height, containerRect);
        boid.flock(flock, mousePos);
    }
    // Update and animate boids.
    for (let boid of flock) {
        boid.color = darkMode ? '#fce6fc' : '#3eb489';
        boid.update();
        boid.show(ctx);
    }

    // Do it again.
    window.requestAnimationFrame(draw);
}

setup();

