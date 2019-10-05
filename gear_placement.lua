local math2d = require("libs.vector-light")
local collisions = require('collisions')
local constants = require('constants')
local placement = {}

local placement_constants = {
  build_inactive_color = {255,155,0},
  build_collision_color = {255,0,0},
  build_active_color = {0,255,0},
  size_mod = 30,
}

local internals = {
  selected_gear = nil,
  new_gear_point = {x=0,y=0},
  new_gear_size = 1,
  new_gear_valid = false,
  build_active = false
}

local update_new_gear_position = function(state,mx,my)
  if not (mx and my) then
    mx, my = love.mouse.getPosition()
  end
  if internals.selected_gear then
    local cx,cy = internals.selected_gear.position.x,internals.selected_gear.position.y
    local angle_to = math2d.angleTo(mx-cx,my-cy)
    local gx, gy = math2d.fromPolar(angle_to,(internals.selected_gear.size + internals.new_gear_size) * constants.size_mod)
    internals.new_gear_point = {x=cx+gx,y=cy+gy}
    internals.new_gear_valid = #collisions.collide_circle_with_state(state,internals.new_gear_point.x,internals.new_gear_point.y,internals.new_gear_size) == 0
  end
end

placement.load = function()
  local screen_width, screen_height = love.graphics.getDimensions()
  internals.connection_point = {
    x = screen_width/2,
    y = screen_height/2
  }
end

placement.mouse_pressed = function(state,x,y,button)
  local result = nil
  local target_gear = collisions.find_component_at(state,x,y)
  if target_gear then
    print("clicked on a "..target_gear.type)
  end
  if button == 1 and not internals.selected_gear then
    --select gear
    internals.selected_gear = target_gear
  elseif button == 1 and internals.selected_gear then
    local selected = internals.selected_gear
    local point = internals.new_gear_point
    local size = internals.new_gear_size
    --check if the mouse collides with a different gear
    if target_gear then
      --connect two gears with a chain
      result = {type='connect',source = selected,target = target_gear}
      selected = nil
    elseif #collisions.collide_circle_with_state(state,point.x,point.y,size) == 0 then
      --place a new gear and select it
      result = {type = 'new',source = selected, position = point, size = size}
      selected = nil
    end
  elseif button == 2 then
    --cancel action logic
    internals.selected_gear = nil
  end

  update_new_gear_position(state)

  return result
end

placement.mouse_moved = function(state,x,y)
  local target_gear = collisions.find_component_at(state,x,y)

  if target_gear and internals.selected_gear and not (target_gear == internals.selected_gear) then
    internals.target_gear = target_gear
  elseif target_gear == nil then
    internals.target_gear = nil
  end
  update_new_gear_position(state,x,y)
end

placement.wheel_moved = function (state,x,y)
  if y > 0 and internals.new_gear_size < 3 then
    internals.new_gear_size = internals.new_gear_size + 1
  elseif y < 0 and internals.new_gear_size > 1 then
    internals.new_gear_size = internals.new_gear_size - 1
  end
  update_new_gear_position(state)
end


placement.draw = function()
  if internals.selected_gear then
    --highlight selected_gear
    local selected = internals.selected_gear
    love.graphics.setColor(placement_constants.build_active_color)
    love.graphics.circle("line",selected.position.x,selected.position.y,(selected.size*constants.size_mod)-1,50)

    if internals.target_gear then
      --draw link option
      if internals.target_gear.child then
        love.graphics.setColor(placement_constants.build_active_color)
      else
        love.graphics.setColor(placement_constants.build_collision_color)
      end
      love.graphics.line(internals.target_gear.position.x,internals.target_gear.position.y,selected.position.x,selected.position.y)
      love.graphics.circle("line",internals.target_gear.position.x,internals.target_gear.position.y,(internals.target_gear.size*constants.size_mod)-1,50)
    else
      --draw new_gear_radius
      if internals.new_gear_valid then
        love.graphics.setColor(placement_constants.build_active_color)
      else
        love.graphics.setColor(placement_constants.build_collision_color)
      end
      local gx,gy = internals.new_gear_point.x, internals.new_gear_point.y
      love.graphics.circle("line",gx,gy,internals.new_gear_size*constants.size_mod,50)
    end

  end

end


return placement