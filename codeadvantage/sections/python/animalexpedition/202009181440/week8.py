# Game elements that we need to create:
  # player: a bunch of boxes that trail
  # player movement locked to the grid
  # the grid
  # the food which reappears randomly
  # score in the top left??
  # the lose condition -- how you lose the game
    # go beyond the boundaries
    # hitting yourself
      # "collisions"

import turtle
import random
import math

SQUARE_SIZE = 30 # in pixels
GRID_SIZE = 24 # in number of squares

WIDTH = SQUARE_SIZE * GRID_SIZE # in pixels
HEIGHT = SQUARE_SIZE * GRID_SIZE # in pixels

FRAMERATE = 16 # delay between frames in milliseconds
SNAKE_SPEED = 4 # delay between snake movement in number of frames

def setup_screen():
    global screen
    screen = turtle.Screen()
    screen.setup(WIDTH + 4, HEIGHT + 8) # window size
    screen.setworldcoordinates(0, HEIGHT, WIDTH, 0) # top left = (0,0), bottom right = (w,h)
    screen.bgcolor("white")
    screen.tracer(0)

def setup_bindings():
    # key bindings between arrows keys and associated movement functions
    screen.onkeypress(game.moveleft, "Left")
    screen.onkeypress(game.moveright, "Right")
    screen.onkeypress(game.moveup, "Up")
    screen.onkeypress(game.movedown, "Down")
    screen.onkeypress(game.restart, "r")
    screen.listen() # listen for user keyboard presses

def distance(x1, y1, x2, y2):
    return math.sqrt((x1 - x2)**2 + (y1 - y2)**2)

# The GRID
class Grid:
    def __init__(self):
        self.draw_grid()

    def draw_grid(self):
        self.borders = {
            "left"   : 0,
            "right"  : WIDTH,
            "bottom" : HEIGHT,
            "top"    : 0
        }

        grid_drawer = turtle.Turtle()
        grid_drawer.hideturtle()

        for x in range(self.borders["left"], self.borders["right"]+SQUARE_SIZE, SQUARE_SIZE):
            grid_drawer.penup()
            grid_drawer.goto(x, self.borders["top"])
            grid_drawer.pendown()
            grid_drawer.goto(x, self.borders["bottom"])

        for y in range(self.borders["top"], self.borders["bottom"]+SQUARE_SIZE, SQUARE_SIZE):
            grid_drawer.penup()
            grid_drawer.goto(self.borders["left"], y)
            grid_drawer.pendown()
            grid_drawer.goto(self.borders["right"], y)

    def get_borders(self):
        return self.borders

class Snake:

    def __init__(self, borders):

        self.vel_x = 0
        self.vel_y = 0
        self.can_move = True

        self.snake = turtle.Turtle()
        self.snake.penup()
        self.snake.color("green")
        self.snake.shape("square")
#snake.shapesize(0.8, 0.8)
        self.snake.setx(self.snake.xcor() + SQUARE_SIZE/2 + (borders["right"] - borders["left"])/3)
        self.snake.sety(self.snake.ycor() + SQUARE_SIZE/2 + (borders["bottom"] - borders["top"])/2)

        # create the tail (initially empty)
        self.tail = []

    def get_vel(self):
        return (self.vel_x, self.vel_y)

    def set_vel(self, vel_x, vel_y):
        self.vel_x = vel_x
        self.vel_y = vel_y

    def stop(self):
        self.can_move = False

    # snake.update(x, y) === Snake.update(snake, x, y)
    def update(self, borders, food_x, food_y):
        if not self.can_move:
            return

        new_x = self.snake.xcor() + self.vel_x * SQUARE_SIZE
        new_y = self.snake.ycor() + self.vel_y * SQUARE_SIZE

        # check for food pickup
        if distance(new_x, new_y, food_x, food_y) < SQUARE_SIZE:
            self.add_segment()
            #food.update() # broadcast an event

        # check for wall collision
        if new_x > borders["right"] or new_x < borders["left"] or new_y < borders["top"] or new_y > borders["bottom"]:
            #game_over() # game over event
            return

        # check for tail collision
        for segment in self.tail:
            if distance(new_x, new_y, segment.xcor(), segment.ycor()) < SQUARE_SIZE:
                #game_over() # game over event
                return

        # move all the tail segments
        self.move_tail()

        # update head position
        self.snake.setx(new_x)
        self.snake.sety(new_y)

    def add_segment(self):
        # new_segment: dictionary, turtle.Turtle(), class Segment, list, tuple
        new_segment = turtle.Turtle()
        new_segment.color("lime")
        new_segment.shape("square")
        new_segment.penup()
        new_segment.hideturtle()
        self.tail.append(new_segment)

    def move_tail(self):
        for i in range(len(self.tail)-1, -1, -1):
            if i==0:
                prev_x = self.snake.xcor()
                prev_y = self.snake.ycor()
            else:
                prev_x = self.tail[i-1].xcor()
                prev_y = self.tail[i-1].ycor()

            self.tail[i].goto(prev_x, prev_y)
            self.tail[i].showturtle()

