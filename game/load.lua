local RESOURCES = "resources/img/"
local dirs = love.filesystem.getDirectoryItems(RESOURCES)

local function load()
    for i=1,#dirs do
        local files = love.filesystem.getDirectoryItems(RESOURCES..dirs[i])
        for j=1,#files do
            print(dirs[i].."/"..files[j])
            _G[dirs[i].."_"..string.match(files[j],"(.+)%.")] = love.graphics.newImage(RESOURCES..dirs[i].."/"..files[j])
        end
    end
end

return load