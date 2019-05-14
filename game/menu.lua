--Contains all necessary code for the menu 'object'
Menu = {}

function Menu:new(x,y)
    --CENTRE COORDINATES
    self.x = x
    self.y = y
    --Used for button presses
    self.isPressed = {
        a = false,
        dpleft = false,
        dpright = false,
        backtogame = false,
        clock = false,
        help = false,
        music = false,
        particle = false,
        save = false,
        saveandquit = false,
        sound = false
    }
    --Used for what to highlight with gamepad
    self.highlight = {
        x = nil,
        y = nil,
        x2 = nil,
        y2 = nil,
        item = 5,
        active = false,
        last = 6,
        color = {1,1,1,1},
        time = 0
    }
    self.show = false
end

function Menu:update(dt)
    --Animate 'highlight' colours if visible
    if (self.highlight.active) then
        self.highlight.time = self.highlight.time + dt
        self.highlight.color[1] = math.sin(0.8*self.highlight.time + 0) * 0.35 + 0.65
        self.highlight.color[2] = math.sin(0.8*self.highlight.time + 2) * 0.35 + 0.65
        self.highlight.color[3] = math.sin(0.8*self.highlight.time + 4) * 0.35 + 0.65
    end

    --Move music and sounds sliders if a and a direction is held
    if (self.isPressed.dpright and self.isPressed.a) then
        if (self.highlight.item == 1) then
            saveData.setting.musicVolume = saveData.setting.musicVolume + 0.01
            if (saveData.setting.musicVolume > 1) then
                saveData.setting.musicVolume = 1
            end
            Audio:adjustMusicVol()
        elseif (self.highlight.item == 2) then
            saveData.setting.soundVolume = saveData.setting.soundVolume + 0.01
            if (saveData.setting.soundVolume > 1) then
                saveData.setting.soundVolume = 1
            end
        end
    elseif (self.isPressed.dpleft and self.isPressed.a) then
        if (self.highlight.item == 1) then
            saveData.setting.musicVolume = saveData.setting.musicVolume - 0.01
            if (saveData.setting.musicVolume < 0) then
                saveData.setting.musicVolume = 0
            end
            Audio:adjustMusicVol()
        elseif (self.highlight.item == 2) then
            saveData.setting.soundVolume = saveData.setting.soundVolume - 0.01
            if (saveData.setting.soundVolume < 0) then
                saveData.setting.soundVolume = 0
            end
        end
    end
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
    if (saveData.setting.showParticles) then
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
    if (saveData.setting.showClock) then
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

    --Audio sliders
    if (self.isPressed.music) then
        love.graphics.setColor(0.8,0.8,0.8,1)
    end
    centeredImage(ui_slider,-30+(185*saveData.setting.musicVolume),-162)
    love.graphics.setColor(1,1,1,1)
    if (self.isPressed.sound) then
        love.graphics.setColor(0.8,0.8,0.8,1)
    end
    centeredImage(ui_slider,-30+(185*saveData.setting.soundVolume),-114)

    --Draw highlighters
    if (self.highlight.active) then
        love.graphics.setColor(unpack(self.highlight.color))
        centeredImage(ui_indicator,self.highlight.x,self.highlight.y)
        if (self.highlight.item > 4 and self.highlight.x2 ~= nil) then
            centeredImage(ui_indicator,self.highlight.x2,self.highlight.y2)
        end
    end

    love.graphics.pop()
end

