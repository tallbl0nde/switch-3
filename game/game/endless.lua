local F = {}

--"Global" variables for this screen/file
--Board object
local Board1
--Menu status
local showMenu = false
--Which button is currently pressed (used for highlighting)
local isPressed = {
    backtogame = false,
    clock = false,
    help = false,
    hint = false,
    menu = false,
    particle = false,
    save = false,
    saveandquit = false
}
--Animation variables
local UIPosX = 245
local UIPosY = -300
local vx = 0
local textY = 0
local rec = {x = 0, y = 0, alpha = 0}
--Time until hint is ready
local hintCountdown = 10
--"Level" variables
local animProgress = 0
local progress = 0
local level = 0
--Function for mapping levels to scores
local function score(lvl)
    if (lvl > 101) then
        return (5000000 + (lvl-101)*250000)
    elseif (lvl == 101) then
        return 5000000
    else
        return 1000*round(math.pow((lvl-1),1.85))
    end
end

--Color 'map' for collection thing
local colorMap = {  {{0.91,0.56,0.20,1},{0.91,0.56,0.20,1},{0.91,0.56,0.20,1},{0.91,0.56,0.20,1},{0.91,0.56,0.20,1},{0.91,0.56,0.20,1},{0.91,0.56,0.20,1},{0.91,0.56,0.20,1},{0.91,0.56,0.20,1},{0.91,0.56,0.20,1}},
                    {{0.91,0.58,0.20,1},{0.97,0.77,0.12,1},{0.97,0.74,0.12,1},{0.97,0.77,0.12,1},{0.91,0.58,0.20,1},{0.91,0.58,0.20,1},{0.91,0.58,0.20,1},{0.91,0.58,0.20,1},{0.91,0.58,0.20,1},{0.91,0.58,0.20,1}},
                    {{0.97,0.77,0.12,1},{0.97,0.74,0.12,1},{0.87,0.69,0.12,1},{0.97,0.74,0.12,1},{0.97,0.77,0.12,1},{0.91,0.59,0.20,1},{0.91,0.59,0.20,1},{0.91,0.59,0.20,1},{0.91,0.59,0.20,1},{0.91,0.59,0.20,1}},
                    {{0.97,0.74,0.12,1},{0.87,0.69,0.12,1},{0.68,0.64,0.55,1},{0.68,0.64,0.55,1},{0.97,0.74,0.12,1},{0.92,0.61,0.19,1},{0.92,0.61,0.19,1},{0.68,0.64,0.55,1},{0.92,0.61,0.19,1},{0.92,0.61,0.19,1}},
                    {{0.97,0.77,0.12,1},{0.68,0.64,0.55,1},{0.62,0.58,0.47,1},{0.20,0.43,0.58,1},{0.62,0.58,0.47,1},{0.92,0.63,0.19,1},{0.68,0.64,0.55,1},{0.62,0.58,0.47,1},{0.47,0.45,0.40,1},{0.92,0.63,0.19,1}},
                    {{0.68,0.64,0.55,1},{0.62,0.58,0.47,1},{0.54,0.50,0.40,1},{0.50,0.46,0.38,1},{0.25,0.49,0.64,1},{0.62,0.58,0.47,1},{0.62,0.58,0.47,1},{0.68,0.64,0.55,1},{0.51,0.49,0.43,1},{0.47,0.45,0.40,1}},
                    {{0.62,0.58,0.47,1},{0.19,0.38,0.18,1},{0.62,0.58,0.47,1},{0.54,0.50,0.40,1},{0.20,0.43,0.58,1},{0.54,0.50,0.40,1},{0.62,0.58,0.47,1},{0.53,0.52,0.49,1},{0.51,0.49,0.43,1},{0.19,0.38,0.18,1}},
                    {{0.19,0.38,0.18,1},{0.18,0.35,0.16,1},{0.19,0.38,0.18,1},{0.68,0.64,0.55,1},{0.20,0.43,0.58,1},{0.23,0.45,0.60,1},{0.49,0.48,0.45,1},{0.49,0.48,0.45,1},{0.19,0.38,0.18,1},{0.18,0.35,0.16,1}},
                    {{0.18,0.35,0.16,1},{0.16,0.32,0.15,1},{0.18,0.35,0.16,1},{0.57,0.56,0.51,1},{0.57,0.56,0.51,1},{0.23,0.45,0.60,1},{0.19,0.42,0.56,1},{0.55,0.55,0.53,1},{0.18,0.35,0.16,1},{0.16,0.32,0.15,1}},
                    {{0.53,0.52,0.49,1},{0.27,0.21,0.08,1},{0.53,0.52,0.49,1},{0.53,0.52,0.49,1},{0.53,0.52,0.49,1},{0.48,0.47,0.46,1},{0.22,0.44,0.59,1},{0.53,0.52,0.49,1},{0.53,0.52,0.49,1},{0.27,0.21,0.08,1}}
}
--Variables storing canvas
local collectCanvas = love.graphics.newCanvas(150,150)
local gridCanvas = love.graphics.newCanvas(150,150)

