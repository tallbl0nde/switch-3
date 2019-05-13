Audio = {}

function Audio:init()
    self.fxSources = {}         --FX Sources
    self.musicSources = {}      --Song 'playlist'
    self.musicPlayed = {}       --Number of songs since last played
    self.musicIndex = 0         --Index of current song
end

function Audio:update()
    --Check if music is finished and if so start next song
    if (#self.musicSources > 0) then
        if (not self.musicSources[self.musicIndex]:isPlaying()) then
            self:playNextSong()
        end
    end
end

--SOUND EFFECTS
function Audio:playEffect(name)
    --Create a new source if needed, otherwise play a stopped one
    for i=1,#fxSources do
        if (fxSources[i].name == name) then
            if (not fxSources[i].source:isPlaying() and saveData.setting.soundVolume > 0) then
                fxSources[i].source:setVolume(saveData.setting.soundVolume)
                love.audio.play(fxSources[i].source)
                return
            end
        end
    end
    fxSources[#fxSources+1] = {name = name, source = love.audio.newSource("resources/sound/fx/"..name..".wav","static")}
    love.audio.play(fxSources[#fxSources].source)
end

function Audio:cleanEffects()
    for i=1,#fxSources do
        if (not fxSources[i].source:isPlaying()) then
            fxSources[i] = nil
        end
    end
end

--MUSIC
function Audio:loadPlaylist(tbl)
    --Reset tables and vars
    for i=1,#tbl do
        self.musicSources[i] = _G["music_"..tbl[i]]
    end
    self.musicPlayed = {}
    for i=1,#tbl do
        self.musicPlayed[i] = -1
    end
    self.musicIndex = 0
end

--Pick next song to play... chances improve the longer it has been since it played
function Audio:playNextSong()
    --Determine order to look at songs
    local order = {}
    for i=1,#self.musicSources do
        order[i] = i
    end
    for i=#self.musicSources,1,-1 do
        local rand = love.math.random(1,#self.musicSources)
        order[i], order[rand] = order[rand], order[i]
    end

    local min = round(#self.musicSources*0.6)
    local done = false
    while (not done) do
        --Check over songs in determined order
        for i=1,#order do
            --If song is above play time thing
            if (self.musicPlayed[order[i]] >= min or self.musicPlayed[order[i]] == -1) then
                self:playSong(order[i])
                done = true
                break
            end
        end
        min = min - 1
    end
end

--Internal function
function Audio:playSong(index)
    --Increase play counter for all other songs
    for i=1,#self.musicPlayed do
        if (self.musicPlayed[i] ~= -1) then
            self.musicPlayed[i] = self.musicPlayed[i] + 1
        end
    end
    --Play song
    love.audio.play(self.musicSources[index])
    self.musicSources[index]:setVolume(saveData.setting.musicVolume)
    self.musicIndex = index
    self.musicPlayed[index] = 0
end

--Stop playing music
function Audio:stop()
    love.audio.stop(self.musicSources[self.musicindex])
end

--Adjust volume of playing song
function Audio:adjustMusicVol()
    if (self.musicIndex ~= 0) then
        self.musicSources[self.musicIndex]:setVolume(saveData.setting.musicVolume)
    end
end

return Audio