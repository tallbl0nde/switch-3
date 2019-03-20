local files = love.filesystem.getDirectoryItems("resources/img/tile")
local step = 1

local function load()
    --Background
    background = love.graphics.newImage("resources/img/bg/background.jpg")

    --Font (image)
    for i=0,9 do
        _G["VGERBold_"..i] = love.graphics.newImage("resources/img/font/VGERBold/"..i..".png")
    end

    --Tiles
    while not (step > #files) do
        local current = string.match(files[step],"(.+)%.")
        _G[current] = love.graphics.newImage("resources/img/tile/"..files[step])
        step = step + 1
    end

    --Ui
    ui_score = love.graphics.newImage("resources/img/ui/ui_score.png")
end

return load