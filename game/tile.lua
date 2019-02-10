--newTile: called to initalise and return a new tile
function new_tile(type,state)
    local t = {}
    -- states:
    -- "vertical" = vertical powerup
    -- "horizontal" = horizontal powerup
    -- "explosion" = explosion powerup
    -- "?" = hypercube powerup thing
    t.state = state or nil
    -- offset (y in percent from -1 to 1)
    t.offset = 0
    -- velocity of gem (when falling)
    t.velocity = 0
    -- variables for swapping animations
    t.swap = {x = 0, y = 0}
    t.swapped = false
    -- variables for disappear animation
    t.size = 1
    t.matched = false
    if (type) then
        t.type = type
    else
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
    end
    if (t.state) then
        t.img = _G["tile_"..t.type.."_"..t.state]
    else
        t.img = _G["tile_"..t.type]
    end
    return t
end