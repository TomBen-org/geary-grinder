local constants = require('constants')
local level_renderer = {}

local level_constants = {
  colors = {
    ['blue-paper'] = {0.114,0.459,0.741},
    ['white-marker'] = {0.988,0.969,0.953},
    ['grid'] = {0.149,0.561,0.835},
  }
}

local internals = {
  level_bottom = nil,
  level_middle = nil,
  level_width = 0,
  level_height = 0,
}

level_renderer.load = function()
  internals.level_width, internals.level_height = constants.screen_w-constants.left_bar-constants.right_bar,constants.area_size
  internals.level_bottom = love.graphics.newCanvas(internals.level_middle, internals.level_height)
  internals.level_middle = love.graphics.newCanvas(internals.level_middle, internals.level_height)
  love.graphics.setCanvas(internals.level_bottom)
  love.graphics.setColor(level_constants.colors['blue-paper'])
  love.graphics.rectangle("fill",0,0,internals.level_middle, internals.level_height)
end

level_renderer.draw = function()

end

return level_renderer