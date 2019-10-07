local math2d = require("libs.vector-light")
local constants = require('constants')
local HC = require("libs.HC")

local collisions = {}

function circle_and_rectangle_overlap(cx, cy, cr, rx, ry, rw, rh)
	local circle_distance_x = math.abs(cx - rx - rw/2)
	local circle_distance_y = math.abs(cy - ry - rh/2)

	if circle_distance_x > (rw/2 + cr) or circle_distance_y > (rh/2 + cr) then
		return false
	elseif circle_distance_x <= (rw/2) or circle_distance_y <= (rh/2) then
		return true
	end

	return (math.pow(circle_distance_x - rw/2, 2) + math.pow(circle_distance_y - rh/2, 2)) <= math.pow(cr, 2)
end

function point_in_rectangle(point_x, point_y, left, top, width, height)
	return point_x >= left
	and point_x <= left + width
	and point_y >= top
	and point_y <= top + height
end

function point_in_circle(point_x, point_y, circle_x, circle_y, circle_radius)
    return (math.pow(circle_x - point_x, 2) + math.pow(circle_y - point_y, 2)) <= math.pow(circle_radius, 2)
end

collisions.find_component_at = function(state,x,y)
  for _, component in pairs(state.all_components) do
    if math2d.dist(x,y,component.position.x,component.position.y) < component.size*constants.size_mod then
      return component
    end
  end
  return nil
end

collisions.circle_inside_boundary = function(x,y,size,bx,by,bw,bh)
  local r = size * constants.size_mod
  return x-r > bx and x+r < bx+bw and y-r > by and y+r < by+bh
end

collisions.rectangle_inside_boundary = function(x, y, w, h, bx, by, bw, bh)
  return point_in_rectangle(x, y, bx, by, bw, bh) and
         point_in_rectangle(x+w, y, bx, by, bw, bh) and
         point_in_rectangle(x+w, y+h, bx, by, bw, bh) and
         point_in_rectangle(x, y+h, bx, by, bw, bh)
end

local make_HC_state_for_gears = function(state, ignored, collider)
	local collider = HC.new(150)

  for _, component in pairs(state.all_components) do
		if component ~= ignored then
			collider:circle(component.position.x, component.position.y, component.size * constants.size_mod)
		end
  end

  for _, obstacle in pairs(state.obstacles) do
		collider:rectangle(obstacle.position.x, obstacle.position.y, obstacle.casing.width, obstacle.casing.height)
  end

  for _, sink in pairs(state.sinks) do
		collider:rectangle(sink.position.x - sink.casing.width/2, sink.position.y - sink.casing.height/2, sink.casing.width, sink.casing.height)
  end

  for _, splitter in pairs(state.splitters) do
		collider:rectangle(splitter.position.x - splitter.casing.width/2, splitter.position.y - splitter.casing.height/2, splitter.casing.width, splitter.casing.height)
  end

	return collider
end

local add_belt_to_collider = function(collider, src, dest)
  local dist = math2d.dist(src.x, src.y, dest.x, dest.y)

  local x, y = math2d.sub(dest.x, dest.y, src.x, src.y)
  local angle = math.atan2(y, x) + math.pi/2

  local rect = collider:rectangle(src.x - constants.size_mod, src.y - dist, constants.size_mod * 2, dist - constants.size_mod * 2)
  rect:rotate(angle, src.x, src.y)

  return rect
end

local make_HC_state_for_belts = function(state)
	local collider = HC.new(150)

  for _, component in pairs(state.all_components) do
    if component.connection_type == "belt" then
      add_belt_to_collider(collider, component.parent.position, component.position)
    end
  end

  for _, obstacle in pairs(state.obstacles) do
		collider:rectangle(obstacle.position.x, obstacle.position.y, obstacle.casing.width, obstacle.casing.height)
  end

	return collider
end



collisions.collide_circle_with_state = function(state,x,y,size, ignored)
	local collider = make_HC_state_for_gears(state, ignored)

  local circle = collider:circle(x, y, size*constants.size_mod)
	if next(collider:collisions(circle)) then
		return true
	end

	return false
end

collisions.collide_machine_rect_with_state = function(state, x, y, w, h)
  local collider = make_HC_state_for_gears(state, ignored)

  local rect = collider:rectangle(x, y, w, h)
	if next(collider:collisions(rect)) then
		return true
	end

	return false
end

collisions.collide_belt_with_state = function(state, src_position, dest_position)
  assert(src_position.x and dest_position.x) -- gimme a position not a gear!

  local collider = make_HC_state_for_belts(state)
  local belt = add_belt_to_collider(collider, src_position, dest_position)

	if next(collider:collisions(belt)) then
		return true
	end

	return false
end

return collisions