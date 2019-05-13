require "board"
require "debugger"
require "func"
require "menu"
require "tile"
Audio = require("audio")

--Global constants
SAVEFILE = "save"
VERSION = "0.2a"

function love.load()
    --Global variables
    --Default saveData which should be overwritten (only assume up to date at time of save/load!!)
    saveData = {
        version = VERSION,
        endless = {
            collection = "----------------------------------------------------------------------------------------------------",
            gemColour = -1,
            gemsMatched = 0,
            gemType = -1,
            playtime = 0,
            score = 0
        },
        setting = {
            musicVolume = 1,
            showClock = false,
            showParticles = true,
            soundVolume = 1
        },
        stats = {
            highestCascade = 0,
            explosionMade = 0,
            laserMade = 0,
            obliterations = 0,
            removerMade = 0
        }
    }
    readData()

    --Check save version
    if (saveData.version ~= VERSION) then
        error("Save version does not match game version!")
    end

    --Set the seed for RNG :D
    love.math.setRandomSeed(love.timer.getTime())

    --Load all assets required into RAM
    require("load")()
    addDebug("X")
    addDebug("Y")
    addDebug("sounds")

    --Init the Audio object
    Audio:init()

    --Screen points to lua file to 'run'
    screen = require "game/endless"
    screen:load()
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
    Audio:update()
    screen:update(dt)
    updateDebug(dt)
    musicVol = saveData.setting.musicVolume
    soundVol = saveData.setting.soundVolume
    sounds = #Audio.fxSources
end

function love.draw()
    screen:draw()
    drawDebug(dt)
end

--DATA MANAGEMENT
function writeData()
    local data = ""
    --Concatenate values
    for k, v in pairs(saveData) do
        if (type(v) == "table") then
            for K, V in pairs(v) do
                data = data..k.."."..K..":"..tostring(V).."\n"
            end
        else
            data = data..k..":"..tostring(v).."\n"
        end
    end
    love.filesystem.write(SAVEFILE,data)
end

function readData()
    --Check if exists
    if (love.filesystem.getInfo(SAVEFILE) ~= nil) then
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
    screen:touchmoved(1,x,y)
    X,Y = x,y
end