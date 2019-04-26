require "board"
require "debugger"
require "func"
require "tile"

--Global constants
SAVEFILE = "save"

function love.load()
    --Global variables
    --Holds saveData (most updates in realtime)
    saveData = {}
    readData()

    --Screen points to lua file to 'run'
    screen = require "game/endless"

    --Set the seed for RNG :D
    love.math.setRandomSeed(love.timer.getTime())

    --Load all assets required into RAM
    require("load")()
    screen:load()
    addDebug("X")
    addDebug("Y")
end

function love.update(dt)
    --Avoid first weird dt
    if (dt > 20) then
        return
    end
    --Update clock (and animate)
    if (os.date("%S")%2 == 0) then
        systemTime = os.date("%H")..":"..os.date("%M")
    else
        systemTime = os.date("%H").." "..os.date("%M")
    end
    screen:update(dt)
    updateDebug(dt)
end

function love.draw()
    screen:draw()
    drawDebug(dt)
end

--DATA MANAGEMENT
function writeData(init)
    local data = ""
    --Initalise with defaults if necessary
    if (init) then
        data = data.."endless.gemColour:-1".."\n"
        data = data.."endless.gemType:-1".."\n"
        data = data.."endless.collection:----------------------------------------------------------------------------------------------------".."\n"
        data = data.."endless.score:0".."\n"
        data = data.."playtime:0".."\n"
        data = data.."setting.musicVolume:1".."\n"
        data = data.."setting.showClock:false".."\n"
        data = data.."setting.showParticles:true".."\n"
        data = data.."setting.soundVolume:1".."\n"
    else
        --Otherwise save normally
        for k, v in pairs(saveData) do
            if (type(v) == "table") then
                for K, V in pairs(v) do
                    data = data..k.."."..K..":"..tostring(V).."\n"
                end
            else
                data = data..k..":"..tostring(v).."\n"
            end
        end
    end
    love.filesystem.write(SAVEFILE,data)
end

function readData()
    --Check if exists and create if necessary
    if (love.filesystem.getInfo(SAVEFILE) == nil) then
        writeData(true)
    end
    --Read file into table
    local dir = love.filesystem.getSaveDirectory().."/"
    for line in io.lines(dir..SAVEFILE) do
        local k, v = string.match(line, "(.*):(.*)")
        --Change to correct type
        if (tonumber(v) ~= nil) then
            v = tonumber(v)
        elseif (v == "true") then
            v = true
        elseif (v == "false") then
            v = false
        end
        --Create another layer of tables if necessary
        if (string.match(k, "(.*)%.(.*)")) then
            local t, k = string.match(k, "(.*)%.(.*)")
            if (saveData[t] == nil) then
                saveData[t] = {}
            end
            saveData[t][k] = v
        else
            saveData[k] = v
        end
    end
end

--SWITCH CONTROLS
function love.gamepadpressed(joystick, button)
    if (button == "minus") then
        toggleDebug()
    elseif (button == "plus") then
        love.event.quit()
    end
    screen:gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
    screen:gamepadreleased(joystick, button)
end

function love.touchpressed(id,x,y)
    screen:touchpressed(id,x,y)
end

function love.touchmoved(id,x,y)
    screen:touchmoved(id,x,y)
end

function love.touchreleased(id,x,y)
    screen:touchreleased(id,x,y)
end

--PC CONTROLS
function love.keypressed(key)
    if (key == "d") then
        key = "dpright"
    elseif (key == "s") then
        key = "dpdown"
    elseif (key == "a") then
        key = "dpleft"
    elseif (key == "w") then
        key = "dpup"
    elseif (key == "l") then
        key = "a"
    end
    screen:gamepadpressed(nil,key)
end

function love.keyreleased(key)
    if (key == "d") then
        key = "dpright"
    elseif (key == "s") then
        key = "dpdown"
    elseif (key == "a") then
        key = "dpleft"
    elseif (key == "w") then
        key = "dpup"
    elseif (key == "l") then
        key = "a"
    elseif (key == "k") then
        key = "b"
    end
    screen:gamepadreleased(nil,key)
end

function love.mousepressed(x,y)
    screen:touchpressed(1,x,y)
end

function love.mousereleased(x,y)
    screen:touchreleased(1,x,y)
end

function love.mousemoved(x,y)
    X,Y = x,y
    screen:touchmoved(1,x,y)
end