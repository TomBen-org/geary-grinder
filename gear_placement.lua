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

placement.select_component = function(component)
  internals.selected_gear = component
end

placement.mouse_pressed = function(state,x,y,button)
  local result = nil
  local target_gear = collisions.find_component_at(state,x,y)
  if target_gear then
    print("clicked on a "..target_gear.type)
  end

  if button == 1 and state.selected_tool == 'splitter' then
    -- TODO: collision check this
    result = {type = 'new_splitter', position = {x = x, y = y}}
  end

  if button == 1 and not internals.selected_gear then
    --select gear
    if target_gear == nil then
      if state.selected_tool == 'gear' then
        result = {type = 'new',source = nil, position = {x=x,y=y}, size = internals.new_gear_size}
      end
    elseif (target_gear.type == 'gear' or target_gear.type == 'source') and target_gear.child == nil then
      internals.selected_gear = target_gear
    end
  elseif button == 1 and internals.selected_gear then
    local selected = internals.selected_gear
    local point = internals.new_gear_point
    local size = internals.new_gear_size
    --check if the mouse collides with a different gear
    if state.selected_tool == 'belt' and target_gear and not(target_gear == selected or target_gear.type == "source" or target_gear.parent) then
      --connect two gears with a chain
      result = {type='connect',source = selected,target = target_gear}
    elseif state.selected_tool == 'gear' and #collisions.collide_circle_with_state(state,point.x,point.y,size) == 0 then
      --place a new gear and select it
      result = {type = 'new',source = selected, position = point, size = size}
    end
  elseif button == 2 then
    if (state.selected_tool == 'gear' or state.selected_tool == 'splitter') and (not internals.selected_gear) and target_gear and (target_gear.type == "gear" or target_gear.type == "splitter_input") then
      result = {type = 'remove', target=target_gear}
    end

    if state.selected_tool == 'belt' and not internals.selected_gear and target_gear then
      if target_gear.connection_type == 'belt' then
        result = {type = 'disconnect_belt', target = target_gear}
      elseif target_gear.child and target_gear.child.connection_type == 'belt' then
        result = {type = 'disconnect_belt', target = target_gear.child}
      end
    end

    --cancel action logic
    internals.selected_gear = nil
  end

  update_new_gear_position(state)

  return result
end

placement.mouse_moved = function(state,x,y)
  local target_gear = collisions.find_component_at(state,x,y)

  if target_gear and internals.selected_gear and not (target_gear == internals.selected_gear) and target_gear.type ~= 'source' and target_gear.parent == nil then
    internals.target_gear = target_gear
  elseif target_gear == nil then
    internals.target_gear = nil
  end
  update_new_gear_position(state,x,y)
end

placement.wheel_moved = function (state,x,y)
  if y > 0 and internals.new_gear_size < constants.max_gear_size then
    internals.new_gear_size = internals.new_gear_size + 1
  elseif y < 0 and internals.new_gear_size > 1 then
    internals.new_gear_size = internals.new_gear_size - 1
  end
  update_new_gear_position(state)
end


placement.draw = function(state)
  if internals.selected_gear then
    --highlight selected_gear
    local selected = internals.selected_gear
    love.graphics.setColor(placement_constants.build_active_color)
    love.graphics.circle("line",selected.position.x,selected.position.y,(selected.size*constants.size_mod)-1,50)

    if state.selected_tool == 'belt' and internals.target_gear then
      --draw link option
      if internals.target_gear.child then
        love.graphics.setColor(placement_constants.build_active_color)
      else
        love.graphics.setColor(placement_constants.build_collision_color)
      end
      love.graphics.line(internals.target_gear.position.x,internals.target_gear.position.y,selected.position.x,selected.position.y)
      love.graphics.circle("line",internals.target_gear.position.x,internals.target_gear.position.y,(internals.target_gear.size*constants.size_mod)-1,50)
    elseif state.selected_tool == 'gear' then
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