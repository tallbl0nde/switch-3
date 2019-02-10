local show = 1
local vars = {}
local runTime = 0
local t = 0

function addDebug(var)
    table.insert(vars,var)
end

function updateDebug(dt)
    runTime = runTime + dt
    t = dt
end

function toggleDebug()
    if (show < 2) then
        show = show + 1
    else
        show = 0
    end
end

function drawDebug()
    if (show == 1) then
        love.graphics.setColor(1,1,1,1)
        love.graphics.print("FPS: "..love.timer.getFPS(),love.graphics.getWidth()-love.graphics.getFont():getWidth("FPS: "..love.timer.getFPS()),0)
        love.graphics.print('Memory used: '..math.ceil(collectgarbage('count')/1024).. " MB",love.graphics.getWidth()-love.graphics.getFont():getWidth('Memory used: '..math.ceil(collectgarbage('count')/1024).. " MB"),15)
        love.graphics.print("Runtime: "..math.floor(runTime).." sec",love.graphics.getWidth()-love.graphics.getFont():getWidth("Runtime: "..math.floor(runTime).." sec"),30)
        love.graphics.print("dt: "..t,love.graphics.getWidth()-love.graphics.getFont():getWidth("dt: "..t),45)
        for i=1,#vars do
            love.graphics.print(vars[i]..": "..(_G[vars[i]] or "nil"),5,(i-1)*15)
        end
    elseif (show == 2) then
        love.graphics.setColor(1,1,1,1)
        love.graphics.print("FPS: "..love.timer.getFPS(),love.graphics.getWidth()-love.graphics.getFont():getWidth("FPS: "..love.timer.getFPS()),0)
    end
end
