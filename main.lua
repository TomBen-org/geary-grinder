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

local win_screen

function love.load()
  local screen_width, screen_height = love.graphics.getDimensions()
  state = simulation.create_state()
  camera = camera_lib(512,384)
  camera.smoother = camera_lib.smooth.linear(100)
  camera:lockX(512)

  levels[1](state)

  level_renderer.load()
  renderer.load()

  placement.load()
  constants.fonts['small'] = love.graphics.newFont('/gfx/font-regular.ttf',8)
  constants.fonts['medium'] = love.graphics.newFont('/gfx/font-regular.ttf',16)
  constants.fonts['big'] = love.graphics.newFont('/gfx/font-regular.ttf',25)
  love.graphics.setFont(constants.fonts['small'])


  local bgm = love.audio.newSource("/sfx/Gears of DAW.wav", "stream")
  bgm:setLooping(true)
  love.audio.play(bgm)

  win_screen = love.graphics.newImage("/gfx/win_screen.png")
end



local rect_clicked = function(_x, _y, rect)
  return _x >= rect[1] and _x <= rect[1] + rect[3] and _y >= rect[2] and _y <= rect[2] + rect[4]
end



function love.draw()
  if state.areas_available > #levels then
    love.graphics.setColor{1,1,1}
    love.graphics.draw(win_screen)
    return
  end

  renderer.render_gui_background()

  camera:attach()
  local mx, my = camera:worldCoords(love.mouse.getPosition())
  --do camera relative drawing here
  level_renderer.draw(10)
  --renderer.render_areas(state, camera)
  renderer.draw(camera, state)


  local extra_lines = {}

  local left_gui_buttons = renderer.get_left_button_rects()
  local s_x, s_y = love.mouse.getPosition()
  for name, rect in pairs(left_gui_buttons) do
    if rect_clicked(s_x, s_y, rect) then
      if name == "gear" then
        table.insert(extra_lines, "Gear placement tool")
        table.insert(extra_lines, "")
        table.insert(extra_lines, "Gears can be connected to")
        table.insert(extra_lines, "each other, and the speed")
        table.insert(extra_lines, "will depend on the ratio of")
        table.insert(extra_lines, "their sizes.")
      end
      if name == "belt" then
        table.insert(extra_lines, "Belt placement tool")
        table.insert(extra_lines, "")
        table.insert(extra_lines, "Belts link gears directly,")
        table.insert(extra_lines, "so the size of the gears doesn't")
        table.insert(extra_lines, "affect the speed.")
      end
      if name == "splitter" then
        table.insert(extra_lines, "Splitter placement tool")
        table.insert(extra_lines, "")
        table.insert(extra_lines, "Splitters have one input gear")
        table.insert(extra_lines, "and two output gears. The outputs")
        table.insert(extra_lines, "both spin at half the input speed.")
      end
      if name == "up" then
        table.insert(extra_lines, "Move view up")
      end
      if name == "down" then
        table.insert(extra_lines, "Move view down")
      end
    end
  end

  placement.draw(state,mx,my,extra_lines)
  camera:detach()
  --do window relative drawing here
  --renderer.render_money_amount(state)
  renderer.render_render_left_gui(state)
  renderer.render_right_gui(state)

end

function love.resize()
end

local move_camera = function(key)
  if key == "down" and camera.y < 384 then
    camera:lookAt(camera.x,camera.y + 100)
  elseif key == "up" then
    camera:lookAt(camera.x,camera.y - 100)
  elseif key == "x" then
    camera:lookAt(camera.x,384)
  end

  state.flash_up_button = false
end

function love.keypressed(key)
  move_camera(key)
end


function love.mousemoved(x,y)
  local w_x, w_y = camera:worldCoords(x, y)
  placement.mouse_moved(state,w_x,w_y)
end

function love.wheelmoved(x,y)
  placement.wheel_moved(state,x,y)
end

function love.mousepressed(x,y,button)
  local w_x, w_y = camera:worldCoords(x, y)



  local buy_button = renderer.get_buy_button_rect()
  local left_gui_buttons = renderer.get_left_button_rects()

  for name, rect in pairs(left_gui_buttons) do
    if rect_clicked(x, y, rect) then

      if name == "up" or name == "down" then
        move_camera(name)
      else
        state.selected_tool = name
        placement.select_component(nil)
      end
      return
    end
  end

  if rect_clicked(x, y, buy_button) then
    if simulation.all_sinks_satisfied(state) then
      state.areas_available = state.areas_available + 1

      local level_index = math.min(state.areas_available, #levels)
      levels[level_index](state)

      state.flash_up_button = true
    end
  else
    local result = placement.mouse_pressed(state,w_x,w_y,button)
    if result and result.type then
      if result.type == 'new' then
        local new_gear = simulation.add_gear(state,result.size,result.position)
        if result.source then
          simulation.connect(result.source,new_gear,"gear")
          placement.select_component(nil)
        end
        placement.select_component(new_gear)
      elseif result.type == 'connect' then
        simulation.connect(result.source,result.target, "belt")
        placement.select_component(nil)
        if result.target.type == "gear" and result.target.child == nil then
          placement.select_component(result.target)
          placement.select_component(nil)
        end
      elseif result.type == 'remove' then
        simulation.remove(state, result.target)
      elseif result.type == 'disconnect_belt' then
        placement.select_component(result.target.parent)
        simulation.disconnect_belt(result.target)
        placement.select_component(nil)
      elseif result.type == 'new_splitter' then
        simulation.add_splitter(state, result.position)
        placement.select_component(nil)
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
