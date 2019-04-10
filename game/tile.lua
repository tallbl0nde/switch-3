--newTile: called to initalise and return a new tile
function new_tile(colour,type,type2)
    local t = {}
    -- states:
    -- "vertical" = vertical powerup
    -- "horizontal" = horizontal powerup
    -- "explosion" = explosion powerup
    -- "remover" = hypercube powerup thing
    t.type = type or nil
    t.type2 = type2 or nil
    -- Animation variables
    t.anim = {}
    t.anim.colour = {0.7,0.7,0.7}   --colour used for animations (will be overwritten if tile has a colour)
    t.anim.velocity = 0             -- velocity of gem (when falling)
    t.anim.size = 1                 -- size of gem (used for animations too)
    t.anim.x = 0                    -- x pos for swap animation
    t.anim.y = 0                    -- y pos for swap animation
    t.anim.status = ""              -- string for current animation use
    t.anim.glow = 0                 -- rotation of glow (explosion powerup)
    t.anim.glowOn = true            -- true if glow should grow
    -- True if matched and needs to be removed
    t.matched = false
    -- True if tile was checked for match in current analyze (so far only used for powerup shizzle)
    t.analyzed = false
    -- True if tile was involved in swapping (used for powerups)
    t.wasSwapped = false
    -- If passed a colour then use that else choose one at random
    if (colour) then
        t.colour = colour
    else
        if (type == "remover") then
            t.colour = nil
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
    end

    --Set animation colour
    if (t.colour == "red") then
        t.anim.colour = {1,0.3,0.3}
    elseif (t.colour == "orange") then
        t.anim.colour = {1,0.5,0.3}
    elseif (t.colour == "yellow") then
        t.anim.colour = {1,1,0.3}
    elseif (t.colour == "green") then
        t.anim.colour = {0.2,1,0.4}
    elseif (t.colour == "blue") then
        t.anim.colour = {0.2,0.4,1}
    elseif (t.colour == "purple") then
        t.anim.colour = {0.9,0.3,1}
    elseif (t.colour == "white") then
        t.anim.colour = {1,1,1}
    else
        t.anim.colour = {0.8,0.8,0.8}
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
    --Should be able to remove anim in future?
    return {anim = {x = 0, y = 0, size = 1}, colour = "invisible"}
end