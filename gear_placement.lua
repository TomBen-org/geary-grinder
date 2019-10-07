local math2d = require("libs.vector-light")
local collisions = require('collisions')
local simulation = require('simulation')
local constants = require('constants')
local renderer = require('simulation_renderer')
local placement = {}

local placement_constants = {
  build_inactive_color = {255,155,0},
  build_collision_color = {255,0,0},
  build_active_color = {0,255,0},
  size_mod = 30,
}

local internals = {
  selected_gear = nil,
  hovered_gear = nil,
  new_gear_point = {x=0,y=0},
  new_gear_size = constants.min_gear_size,
  new_gear_valid = false,
  build_active = false
}

local rgb_255_to_1 = function(color)
  return {color[1]/255,color[2]/255,color[3]/255}
end

local draw_fake_belt = function(source,target,color)
  local x = source.position.x - target.position.x
  local y = source.position.y - target.position.y
  local angle = math2d.angleTo(x,y)

  local belt_radius = constants.size_mod

  local quart = math.pi/2
  local parent = {
    top = {
      angle = angle + quart,
      x = source.position.x + belt_radius * math.cos(angle+quart),
      y = source.position.y + belt_radius * math.sin(angle+quart),
    },
    bottom = {
      angle = angle - quart,
      x = source.position.x + belt_radius * math.cos(angle-quart),
      y = source.position.y + belt_radius * math.sin(angle-quart),
    },
  }
  local child = {
    top = {
      x = target.position.x + belt_radius * math.cos(angle+quart),
      y = target.position.y + belt_radius * math.sin(angle+quart),
    },
    bottom = {
      x = target.position.x + belt_radius * math.cos(angle + quart*3),
      y = target.position.y + belt_radius * math.sin(angle + quart*3),
    },
  }
  love.graphics.setColor(color)
  love.graphics.setLineWidth(2)
  love.graphics.line(parent.top.x,parent.top.y,child.top.x,child.top.y)
  love.graphics.line(parent.bottom.x,parent.bottom.y,child.bottom.x,child.bottom.y)

  love.graphics.arc("line","open",
    source.position.x,
    source.position.y,
    belt_radius,
    angle - quart,
    angle + quart,
    10)

  love.graphics.arc("line","open",
    target.position.x,
    target.position.y,
    belt_radius,
    angle + quart,
    angle + quart*3,
    10)

  love.graphics.setLineWidth(1)
  love.graphics.setColor(255,255,255)
end

placement.get_splitter_preview_rect = function(x, y)
  return {x-95,y-90,190,180}
end

placement.valid_splitter_placement = function(state,x,y)
  local rect = placement.get_splitter_preview_rect(x, y)
  local bounds = simulation.get_bounding_box(state)

  return not collisions.collide_machine_rect_with_state(state,rect[1], rect[2], rect[3], rect[4]) and
         collisions.rectangle_inside_boundary(rect[1], rect[2], rect[3], rect[4],
                                              bounds.x,
                                              bounds.y,
                                              bounds.width,
                                              bounds.height)
end

placement.valid_circle_placement = function(state,x,y,s,ignore_gear)
  local no_collide = not collisions.collide_circle_with_state(state,x,y,s, internals.selected_gear)
  local bounds = simulation.get_bounding_box(state)
  local inside_boundary = collisions.circle_inside_boundary(
    x,y,s,
    bounds.x,
    bounds.y,
    bounds.width,
    bounds.height
  )
  return no_collide and inside_boundary
end

local update_new_gear_position = function(state,mx,my)
  if not (mx and my) then
    mx, my = internals.camera:worldCoords(love.mouse.getPosition())
  end
  if internals.selected_gear then
    local cx,cy = internals.selected_gear.position.x,internals.selected_gear.position.y
    local angle_to = math2d.angleTo(mx-cx,my-cy)
    local gx, gy = math2d.fromPolar(angle_to,(internals.selected_gear.size + internals.new_gear_size) * constants.size_mod)
    internals.new_gear_point = {x=cx+gx,y=cy+gy}
  else
    internals.new_gear_point = {x=mx,y=my}
  end
  internals.new_gear_valid = placement.valid_circle_placement(state,
    internals.new_gear_point.x,
    internals.new_gear_point.y,
    internals.new_gear_size
  )
end

placement.load = function(camera)
  local screen_width, screen_height = love.graphics.getDimensions()
  internals.connection_point = {
    x = screen_width/2,
    y = screen_height/2
  }
  internals.camera = camera
end

placement.select_component = function(component)
  internals.selected_gear = component
end

local valid_belt_placement = function(state, selected, target)
  return not (selected == target) and
    selected.child == nil and
    target.type ~= 'source' and
    target.parent == nil and
    not collisions.collide_belt_with_state(state, selected.position, target.position)
end

local valid_belt_preview_placement = function(state, selected, target_position)
  return not collisions.collide_belt_with_state(state, selected.position, target_position)
