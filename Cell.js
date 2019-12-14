function Cell (i, j, w) {

    this.i = i;
    this.j = j;
    this.x = i * w;
    this.y = j * w;
    this.w = w;
    this.neighboringMines = 0;

    this.mine = false;
    this.revealed = false;
    this.flagged = false;
    
}

Cell.prototype.show = function() {

    stroke(0);
    noFill();
    rect(this.x, this.y, this.w, this.w);

    if (this.flagged) {

        noStroke();
        fill('red');
        triangle(this.x + this.w/6, this.y + this.w/1.2,
                 this.x + this.w/1.2, this.y + this.w/1.2,
                 this.x + this.w/2, this.y + this.w/6);

    } else if (this.revealed) {

        if (this.mine) {
            stroke(0);
            fill(0);
            ellipse(this.x + this.w/2, this.y + this.w/2, w/2);
        } else {
            stroke(0);
            fill(200);
            rect(this.x, this.y, this.w, this.w);
            if (this.neighboringMines > 0) {
                textSize(w*0.9);
                textAlign(CENTER);
                fill(0);
                text(this.neighboringMines,
                    this.x + this.w/2,
                    this.y + this.w/1.2);
            }
        }

    }

}

Cell.prototype.countNeighboringMines = function() {

    if (this.mine) {
        this.neighboringMines = -1;
        return;
    }

    let count = 0;

    for (let x_off = -1; x_off <= 1; x_off++) {
        for (let y_off = -1; y_off <= 1; y_off++) {

            let i = this.i + x_off;
            let j = this.j + y_off;
            
            if (i > -1 && i < cols && j > -1 && j < rows) {

                let neighbor = grid[i][j];
                if (neighbor.mine) {
                    count++;

                }
            }
        }
    }

    this.neighboringMines = count;

}

Cell.prototype.contains = function(x, y) {
    return (x > this.x && x < this.x + this.w
        && y > this.y && y < this.y + this.w);
}

Cell.prototype.reveal = function() {

    this.revealed = true;
    
    if (this.neighboringMines == 0) {

       this.floodFill();

    }

}

Cell.prototype.floodFill = function() {

    for (let x_off = -1; x_off <= 1; x_off++) {
        for (let y_off = -1; y_off <= 1; y_off++) {

            let i = this.i + x_off;
            let j = this.j + y_off;

            if (i > -1 && i < cols && j > -1 && j < rows) {

                let neighbor = grid[i][j];

                if (!neighbor.mine && !neighbor.revealed
                    && !neighbor.flagged) {
                    neighbor.reveal();
                }

            }
        }
    }

}