local placement = require('gear_placement')
require('registry')

function love.load()
  local screen_width, screen_height = love.graphics.getDimensions()
  for _=1, 100 do
    table.insert(circles,{x=math.random()*screen_width,y=math.random()*screen_height})
  end

  placement.load()
end

function love.draw()
  for _, circle in pairs(circles) do
    love.graphics.setColor(circle_constants.color)
    love.graphics.circle("fill",circle.x,circle.y,circle_constants.radius,10)
  end

  placement.draw()
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

end
