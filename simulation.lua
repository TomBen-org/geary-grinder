local simulation = {}

simulation.create_state = function()
  return
  {
    sources = {},
    sinks = {},
    splitters = {},
    all_components = {},
    money = 0,
    areas_available = 1,
    selected_tool = "gear",
  }
end

simulation.add_source = function(state, name, size, speed, position)
  local new_source =
  {
    type = "source",
    name = name,
    size = size,
    current_speed = speed,
    position = position,
    child = nil,
  }

  table.insert(state.sources, new_source)
  table.insert(state.all_components, new_source)

  return new_source
end

simulation.update_source = function(source)
  assert(source.type == "source")

  if source.child then
    simulation.update_recursive(source.child, source.size, source.current_speed)
  end
end

simulation.add_sink = function(state, name, position, money_per_tick)
  local new_sink =
  {
    type = "sink",
    name = name,
    position = position,
    money_per_tick = money_per_tick,
    components = {},
    satisfied = false,
  }

  table.insert(state.sinks, new_sink)

  return new_sink
end

simulation.update_sink = function(state, sink)
  assert(sink.type == "sink")

  sink.satisfied = true
  for _, sink_part in pairs(sink.components) do
    if not sink_part.satisfied then
      sink.satisfied = false
      break
    end
  end

  if sink.satisfied then
    state.money = state.money + sink.money_per_tick
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
    parent = nil,
    satisfied = false,
    current_speed = 0,
  }

  table.insert(sink.components, new_sink_component)
  table.insert(state.all_components, new_sink_component)

  return new_sink_component
end

simulation.update_sink_part = function(sink_part, parent_size, parent_speed)
  assert(sink_part.type == "sink_part")

  sink_part.current_speed = -(parent_speed * (parent_size / sink_part.size))
  sink_part.satisfied = sink_part.current_speed >= sink_part.speed_min and sink_part.current_speed <= sink_part.speed_max
end

simulation.add_gear = function(state, size, position)
  local new_gear =
  {
    type = "gear",
    size = size,
    position = position,
    parent = nil,
    child = nil,
    current_speed = 0,
  }

  table.insert(state.all_components, new_gear)

  return new_gear
end

simulation.update_gear = function(gear, parent_size, parent_speed)
  assert(gear.type == "gear")

  gear.current_speed = -(parent_speed * (parent_size / gear.size))

  if gear.child then
    simulation.update_recursive(gear.child, gear.size, gear.current_speed)
  end
end

simulation.add_splitter = function(state, position)
  local splitter_input =
  {
    type = "splitter_input",
    size = 1,
    position = {x = position.x, y = position.y - 40},
    parent = nil,
    outputs = {},
    current_speed = 0,
  }
  table.insert(state.all_components, splitter_input)

  local output_1 = simulation.add_gear(state, 1, {x = position.x - 40, y = position.y + 30})
  local output_2 = simulation.add_gear(state, 1, {x = position.x + 40, y = position.y + 30})
  table.insert(splitter_input.outputs, output_1)
  table.insert(splitter_input.outputs, output_2)
  output_1.parent = splitter_input
  output_2.parent = splitter_input

  local new_splitter =
  {
    type = "splitter",
    position = position,
    input = splitter_input,
  }

  table.insert(state.splitters, new_splitter)

  return new_splitter
end

simulation.update_splitter_input = function(splitter_input, parent_size, parent_speed)
  assert(splitter_input.type == "splitter_input")

  splitter_input.current_speed = -(parent_speed * (parent_size / splitter_input.size))

  for _, child in pairs(splitter_input.outputs) do
    simulation.update_recursive(child, splitter_input.size, -splitter_input.current_speed / 2)
  end
end

simulation.can_connect = function (parent, child)
  return parent.type ~= "sink" and child.type ~= "source" and parent.child == nil and child.parent == nil
end

simulation.connect = function(parent, child)
  assert(simulation.can_connect(parent, child))
  parent.child = child
  child.parent = parent
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
  for _, source in pairs(state.sources) do
    simulation.update_recursive(source, nil, nil)
  end

  for _, sink in pairs(state.sinks) do
    simulation.update_sink(state, sink)
  end
end

return simulation


































































