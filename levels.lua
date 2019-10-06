local simulation = require('simulation')
local constants = require('constants')

local levels = {}

local left = constants.left_bar + 100
local right = constants.screen_w - constants.right_bar - 100


levels[1] = function(state)
  local y = constants.screen_h - state.areas_available * constants.area_size + 100

  local source = simulation.add_source(state, "basic_source", 3, 5, {x = left, y = y})
  local sink = simulation.add_sink(state, "basic_sink", {x = 50, y = 50}, 1)
  simulation.add_sink_part(state, sink, "basic_sink_part_1", 1, 9, {x = right, y = y})

  local gear = simulation.add_gear(state, 2, { x=left*2, y=y})
  --simulation.connect(source, gear)
  --simulation.connect(gear, sink.components[1])
end

--puzzles[2] = function(state)
--  local y = 500
--
--  local source = simulation.add_source(state, "l2_source", 2, 5, {x = left, y = y})
--  local sink = simulation.add_sink(state, "2_part_sink", {x = 50, y = 50}, 1)
--  simulation.add_sink_part(state, sink, "part_1", 1, 4,6, {x = right - 60, y = y})
--  simulation.add_sink_part(state, sink, "part_2", 1, 4,6, {x = right, y = y})
--
--  local splitter = simulation.add_splitter(state, { x=300, y=y})
--
--  simulation.connect(source, splitter.input)
--  simulation.connect(splitter.input.outputs[1], sink.components[1])
--  simulation.connect(splitter.input.outputs[2], sink.components[2])
--
--end

return levels