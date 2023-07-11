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

screen = turtle.Screen()
screen.setup(600, 600) # window 
screen.screensize(550, 550) # canvas
screen.bgcolor("white")
screen.tracer(0)
framerate = 16

# The GRID
grid_drawer = turtle.Turtle()
grid_drawer.hideturtle()

square_size = 50

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

def moveleft():
  cur_x = snake.xcor()
  snake.setx(cur_x - square_size)

def moveright():
  cur_x = snake.xcor()
  snake.setx(cur_x + square_size)

def moveup():
  cur_y = snake.ycor()
  snake.sety(cur_y + square_size)

def movedown():
  cur_y = snake.ycor()
  snake.sety(cur_y - square_size)

# key bindings between arrows keys and associated movement functions
screen.onkeypress(moveleft, "Left")
screen.onkeypress(moveright, "Right")
screen.onkeypress(moveup, "Up")
screen.onkeypress(movedown, "Down")

def frame():
  screen.update() # update screen
  screen.ontimer(frame, framerate)

frame() # call the frame function to start the animation running!

screen.listen() # listen for user keyboard presses
screen.mainloop()
