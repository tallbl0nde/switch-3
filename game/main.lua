require "debugger"
require "func"
require "tile"
require "game"
require "board"

function love.load()
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()
    screen = 0
    while (screen == 0) do
        require("load")()
    end
    Board1 = Board
    Board1:new(290,10,8,700)
end

function love.update(dt)
    updateDebug(dt)
end

function love.draw()
    game_endless()
    drawDebug()
end

function love.gamepadpressed(joystick, button)
    if (button == "minus") then
        toggleDebug()
    end
    if (button == "plus") then
        love.event.quit()
    end
end

function love.keypressed(k)
    Board1:new(290,10,8,700)
end

function love.mousepressed(x,y)
    Board1:pressed(x,y)
end

function love.mousereleased(x,y)
    Board1:released(x,y)
end