end


placement.mouse_pressed = function(state,x,y,button)
  local result = nil
  local target_gear = collisions.find_component_at(state,x,y)
  if target_gear then
    print("clicked on a "..target_gear.type)
  end

  if button == 1 and state.selected_tool == 'splitter' then
    if placement.valid_splitter_placement(state, x, y) then
      result = {type = 'new_splitter', position = {x = x, y = y}}
    end
  end

  if button == 1 and not internals.selected_gear then
    --select gear
    if target_gear == nil then
      if state.selected_tool == 'gear' then
        local valid_placement = placement.valid_circle_placement(state,x,y,internals.new_gear_size)

        if valid_placement then
          result = {type = 'new',source = nil, position = {x=x,y=y}, size = internals.new_gear_size}
        end
      end
    elseif (target_gear.type == 'gear' or target_gear.type == 'source') and target_gear.child == nil then
      internals.selected_gear = target_gear
    end
  elseif button == 1 and internals.selected_gear then
    local selected = internals.selected_gear
    local point = internals.new_gear_point
    local size = internals.new_gear_size
    --check if the mouse collides with a different gear
    if state.selected_tool == 'belt' and target_gear and valid_belt_placement(state, selected, target_gear) then
      --connect two gears with a chain
      result = {type='connect',source = selected,target = target_gear}
    elseif state.selected_tool == 'gear' and placement.valid_circle_placement(state, x, y, internals.new_gear_size) then
      --place a new gear and select it
      result = {type = 'new',source = selected, position = point, size = size}
    end
  elseif button == 2 then
    if (state.selected_tool == 'gear' or state.selected_tool == 'splitter') and (not internals.selected_gear) and target_gear and (target_gear.type == "gear" or target_gear.type == "splitter_input") then
      result = {type = 'remove', target=target_gear}
    end

    if state.selected_tool == 'belt' and not internals.selected_gear and target_gear then
      if target_gear.connection_type == 'belt' then
        result = {type = 'disconnect_belt', target = target_gear}
      elseif target_gear.child and target_gear.child.connection_type == 'belt' then
        result = {type = 'disconnect_belt', target = target_gear.child}
      end
    end

    --cancel action logic
    internals.selected_gear = nil
  end

  update_new_gear_position(state)

  return result
end


placement.mouse_moved = function(state,x,y)
  local target_gear = collisions.find_component_at(state,x,y)
  internals.hovered_gear = target_gear or nil
  if target_gear and internals.selected_gear and not (target_gear == internals.selected_gear) and target_gear.type ~= 'source' and target_gear.parent == nil then
    internals.target_gear = target_gear
  elseif target_gear == nil then
    internals.target_gear = nil
  end
  update_new_gear_position(state,x,y)
end

placement.wheel_moved = function (state,x,y)
  if y > 0 and internals.new_gear_size < constants.max_gear_size then
    internals.new_gear_size = internals.new_gear_size + 1
  elseif y < 0 and internals.new_gear_size > constants.min_gear_size then
    internals.new_gear_size = internals.new_gear_size - 1
  end
  update_new_gear_position(state)
end

placement.draw_belt_tool_overlay = function(state,mx,my)
  local texts = {}

  if internals.selected_gear and internals.hovered_gear then

    local color = placement_constants.build_collision_color
    if valid_belt_placement(state, internals.selected_gear,internals.hovered_gear) then
      color = placement_constants.build_active_color
      table.insert(texts,"Left Click to connect belt")
    end
    draw_fake_belt(internals.selected_gear,internals.hovered_gear,color)
    table.insert(texts, "Right Click to cancel belt placement")

  elseif internals.selected_gear and not internals.hovered_gear then


    local color = placement_constants.build_collision_color
    if valid_belt_preview_placement(state, internals.selected_gear, {x=mx,y=my}) then
      color = placement_constants.build_inactive_color
    end


    draw_fake_belt(internals.selected_gear,{position={x=mx,y=my}}, color)
    table.insert(texts,"Left click a target to join")

  elseif internals.hovered_gear and internals.hovered_gear.type ~= "sink_part" then
    if internals.hovered_gear.child == nil then
      love.graphics.setLineWidth(1)
      love.graphics.setColor(placement_constants.build_inactive_color)
      love.graphics.circle("line",
        internals.hovered_gear.position.x,
        internals.hovered_gear.position.y,
        constants.size_mod,
        30
      )
      table.insert(texts,"Left Click to start a new belt link")
    end
    --if internals.hovered_gear.child and internals.hovered_gear.connection_type == "belt" then
    --  draw_fake_belt(internals.hovered_gear,internals.hovered_gear.child,placement_constants.build_collision_color)
    --end
    --if internals.hovered_gear.parent and internals.hovered_gear.parent.connection_type == "belt" then
    --  draw_fake_belt(internals.hovered_gear.parent,internals.hovered_gear,placement_constants.build_collision_color)
    --end
    if internals.hovered_gear.parent or internals.hovered_gear.child then
      table.insert(texts,"Right Click to delete belts on this gear")
    end
  end

  return texts
