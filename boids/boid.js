var canvas = document.getElementById('background');

const MAX_STEERING_FORCE = 1;
const MAX_AVOIDANCE_FORCE = 1;
const MAX_VELOCITY = 4;

const ALIGNMENT_RADIUS = 50;
const COHESION_RADIUS = 100;
const SEPARATION_RADIUS = 50;

const BOID_SIZE = 10;

const MOUSE_FEAR_FACTOR = 100; // Due to the force limit there is a definite upper bound on this.

class Boid {
    constructor(color='#fce6fc', stroke=3) {
        this.color = color;
        this.stroke = stroke;
        this.pos = new Vector(Math.random() * canvas.width, Math.random() * canvas.height);
        this.vel = new Vector(Math.random() - 0.5, Math.random() - 0.5);
        this.vel.setMag((Math.random() * 2) + 2);
        this.acc = new Vector();
    }

    align(boids) {
        var local = boids.filter(b => b != this && this.pos.dist(b.pos) <= ALIGNMENT_RADIUS);
        var avg = new Vector();
        for (let b of local) {
            avg.add(b.vel);
        }
        if (local.length > 0) {
            avg.scale(1 / local.length);
            avg.setMag(MAX_VELOCITY);
            avg.sub(this.vel);
            avg.limit(MAX_STEERING_FORCE);
        }

        this.acc.add(avg);
    }

    cohere(boids) {
        var local = boids.filter(b => b != this && this.pos.dist(b.pos) <= COHESION_RADIUS);
        var avg = new Vector();
        for (let b of local) {
            avg.add(b.pos);
        }
        if (local.length > 0) {
            avg.scale(1 / local.length);
            avg.sub(this.pos);
            avg.setMag(MAX_VELOCITY);
            avg.sub(this.vel);
            avg.limit(MAX_STEERING_FORCE);
            avg.scale(0.2);
        }

        this.acc.add(avg);
    }

    separate(boids, mousePos) {
        var local = boids.filter(b => b != this && this.pos.dist(b.pos) <= SEPARATION_RADIUS);
        if (this.pos.dist(mousePos) <= SEPARATION_RADIUS) {
            local.push({pos: mousePos, isMouse: true});
        }
        var avg = new Vector();
        for (let b of local) {
            var diff = new Vector(this.pos.x - b.pos.x, this.pos.y - b.pos.y);
            var dist = this.pos.dist(b.pos);
            if (dist != 0) {
                diff.scale(1 / (dist ** 2));
            }
            if (b.isMouse) {
                diff.scale(MOUSE_FEAR_FACTOR);
            }
            avg.add(diff);
        }
        if (local.length > 0) {
            avg.scale(1 / local.length);
            avg.setMag(MAX_VELOCITY);
            avg.sub(this.vel);
            avg.limit(MAX_AVOIDANCE_FORCE);
        } else {
            return;
        }

        this.acc.add(avg);
    }

    flock(boids, mouseX, mouseY) {
        this.align(boids);
        this.cohere(boids);
        this.separate(boids, mouseX, mouseY);
    }

    edgeWrap(containerRect) {
        if (this.pos.x > canvas.width) {
            this.pos.x = 0;
        } else if (this.pos.x < 0) {
            this.pos.x = canvas.width;
        }
        if (this.pos.y > canvas.height) {
            this.pos.y = 0;
        } else if (this.pos.y < 0) {
            this.pos.y = canvas.height;
        }

        // This doesn't work :cc
        var offset = SEPARATION_RADIUS;
        if (this.pos.x > containerRect.left - offset && this.pos.x < containerRect.right + offset &&
            this.pos.y > containerRect.bottom - offset && this.pos.y < containerRect.top + offset) {
            //this.vel.scale(-1);
            //this.acc.scale(-1);
        }
    }

    update() {
        this.pos.add(this.vel);
        this.vel.add(this.acc);
        this.vel.limit(MAX_VELOCITY);
        this.acc.scale(0);
    }

    show(ctx) {
        ctx.strokeStyle = this.color;
        ctx.lineWidth = this.stroke;
        var heading = this.vel.angle();
        ctx.beginPath();
        ctx.moveTo(this.pos.x + (BOID_SIZE * Math.cos(heading)), this.pos.y + (BOID_SIZE * Math.sin(heading)));
        ctx.lineTo(this.pos.x + (BOID_SIZE * Math.cos(heading + (Math.PI * (3/4)))), this.pos.y + (BOID_SIZE * Math.sin(heading + (Math.PI * (3/4)))));
        ctx.moveTo(this.pos.x + (BOID_SIZE * Math.cos(heading)), this.pos.y + (BOID_SIZE * Math.sin(heading)));
        ctx.lineTo(this.pos.x + (BOID_SIZE * Math.cos(heading - (Math.PI * (3/4)))), this.pos.y + (BOID_SIZE * Math.sin(heading - (Math.PI * (3/4)))));
        ctx.stroke();
    }
}