function Menu:pressed(absX,absY)
    local x = absX - self.x
    local y = absY - self.y
    self.highlight.active = false
    --Music
    if (x > -30 and x < 155 and y > -180 and y < -145) then
        self.isPressed.music = true
        saveData.setting.musicVolume = round((x+30)/185,2)
        if (saveData.setting.musicVolume < 0) then
            saveData.setting.musicVolume = 0
        elseif (saveData.setting.musicVolume > 1) then
            saveData.setting.musicVolume = 1
        end
        Audio:adjustMusicVol()
        self.highlight.item = 1
    --Sound
    elseif (x > -30 and x < 155 and y > -135 and y < -95) then
        self.isPressed.sound = true
        saveData.setting.soundVolume = round((x+30)/185,2)
        if (saveData.setting.soundVolume < 0) then
            saveData.setting.soundVolume = 0
        elseif (saveData.setting.soundVolume > 1) then
            saveData.setting.soundVolume = 1
        end
        self.highlight.item = 2
    --Toggle particle
    elseif (x > -35 and x < 35 and y > -85 and y < -55) then
        self.isPressed.particle = true
        self.highlight.item = 3
    --Toggle clock
    elseif (x > -35 and x < 35 and y > -45 and y < -15) then
        self.isPressed.clock = true
        self.highlight.item = 4
    --Back to game
    elseif (x > -160 and x < 160 and y > 5 and y < 75) then
        self.isPressed.backtogame = true
        self.highlight.item = 5
    --Help
    elseif (x > -160 and x < -5 and y > 85 and y < 155) then
        self.isPressed.help = true
        self.highlight.item = 6
    --Save
    elseif (x > 5 and x < 160 and y > 85 and y < 155) then
        self.isPressed.save = true
        self.highlight.item = 7
    --Save and quit
    elseif (x > -160 and x < 160 and y > 165 and y < 235) then
        self.isPressed.saveandquit = true
        self.highlight.item = 8
    end
end

function Menu:dragged(absX,absY)
    local x = absX - self.x
    local y = absY - self.y
    if (self.isPressed.music) then
        saveData.setting.musicVolume = round((x+30)/185,2)
        if (saveData.setting.musicVolume < 0) then
            saveData.setting.musicVolume = 0
        elseif (saveData.setting.musicVolume > 1) then
            saveData.setting.musicVolume = 1
        end
        Audio:adjustMusicVol()
    elseif (self.isPressed.sound) then
        saveData.setting.soundVolume = round((x+30)/185,2)
        if (saveData.setting.soundVolume < 0) then
            saveData.setting.soundVolume = 0
        elseif (saveData.setting.soundVolume > 1) then
            saveData.setting.soundVolume = 1
        end
    end
end

function Menu:released(absX,absY)
    local x = absX - self.x
    local y = absY - self.y
    local ret
    --Toggle particle
    if (x > -35 and x < 35 and y > -85 and y < -55 and self.isPressed.particle) then
        ret = "toggleparticle"
    --Toggle clock
    elseif (x > -35 and x < 35 and y > -45 and y < -15 and self.isPressed.clock) then
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
    --Audio sliders
    elseif (self.isPressed.music) then
        ret = "adjustmusic"
    elseif (self.isPressed.sound) then
        ret = "adjustsound"
    end
    --Reset self.isPressed
    for k,v in pairs(self.isPressed) do
        self.isPressed[k] = false
    end
    return ret
end

function Menu:gamepadPressed(b)
    if (b == "b") then
        self.isPressed.backtogame = true
        return
    end
    --If the highlight is active move it on press
    if (self.highlight.active) then
        if (b == "dpup") then
            if (not self.isPressed.a) then
                self:moveHighlight("up")
            end
        elseif (b == "dpright") then
            if (not self.isPressed.a) then
                self:moveHighlight("right")
            end
            self.isPressed.dpright = true
        elseif (b == "dpdown") then
            if (not self.isPressed.a) then
                self:moveHighlight("down")
            end
        elseif (b == "dpleft") then
            if (not self.isPressed.a) then
                self:moveHighlight("left")
            end
            self.isPressed.dpleft = true

        --'press' the item that is highlighted
        elseif (b == "a") then
            self.isPressed.a = true
            if (self.highlight.item == 1) then
                self.isPressed.music = true
            elseif (self.highlight.item == 2) then
                self.isPressed.sound = true
            elseif (self.highlight.item == 3) then
                self.isPressed.particle = true
            elseif (self.highlight.item == 4) then
                self.isPressed.clock = true
            elseif (self.highlight.item == 5) then
                self.isPressed.backtogame = true
            elseif (self.highlight.item == 6) then
                self.isPressed.help = true
            elseif (self.highlight.item == 7) then
                self.isPressed.save = true
            elseif (self.highlight.item == 8) then
                self.isPressed.saveandquit = true
            end
        end

    --Otherwise activate highlight
    else
        self.highlight.active = true
        self:moveHighlight()
    end
