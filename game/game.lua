function game_endless()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(background,0,0,0,2/3,2/3)

    love.graphics.draw(ui_score,100,50)
    Board1:draw()
    if (Board1.no_matches == true) then
        love.graphics.print("Tap to\nshuffle",10,300)
    end

    love.graphics.setFont(font25)
    printC(Board1.score.."\nx"..Board1.score_multiplier,250,100,font25)
end