local constants = require('constants')

local simulation = {}

simulation.create_state = function()
  return
  {
    sources = {},
    sinks = {},
    splitters = {},
    obstacles = {},
    all_components = {},
    money = 0,
    last_income = 0,
    areas_available = 1,
    next_price = 0,
    selected_tool = "gear",
  }
end

simulation.add_obstacle = function(state, position, width, height, depth)
  local new_obstacle =
  {
    type = "obstacle",
    position = position,
    depth = depth,
    casing = {
      height = height or 80,
      width = width or 130,
    },
  }

  table.insert(state.obstacles, new_obstacle)
end

simulation.add_source = function(state, name, size, speed, position)
  local new_source =
  {
    type = "source",
    name = name,
    size = size,
    current_speed = speed,
    position = position,
    rotation = 0,
    child = nil,
  }

  table.insert(state.sources, new_source)
  table.insert(state.all_components, new_source)

  return new_source
end

simulation.update_source = function(source)
  assert(source.type == "source")
  source.rotation = source.rotation + (source.current_speed*math.pi/constants.speed_mod)
  if source.child then
    simulation.update_recursive(source.child, source.size, source.current_speed)
  end
end

simulation.add_sink = function(state, name, position, money_per_tick, case_height, case_width)
  local new_sink =
  {
    type = "sink",
    name = name,
    position = position,
    money_per_tick = money_per_tick,
    casing = {
      height = case_height or 100,
      width = case_width or 200,
    },
    components = {},
    satisfied = false,
  }

  table.insert(state.sinks, new_sink)

  return new_sink
end

simulation.update_sink = function(state, sink)
  assert(sink.type == "sink")

  local percentage_satisfied = 1

  for _, sink_part in pairs(sink.components) do
    local abs_speed = math.abs(sink_part.current_speed)

    local this_percentage = 0
    if abs_speed >= sink_part.speed_min and abs_speed <= sink_part.speed_max then
      this_percentage = math.min(abs_speed, sink_part.speed_max) / sink_part.speed_max
    end

    percentage_satisfied = math.min(this_percentage, percentage_satisfied)
  end

  if percentage_satisfied > 0 then
    state.money = state.money + percentage_satisfied * sink.money_per_tick
  end
end

simulation.add_sink_part = function(state, sink, name, size, speed_min, speed_max, position)
  assert(sink.type == "sink")

  local new_sink_component =
  {
    type = "sink_part",
    name = name,
    size = size,
    speed_min = speed_min,
    speed_max = speed_max,
    position = position,
    rotation = 0,
    parent = nil,
    connection_type = 'none',
    current_speed = 0,
  }

  table.insert(sink.components, new_sink_component)
  table.insert(state.all_components, new_sink_component)

  return new_sink_component
end

simulation.update_sink_part = function(sink_part, parent_size, parent_speed)
  assert(sink_part.type == "sink_part")
  sink_part.current_speed = -parent_speed * (parent_size / sink_part.size)
  if sink_part.connection_type == 'belt' then
    sink_part.current_speed = parent_speed
  end

  sink_part.rotation = sink_part.rotation + (sink_part.current_speed*math.pi/constants.speed_mod)
end

simulation.add_gear = function(state, size, position)
  local new_gear =
  {
    type = "gear",
    size = size,
    position = position,
    parent = nil,
    child = nil,
    connection_type = 'none',
    current_speed = 0,
    rotation = 0,
  }

  table.insert(state.all_components, new_gear)

  return new_gear
end

simulation.update_gear = function(gear, parent_size, parent_speed)
  assert(gear.type == "gear")

  gear.current_speed = -parent_speed * (parent_size / gear.size)
  if gear.connection_type == 'belt' then
    gear.current_speed = parent_speed
  end

  gear.rotation = gear.rotation + (gear.current_speed*math.pi/constants.speed_mod)
  if gear.child then
    simulation.update_recursive(gear.child, gear.size, gear.current_speed)
  end
end

