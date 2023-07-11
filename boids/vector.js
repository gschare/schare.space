class Vector {
    constructor(x=0, y=0) {
        this.x = x;
        this.y = y;
    }

    set(x=this.x, y=this.y) {
        this.x = x;
        this.y = y;
    }

    dist(v) {
        return Math.sqrt(Math.pow(this.x - v.x, 2) + Math.pow(this.y - v.y, 2));
    }

    mag() {
        return Math.sqrt(this.x**2 + this.y**2);
    }

    setMag(magnitude) {
        if (this.mag() == 0) {
            return;
        }
        this.scale(magnitude / this.mag());
    }

    angle() {
        var theta = Math.atan(this.y / this.x);
        if (this.x < 0 && this.y < 0) {
            theta = theta + Math.PI;
        } else if (this.x < 0 && this.y >= 0) {
            theta = Math.PI - theta;
        }
        return theta;
    }

    limit(magnitude) {
        if (this.mag() == 0) {
            return;
        }
        this.scale(Math.min(magnitude, this.mag()) / this.mag());
    }

    add(v) {
        this.x += v.x;
        this.y += v.y;
    }

    sub(v) {
        this.x -= v.x;
        this.y -= v.y;
    }

    scale(m) {
        this.x *= m;
        this.y *= m;
    }

    mul(v) {
        return;
    }
}
