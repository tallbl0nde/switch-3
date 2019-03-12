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
    Board1:new(500,20,8,680)

    font14 = love.graphics.newFont(14)
    font25 = love.graphics.newFont("resources/font/Bebas.ttf",25)
end

function love.update(dt)
    Board1:update(dt)
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

--SWITCH CONTROLS
function love.touchpressed(id,x,y)
    Board1:pressed(id,x,y)
end

function love.touchreleased(id,x,y)
    Board1:released(id,x,y)
end

--PC CONTROLS
function love.mousepressed(x,y)
    Board1:pressed(1,x,y)
end

function love.mousereleased(x,y)
    Board1:released(1,x,y)
end