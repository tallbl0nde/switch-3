function game_endless()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(background,0,0,0,2/3,2/3)
    Board1:draw()
    if (Board1.no_matches == true) then
        love.graphics.print("Tap to\nshuffle",10,300)
    end
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(Board1.score,5,5)
end