end

function Menu:gamepadReleased(b)
    --B closes the menu
    if (b == "b") then
        self.isPressed.backtogame = false
        self.show = "moveout"
        return

    --Perform required action when A is released
    elseif (b == "a") then
        self.isPressed.a = false
        local ret
        if (self.highlight.item == 1) then
            self.isPressed.music = false
            ret = "adjustmusic"
        elseif (self.highlight.item == 2) then
            self.isPressed.sound = false
            ret = "adjustsound"
        elseif (self.highlight.item == 3) then
            self.isPressed.particle = false
            ret = "toggleparticle"
        elseif (self.highlight.item == 4) then
            self.isPressed.clock = false
            ret = "toggleclock"
        elseif (self.highlight.item == 5) then
            self.isPressed.backtogame = false
            ret = "hidemenu"
        elseif (self.highlight.item == 6) then
            self.isPressed.help = false
            ret = "help"
        elseif (self.highlight.item == 7) then
            self.isPressed.save = false
            ret = "save"
        elseif (self.highlight.item == 8) then
            self.isPressed.saveandquit = false
            ret = "saveandquit"
        end
        return ret
    elseif (b == "dpright") then
        self.isPressed.dpright = false
    elseif (b == "dpleft") then
        self.isPressed.dpleft = false
    end
end

--1: music     2: sound    3: particle     4: clock    5: back     6: help     7: save     8: quit
function Menu:moveHighlight(dir)
    --Move position
    if (dir == "down") then
        if (self.highlight.item == 6) then
            self.highlight.item = 8
        elseif (self.highlight.item == 5) then
            self.highlight.item = self.highlight.last
        elseif (self.highlight.item < 8) then
            self.highlight.item = self.highlight.item + 1
        end
    elseif (dir == "up") then
        if (self.highlight.item == 7) then
            self.highlight.item = 5
        elseif (self.highlight.item == 8) then
            self.highlight.item = self.highlight.last
        elseif (self.highlight.item > 1) then
            self.highlight.item = self.highlight.item - 1
        end
    elseif (dir == "right") then
        if (self.highlight.item == 6) then
            self.highlight.item = 7
        elseif (self.highlight.item == 8 or self.highlight.item == 5) then
            self.highlight.last = 7
        end
    elseif (dir == "left") then
        if (self.highlight.item == 7) then
            self.highlight.item = 6
        elseif (self.highlight.item == 8 or self.highlight.item == 5) then
            self.highlight.last = 6
        end
    end

    --Set x and y coords accordingly
    if (self.highlight.item == 1) then
        self.highlight.x = -155
        self.highlight.y = -167
    elseif (self.highlight.item == 2) then
        self.highlight.x = -170
        self.highlight.y = -118
    elseif (self.highlight.item == 3) then
        self.highlight.x = -170
        self.highlight.y = -70
    elseif (self.highlight.item == 4) then
        self.highlight.x = -145
        self.highlight.y = -30
    elseif (self.highlight.item == 5) then
        self.highlight.x = -115
        self.highlight.y = 40
        self.highlight.x2 = 115
        self.highlight.y2 = 40
    elseif (self.highlight.item == 6) then
        self.highlight.x = -132
        self.highlight.y = 122
        self.highlight.x2 = -32
        self.highlight.y2 = 122
        self.highlight.last = 6
    elseif (self.highlight.item == 7) then
        self.highlight.x = 32
        self.highlight.y = 122
        self.highlight.x2 = 132
        self.highlight.y2 = 122
        self.highlight.last = 7
    elseif (self.highlight.item == 8) then
        self.highlight.x = -100
        self.highlight.y = 201
        self.highlight.x2 = 100
        self.highlight.y2 = 201
    end
end