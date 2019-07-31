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
    sx = sx or 1
    sy = sy or sx or 1
    local X = round(x-(sx*img:getWidth())/2)
    local Y = round(y-(sy*img:getHeight())/2)
    love.graphics.draw(img,X,Y,r or 0,sx or 1,sy or 1)
end

--Draw a image centered at (x,y) [without rounding]
function centeredImage2(img,x,y,sx,sy)
    sx = sx or 1
    sy = sy or sx or 1
    local X = x-(sx*img:getWidth())/2
    local Y = y-(sy*img:getHeight())/2
    love.graphics.draw(img,X,Y,r or 0,sx or 1,sy or 1)
end

--Draw centered text
function printC(txt,x,y,size)
    -- Prevent a random crash (from a variable being nil??)
    if (txt == nil) then
        txt = ""
    end
	local w = round(size:getWidth(txt)/2)
	local h = round(size:getHeight(txt)/2)
	love.graphics.print(txt,x-w,y-h)
end

--Return a random float
function randomFloat(min, max, precision)
	local range = max - min
	local offset = range * math.random()
	local unrounded = min + offset

	if not precision then
		return unrounded
	end

	local powerOfTen = 10 ^ precision
	return math.floor(unrounded * powerOfTen + 0.5) / powerOfTen
end

--Format an integer with commas
function commaNumber(num)
    str = tostring(num)
    ret = ""
    local p = #str
    while (p-2 > 1) do
        ret = ","..string.sub(str,p-2,p)..ret
        p=p-3
    end
    ret = string.sub(str,1,p)..ret
    return ret
end