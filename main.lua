local placement = require('gear_placement')
require('registry')
local simulation = require('simulation')
local renderer = require('simulation_renderer')
local puzzles = require('puzzles')
local camera_lib = require('libs.camera')

local state
local camera

function love.load()
  local screen_width, screen_height = love.graphics.getDimensions()
  state = simulation.create_state()
  camera = camera_lib(512,384)
  camera.smoother = camera_lib.smooth.linear(100)
  camera:lockX(512)

  for _, puzzle in pairs(puzzles) do
  puzzle(state)
  end


  for _=1, 100 do
    table.insert(circles,{shape='circle',x=math.random()*screen_width,y=math.random()*screen_height,radius=math.random(1,10)})
  end

  placement.load()
end

function love.draw()
  love.graphics.clear({0,0.34,0.73})

  renderer.render_money_background()

  camera:attach()
  --do camera relative drawing here
  renderer.render_areas(state, camera)
  placement.draw()
  renderer.draw(state)
  renderer.render_money_bar(state)

  camera:detach()
  --do window relative drawing here
  love.graphics.print(camera.x..","..camera.y,10,10)
  renderer.render_money_amount(state)
end

function love.resize()
  local screen_width, screen_height = love.graphics.getDimensions()
  circles = {}
  for _=1, 100 do
    table.insert(circles,{x=math.random()*screen_width,y=math.random()*screen_height})
  end
end

function love.keypressed(key)
  if key == "down" and camera.y < 384 then
    camera:lookAt(camera.x,camera.y + 100)
  elseif key == "up" then
    camera:lookAt(camera.x,camera.y - 100)
  elseif key == "x" then
    camera:lookAt(camera.x,384)
  end
end

function love.mousemoved(x,y)
  placement.mouse_moved(x,y)
end

function love.wheelmoved(x,y)
  placement.wheel_moved(x,y)
end

function love.mousepressed(x,y,button)
  local x, y, size, is_placed = placement.mouse_pressed(x,y,button,state)
  if is_placed == true then
    local new_gear = simulation.add_gear(state,size,{x=x,y=y})
  end
end

function love.quit()

end

local accumulatedDeltaTime = 0
function love.update(deltaTime)

  accumulatedDeltaTime = accumulatedDeltaTime + deltaTime

  local tickTime = 1/60

  while accumulatedDeltaTime > tickTime do
    simulation.update(state)
    accumulatedDeltaTime = accumulatedDeltaTime - tickTime
  end
end
