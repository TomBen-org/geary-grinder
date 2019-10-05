local renderer = {}

local constants = {
  size_mod = 30,
  colors = {
    ["source"] = {0.63,0.21,0.79},
    ["sink_part"] = {0.94,0.99,0.23},
    ["gear"] = {1,0.69,0.23},
    ["sink"] = {0.23,0.49,0.78},
    ["other"] = {1,1,1},
  }
}



renderer.draw = function(state)
  for _, component in pairs(state.all_components) do
    love.graphics.setColor(constants.colors[component.type])
    love.graphics.circle('line',component.position.x,component.position.y,component.size * constants.size_mod,50)
    love.graphics.print(tostring(component.current_speed),component.position.x,component.position.y)
  end
end

return renderer