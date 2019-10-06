local renderer = {}

local constants = require('constants')

local render_constants = {
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
    ["buy_area_unavailable"] = {1, 0, 0},
    ["buy_area_available"] = {0, 1, 0},
    ["left_bar_button"] = {0.5, 0.5, 0.5},
    ["selected_left_bar_button"] = {0.75, 0.75, 0.75},
  }
}

local draw_gear = function(gear)
  local pos = gear.position
	-- rotate around the center of the screen by angle radians
  local transform = love.math.newTransform()
  transform:translate(pos.x,pos.y)
  transform:rotate(gear.rotation)
  transform:translate(-pos.x,-pos.y)
  love.graphics.push()
  love.graphics.applyTransform(transform)

  --draw everything as normal
  --draw body
	love.graphics.setColor(render_constants.colors[gear.type] or render_constants.colors['other'])
  love.graphics.circle('fill',pos.x,pos.y,(gear.size*constants.size_mod)-constants.whole_depth/2,30)

  --draw teeth
  local quantity = gear.size * constants.teeth_per_size
  local pitch = math.pi*2/quantity

  --love.graphics.arc("fill","pie",pos.x,pos.y,gear.size*constants.size_mod*1.3,i*pitch,(i+1)*pitch,5)
  --love.graphics.arc("fill","pie",pos.x,pos.y,gear.size*constants.size_mod*1.3,3*pitch,4*pitch,5)

  for i=1, quantity/2 do
    local k = i*2
    love.graphics.arc("fill","pie",pos.x,pos.y,(gear.size*constants.size_mod)+constants.working_depth/2,k*pitch,((k+1)*pitch),5)
  end

	love.graphics.setPointSize(5)
	love.graphics.setColor(0, 0, 0)
	love.graphics.points(pos.x, pos.y)

  love.graphics.pop()
end

renderer.render_areas = function(state, camera)
  local _, y_offset = camera:worldCoords(0, 0)

  local highest = math.ceil((constants.screen_h-y_offset) / constants.area_size)
  local lowest = highest - math.ceil(constants.screen_h / constants.area_size)

  local current = lowest
  while current <= highest do
    local level = constants.screen_h - current * constants.area_size

    love.graphics.setColor(render_constants.colors.grid_color)
    love.graphics.line(constants.left_bar, level, constants.screen_w - constants.right_bar, level)
    current = current + 1
  end
end

renderer.render_gui_background = function()
  love.graphics.clear(render_constants.colors.money_background)
  love.graphics.setColor(render_constants.colors.money_background)
  love.graphics.rectangle('fill', constants.screen_w - constants.right_bar, 0, constants.right_bar, constants.screen_h)
  love.graphics.rectangle('fill', 0, 0, constants.left_bar, constants.screen_h)
end

renderer.get_buy_button_rect = function(state)
  return {constants.screen_w - constants.right_bar + 20, constants.screen_h - constants.area_size * (state.areas_available), constants.right_bar - 40, 100}
end

renderer.render_money_bar = function(state)
  local money_height = state.money / constants.money_size_scaler
  love.graphics.setColor(render_constants.colors.money_foreground)
  love.graphics.rectangle('fill', constants.screen_w - constants.right_bar, constants.screen_h - money_height, constants.right_bar, money_height)

  love.graphics.setColor(render_constants.colors.buy_area_available)
  local rect = renderer.get_buy_button_rect(state)
  love.graphics.rectangle('fill', rect[1], rect[2], rect[3], rect[4])

  love.graphics.setColor{0,0,0}
  local text = love.graphics.newText(love.graphics.getFont(), "Buy\nnext\narea")
  local textWidth, textHeight = text:getDimensions()
  love.graphics.draw(text, rect[1] + rect[3]/2 - textWidth/2, rect[2] + rect[4]/2 - textHeight/2)
end

renderer.get_left_button_rects = function()
  local rects = {}

  local buttonMargin = 10

  local current_y = 100
  for _, name in pairs{"gear", "belt", "splitter"} do
    rects[name] =
    {
      buttonMargin,
      current_y,
      constants.left_bar - buttonMargin*2,
      constants.left_bar - buttonMargin*2,
    }

    current_y = current_y + constants.left_bar - buttonMargin
  end

  return rects
end

renderer.render_render_left_gui = function(state)
  for name, rect in pairs(renderer.get_left_button_rects()) do
    if name == state.selected_tool then
      love.graphics.setColor(render_constants.colors.selected_left_bar_button)
    else
      love.graphics.setColor(render_constants.colors.left_bar_button)
    end
    love.graphics.rectangle('fill', rect[1], rect[2], rect[3], rect[4])
    love.graphics.setColor{0,0,0}
    love.graphics.print(name, rect[1], rect[2])
  end
end

renderer.render_money_amount = function(state)
  love.graphics.setColor({0, 0, 0})
  love.graphics.print(tostring(state.money), constants.screen_w - constants.right_bar, 50)
end

renderer.draw = function(state)
  for _, component in pairs(state.all_components) do
    --love.graphics.setColor(render_constants.colors[component.type] or render_constants.colors['other'])
    --love.graphics.circle('line',component.position.x,component.position.y,component.size * constants.size_mod,50)
    draw_gear(component)
    if component.child then
      love.graphics.setColor(render_constants.colors["link"])
      love.graphics.line(component.position.x,component.position.y,component.child.position.x,component.child.position.y)
    end
    love.graphics.print(tostring(component.size)..","..component.current_speed,component.position.x,component.position.y)
  end
end



return renderer