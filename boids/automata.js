const STEP_SPEED = 2; // How many frames it should take to move one row.
const N_CELLS = 80;
const RULE = 90;
var grid = [];
var t = 0;
var isMoving = false;

function setup() {
    initialRow = [];
    for (let i=0; i<N_CELLS; i++) {
        initialRow.push(Boolean(Math.round(Math.random())));
        //initialRow.push(i == Math.floor(N_CELLS / 2) ? true : false);
    }
    grid.push(initialRow);
    isMoving = false;

    window.requestAnimationFrame(draw);
}

function draw() {
    var canvas = document.getElementById('background');
    var ctx = canvas.getContext('2d');

    var cellSize = Math.round(canvas.width / (N_CELLS - 2));

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    ctx.fillStyle = "#fce6fc";
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    if (t == 0) {
        // Step the automata.
        var lastRow = grid[grid.length - 1];
        lastRow.unshift(Boolean(Math.round(Math.random())));
        lastRow.push(Boolean(Math.round(Math.random())));
        var nextRow = [];
        for (let i=1; i<lastRow.length - 1; i++) {
            nextRow.push(step(lastRow[i - 1], lastRow[i], lastRow[i + 1]));
        }
        lastRow.shift();
        lastRow.pop();
        grid.push(nextRow);

        // Shift the grid down if it is filling the screen.
        if (cellSize * (grid.length - 2) > canvas.height) {
            isMoving = true;
            grid.shift();
        }
    }

    // Draw the grid.
    for (let i=0; i<grid.length; i++) {
        for (let j=0; j<N_CELLS; j++) {
            if (grid[i][j]) {
                ctx.fillStyle = "#fce6fc";
            } else {
                ctx.fillStyle = "#3eb489";
            }
            //ctx.fillRect(j * cellSize, i * cellSize - (isMoving ? (t * (cellSize / STEP_SPEED)) : 0), cellSize, cellSize);
            ctx.beginPath();
            ctx.arc(j * cellSize, i * cellSize - (isMoving ? (t * (cellSize / STEP_SPEED)) : 0), cellSize/2, 0, 2 * Math.PI, true);
            ctx.fill();
        }
    }

    t = isMoving ? (t + 1) % STEP_SPEED : 0;
    window.requestAnimationFrame(draw);
}

function step(left, center, right) {
    var binString = (+left).toString() + (+center).toString() + (+right).toString();
    var index = parseInt(binString, 2);
    var newValue = Boolean((RULE >>> index) & 1);
    return newValue;
}

setup();
