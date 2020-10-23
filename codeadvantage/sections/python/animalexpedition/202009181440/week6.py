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
grid_size = 24 # in number of squares

WIDTH = SQUARE_SIZE * grid_size # in pixels
HEIGHT = SQUARE_SIZE * grid_size # in pixels

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
    screen.onkeypress(moveleft, "Left")
    screen.onkeypress(moveright, "Right")
    screen.onkeypress(moveup, "Up")
    screen.onkeypress(movedown, "Down")
    screen.onkeypress(restart, "r")
    screen.listen() # listen for user keyboard presses

def distance(x1, y1, x2, y2):
    return math.sqrt((x1 - x2)**2 + (y1 - y2)**2)

# The GRID
def draw_grid():
    global border
    border = {
        "left"   : 0,
        "right"  : WIDTH,
        "bottom" : HEIGHT,
        "top"    : 0
    }

    grid_drawer = turtle.Turtle()
    grid_drawer.hideturtle()

    for x in range(border["left"], border["right"], SQUARE_SIZE):
        grid_drawer.penup()
        grid_drawer.goto(x, border["top"])
        grid_drawer.pendown()
        grid_drawer.goto(x, border["bottom"])

    for y in range(border["top"], border["bottom"], SQUARE_SIZE):
        grid_drawer.penup()
        grid_drawer.goto(border["left"], y)
        grid_drawer.pendown()
        grid_drawer.goto(border["right"], y)

def create_snake():
    global snake, vel_x, vel_y, can_move, tail

    can_move = True

    snake = turtle.Turtle()
    snake.penup()
    snake.color("green")
    snake.shape("square")
#snake.shapesize(0.8, 0.8)
    snake.setx(snake.xcor() + SQUARE_SIZE/2 + (border["right"] - border["left"])/3)
    snake.sety(snake.ycor() + SQUARE_SIZE/2 + (border["bottom"] - border["top"])/2)

    vel_x = 0
    vel_y = 0

    # create the tail (initially empty)
    tail = []

def move_snake():
    if not can_move:
        return

    new_x = snake.xcor() + vel_x * SQUARE_SIZE
    new_y = snake.ycor() + vel_y * SQUARE_SIZE

    # check for food pickup
    if distance(new_x, new_y, food.xcor(), food.ycor()) < SQUARE_SIZE:
        add_segment()
        move_food()

    # check for wall collision
    if new_x > border["right"] or new_x < border["left"] or new_y < border["top"] or new_y > border["bottom"]:
        game_over()
        return

    # check for tail collision
    for segment in tail:
        if distance(new_x, new_y, segment.xcor(), segment.ycor()) < SQUARE_SIZE:
            game_over()
            return

    # move all the tail segments
    move_tail()

    # update head position
    snake.setx(new_x)
    snake.sety(new_y)
    #prev_x = snake.xcor() - vel_x * SQUARE_SIZE


def add_segment():
    # new_segment: dictionary, turtle.Turtle(), class Segment, list, tuple
    new_segment = turtle.Turtle()
    new_segment.color("lime")
    new_segment.shape("square")
    new_segment.penup()
    new_segment.hideturtle()
    tail.append(new_segment)

def move_tail():
    for i in range(len(tail)-1, -1, -1):
        if i==0:
            prev_x = snake.xcor()
            prev_y = snake.ycor()
        else:
            prev_x = tail[i-1].xcor()
            prev_y = tail[i-1].ycor()

        tail[i].goto(prev_x, prev_y)
        tail[i].showturtle()

# Food
# when the food and snake head are occupying the same square, then
# jump instantly to a different square WHERE THE TAIL DOES NOT EXIST
# and also add to the end of the snake tail
def create_food():
    global food
    food = turtle.Turtle()
    food.penup()
    food.color("red")
    food.shape("circle")
    food.setx(food.xcor() + SQUARE_SIZE/2 + (border["right"]-border["left"])*2/3)
    food.sety(food.ycor() + SQUARE_SIZE/2 + (border["bottom"]-border["top"])/2)

def move_food():
    # must not be where tail is... how to do this?
    food.setx(random.randint(0, grid_size-1) * SQUARE_SIZE + SQUARE_SIZE/2)
    food.sety(random.randint(0, grid_size-1) * SQUARE_SIZE + SQUARE_SIZE/2)

# Snake tail
# update with a for loop
# exclude snake head
# single variable representing the tail
# lots of turtles in this variable
# a list holding all the tails
# can be exactly the same "thing" as the head, just backed up

def game_over():
    global vel_x, vel_y, can_move
    vel_x = 0
    vel_y = 0
    can_move = False
    print("Game Over!")

def restart():
    setup()

def moveleft():
    global vel_x, vel_y
    vel_x = -1 if vel_x != 1 else vel_x # cannot reverse direction
    vel_y = 0

def moveright():
    global vel_x, vel_y
    vel_x = 1 if vel_x != -1 else vel_x # cannot reverse direction
    vel_y = 0

def moveup():
    global vel_x, vel_y
    vel_x = 0
    vel_y = -1 if vel_y != 1 else vel_y # cannot reverse direction

def movedown():
    global vel_x, vel_y
    vel_x = 0
    vel_y = 1 if vel_y != -1 else vel_y # cannot reverse direction

def setup():
    global frame_count
    turtle.clearscreen()
    setup_screen()
    setup_bindings()
    draw_grid()
    create_snake()
    create_food()

    frame_count = 0

def frame():
    global frame_count
    screen.update() # update screen
    screen.ontimer(frame, FRAMERATE)
    frame_count += 1
    if frame_count >= SNAKE_SPEED:
        move_snake()
        frame_count = 0

setup()
frame() # call the frame function to start the animation running!
screen.mainloop()
