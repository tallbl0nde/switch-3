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
