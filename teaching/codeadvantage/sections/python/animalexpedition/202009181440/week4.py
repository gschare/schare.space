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

square_size = 40 # in pixels
grid_size = 16 # in number of squares

window_size = square_size * grid_size # in pixels

screen = turtle.Screen()
screen.setup(window_size, window_size) # window 
screen.screensize(window_size * 0.9, window_size * 0.9) # canvas
screen.bgcolor("white")
screen.tracer(0)
framerate = 16 # delay between frames in milliseconds
snake_speed = 20 # delay between snake movement in number of frames

# The GRID
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

del grid_drawer

snake = turtle.Turtle()
snake.penup()
snake.color("green")
snake.shape("square")
#snake.shapesize(0.8, 0.8)
snake.setx(snake.xcor() + square_size/2)
snake.sety(snake.ycor() + square_size/2)

vel_x = 1
vel_y = 0

def move_snake():
    snake.setx(snake.xcor() + vel_x * square_size)
    snake.sety(snake.ycor() + vel_y * square_size)
    

# Food
# when the food and snake head are occupying the same square, then
# jump instantly to a different square WHERE THE TAIL DOES NOT EXIST
# and also add to the end of the snake tail

# Snake tail
# update with a for loop
# exclude snake head
# single variable representing the tail
# lots of turtles in this variable
# a list holding all the tails
# can be exactly the same "thing" as the head, just backed up

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

# key bindings between arrows keys and associated movement functions
screen.onkeypress(moveleft, "Left")
screen.onkeypress(moveright, "Right")
screen.onkeypress(moveup, "Up")
screen.onkeypress(movedown, "Down")

frame_count = 0

def frame():
    global frame_count
    screen.update() # update screen
    screen.ontimer(frame, framerate)
    frame_count += 1
    if frame_count >= snake_speed:
        move_snake()
        frame_count = 0

frame() # call the frame function to start the animation running!

screen.listen() # listen for user keyboard presses
screen.mainloop()
