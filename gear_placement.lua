local math2d = require("libs.vector-light")
local placement = {}

local constants = {
  build_inactive_color = {255,155,0},
  build_collision_color = {255,0,0},
  build_active_color = {0,255,0},
  size_mod = 30,
}

local internals = {
  selected_gear = nil,
  new_gear_point = {x=0,y=0},
  new_gear_radius = 1,
  new_gear_valid = false,
  build_active = false
}

local update_new_gear_position = function(mx,my)
  if not (mx and my) then
    mx, my = love.mouse.getPosition()
  end
  if internals.selected_gear then
    local cx,cy = internals.selected_gear.position.x,internals.selected_gear.position.y
    local angle_to = math2d.angleTo(mx-cx,my-cy)
    local gx, gy = math2d.fromPolar(angle_to,(internals.selected_gear.size + internals.new_gear_radius) * constants.size_mod)
    internals.new_gear_point = {x=cx+gx,y=cy+gy}
  end
end

local check_collisions_with_list = function(x,y,radius,collider_list)
  for _, collider in pairs(collider_list) do
    if math2d.dist(x,y,collider.position.x,collider.position.y) < collider.size + radius then
      return true
    end
  end
  return false
end

local find_gear_under_position = function(x,y,state) 
  for _, component in pairs(state.all_components) do
    if math2d.dist(x,y,component.position.x,component.position.y) < component.size*constants.size_mod then
      return component
    end
  end
  return nil
end

placement.load = function()
  local screen_width, screen_height = love.graphics.getDimensions()
  internals.connection_point = {
    x = screen_width/2,
    y = screen_height/2
  }
end

placement.mouse_pressed = function(x,y,button,state)
  local target_gear = find_gear_under_position(x,y,state)
  if target_gear then
    print("clicked on a "..target_gear.type)
  end
  if button == 1 and not internals.selected_gear then
    --select gear
    internals.selected_gear = target_gear
  elseif button == 1 and internals.selected_gear then
    local selected = internals.selected_gear
    --check if the mouse collides with a different gear
    if target_gear then
      --connect two gears with a chain
    elseif check_collisions_with_list(selected.position.x,selected.position.y,selected.size*constants.size_mod,state.all_components) then
      --place a new gear and select it
    end
  elseif button == 2 then
    --cancel action logic
    internals.selected_gear = nil
  end

  update_new_gear_position()
end

placement.mouse_moved = function(x,y)
  update_new_gear_position(x,y)
end

placement.wheel_moved = function (x,y)
  if y > 0 and internals.new_gear_radius < 3 then
    internals.new_gear_radius = internals.new_gear_radius + 1
  elseif y < 0 and internals.new_gear_radius > 1 then
    internals.new_gear_radius = internals.new_gear_radius - 1
  end
  update_new_gear_position()
end


placement.draw = function(colliders)
  local pos = internals.connection_point
  local sw,sh = love.graphics.getDimensions()

  if internals.selected_gear then
    --highlight selected_gear
    local selected = internals.selected_gear
    love.graphics.setColor(constants.build_active_color)
    print(selected.position.x)
    love.graphics.circle("line",selected.position.x,selected.position.y,(selected.size*constants.size_mod)-1,50)
    --draw new_gear_radius
    local gx,gy = internals.new_gear_point.x, internals.new_gear_point.y
    love.graphics.circle("line",gx,gy,internals.new_gear_radius*constants.size_mod,50)
  end

  --if internals.build_active then
  --  local gx, gy = internals.new_gear_point.x, internals.new_gear_point.y
  --  if check_collisions_with_list(gx,gy,internals.new_gear_radius,colliders) then
  --    love.graphics.setColor(constants.build_collision_color)
  --  else
  --    love.graphics.setColor(constants.build_active_color)
  --  end
  --    --draw the line between connection_point and mouse
  --    local cx, cy = internals.connection_point.x,internals.connection_point.y
  --  love.graphics.line(gx, gy, cx, cy)
  --  --draw the new gear
  --  local gx,gy = internals.new_gear_point.x,internals.new_gear_point.y
  --  love.graphics.circle("line",gx,gy,internals.new_gear_radius,50)
  --else
  --  love.graphics.setColor(constants.build_inactive_color)
  --end
  --
  ----draw the connection_point
  --love.graphics.circle("line",pos.x,pos.y,internals.connection_radius,50)
end


return placement