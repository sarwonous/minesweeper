SMM = require "libs.manager".newManager()

function love.load()
    love.window.setTitle("Sugasweeper")
    SMM.setPath('scenes')
    SMM.add("game")
end

function love.update(dt)
    SMM.update(dt)
end

function love.draw()
    SMM.draw()
end
