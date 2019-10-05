local math2d = require("libs.vector-light")
local constants = require('constants')

local collisions = {}

collisions.find_component_at = function(state,x,y)
  for _, component in pairs(state.all_components) do
    if math2d.dist(x,y,component.position.x,component.position.y) < component.size*constants.size_mod then
      return component
    end
  end
  return nil
end

collisions.collide_circle_with_state = function(state,x,y,size)
  local collided = {}
  for _, component in pairs(state.all_components) do
    if math2d.dist(x,y,component.position.x,component.position.y) < ((component.size + size) * constants.size_mod) - 1 then
      table.insert(collided,component)
    end
  end
  return collided
end


return collisions