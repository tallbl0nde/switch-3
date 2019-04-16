--Constants (folder locations)
local FONTPATH = "resources/font/"
local IMAGEPATH = "resources/img/"

local function load()
    --Fonts
    font14 = love.graphics.newFont(FONTPATH.."Dosis-Medium.ttf",14)
    font23 = love.graphics.newFont(FONTPATH.."Dosis-Medium.ttf",23)
    font30 = love.graphics.newFont(FONTPATH.."Dosis-Medium.ttf",30)
    font35 = love.graphics.newFont(FONTPATH.."Dosis-Bold.ttf",35)
    --Images
    local dirs = love.filesystem.getDirectoryItems(IMAGEPATH)
    for i=1,#dirs do
        local files = love.filesystem.getDirectoryItems(IMAGEPATH..dirs[i])
        for j=1,#files do
            _G[dirs[i].."_"..string.match(files[j],"(.+)%.")] = love.graphics.newImage(IMAGEPATH..dirs[i].."/"..files[j])
        end
    end
end

return load