var p;

function init() {
    p = 0.0;
    window.requestAnimationFrame(draw);
}

function draw() {
    var canvas = document.getElementById('background');
    var ctx = canvas.getContext('2d');

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(canvas.width/2, canvas.height/2, 50, 8 * p, (Math.PI / 2) + (8 * p), false); // Outer circle
    //ctx.moveTo(110, 75);
    //ctx.arc(75, 75, 35, 0, Math.PI, false);  // Mouth (clockwise)
    //ctx.moveTo(65, 65);
    //ctx.arc(60, 65, 5, 0, Math.PI * 2, true);  // Left eye
    //ctx.moveTo(95, 65);
    //ctx.arc(90, 65, 5, 0, Math.PI * 2, true);  // Right eye
    ctx.stroke();

    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.arc(canvas.width/2, canvas.height/2, 100, (Math.PI * 1.5) - p, Math.PI - p, true); // Outer circle
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(canvas.width/2, canvas.height/2, 100, 0 - p, (Math.PI/2) - p, false); // Outer circle
    ctx.stroke();

    console.log(p);
    p = p + 0.01;
    window.requestAnimationFrame(draw);
}

init();
