local simulation = require('simulation')

local puzzles = {}

local left = 100
local right = 900


puzzles[1] = function(state)
  local y = 700

  local source = simulation.add_source(state, "basic_source", 2, 5, {x = left, y = y})
  local sink = simulation.add_sink(state, "basic_sink", {x = 50, y = 50}, 1)
  simulation.add_sink_part(state, sink, "basic_sink_part_1", 1, 9,10, {x = right, y = y})

  local gear = simulation.add_gear(state, 1, { x=left*2, y=y})
  simulation.connect(source, gear)
  simulation.connect(gear, sink.components[1])
end

puzzles[2] = function(state)
  local y = 500

  local source = simulation.add_source(state, "l2_source", 2, 5, {x = left, y = y})
  local sink = simulation.add_sink(state, "2_part_sink", {x = 50, y = 50}, 1)
  simulation.add_sink_part(state, sink, "part_1", 1, 4,6, {x = right - 60, y = y})
  simulation.add_sink_part(state, sink, "part_2", 1, 4,6, {x = right, y = y})

  local splitter = simulation.add_splitter(state, { x=300, y=y})

  simulation.connect(source, splitter.input)
  simulation.connect(splitter.input.outputs[1], sink.components[1])
  simulation.connect(splitter.input.outputs[2], sink.components[2])

end

return puzzles