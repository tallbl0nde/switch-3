--newTile: called to initalise and return a new tile
function new_tile()
    local t = {}
    -- states:
    -- 0: normal
    -- 1: charged (bomb)
    -- 2: vertical
    -- 3: horizontal
    t.state = 0
    -- offset (y in percent from -1 to 1)
    t.offset = 0
    local col = love.math.random(1,7)
    if (col == 1) then
        t.type = "red"
    elseif (col == 2) then
        t.type = "orange"
    elseif (col == 3) then
        t.type = "yellow"
    elseif (col == 4) then
        t.type = "green"
    elseif (col == 5) then
        t.type = "blue"
    elseif (col == 6) then
        t.type = "purple"
    elseif (col == 7) then
        t.type = "white"
    end
    t.img = _G["tile_"..t.type]
    return t
end