end

placement.draw_gear_tool_overlay = function(state,mx,my)
  local texts = {}

  love.graphics.setLineWidth(1)
  if internals.selected_gear then
    table.insert(texts,"Mouse wheel to change size")
    if internals.new_gear_valid then
      love.graphics.setColor(placement_constants.build_active_color)
      table.insert(texts,"Left click to attach new gear")
    else
      love.graphics.setColor(placement_constants.build_collision_color)
      table.insert(texts,"Can't attach here")
    end
    local gx,gy = internals.new_gear_point.x, internals.new_gear_point.y
    love.graphics.circle("line",gx,gy,internals.new_gear_size*constants.size_mod,50)

    table.insert(texts, "")
    table.insert(texts, "Size: " .. internals.new_gear_size)
    table.insert(texts, "")
    table.insert(texts, "Parent size: " .. internals.selected_gear.size)
    table.insert(texts, "Parent speed: " .. internals.selected_gear.current_speed)
  elseif internals.hovered_gear and
    not (internals.hovered_gear.type == "sink_part" or
    internals.hovered_gear.type == "splitter_input") then
    --display a hover selection
    love.graphics.setColor(placement_constants.build_inactive_color)
    love.graphics.circle("line",
      internals.hovered_gear.position.x,
      internals.hovered_gear.position.y,
      (constants.size_mod * internals.hovered_gear.size) + constants.whole_depth,
      30
    )
    table.insert(texts,"Left click to start")
    table.insert(texts,"attaching new gears here")
  else
    table.insert(texts,"Mouse wheel to change size")
    if internals.new_gear_valid then
      love.graphics.setColor(placement_constants.build_active_color)
      table.insert(texts,"Left click to build a gear here")
    else
      love.graphics.setColor(placement_constants.build_collision_color)
      table.insert(texts,"Cannot build here")
    end
    local gx,gy = internals.new_gear_point.x, internals.new_gear_point.y
    love.graphics.circle("line",gx,gy,(internals.new_gear_size*constants.size_mod),50)

    table.insert(texts, "")
    table.insert(texts, "Size: " .. internals.new_gear_size)
  end

  return texts
end

placement.draw_splitter_tool_overlay = function(state,mx,my)
  local texts = {}


  if placement.valid_splitter_placement(state,mx, my) then
    love.graphics.setColor(placement_constants.build_active_color)
    table.insert(texts,"Left click to build a splitter here")
  else
    love.graphics.setColor(placement_constants.build_collision_color)
    table.insert(texts,"Cannot build here")
  end
  table.insert(texts,"Right Click to remove splitters")

  local rect = placement.get_splitter_preview_rect(mx, my)
  love.graphics.rectangle("line",rect[1], rect[2], rect[3], rect[4])

  return texts
end

placement.draw_tooltip = function(mx,my,texts)
  local left_top = {
    x = mx + 30,
    y = my + 30
  }
  local text_objs = {}
  local line_height = 0
  local max_length = 0
  for _, text in pairs(texts) do
    local obj = love.graphics.newText(constants.fonts['medium'],text)
    if obj:getWidth() > max_length then
      max_length = obj:getWidth()
    end
    if obj:getHeight() > line_height then
      line_height = obj:getHeight()
    end

    table.insert(text_objs,obj)
  end

  love.graphics.setColor({255,255,255})
  love.graphics.rectangle("fill",left_top.x,left_top.y,max_length+10,(line_height*#texts)+10)
  love.graphics.setColor(rgb_255_to_1({29,117,189}))
  for num, obj in pairs(text_objs) do
    love.graphics.draw(obj,left_top.x + 5, left_top.y + 5 + (line_height*(num-1)))
  end
end

placement.draw = function(state,mx,my,other_texts)
  local texts = {}

  local b = simulation.get_bounding_box(state)
  if collisions.point_inside_boundary(mx,my,b.x,b.y,b.width,b.height) then

    if state.selected_tool == "gear" then
      texts = placement.draw_gear_tool_overlay(state,mx,my)
    elseif state.selected_tool == "belt" then
      texts = placement.draw_belt_tool_overlay(state,mx,my)
    elseif state.selected_tool == "splitter" then
      texts = placement.draw_splitter_tool_overlay(state,mx,my)
    end

    if internals.hovered_gear then
      table.insert(texts, "")
      table.insert(texts, "Gear size: " .. internals.hovered_gear.size)
      table.insert(texts, "Gear speed: " .. internals.hovered_gear.current_speed)
    end

  end

  local use_texts = texts
  if #other_texts > 0 then
    use_texts = other_texts
  end

  if #use_texts > 0 then
    placement.draw_tooltip(mx,my,use_texts)
  end
end


return placement