--Local functions (not accessible outside file)
local save
local generateCollection

function F:load()
    --Init the board
    Board1 = Board
    Board1:new(500,20,8,680)
    Board1.hint.active = false
    Board1.score = saveData.endless.score
    Board1.showParticles = saveData.setting.showParticles
    --Load board if saved
    if (saveData.endless.gemColour ~= -1) then
        for i=1,#saveData.endless.gemColour do
            local c = saveData.endless.gemColour:sub(i,i)
            local t = saveData.endless.gemType:sub(i,i)
            --Get colours
            if (c == "r") then
                c = "red"
            elseif (c == "o") then
                c = "orange"
            elseif (c == "y") then
                c = "yellow"
            elseif (c == "g") then
                c = "green"
            elseif (c == "b") then
                c = "blue"
            elseif (c == "p") then
                c = "purple"
            elseif (c == "w") then
                c = "white"
            else
                c = nil
            end
            --Get types
            if (t == "v") then
                t = "vertical"
            elseif (t == "h") then
                t = "horizontal"
            elseif (t == "r") then
                t = "remover"
            elseif (t == "e") then
                t = "explosion"
            else
                t = nil
            end
            --Populate board with saved tiles
            Board1.tiles[math.ceil(i/Board1.grid_size)][((i-1)%Board1.grid_size)+1] = new_tile(c,t)
        end
    end

    --Determine 'level' (calculate from score)
    while (saveData.endless.score > score(level+1)) do
        level = level + 1
    end
    progress = (Board1.score-score(level))/(score(level+1)-score(level))
    animProgress = progress

    --Generate "collection" canvases
    love.graphics.setCanvas(gridCanvas)
    for x=1,10 do
        for y=1,10 do
            if ((x+y)%2 == 0) then
                love.graphics.setColor(0.04,0.04,0.04,1)
            else
                love.graphics.setColor(0.07,0.07,0.07,1)
            end
            love.graphics.rectangle("fill",(x-1)*15,(y-1)*15,15,15)
        end
    end
    love.graphics.setCanvas()
    generateCollection()
end

function F:update(dt)
    --Update board stuff
    Board1:update(dt)
    --Animate menu move in/out
    if (showMenu == "movein") then
        vx = vx + 20*dt
        Board1.x = Board1.x + vx*60*dt
        UIPosX = UIPosX - vx*60*dt
        if (Board1.x > 750) then
            UIPosY = UIPosY + (45-vx)*30*dt
        end
        if (UIPosY >= 360) then
            showMenu = true
            UIPosY = 360
        end
    elseif (showMenu == "moveout") then
        if (vx > 2) then
            vx = vx - 19*dt
        end
        Board1.x = Board1.x - vx*60*dt
        UIPosX = UIPosX + vx*60*dt
        UIPosY = UIPosY - (45-vx)*30*dt
        if (Board1.x <= 500) then
            Board1.x = 500
            UIPosX = 245
            UIPosY = -300
            vx = 0
            showMenu = false
        end
    --Reduce hint cooldown
    elseif (showMenu == false) then
        if (hintCountdown > 0) then
            hintCountdown = hintCountdown - dt
        else
            hintCountdown = 0
        end
    end

    --Update progress on level
    progress = (Board1.score-score(level))/(score(level+1)-score(level))
    if (progress > 1) then
        progress = 1
    end
    if (Board1.score >= score(level+1)) then
        level = level+1
        textY = -1
        --Add tile to collection
        if (level < 101) then
            local i = love.math.random(1,100)
            while (saveData.endless.collection:sub(i,i) == ".") do
                i = i - 1
                if (i < 1) then
                    i = 100
                end
            end
            saveData.endless.collection = saveData.endless.collection:sub(1, i-1) ..'.'.. saveData.endless.collection:sub(i+1)
            --Change animation variables
            rec.y = math.ceil(i/10)
            rec.x = i-(rec.y-1)*10
            rec.alpha = 1
            --Regenerate canvas
            generateCollection()
        end
    end

    --Animate progress bar
    --Increase progress on match
    if (animProgress < progress) then
        local add = (math.pi*(progress-animProgress)*dt)/1.5
        if (add < 0.0001) then
            animProgress = progress
        end
        animProgress = animProgress + add
        if (animProgress > progress) then
            animProgress = progress
        end
    --Decrease progress on level up
    elseif (animProgress > progress) then
        local sub = (math.pi*(animProgress-progress)*dt)/1.5
        if (sub < 0.0001) then
            animProgress = progress
        end
        animProgress = animProgress - sub
        if (animProgress < progress) then
            animProgress = progress
        end
    end

    --Animate level up text
    if (textY < 0) then
        textY = textY - 40*dt
        if (textY < -80) then
            textY = 0
        end
    end

    --Animate new tile in collection
    if (rec.alpha > 0) then
        rec.alpha = rec.alpha - dt*0.8
    end
