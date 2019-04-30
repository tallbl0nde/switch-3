--Contains all necessary code for the menu 'object'
Menu = {}

function Menu:new(x,y)
    --CENTRE COORDINATES
    self.x = x
    self.y = y
    --Used for button presses
    self.isPressed = {
        backtogame = false,
        clock = false,
        help = false,
        particle = false,
        save = false,
        saveandquit = false
    }
    --Settings (will be overridden)
    self.setting = {
        showParticles = false,
        showClock = false
    }
end

function Menu:draw()
    love.graphics.push("all")
    love.graphics.translate(self.x,self.y)
    love.graphics.setColor(1,1,1,1)

    --Draw main menu image
    if (self.isPressed.backtogame) then
        centeredImage(ui_game_menu_backtogame,0,0)
    elseif (self.isPressed.help) then
        centeredImage(ui_game_menu_help,0,0)
    elseif (self.isPressed.save) then
        centeredImage(ui_game_menu_save,0,0)
    elseif (self.isPressed.saveandquit) then
        centeredImage(ui_game_menu_saveandquit,0,0)
    else
        centeredImage(ui_game_menu,0,0)
    end

    --Draw toggles based on state
    if (self.setting.showParticles) then
        if (self.isPressed.particle) then
            centeredImage(ui_toggle_on_touch,-5,-69,0.7)
        else
            centeredImage(ui_toggle_on,-5,-69,0.7)
        end
    else
        if (self.isPressed.particle) then
            centeredImage(ui_toggle_off_touch,-5,-69,0.7)
        else
            centeredImage(ui_toggle_off,-5,-69,0.7)
        end
    end
    if (self.setting.showClock) then
        if (self.isPressed.clock) then
            centeredImage(ui_toggle_on_touch,-5,-30,0.7)
        else
            centeredImage(ui_toggle_on,-5,-30,0.7)
        end
    else
        if (self.isPressed.clock) then
            centeredImage(ui_toggle_off_touch,-5,-30,0.7)
        else
            centeredImage(ui_toggle_off,-5,-30,0.7)
        end
    end

    love.graphics.pop()
end

function Menu:pressed(absX,absY)
    local x = absX - self.x
    local y = absY - self.y
    --Toggle particle
    if (x > -35 and x < 35 and y > -85 and y < -55) then
        self.isPressed.particle = true
    --Toggle clock
    elseif (x > -35 and x < 35 and y > -45 and y < -15) then
        self.isPressed.clock = true
    --Back to game
    elseif (x > -160 and x < 160 and y > 5 and y < 75) then
        self.isPressed.backtogame = true
    --Help
    elseif (x > -160 and x < -5 and y > 85 and y < 155) then
        self.isPressed.help = true
    --Save
    elseif (x > 5 and x < 160 and y > 85 and y < 155) then
        self.isPressed.save = true
    --Save and quit
    elseif (x > -160 and x < 160 and y > 165 and y < 235) then
        self.isPressed.saveandquit = true
    end
end

function Menu:released(absX,absY)
    local x = absX - self.x
    local y = absY - self.y
    local ret
    --Toggle particle
    if (x > -35 and x < 35 and y > -85 and y < -55 and self.isPressed.particle) then
        self.setting.showParticles = not self.setting.showParticles
        ret = "toggleparticle"
    --Toggle clock
    elseif (x > -35 and x < 35 and y > -45 and y < -15 and self.isPressed.clock) then
        self.setting.showClock = not self.setting.showClock
        ret = "toggleclock"
    --Back to game
    elseif (x > -160 and x < 160 and y > 5 and y < 75 and self.isPressed.backtogame) then
        ret = "hidemenu"
    --Help
    elseif (x > -160 and x < -5 and y > 85 and y < 155 and self.isPressed.help) then
        ret = "help"
    --Save
    elseif (x > 5 and x < 160 and y > 85 and y < 155 and self.isPressed.save) then
        ret = "save"
    --Save and quit
    elseif (x > -160 and x < 160 and y > 165 and y < 235 and self.isPressed.saveandquit) then
        ret = "saveandquit"
    end
    --Reset self.isPressed
    for k,v in pairs(self.isPressed) do
        self.isPressed[k] = false
    end
    return ret
end