local math2d = require("libs.vector-light")
local constants = require('constants')
local simulation = require('simulation')

local renderer = {}

local rgb_255_to_1 = function(color)
  return {color[1]/255,color[2]/255,color[3]/255}
end

local render_constants = {
  colors = {
    ["source"] = {0.63,0.21,0.79},
    ["sink_part"] = {0.94,0.99,0.23},
    ["gear"] = rgb_255_to_1({172,230,241}),
    ["gear-inner"] = rgb_255_to_1({132,218,234}),
    ["peg"] = rgb_255_to_1({134,180,82}),
    ["belt"] = {0.2,0.2,0.2},
    ["sink"] = {0.23,0.49,0.78},
    ["link"] = {0.3,0.3,0.3},
    ["blueprint-bg"] = rgb_255_to_1({29,117,189}),
    ["other"] = {1,1,1},
    ["money_background"] = {0.3, 0.3, 0.3},
    ["money_foreground"] = {1, 1, 0},
    ["grid_color"] = {0.9,0.9,0.9},
    ["buy_area_unavailable"] = {1, 0, 0},
    ["buy_area_available"] = {0, 1, 0},
    ["left_bar_button"] = {0.5, 0.5, 0.5},
    ["selected_left_bar_button"] = {0.75, 0.75, 0.75},
    ["locked_area_tint"] = {1, 0, 0, 0.3}
  },
  line_widths = {
    ["case"] = 2,
    ["selection"] = 1,
    ["belt"] = 6
  }
}

local draw_belt = function(component)
  local x = component.position.x - component.child.position.x
  local y = component.position.y - component.child.position.y
  local angle = math2d.angleTo(x,y)
  --local angle = math2d.angleTo(component.position.x,component.position.y,component.child.position.x,component.child.position.y)

  local belt_radius = constants.size_mod


  local quart = math.pi/2
  local parent = {
    top = {
      angle = angle + quart,
      x = component.position.x + belt_radius * math.cos(angle+quart),
      y = component.position.y + belt_radius * math.sin(angle+quart),
    },
    bottom = {
      angle = angle - quart,
      x = component.position.x + belt_radius * math.cos(angle-quart),
      y = component.position.y + belt_radius * math.sin(angle-quart),
    },
  }
  local child = {
    top = {
      x = component.child.position.x + belt_radius * math.cos(angle+quart),
      y = component.child.position.y + belt_radius * math.sin(angle+quart),
    },
    bottom = {
      x = component.child.position.x + belt_radius * math.cos(angle + quart*3),
      y = component.child.position.y + belt_radius * math.sin(angle + quart*3),
    },
  }
  love.graphics.setColor(render_constants.colors["belt"])
  love.graphics.setLineWidth(render_constants.line_widths["belt"])
  love.graphics.line(parent.top.x,parent.top.y,child.top.x,child.top.y)
  love.graphics.line(parent.bottom.x,parent.bottom.y,child.bottom.x,child.bottom.y)

  love.graphics.arc("line","open",
    component.position.x,
    component.position.y,
    belt_radius,
    angle - quart,
    angle + quart,
    10)

  love.graphics.arc("line","open",
    component.child.position.x,
    component.child.position.y,
    belt_radius,
    angle + quart,
    angle + quart*3,
    10)

  love.graphics.setLineWidth(1)
  love.graphics.setColor(255,255,255)
end

local draw_obstacle = function(obstacle)
  local left_top = {
    x = obstacle.position.x,
    y = obstacle.position.y,
  }
  love.graphics.setColor(render_constants.colors["blueprint-bg"])
  love.graphics.rectangle("fill",left_top.x,left_top.y,obstacle.casing.width,obstacle.casing.height)
  love.graphics.setLineWidth(render_constants.line_widths['case'])
  love.graphics.setColor(render_constants.colors["gear"])
  love.graphics.rectangle("line",left_top.x,left_top.y,obstacle.casing.width,obstacle.casing.height)

  love.graphics.setLineWidth(render_constants.line_widths['selection'])
end

local draw_machine = function(machine)
  local left_top = {
    x = machine.position.x - machine.casing.width/2,
    y = machine.position.y - machine.casing.height/2,
  }
  --love.graphics.setColor(render_constants.colors["gear-inner"])
  --love.graphics.rectangle("fill",left_top.x+2,left_top.y+2,machine.casing.width,machine.casing.height)
  love.graphics.setColor(render_constants.colors["blueprint-bg"])
  love.graphics.rectangle("fill",left_top.x,left_top.y,machine.casing.width,machine.casing.height)
  love.graphics.setLineWidth(render_constants.line_widths['case'])
  love.graphics.setColor(render_constants.colors["gear"])
  love.graphics.rectangle("line",left_top.x,left_top.y,machine.casing.width,machine.casing.height)

  love.graphics.setLineWidth(render_constants.line_widths['selection'])

