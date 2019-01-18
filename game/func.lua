--Various functions used throughout the code
--Round a number
function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
 	return math.floor(num * mult + 0.5) / mult
end

--Deep copy a table
function copyTable(t)
    local ret = {}
    for k,v in pairs(t) do
        ret[k] = v
    end
    return ret
end

--Draw a image centered at (x,y)
function centeredImage(img,x,y,sx,sy)
    local sx = sx or 1
    local sy = sy or 1
    local X = round(x-(sx*img:getWidth())/2)
    local Y = round(y-(sy*img:getHeight())/2)
    love.graphics.draw(img,X,Y,0,sx,sy)
end
