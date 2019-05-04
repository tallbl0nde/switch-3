local sources = {}

function playEffect(name)
    for i=1,#sources do
        if (sources[i].name == name) then
            if (not sources[i].source:isPlaying() and saveData.setting.soundVolume > 0) then
                --sources[i].source:setVolume(saveData.setting.soundVolume)
                love.audio.play(sources[i].source)
                return
            end
        end
    end
    sources[#sources+1] = {name = name, source = love.audio.newSource("resources/sound/fx/"..name..".wav","static")}
    love.audio.play(sources[#sources].source)
end

function adjustVolume()

end