# Food
# when the food and snake head are occupying the same square, then
# jump instantly to a different square WHERE THE TAIL DOES NOT EXIST
# and also add to the end of the snake tail

class Food:
    def __init__(self, borders):
        delegation = {
            200 : self.update
        }
        self.food = turtle.Turtle()
        self.food.penup()
        self.food.color("red")
        self.food.shape("circle")
        self.food.setx(self.food.xcor() + SQUARE_SIZE/2 + (borders["right"]-borders["left"])*2/3)
        self.food.sety(self.food.ycor() + SQUARE_SIZE/2 + (borders["bottom"]-borders["top"])/2)

    def get_pos(self):
        return self.food.pos()

    def update(self):
        pass

    def reset(self):
        # must not be where tail is... how to do this?
        self.food.setx(random.randint(0, GRID_SIZE-1) * SQUARE_SIZE + SQUARE_SIZE/2)
        self.food.sety(random.randint(0, GRID_SIZE-1) * SQUARE_SIZE + SQUARE_SIZE/2)

    def delegator(self, code):
        return delegation[code]

# Snake tail
# update with a for loop
# exclude snake head
# single variable representing the tail
# lots of turtles in this variable
# a list holding all the tails
# can be exactly the same "thing" as the head, just backed up

class Game:
    def __init__(self):
        self.grid = Grid()
        self.borders = self.grid.get_borders()
        self.food = Food(self.borders)
        self.snake = Snake(self.borders)

    def game_over(self):
        self.snake.set_vel(0, 0)
        self.snake.stop()
        print("Game Over!")
        
    def restart(self):
        setup()

    def moveleft(self):
        vel_x, vel_y = self.snake.get_vel()
        vel_x = -1 if vel_x != 1 else vel_x # cannot reverse direction
        vel_y = 0
        self.snake.set_vel(vel_x, vel_y)

    def moveright(self):
        vel_x, vel_y = self.snake.get_vel()
        vel_x = 1 if vel_x != -1 else vel_x # cannot reverse direction
        vel_y = 0
        self.snake.set_vel(vel_x, vel_y)

    def moveup(self):
        vel_x, vel_y = self.snake.get_vel()
        vel_x = 0
        vel_y = -1 if vel_y != 1 else vel_y # cannot reverse direction
        self.snake.set_vel(vel_x, vel_y)

    def movedown(self):
        vel_x, vel_y = self.snake.get_vel()
        vel_x = 0
        vel_y = 1 if vel_y != -1 else vel_y # cannot reverse direction
        self.snake.set_vel(vel_x, vel_y)

    def update(self):
        self.snake.update(self.borders, *self.food.get_pos())
        self.food.update()

class EventStack:
    def __init__(self):
        self.stack = []
    def push(code):
        self.stack.append(code)

def setup():
    global frame_count, game
    turtle.clearscreen()
    setup_screen()
    game = Game()
    setup_bindings()

    frame_count = 0

def frame():
    global frame_count
    screen.update() # update screen
    screen.ontimer(frame, FRAMERATE)
    frame_count += 1
    if frame_count >= SNAKE_SPEED:
        game.update()
        frame_count = 0

setup()
frame() # call the frame function to start the animation running!
screen.mainloop()
