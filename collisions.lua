local math2d = require("libs.vector-light")
local constants = require('constants')

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

collisions.collide_circle_with_state = function(state,x,y,size,ignored_gear)
  local collided = {}
  for _, component in pairs(state.all_components) do
    if math2d.dist(x,y,component.position.x,component.position.y) < ((component.size + size) * constants.size_mod) - 1 then
      table.insert(collided,component)
    end
  end

  for _, obstacle in pairs(state.obstacles) do
    if circle_and_rectangle_overlap(x,y,size*constants.size_mod,
      obstacle.position.x,
      obstacle.position.y,
      obstacle.casing.width,
      obstacle.casing.height) then
      table.insert(collided,obstacle)
    end
  end

  for _, sink in pairs(state.sinks) do
    if circle_and_rectangle_overlap(x,y,size*constants.size_mod,
      sink.position.x - sink.casing.width/2,
      sink.position.y - sink.casing.height/2,
      sink.casing.width,
      sink.casing.height) then
      table.insert(collided,sink)
    end
  end

  for _, splitter in pairs(state.splitters) do
    if circle_and_rectangle_overlap(x,y,size*constants.size_mod,
      splitter.position.x - splitter.casing.width/2,
      splitter.position.y - splitter.casing.height/2,
      splitter.casing.width,
      splitter.casing.height) then
      table.insert(collided,splitter)
    end
  end

  return collided
end


return collisions