local F = {}

--"Global" variables for this screen/file
--Board object
local Board1
--Menu status
local showMenu = false
--Which button is currently pressed (used for highlighting)
local isPressed = {
    hint = false,
    menu = false,
    particle = false,
    clock = false,
    backtogame = false,
    help = false,
    save = false,
    saveandquit = false
}
--Animation variables
local UIPosX = 245
local UIPosY = -300
local vx = 0
--Time until hint is ready
local hintCountdown = 10
--"Level" variables
local progress = 0
local level = 1
--Scores matching each level
local score = { 0,      10000,  20000,  30000,  40000,  50000,  60000,  70000,  80000,  90000,  100000,
--              0       1       2       3       4       5       6       7       8       9       10
                        120000, 140000, 160000, 180000, 200000, 230000, 260000, 300000, 350000, 400000,
--                      11      12      13      14      15      16      17      18      19      20
                        450000, 500000, 550000, 600000, 650000, 700000, 750000, 800000, 850000, 900000,
--                      21      22      23      24      25      26      27      28      29      30
                        1000000,1100000,1200000,1300000,1400000,1500000,1600000,1700000,1800000,2000000
--                      31      32      33      34      35      36      37      38      39      40
}

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
            end
            --Get types
            if (t == "v") then
                t = "vertical"
            elseif (t == "h") then
                t = "horizontal"
            elseif (t == "r") then
                t = "remover"
                c = nil
            elseif (t == "e") then
                t = "explosion"
            else
                t = nil
            end
            Board1.tiles[math.ceil(i/Board1.grid_size)][((i-1)%Board1.grid_size)+1] = new_tile(c,t)
        end
    end
end

function F:update(dt)
    --Update board stuff
    Board1:update(dt)
    saveData.endless.score = Board1.score
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
    elseif (showMenu == false) then
        if (hintCountdown > 0) then
            hintCountdown = hintCountdown - dt
        else
            hintCountdown = 0
        end
    end

    --Progress on level
    progress = (Board1.score-score[level])/(score[level+1]-score[level])
    if (Board1.score >= score[level+1]) then
        level = level+1
    end
end

function F:draw()
    --Background
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(bg_background,0,0,0,2/3,2/3)

    --Draw menu things
    if (showMenu ~= false) then
        if (isPressed.backtogame) then
            centeredImage(ui_game_menu_backtogame,640,UIPosY)
        elseif (isPressed.help) then
            centeredImage(ui_game_menu_help,640,UIPosY)
        elseif (isPressed.save) then
            centeredImage(ui_game_menu_save,640,UIPosY)
        elseif (isPressed.saveandquit) then
            centeredImage(ui_game_menu_saveandquit,640,UIPosY)
        else
            centeredImage(ui_game_menu,640,UIPosY)
        end
        if (saveData.setting.showParticles) then
            if (isPressed.particle) then
                centeredImage(ui_toggle_on_touch,635,UIPosY-69,0.7)
            else
                centeredImage(ui_toggle_on,635,UIPosY-69,0.7)
            end
        else
            if (isPressed.particle) then
                centeredImage(ui_toggle_off_touch,635,UIPosY-69,0.7)
            else
                centeredImage(ui_toggle_off,635,UIPosY-69,0.7)
            end
        end
        if (saveData.setting.showClock) then
            if (isPressed.clock) then
                centeredImage(ui_toggle_on_touch,635,UIPosY-30,0.7)
            else
                centeredImage(ui_toggle_on,635,UIPosY-30,0.7)
            end
        else
            if (isPressed.clock) then
                centeredImage(ui_toggle_off_touch,635,UIPosY-30,0.7)
            else
                centeredImage(ui_toggle_off,635,UIPosY-30,0.7)
            end
        end
    end

    --Draw board/side things
    if (showMenu ~= true) then
        Board1:draw()

        --Top 'cluster'
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle("fill",UIPosX-125,97,250*progress,65)
        love.graphics.setColor(1,1,1,1)
        centeredImage(ui_top_cluster,UIPosX,130)
        love.graphics.setFont(font23)
        if (saveData.setting.showClock) then
            printC(systemTime,UIPosX+2,77,font23)
        else
            printC("Level "..level,UIPosX+2,77,font23)
        end
        printC("x"..Board1.score_multiplier,UIPosX+2,180,font23)
        love.graphics.setFont(font35)
        printC(commaNumber(Board1.score),UIPosX+2,128,font35)

        --Bottom 'cluster'
        love.graphics.rectangle("fill",UIPosX-80,548,hintCountdown*16,5)
        if (isPressed.hint) then
            centeredImage(ui_bottom_cluster_hint,UIPosX,575)
        elseif (isPressed.menu) then
            centeredImage(ui_bottom_cluster_menu,UIPosX,575)
        else
            centeredImage(ui_bottom_cluster,UIPosX,575)
        end
        love.graphics.setFont(font30)
        if (hintCountdown ~= 0) then
            love.graphics.setColor(1,1,1,0.4)
        end
        printC("HINT",UIPosX+1,527,font30)
    end
end

function F:gamepadpressed(joystick, button)

end

function F:gamepadreleased(joystick, button)

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
            self:save()
        --Save and quit
        elseif (x > 480 and x < 800 and y > 525 and y < 595 and isPressed.saveandquit) then
            self:save()
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

function F:save()
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
    writeData()
end

return F