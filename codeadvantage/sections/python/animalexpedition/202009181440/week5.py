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

square_size = 30 # in pixels
grid_size = 24 # in number of squares

window_size = square_size * grid_size # in pixels

framerate = 16 # delay between frames in milliseconds
snake_speed = 4 # delay between snake movement in number of frames

def setup_screen():
    global screen
    screen = turtle.Screen()
    screen.setup(window_size, window_size) # window 
    screen.screensize(window_size * 0.8, window_size * 0.8) # canvas
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
    grid_drawer = turtle.Turtle()
    grid_drawer.hideturtle()

    for x in range(-screen.window_width()//2, screen.window_width()//2 + square_size, square_size):
        grid_drawer.penup()
        grid_drawer.goto(x, screen.window_height()/2)
        grid_drawer.pendown()
        grid_drawer.goto(x, -screen.window_height()/2)

    for y in range(-screen.window_height()//2, screen.window_height()//2 + square_size, square_size):
        grid_drawer.penup()
        grid_drawer.goto(screen.window_width()/2, y)
        grid_drawer.pendown()
        grid_drawer.goto(-screen.window_width()/2, y)

def create_snake():
    global snake, vel_x, vel_y, can_move

    can_move = True

    snake = turtle.Turtle()
    snake.penup()
    snake.color("green")
    snake.shape("square")
#snake.shapesize(0.8, 0.8)
    snake.setx(snake.xcor() + square_size/2 - screen.window_width()//3)
    snake.sety(snake.ycor() + square_size/2)

    vel_x = 0
    vel_y = 0

def move_snake():
    if not can_move:
        return

    new_x = snake.xcor() + vel_x * square_size
    new_y = snake.ycor() + vel_y * square_size

    # check for food pickup
    if distance(new_x, new_y, food.xcor(), food.ycor()) < square_size:
        add_tail()
        move_food()

    # check for wall collision
    if new_x > screen.window_width()//2 or new_x < -screen.window_width()//2 or new_y > screen.window_height()//2 or new_y < -screen.window_height()//2:
        game_over()
        return

    # TODO: check for tail collision

    snake.setx(new_x)
    snake.sety(new_y)
    
def add_tail():
    pass

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
    food.setx(food.xcor() + square_size/2 + screen.window_width()//3)
    food.sety(food.ycor() + square_size/2)

def move_food():
    food.setx(random.randint(-grid_size/2, grid_size/2) * square_size + square_size/2)
    food.sety(random.randint(-grid_size/2, grid_size/2) * square_size + square_size/2)

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
    vel_x = -1
    vel_y = 0

def moveright():
    global vel_x, vel_y
    vel_x = 1
    vel_y = 0

def moveup():
    global vel_x, vel_y
    vel_x = 0
    vel_y = 1

def movedown():
    global vel_x, vel_y
    vel_x = 0
    vel_y = -1

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
    screen.ontimer(frame, framerate)
    frame_count += 1
    if frame_count >= snake_speed:
        move_snake()
        frame_count = 0

setup()
frame() # call the frame function to start the animation running!
screen.mainloop()