end

function F:draw()
    --Background
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(bg_background,0,0,0,2/3,2/3)

    --Draw menu things
    if (showMenu ~= false) then
        love.graphics.push("all")
        love.graphics.translate(640,UIPosY)
        love.graphics.setColor(1,1,1,1)

        if (isPressed.backtogame) then
            centeredImage(ui_game_menu_backtogame,0,0)
        elseif (isPressed.help) then
            centeredImage(ui_game_menu_help,0,0)
        elseif (isPressed.save) then
            centeredImage(ui_game_menu_save,0,0)
        elseif (isPressed.saveandquit) then
            centeredImage(ui_game_menu_saveandquit,0,0)
        else
            centeredImage(ui_game_menu,0,0)
        end
        if (saveData.setting.showParticles) then
            if (isPressed.particle) then
                centeredImage(ui_toggle_on_touch,-5,-69,0.7)
            else
                centeredImage(ui_toggle_on,-5,-69,0.7)
            end
        else
            if (isPressed.particle) then
                centeredImage(ui_toggle_off_touch,-5,-69,0.7)
            else
                centeredImage(ui_toggle_off,-5,-69,0.7)
            end
        end
        if (saveData.setting.showClock) then
            if (isPressed.clock) then
                centeredImage(ui_toggle_on_touch,-5,-30,0.7)
            else
                centeredImage(ui_toggle_on,-5,-30,0.7)
            end
        else
            if (isPressed.clock) then
                centeredImage(ui_toggle_off_touch,-5,-30,0.7)
            else
                centeredImage(ui_toggle_off,-5,-30,0.7)
            end
        end

        love.graphics.pop()
    end

    --Draw board/side things
    if (showMenu ~= true) then
        Board1:draw()

        love.graphics.push("all")
        love.graphics.translate(UIPosX,0)
        love.graphics.setColor(1,1,1,1)

        --Top 'cluster'
        love.graphics.rectangle("fill",-125,97,250*animProgress,65)
        centeredImage(ui_top_cluster,0,130)
        love.graphics.setFont(font23)
        if (saveData.setting.showClock) then
            printC(systemTime,2,77,font23)
        else
            printC("Level "..level,2,77,font23)
        end
        printC("x"..Board1.score_multiplier,2,180,font23)
        love.graphics.setFont(font35)
        printC(commaNumber(Board1.score),2,128,font35)
        love.graphics.print(score(level+1),0,140)

        --Level up text
        if (textY < 0) then
            love.graphics.setColor(1,1,1,(55+textY)/43)
            centeredImage(ui_level_up_text,0,43+textY)
            love.graphics.setColor(1,1,1,1)
        end

        --Collection (middle)
        love.graphics.setColor(1,1,1,0.7)
        love.graphics.draw(gridCanvas,-75,270)
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(collectCanvas,-75,270)
        centeredImage(endless_border,0,347)
        if (rec.alpha > 0) then
            love.graphics.setColor(1,1,1,rec.alpha)
            love.graphics.rectangle("fill",-75+(15*(rec.x-1)),270+(15*(rec.y-1)),15,15)
            love.graphics.setColor(1,1,1,1)
        end

        --Bottom 'cluster'
        love.graphics.rectangle("fill",-80,548,hintCountdown*16,5)
        if (isPressed.hint) then
            centeredImage(ui_bottom_cluster_hint,0,575)
        elseif (isPressed.menu) then
            centeredImage(ui_bottom_cluster_menu,0,575)
        else
            centeredImage(ui_bottom_cluster,0,575)
        end
        love.graphics.setFont(font30)
        if (hintCountdown > 0) then
            love.graphics.setColor(1,1,1,0.4)
        end
        printC("HINT",1,527,font30)

        love.graphics.pop()
    end
end

function F:gamepadpressed(joystick, button)
    Board1:gamepadPressed(button)
end

function F:gamepadreleased(joystick, button)
    Board1:gamepadReleased(button)
end

