local placement = require('gear_placement')
require('registry')
local simulation = require('simulation')
local renderer = require('simulation_renderer')
local levels = require('levels')
local camera_lib = require('libs.camera')
local level_renderer = require('level_renderer')
local constants = require('constants')

local state
local camera

function love.load()
  local screen_width, screen_height = love.graphics.getDimensions()
  state = simulation.create_state()
  camera = camera_lib(512,384)
  camera.smoother = camera_lib.smooth.linear(100)
  camera:lockX(512)

  levels[1](state)

  for _=1, 100 do
    table.insert(circles,{shape='circle',x=math.random()*screen_width,y=math.random()*screen_height,radius=math.random(1,10)})
  end

  level_renderer.load()

  placement.load()
end

function love.draw()
  love.graphics.clear({0,0.34,0.73})

  renderer.render_gui_background()

  camera:attach()
  --do camera relative drawing here
  level_renderer.draw(5)
  --renderer.render_areas(state, camera)
  placement.draw(state)
  renderer.draw(state)
  renderer.render_money_bar(state)

  camera:detach()
  --do window relative drawing here
  love.graphics.print(camera.x..","..camera.y,10,10)
  renderer.render_money_amount(state)
  renderer.render_render_left_gui(state)
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
  placement.mouse_moved(state,x,y)
end

function love.wheelmoved(x,y)
  placement.wheel_moved(state,x,y)
end

function love.mousepressed(x,y,button)
  local rect_clicked = function(rect)
    local m_x, m_y = camera:worldCoords(x, y)
    return m_x >= rect[1] and m_x <= rect[1] + rect[3] and m_y >= rect[2] and m_y <= rect[2] + rect[4]
  end

  local buy_button = renderer.get_buy_button_rect(state)
  local left_gui_buttons = renderer.get_left_button_rects()

  for name, rect in pairs(left_gui_buttons) do
    if rect_clicked(rect) then
      state.selected_tool = name
      return
    end
  end

  if rect_clicked(buy_button) then
    state.areas_available = state.areas_available + 1
    levels[1](state)
  else
    local result = placement.mouse_pressed(state,x,y,button)
    if result and result.type then
      if result.type == 'new' then
        local new_gear = simulation.add_gear(state,result.size,result.position)
        if result.source then
          simulation.connect(result.source,new_gear,"gear")
        end
        placement.select_component(new_gear)
      elseif result.type == 'connect' then
        simulation.connect(result.source,result.target, "belt")
        placement.select_component(nil)
        if result.target.type == "gear" and result.target.child == nil then
          placement.select_component(result.target)
        end
      elseif result.type == 'remove' then
        simulation.remove(state, result.target)
      elseif result.type == 'disconnect_belt' then
        placement.select_component(result.target.parent)
        simulation.disconnect_belt(result.target)
      elseif result.type == 'new_splitter' then
        simulation.add_splitter(state, result.position)
      end
    end
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
