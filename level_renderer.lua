local constants = require('constants')
local level_renderer = {}

level_renderer.internals = {
  gfx = {}
}

level_renderer.load = function()
  level_renderer.internals.gfx.bottom = love.graphics.newImage('/gfx/level-bottom.png')
  level_renderer.internals.gfx.middle = love.graphics.newImage('/gfx/level-middle.png')
end

level_renderer.draw = function(level_number)
  local first_level_y = 403
  love.graphics.setColor(255,255,255)
  love.graphics.draw(level_renderer.internals.gfx.bottom,constants.left_bar,first_level_y)

  if level_number > 1 then
    for l = 1, level_number do
      love.graphics.draw(level_renderer.internals.gfx.middle,constants.left_bar,(l*-300) + first_level_y)
    end
  end
end

return level_renderer