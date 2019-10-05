local simulation = {}

simulation.create_state = function()
  return
  {
    sources = {},
    sinks = {},
    all_components = {},
    money = 0,
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

simulation.add_sink_part = function(sink, name, size, speed_min, speed_max, position)
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


































































