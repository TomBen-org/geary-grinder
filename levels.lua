local simulation = require('simulation')
local constants = require('constants')

local levels = {}

local left = constants.left_bar + 200
local right = constants.screen_w - constants.right_bar - 200

levels[1] = function(state)
  local y = constants.screen_h - state.areas_available * constants.area_size + constants.area_size/2

  local source = simulation.add_source(state, "basic_source", 6, 5, {x = left, y = y})
  local sink = simulation.add_sink(state, "basic_sink", {x = right-50, y = y-50}, 1/60)
  simulation.add_sink_part(state, sink, "basic_sink_part_1", 3, 9, 10,{x = right, y = y})

  state.next_price = 10
  simulation.add_obstacle(state,{x=500,y=350},40,200,1)

end

levels[2] = function(state)
  local y = constants.screen_h - state.areas_available * constants.area_size + constants.area_size/2

  simulation.add_source(state, "basic_source", 6, 5, {x = left, y = y})
  local sink = simulation.add_sink(state, "basic_sink", {x = right - 50, y = y}, 5/60)
  simulation.add_sink_part(state, sink, "basic_sink_part_1", 2, 2, 10,{x = sink.position.x - 45, y = sink.position.y + 45})
  simulation.add_sink_part(state, sink, "basic_sink_part_1", 2, 10, 20,{x = sink.position.x + 45, y = sink.position.y + 45})

  state.next_price = 400
end

levels[3] = function(state)
  local y = constants.screen_h - state.areas_available * constants.area_size + constants.area_size/2

  local sink = simulation.add_sink(state, "basic_sink", {x = right - 50, y = y}, 5/60)
  simulation.add_sink_part(state, sink, "basic_sink_part_1", 2, 2, 10,{x = sink.position.x - 45, y = sink.position.y + 45})
  simulation.add_sink_part(state, sink, "basic_sink_part_1", 2, 10, 20,{x = sink.position.x + 45, y = sink.position.y + 45})

  state.next_price = 600
end

return levels