
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
let w;

cells = 200;
let percentMines = 0.2;
let totalMines = Math.floor(cells * percentMines);
console.log("Mines: " + totalMines);

let options = [];
let firstMove = true;

function setup() {

    let size = min(windowWidth, windowHeight);
    createCanvas(size, size);

    w = Math.floor(size / Math.sqrt(cells));

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

function revealCell(x, y) {

    console.log("revealCell() has been invoked");
    
    for (let i = 0; i < cols; i++) {
        for (let j = 0; j < rows; j++) {
            if (grid[i][j].contains(x, y)) {
                
                console.log("First move: " + firstMove);

                if (firstMove) {
                    setMines(i, j);
                    firstMove = false;
                    console.log("First move: " + firstMove);
                }

                grid[i][j].reveal();
                console.log("revealing " + i + ", " + j);

                if (grid[i][j].mine) {
                    gameOver();
                }

            }
        }
    }

}

function flagCell(x, y) {

    console.log("flagCell() has been invoked");

    for (let i = 0; i < cols; i++) {
        for (let j = 0; j < rows; j++) {
            if (grid[i][j].contains(x, y)) {
                
                if (!grid[i][j].revealed) {
                    grid[i][j].flagged = !grid[i][j].flagged;
                    console.log("flagging cell!");
                }

            }
        }
    }

}

// function mouseClicked(event) {
//     if (event.button == LEFT) {
//         revealCell(mouseX, mouseY);
//     } else if (mouseButton == RIGHT) {
//         flagCell(mouseX, mouseY);
//         return false;
//     }
// }

function mousePressed() {
    console.log("mouse press event!");

    if (mouseButton == LEFT) {
        revealCell(mouseX, mouseY);
    } else if (mouseButton == RIGHT) {
        flagCell(mouseX, mouseY);
        return false;
    }    

}

// function touchMoved() {
//     flagCell(mouseX, mouseY);
//     console.log("Touch flag!");
//     return false;
// }

// function touchStarted(event) {
//     if (event.ended) {
//         revealCell(mouseX, mouseY);
//         console.log("Touch reveal!");
//         return false;
//     }
// }

function keyPressed() {
    
    if (key == ' ') {
        revealCell(mouseX, mouseY);
        return false;
    } else if (keyCode == SHIFT) {
        flagCell(mouseX, mouseY);
        return false;
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