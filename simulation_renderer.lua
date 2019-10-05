local renderer = {}

local constants = require('constants')

local render_constants = {
  size_mod = 30,
  colors = {
    ["source"] = {0.63,0.21,0.79},
    ["sink_part"] = {0.94,0.99,0.23},
    ["gear"] = {1,0.69,0.23},
    ["sink"] = {0.23,0.49,0.78},
    ["link"] = {0.3,0.3,0.3},
    ["other"] = {1,1,1},
    ["money_background"] = {0.3, 0.3, 0.3},
    ["money_foreground"] = {1, 1, 0},
    ["grid_color"] = {0.9,0.9,0.9},
  }
}

renderer.render_areas = function(state, camera)
  local _, y_offset = camera:worldCoords(0, 0)

  local highest = math.ceil((constants.screen_h-y_offset) / constants.area_size)
  local lowest = highest - math.floor(constants.screen_h / constants.area_size)

  local current = lowest
  while current <= highest do
    local level = constants.screen_h - current * constants.area_size

    love.graphics.setColor(render_constants.colors.grid_color)
    love.graphics.line(0, level, constants.screen_w - constants.right_bar, level)
    current = current + 1
  end
end

renderer.render_money_background = function()
  love.graphics.setColor(render_constants.colors.money_background)
  love.graphics.rectangle('fill', constants.screen_w - constants.right_bar, 0, constants.right_bar, constants.screen_h)
end

renderer.render_money_bar = function(state)
  local money_height = state.money / constants.money_size_scaler
  love.graphics.setColor(render_constants.colors.money_foreground)
  love.graphics.rectangle('fill', constants.screen_w - constants.right_bar, constants.screen_h - money_height, constants.right_bar, money_height)
end

renderer.render_money_amount = function(state)
  love.graphics.setColor({0, 0, 0})
  love.graphics.print(tostring(state.money), constants.screen_w - constants.right_bar, 50)
end

renderer.draw = function(state)
  for _, component in pairs(state.all_components) do
    love.graphics.setColor(render_constants.colors[component.type] or render_constants.colors['other'])
    love.graphics.circle('line',component.position.x,component.position.y,component.size * render_constants.size_mod,50)
    love.graphics.print(tostring(component.current_speed),component.position.x,component.position.y)
    if component.child then
      love.graphics.setColor(render_constants.colors["link"])
      love.graphics.line(component.position.x,component.position.y,component.child.position.x,component.child.position.y)
    end
  end
end

return renderer