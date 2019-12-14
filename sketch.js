
function make2DArray(cols, rows) {

    let arr = new Array(cols);

    for (let i = 0; i < arr.length; i++) {
        arr[i] = new Array(rows);
    }

    return arr;

}

let grid;
let cols;
let rows;

let canvasPx = 801;
let cells = 400;
let w = Math.floor(canvasPx / Math.sqrt(cells));
let percentMines = 0.2;
let totalMines = Math.floor(cells * percentMines);
console.log("Mines: " + totalMines);

let options = [];

function setup() {

    createCanvas(canvasPx, canvasPx);
    cols = floor(width / w);
    rows = floor(height / w);

    grid = make2DArray(cols, rows);

    for (let i = 0; i < cols; i++) {
        for (let j = 0; j < rows; j++) {
            grid[i][j] = new Cell(i, j, w);
        }
    }

    for (let i = 0; i < cols; i++) {
        for (let j = 0; j < rows; j++) {
            options.push([i, j]);
        }
    }

    for (let n = 0; n < totalMines; n++) {
        let index = floor(random(options.length));
        let choice = options[index];
        let i = choice[0];
        let j = choice[1];
        options.splice(index, 1);
        grid[i][j].mine = true;
    }

    for (let i = 0; i < cols; i++) {
        for (let j = 0; j < rows; j++) {
            grid[i][j].countNeighboringMines();
        }
    }

}

function gameOver() {

    for (let i = 0; i < cols; i++) {
        for (let j = 0; j < rows; j++) {
            grid[i][j].flagged = false;
            grid[i][j].revealed = true;
        }
    }

}

function revealCell() {
    
    for (let i = 0; i < cols; i++) {
        for (let j = 0; j < rows; j++) {
            if (grid[i][j].contains(mouseX, mouseY)) {
                
                grid[i][j].reveal();

                if (grid[i][j].mine) {
                    gameOver();
                }

            }
        }
    }

}

function flagCell() {

    for (let i = 0; i < cols; i++) {
        for (let j = 0; j < rows; j++) {
            if (grid[i][j].contains(mouseX, mouseY)) {
                
                if (!grid[i][j].revealed) {
                    grid[i][j].flagged = !grid[i][j].flagged;
                }

            }
        }
    }

}

// function mouseClicked(event) {
//     event.preventDefault()
//     if (event.button == LEFT) {
//         revealCell();
//     } else if (mouseButton == RIGHT) {
//         flagCell();
//     }
// }

function mousePressed() {

    if (mouseButton == LEFT) {
        revealCell();
    } else if (mouseButton == RIGHT) {
        flagCell();
    }

}

function keyPressed() {
    
    if (key == ' ') {
        revealCell();
    } else if (keyCode == SHIFT) {
        flagCell();
    }

}

function draw() {

    background(255);

    for (let i = 0; i < cols; i++) {
        for (let j = 0; j < rows; j++) {
            grid[i][j].show();
        }
    }

    // textAlign(CENTER);
    // fill('red');
    // textSize(width/3);
    // text('Game Over', width/2, height/2);

}