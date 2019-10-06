local simulation = require('simulation')
local constants = require('constants')


local left = constants.left_bar + 200
local right = constants.screen_w - constants.right_bar - 200

local levels =
{
  --function(state)
  --  local top = constants.screen_h - state.areas_available * constants.area_size
  --  local y = top + constants.area_size/2
  --
  --
  --  simulation.add_obstacle(state,{x=500,y=top + 20},40,400,1)
  --  simulation.add_obstacle(state,{x=700,y=top + 260},40,220,1)
  --
  --  simulation.add_obstacle(state,{x=500,y=top + 500},300,40,1)
  --
  --
  --
  --  simulation.add_source(state, "basic_source", 6, 5, {x = left, y = y- 200})
  --
  --  local sink = simulation.add_sink(state, "basic_sink", {x = right - 50, y = y - 200}, 5/60)
  --  simulation.add_sink_part(state, sink, "basic_sink_part_1", 2, 6, 7.5,{x = sink.position.x - 45, y = sink.position.y + 45})
  --  simulation.add_sink_part(state, sink, "basic_sink_part_1", 2, 6, 10,{x = sink.position.x + 45, y = sink.position.y + 45})
  --end,

  function(state)
    local y = constants.screen_h - state.areas_available * constants.area_size + constants.area_size/2

    simulation.add_source(state, "basic_source", 6, 5, {x = left, y = y})
    local sink = simulation.add_sink(state, "basic_sink", {x = right-50, y = y-50}, 1/60, 100, 70)
    simulation.add_sink_part(state, sink, "basic_sink_part_1", 3, 10, 10,{x = sink.position.x, y = sink.position.y + 60})

    state.next_price = 10
  end,

  function(state)
    local y = constants.screen_h - state.areas_available * constants.area_size + constants.area_size/2

    simulation.add_source(state, "basic_source", 6, 5, {x = left, y = y})
    local sink = simulation.add_sink(state, "basic_sink", {x = right - 50, y = y}, 5/60)
    simulation.add_sink_part(state, sink, "basic_sink_part_1", 2, 2, 10,{x = sink.position.x - 45, y = sink.position.y + 45})
    simulation.add_sink_part(state, sink, "basic_sink_part_1", 2, 10, 20,{x = sink.position.x + 45, y = sink.position.y + 45})

    state.next_price = 400
  end,

  function(state)
    local y = constants.screen_h - state.areas_available * constants.area_size + constants.area_size/2

    local sink = simulation.add_sink(state, "basic_sink", {x = right - 50, y = y}, 5/60)
    simulation.add_sink_part(state, sink, "basic_sink_part_1", 2, 2, 10,{x = sink.position.x - 45, y = sink.position.y + 45})
    simulation.add_sink_part(state, sink, "basic_sink_part_1", 2, 10, 20,{x = sink.position.x + 45, y = sink.position.y + 45})

    state.next_price = 600
  end,
}


return levels