function F:touchpressed(id,x,y)
    if (showMenu) then
        --Toggle particle
        if (x > 605 and x < 675 and y > 275 and y < 305) then
            isPressed.particle = true
        --Toggle clock
        elseif (x > 605 and x < 675 and y > 315 and y < 345) then
            isPressed.clock = true
        --Back to game
        elseif (x > 480 and x < 800 and y > 365 and y < 435) then
            isPressed.backtogame = true
        --Help
        elseif (x > 480 and x < 635 and y > 445 and y < 515) then
            isPressed.help = true
        --Save
        elseif (x > 645 and x < 800 and y > 445 and y < 515) then
            isPressed.save = true
        --Save and quit
        elseif (x > 480 and x < 800 and y > 525 and y < 595) then
            isPressed.saveandquit = true
        end
    else
        --Hint button
        if (x > 175 and x < 315 and y > 500 and y < 550 and hintCountdown == 0) then
            isPressed.hint = true
        --Menu button
        elseif (x > 140 and x < 350 and y > 560 and y < 650) then
            isPressed.menu = true
        else
            Board1:pressed(id,x,y)
        end
    end
end

function F:touchmoved(id,x,y)

end

function F:touchreleased(id,x,y)
    if (showMenu) then
        --Toggle particle
        if (x > 605 and x < 675 and y > 275 and y < 305 and isPressed.particle) then
            saveData.setting.showParticles = not saveData.setting.showParticles
            Board1.showParticles = saveData.setting.showParticles
        --Toggle clock
        elseif (x > 605 and x < 675 and y > 315 and y < 345 and isPressed.clock) then
            saveData.setting.showClock = not saveData.setting.showClock
        --Back to game
        elseif (x > 480 and x < 800 and y > 365 and y < 435 and isPressed.backtogame) then
            showMenu = "moveout"
        --Help
        elseif (x > 480 and x < 635 and y > 445 and y < 515 and isPressed.help) then

        --Save
        elseif (x > 645 and x < 800 and y > 445 and y < 515 and isPressed.save) then
            save()
        --Save and quit
        elseif (x > 480 and x < 800 and y > 525 and y < 595 and isPressed.saveandquit) then
            save()
            love.event.quit()
        end
    else
        --Hint button
        if (x > 175 and x < 315 and y > 500 and y < 550 and hintCountdown == 0 and isPressed.hint) then
            Board1.hint.time = 10
            hintCountdown = 10
        --Menu button
        elseif (x > 140 and x < 350 and y > 560 and y < 650 and isPressed.menu) then
            showMenu = "movein"
        else
            Board1:released(id,x,y)
        end
    end
    --Reset isPressed
    for k,v in pairs(isPressed) do
        isPressed[k] = false
    end
end

save = function()
    --Save tile properties
    local gc = ""
    local gt = ""
    for x=1,Board1.grid_size do
        for y=1,Board1.grid_size do
            --Get colours
            if (Board1.tiles[x][y].colour == "red") then
                gc = gc.."r"
            elseif (Board1.tiles[x][y].colour == "orange") then
                gc = gc.."o"
            elseif (Board1.tiles[x][y].colour == "yellow") then
                gc = gc.."y"
            elseif (Board1.tiles[x][y].colour == "green") then
                gc = gc.."g"
            elseif (Board1.tiles[x][y].colour == "blue") then
                gc = gc.."b"
            elseif (Board1.tiles[x][y].colour == "purple") then
                gc = gc.."p"
            elseif (Board1.tiles[x][y].colour == "white") then
                gc = gc.."w"
            else
                gc = gc.."-"
            end
            --Get types
            if (Board1.tiles[x][y].type == "vertical") then
                gt = gt.."v"
            elseif (Board1.tiles[x][y].type == "horizontal") then
                gt = gt.."h"
            elseif (Board1.tiles[x][y].type == "remover") then
                gt = gt.."r"
            elseif (Board1.tiles[x][y].type == "explosion") then
                gt = gt.."e"
            else
                gt = gt.."-"
            end
        end
    end
    saveData.endless.gemColour = gc
    saveData.endless.gemType = gt
    --Save score
    saveData.endless.score = Board1.score
    --Write to file
    writeData()
end

--Generates the canvas for the 'collection'
generateCollection = function()
    love.graphics.setCanvas(collectCanvas)
    for y=1,10,1 do
        for x=1,10,1 do
            local i = ((y-1)*10)+x
            if (saveData.endless.collection:sub(i,i) == '.') then
                love.graphics.setColor(unpack(colorMap[y][x]))
                love.graphics.draw(endless_tile,(x-1)*15,(y-1)*15)
            end
        end
    end
    love.graphics.setCanvas()
end

return F