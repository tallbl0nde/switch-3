local files = love.filesystem.getDirectoryItems("resources")
local step = 1

local function load()
    if (step > #files) then
        screen = 1
        return
    end
    local current = string.match(files[step],"(.+)%.")

    --Draw stuff
    love.graphics.setBackgroundColor(0.2,0.2,0.2)
    love.graphics.print("Loading: "..current.." ("..step.."/"..#files..")",0,height-50)
    love.graphics.rectangle("line",0,height-20,width,20)
    love.graphics.rectangle("fill",0,height-20,width*(step/#files),20)

    --Load into memory
    _G[current] = love.graphics.newImage("resources/"..files[step])
    step = step + 1
end

return load