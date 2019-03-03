--newTile: called to initalise and return a new tile
function new_tile(colour,type)
    local t = {}
    -- states:
    -- "vertical" = vertical powerup
    -- "horizontal" = horizontal powerup
    -- "explosion" = explosion powerup
    -- "remover" = hypercube powerup thing
    t.type = type or nil
    -- Animation variables
    t.anim = {}
    t.anim.offset = 0       -- offset (y in percent from -1 to 1)
    t.anim.velocity = 0     -- velocity of gem (when falling)
    t.anim.swapped = false  -- prevents infinite swaps :D
    t.anim.size = 1         -- size of gem (used for animations too)
    t.anim.swap = {}
    t.anim.swap.x = 0       -- x pos for swap animation
    t.anim.swap.y = 0       -- y pos for swap animation
    -- True if matched and needs to be removed
    t.matched = false
    -- True if tile was involved in swapping (used for powerups)
    t.wasSwapped = false
    -- If passed a colour then use that else choose one at random
    if (colour) then
        t.colour = colour
    else
        local col = love.math.random(1,7)
        if (col == 1) then
            t.colour = "red"
        elseif (col == 2) then
            t.colour = "orange"
        elseif (col == 3) then
            t.colour = "yellow"
        elseif (col == 4) then
            t.colour = "green"
        elseif (col == 5) then
            t.colour = "blue"
        elseif (col == 6) then
            t.colour = "purple"
        elseif (col == 7) then
            t.colour = "white"
        end
    end
    -- Get image based on states
    if (t.type == "remover") then
        t.img = _G["tile_remover"]
    elseif (t.type) then
        t.img = _G["tile_"..t.colour.."_"..t.type]
    else
        t.img = _G["tile_"..t.colour]
    end
    return t
end

--new_placeholder: called to initalise and return a new tile placeholder (invisible)
function new_placeholder()
    local t = {}
    -- Required for no crash
    t.anim = {}
    t.anim.offset = 0       -- offset (y in percent from -1 to 1)
    t.anim.velocity = 0     -- velocity of gem (when falling)
    t.anim.swapped = false  -- prevents infinite swaps :D
    t.anim.size = 1         -- size of gem (used for animations too)
    t.anim.swap = {}
    t.anim.swap.x = 0       -- x pos for swap animation
    t.anim.swap.y = 0       -- y pos for swap animation
    t.matched = false
    t.wasSwapped = false
    -- Colour is 'invisible'
    t.colour = "invisible"
    return t
end