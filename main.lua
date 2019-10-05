local placement = require('gear_placement')
require('registry')
local simulation = require('simulation')


local test_gear

local state

function love.load()
  state = simulation.create_state()

  local source = simulation.add_source(state, "basic_source", 2, 5, {x = 0, y = 50})
  local sink = simulation.add_sink(state, "basic_sink", {x = 50, y = 50}, 1)
  simulation.add_sink_part(sink, "basic_sink_part_1", 1, 4,6, {x=50,y=55})

  test_gear = simulation.add_gear(state, 1, {x=25, y=50})
  simulation.connect(source, test_gear)
  simulation.connect(test_gear, sink.components[1])

  local screen_width, screen_height = love.graphics.getDimensions()
  for _=1, 100 do
    table.insert(circles,{shape='circle',x=math.random()*screen_width,y=math.random()*screen_height,radius=math.random(1,10)})
  end

  placement.load()
end

function love.draw()
  for _, circle in pairs(circles) do
    love.graphics.setColor(circle_constants.color)
    love.graphics.circle("fill",circle.x,circle.y,circle.radius,10)
  end

  placement.draw(circles)
end

function love.resize()
  local screen_width, screen_height = love.graphics.getDimensions()
  circles = {}
  for _=1, 100 do
    table.insert(circles,{x=math.random()*screen_width,y=math.random()*screen_height})
  end
end

function love.keypressed()

end

function love.mousemoved(x,y)
  placement.mouse_moved(x,y)
end

function love.wheelmoved(x,y)
  placement.wheel_moved(x,y)
end

function love.mousepressed(x,y,button)
  placement.mouse_pressed(x,y)
end

function love.quit()

end

function love.update(dt)
  simulation.update(state)

  --print(test_gear.current_speed)
  --print(state.sinks[1].components[1].current_speed)
end
