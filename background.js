var p;
var arc;

function init() {
    p = 0.0;

    var canvas = document.getElementById('background');
    var ctx = canvas.getContext('2d');
    ctx.fillStyle = "#1d1d1d";
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    arc = { prevRadius: 100,
            prevCenter: { x: Math.random() * canvas.width, y: Math.random() * canvas.height },
            prevTheta:  Math.random() * 2 * Math.PI,
            prevDir:    Math.ceil(Math.random()) };

    window.requestAnimationFrame(draw);
}

function draw() {
    var canvas = document.getElementById('background');
    var ctx = canvas.getContext('2d');

    //ctx.clearRect(0, 0, canvas.width, canvas.height);

    ctx.lineWidth = 2;
    /*
    ctx.strokeStyle = "#ffffff";

    ctx.beginPath();
    ctx.arc(canvas.width/2, canvas.height/2, 50, 8 * p, (Math.PI / 2) + (8 * p), false);
    ctx.stroke();

    ctx.lineWidth = 6;

    ctx.beginPath();
    ctx.arc(canvas.width/2, canvas.height/2, 100, (Math.PI * 1.5) - p, Math.PI - p, true);
    ctx.stroke();

    ctx.beginPath();
    ctx.arc(canvas.width/2, canvas.height/2, 100, 0 - p, (Math.PI/2) - p, false); // Outer circle
    ctx.stroke();

    console.log(p);
    p = p + 0.01;
    */
    console.log(arc);
    arc = continueArc(ctx, arc.prevRadius, arc.prevCenter, arc.prevTheta, arc.prevDir);
    window.requestAnimationFrame(draw);
}

function continueArc(ctx, prevRadius, prevCenter, prevTheta, prevDir) {
    newDir = prevDir;//!prevDir;
    newCenter = { x: prevCenter.x + 5,//prevCenter.x + Math.floor((Math.random() - 0.5) * 2 * prevRadius),
                  y: prevCenter.y + 5 }//prevCenter.y + Math.floor((Math.random() - 0.5) * 2 * prevRadius) }
    cosPrevTheta = Math.cos(prevTheta);
    newRadius = Math.abs((((prevRadius * cosPrevTheta) + prevCenter.x - newCenter.x) / cosPrevTheta))
    newTheta = (Math.random() * Math.PI) + prevTheta;

    ctx.strokeStyle = "#ffffff";
    ctx.beginPath();
    ctx.arc(newCenter.x, newCenter.y, newRadius, prevTheta, newTheta, newDir);
    ctx.stroke();

    return { prevRadius: newRadius,
             prevCenter: newCenter,
             prevTheta:  newTheta,
             prevDir:    newDir };
}

init();
