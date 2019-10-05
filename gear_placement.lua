local math2d = require("libs.vector-light")
local placement = {}

local constants = {
  build_inactive_color = {255,0,0},
  build_active_color = {0,255,0},
}

local internals = {
  connection_point = {x=0,y=0},
  connection_radius = 50,
  new_gear_point = {x=0,y=0},
  new_gear_radius = 50,
  build_active = false
}

local update_new_gear_position = function(mx,my)
  if not (mx and my) then
    mx, my = love.mouse.getPosition()
  end
  if internals.build_active then
    local cx,cy = internals.connection_point.x,internals.connection_point.y
    local angle_to = math2d.angleTo(mx-cx,my-cy)
    local gx, gy = math2d.fromPolar(angle_to,internals.connection_radius + internals.new_gear_radius)
    internals.new_gear_point = {x=cx+gx,y=cy+gy}
  end
end

placement.load = function()
  local screen_width, screen_height = love.graphics.getDimensions()
  internals.connection_point = {
    x = screen_width/2,
    y = screen_height/2
  }
end

placement.mouse_pressed = function(x,y,button)
  if math2d.dist(x,y,internals.connection_point.x,internals.connection_point.y) < internals.connection_radius and
    internals.build_active == false then
    internals.build_active = true
  else
    internals.build_active = false
  end
  update_new_gear_position()
end

placement.mouse_moved = function(x,y)
  update_new_gear_position(x,y)
end

placement.wheel_moved = function (x,y)
  if y > 0 and internals.new_gear_radius < 50 then
    internals.new_gear_radius = internals.new_gear_radius + 10
  elseif y < 0 and internals.new_gear_radius > 10 then
    internals.new_gear_radius = internals.new_gear_radius - 10
  end
  update_new_gear_position()
end


placement.draw = function()
  local pos = internals.connection_point

  if internals.build_active then
    love.graphics.setColor(constants.build_active_color)
    --draw the line between connection_point and mouse
    local cx, cy = internals.connection_point.x,internals.connection_point.y
    local gx, gy = internals.new_gear_point.x, internals.new_gear_point.y
    love.graphics.line(gx, gy, cx, cy)
    --draw the new gear
    local gx,gy = internals.new_gear_point.x,internals.new_gear_point.y
    love.graphics.circle("line",gx,gy,internals.new_gear_radius,50)
  else
    love.graphics.setColor(constants.build_inactive_color)
  end

  --draw the connection_point
  love.graphics.circle("line",pos.x,pos.y,internals.connection_radius,50)
end


return placement