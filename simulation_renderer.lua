local renderer = {}

local constants = {
  size_mod = 30
}

renderer.draw = function(state)
  for _, component in pairs(state.all_components) do
    love.graphics.circle('line',component.position.x,component.position.y,component.size * constants.size_mod,50)
    love.graphics.print(tostring(component.current_speed),component.position.x,component.position.y)
  end
end

return renderer