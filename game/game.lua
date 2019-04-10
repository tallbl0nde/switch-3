function game_endless()
    --Background
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(bg_background,0,0,0,2/3,2/3)

    --Draw the board
    Board1:draw()

    --Score stuff
    love.graphics.draw(ui_top_cluster,100,50)
    -- love.graphics.setFont(font25)
    -- love.graphics.setColor(1,1,1,1)
    -- printC(Board1.score.."\nx"..Board1.score_multiplier,250,100,font25)

    --Menu button
    --love.graphics.draw()
end