simulation.add_splitter = function(state, position, case_height, case_width)
  local splitter_input =
  {
    type = "splitter_input",
    size = 2,
    position = {x = position.x, y = position.y - 40},
    parent = nil,
    connection_type = 'none',
    outputs = {},
    current_speed = 0,
    rotation = 0,
    splitter = nil,
  }
  table.insert(state.all_components, splitter_input)

  local output_1 = simulation.add_gear(state, 2, {x = position.x - 45, y = position.y + 40})
  local output_2 = simulation.add_gear(state, 2, {x = position.x + 45, y = position.y + 40})
  table.insert(splitter_input.outputs, output_1)
  table.insert(splitter_input.outputs, output_2)
  output_1.parent = splitter_input
  output_2.parent = splitter_input
  output_1.connection_type = "splitter"
  output_2.connection_type = "splitter"

  local new_splitter =
  {
    type = "splitter",
    position = position,
    casing = {
      height = case_height or 80,
      width = case_width or 130,
    },
    input = splitter_input,
  }
  table.insert(state.splitters, new_splitter)
  splitter_input.splitter = new_splitter

  return new_splitter
end

simulation.update_splitter_input = function(splitter_input, parent_size, parent_speed)
  assert(splitter_input.type == "splitter_input")

  splitter_input.current_speed = -parent_speed * (parent_size / splitter_input.size)
  if splitter_input.connection_type == 'belt' then
    splitter_input.current_speed = parent_speed
  end

  splitter_input.rotation = splitter_input.rotation + (splitter_input.current_speed*math.pi/constants.speed_mod)

  for _, child in pairs(splitter_input.outputs) do
    simulation.update_recursive(child, splitter_input.size, -splitter_input.current_speed / 2)
  end
end

simulation.can_connect = function (parent, child)
  return parent.type ~= "sink" and child.type ~= "source" and parent.child == nil and child.parent == nil
end

simulation.connect = function(parent, child, type)
  assert(simulation.can_connect(parent, child))
  parent.child = child
  child.parent = parent
  child.rotation = parent.rotation + math.pi*2/constants.teeth_per_size
  child.connection_type = type
end

simulation.remove = function(state, to_remove, _from_splitter_input)
  if to_remove.connection_type == 'splitter' and not _from_splitter_input then
    assert(to_remove.parent and to_remove.parent.type == "splitter_input")
    simulation.remove(state, to_remove.parent)
  end

  if to_remove.type == 'splitter_input' then
    simulation.remove(state, to_remove.outputs[1], true)
    simulation.remove(state, to_remove.outputs[2], true)

    for index, item in pairs(state.splitters) do
      if item == to_remove.splitter then
        table.remove(state.splitters, index)
        break
      end
    end
  end

  if to_remove.child then
    to_remove.child.parent = nil
    to_remove.child.connection_type = 'none'
  end

  if to_remove.parent and not _from_splitter_input then
    to_remove.parent.child = nil
  end

  for index, item in pairs(state.all_components) do
    if item == to_remove then
      table.remove(state.all_components, index)
      break
    end
  end
end

simulation.disconnect_belt = function(to_disconnect)
  if to_disconnect.connection_type ~= 'belt' then
    assert(to_disconnect.child.connection_type == 'belt')
    to_disconnect = to_disconnect.child
  end

  to_disconnect.connection_type = 'none'
  to_disconnect.parent.child = nil
  to_disconnect.parent = nil
end

simulation.update_recursive = function(component, parent_size, parent_speed)
  if component.type == "source" then
    simulation.update_source(component)
  elseif component.type == "sink_part" then
    simulation.update_sink_part(component, parent_size, parent_speed)
  elseif component.type == "gear" then
    simulation.update_gear(component, parent_size, parent_speed)
  elseif component.type == "splitter_input" then
    simulation.update_splitter_input(component, parent_size, parent_speed)
  else
    error("bad component type: " .. component.type)
  end
end

simulation.update = function(state)
  local money_before = state.money

  for _, component in pairs(state.all_components) do
    if component.current_speed and component.type ~= 'source' then
      component.current_speed = 0
    end
  end

  for _, source in pairs(state.sources) do
    simulation.update_recursive(source, nil, nil)
  end

  for _, sink in pairs(state.sinks) do
    simulation.update_sink(state, sink)
  end

  state.last_income = state.money - money_before
end

return simulation


































