end

local draw_sink_indicators = function(machine)
  local percentage_satisfied = simulation.get_sink_percentage_satisfied(machine)
  if percentage_satisfied == 0 then
    love.graphics.setColor{1,0,0}
  elseif percentage_satisfied < 1 then
    love.graphics.setColor{1,1,0}
  elseif percentage_satisfied == 1 then
    love.graphics.setColor{0,1,0}
  end

  love.graphics.circle('fill', machine.position.x, machine.position.y - machine.casing.height/2 + 10, 8)


  for _, gear in pairs(machine.components) do
    local absSpeed = math.abs(gear.current_speed)
    local speedText
    if absSpeed == math.floor(absSpeed) then
      speedText = tostring(absSpeed)
    else
      speedText = string.format("%.2f", absSpeed)
    end

    local text = love.graphics.newText(love.graphics.getFont(), speedText .. "/" .. gear.speed_max)
    local textWidth, textHeight = text:getDimensions()

    if absSpeed < gear.speed_min then
      love.graphics.setColor{1,0,0}
    elseif absSpeed < gear.speed_max then
      love.graphics.setColor{1,1,0}
    elseif absSpeed == gear.speed_max then
      love.graphics.setColor{0,1,0}
    else
      love.graphics.setColor{1,0,0}
    end
    love.graphics.draw(text, gear.position.x - textWidth/2, gear.position.y - gear.size*constants.size_mod - 20)
  end
end

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
	love.graphics.setColor(render_constants.colors["gear"])
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

  love.graphics.setColor(render_constants.colors["gear-inner"])
  love.graphics.circle('fill',pos.x,pos.y,((gear.size*constants.size_mod)-constants.whole_depth/2)*0.8,30)

  love.graphics.setColor(render_constants.colors["gear"])
  love.graphics.circle('fill',pos.x,pos.y,((gear.size*constants.size_mod)-constants.whole_depth/2)*0.2,30)

  love.graphics.setColor(render_constants.colors["peg"])
  love.graphics.circle('fill',pos.x,pos.y,5,30)

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
  return {constants.screen_w - constants.right_bar + 20, 20, constants.right_bar - 40, 100}
end

renderer.render_next_level_button = function(state)
  --local money_height = (state.money / state.next_price) * state.areas_available * constants.area_size
  --love.graphics.setColor(render_constants.colors.money_foreground)
  --love.graphics.rectangle('fill', constants.screen_w - constants.right_bar, constants.screen_h - money_height, constants.right_bar, money_height)

  love.graphics.setColor(render_constants.colors.buy_area_available)
  if not simulation.all_sinks_satisfied(state) then
    love.graphics.setColor(render_constants.colors.buy_area_unavailable)
  end
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

  local current_y = 20
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
  love.graphics.print("Money: " .. math.floor(state.money), constants.left_bar + 10, 50)
  love.graphics.print("Income: " ..  string.format("%.2f",state.last_income * 60) .. " / s", constants.left_bar + 10, 70)
end

renderer.draw = function(camera, state)
  love.graphics.setColor(render_constants.colors.locked_area_tint)

  local _, top_y = camera:worldCoords(0, 0)

  love.graphics.rectangle('fill', constants.left_bar, top_y, constants.screen_w - constants.left_bar - constants.right_bar - 1, constants.screen_h - (state.areas_available * constants.area_size) - top_y)


  for i=1,state.areas_available do
    love.graphics.setColor{0,0,0}
    local text = love.graphics.newText(love.graphics.getFont(), "Level " .. i)
    local textWidth, textHeight = text:getDimensions()
    love.graphics.draw(text, constants.screen_w / 2 - textWidth/2, constants.screen_h - constants.area_size*i)
  end

  for _, sink in pairs(state.sinks) do
    draw_machine(sink)
  end

  for _, splitter in pairs(state.splitters) do
    draw_machine(splitter)
  end

  for _, obstacle in pairs(state.obstacles) do
    draw_obstacle(obstacle)
  end

  for _, component in pairs(state.all_components) do
    --love.graphics.setColor(render_constants.colors[component.type] or render_constants.colors['other'])
    --love.graphics.circle('line',component.position.x,component.position.y,component.size * constants.size_mod,50)
    draw_gear(component)

    --if component.child then
    --  love.graphics.setColor(render_constants.colors["link"])
    --  love.graphics.line(component.position.x,component.position.y,component.child.position.x,component.child.position.y)
    --end
    love.graphics.setColor{0,0,0}
    love.graphics.print(tostring(component.size)..","..component.current_speed,component.position.x,component.position.y)
  end

  for _, gear in pairs(state.all_components) do
    if gear.parent and gear.connection_type == 'belt' then
      draw_belt(gear.parent)
    end
  end

  for _, sink in pairs(state.sinks) do
    draw_sink_indicators(sink)
  end
end



return renderer