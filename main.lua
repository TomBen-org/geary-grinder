local placement = require('gear_placement')
require('registry')
local simulation = require('simulation')
local renderer = require('simulation_renderer')
local puzzles = require('puzzles')

local state

function love.load()
  state = simulation.create_state()

  for _, puzzle in pairs(puzzles) do
    puzzle(state)
  end

  local screen_width, screen_height = love.graphics.getDimensions()

  for _=1, 100 do
    table.insert(circles,{shape='circle',x=math.random()*screen_width,y=math.random()*screen_height,radius=math.random(1,10)})
  end

  placement.load()
end

function love.draw()
  --for _, circle in pairs(circles) do
  --  love.graphics.setColor(circle_constants.color)
  --  love.graphics.circle("fill",circle.x,circle.y,circle.radius,10)
  --end

  --placement.draw(circles)
  renderer.draw(state)
end

function love.resize()
  local screen_width, screen_height = love.graphics.getDimensions()
  circles = {}
  for _=1, 100 do
    table.insert(circles,{x=math.random()*screen_width,y=math.random()*screen_height})
  end
end

function love.keypressed()

end

function love.mousemoved(x,y)
  placement.mouse_moved(x,y)
end

function love.wheelmoved(x,y)
  placement.wheel_moved(x,y)
end

function love.mousepressed(x,y,button)
  local x, y, size, is_placed = placement.mouse_pressed(x,y,button,clicked_gear)
  if is_placed == true then
    local new_gear = simulation.add_gear(state,size,{x=x,y=y})
  end
end

function love.quit()

end

function love.update(dt)
  simulation.update(state)
end
