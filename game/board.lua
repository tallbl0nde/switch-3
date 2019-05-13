--Contains all necessary code for the board 'object'
Board = {}

function Board:new(x,y,grid_size,s)
    self.x = x or 0
    self.y = y or 0
    self.grid_size = grid_size or 8
    self.size = s or 720
    self.grid_size_px = self.size/self.grid_size

    --Stores coords/properties of particles
    self.animparticles = {}

    --Initalise tile array (and other arrays for animations)
    self.tiles = {}
    self.replacetile = {}
    self.animtiles = {}
    self.animscore = {}
    self.animlaser = {}
    for i = 1,self.grid_size do
        self.tiles[i] = {}
        self.replacetile[i] = {}
        self.animtiles[i] = {}
        self.animscore[i] = {}
        self.animlaser[i] = {}
        for j = 1,self.grid_size do
            self.tiles[i][j] = new_tile()
            self.animlaser[i][j] = {}
        end
    end

    --Check for a combination and replace if necessary
    for i = 1,self.grid_size do
        for j = 1,self.grid_size do
            while (self:matchAt(i,j) == true) do
                self.tiles[i][j] = new_tile()
            end
        end
    end

    --Create grid canvas
    self.gridCanvas = love.graphics.newCanvas(self.size,self.size)
    love.graphics.setCanvas(self.gridCanvas)
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            if ((x+y)%2 == 0) then
                love.graphics.setColor(0,0,0,1)
            else
                love.graphics.setColor(0.07,0.07,0.07,1)
            end
            love.graphics.rectangle("fill",(x-1)*self.grid_size_px,(y-1)*self.grid_size_px,self.grid_size_px,self.grid_size_px)
        end
    end
    love.graphics.setCanvas()

    --Variable for current board state
    self.state = "normal"
    --Shuffle fade in animation
    self.shuffle_alpha = 0
    --Manages colours for remover animation
    self.removerTime = 0
    self.removerColour = {0,0,0}
    --True when a check for matches is required
    self.doCheck = true
    --Variables for score related things
    self.score = 0
    self.score_multiplier = 1
    self.match_number = 1
    --Variable for particles
    self.showParticles = true
    --Variables for hint icon (show: fade in/out; draw: actually draw)
    self.hint = {x = nil, y = nil, offset = 0, time = 0, alpha = 0, show = false, draw = false, active = true}
    --Variables for selector thing
    self.selector = {x = 1, y = 1, x2 = 1, y2 = 1, size = 1, active = true, status = "hover", alpha = 1, time = 0, held = {right = false, down = false, left = false, up = false, a = false}, holdtime = 0}
end

--Update is literally only used for animations (and analysing when not animating) :D
function Board:update(dt)
    --Normal gameplay
    if (self.state == "normal") then
        self.isAnimated = false
        self.isSwapping = false
        for x=1,self.grid_size do
            for y=1,self.grid_size do
                --Falling animation
                if (self.tiles[x][y].anim.status == "falling") then
                    self.isAnimated = true
                    self.tiles[x][y].anim.velocity = self.tiles[x][y].anim.velocity + (0.4*dt)
                    self.tiles[x][y].anim.y = self.tiles[x][y].anim.y + (self.tiles[x][y].anim.velocity*60*dt)
                    if (self.tiles[x][y].anim.y > 0) then
                        self.tiles[x][y].anim.y = 0
                        self.tiles[x][y].anim.status = ""
                        --playEffect("tiledrop")
                    end
                end

                --Swipe animation
                if (self.tiles[x][y].anim.status == "swap") then
                    self.isSwapping = true
                    --x (and swap back)
                    if (self.tiles[x][y].anim.x > 0) then
                        self.isAnimated = true
                        self.tiles[x][y].anim.x = self.tiles[x][y].anim.x - (5*dt)
                        if (self.tiles[x][y].anim.x <= 0) then
                            self.tiles[x][y].anim.x = 0
                            self.tiles[x][y].anim.status = ""
                            --Swap back if no match (x axis)
                            if (not self:matchAt(x,y) and not self:matchAt(x+1,y) and self.tiles[x][y].wasSwapped and self.tiles[x+1][y].wasSwapped) then
                                self:swapTiles(x,y,x+1,y)
                                self.tiles[x][y].anim.x = 1
                                self.tiles[x][y].wasSwapped = false
                                self.tiles[x][y].anim.status = "swap"
                                self.tiles[x+1][y].anim.x = -1
                                self.tiles[x+1][y].wasSwapped = false
                                self.tiles[x+1][y].anim.status = "swap"
                            end
                        end
                    end
                    if (self.tiles[x][y].anim.x < 0) then
                        self.isAnimated = true
                        self.tiles[x][y].anim.x = self.tiles[x][y].anim.x + (5*dt)
                        if (self.tiles[x][y].anim.x >= 0) then
                            self.tiles[x][y].anim.x = 0
                            self.tiles[x][y].anim.status = ""
                        end
                    end
                    --y (and swap back)
                    if (self.tiles[x][y].anim.y > 0) then
                        self.isAnimated = true
                        self.tiles[x][y].anim.y = self.tiles[x][y].anim.y - (5*dt)
                        if (self.tiles[x][y].anim.y <= 0) then
                            self.tiles[x][y].anim.y = 0
                            self.tiles[x][y].anim.status = ""
                            --Swap back if no match (y axis)
                            if (not self:matchAt(x,y) and not self:matchAt(x,y+1) and self.tiles[x][y].wasSwapped and self.tiles[x][y+1].wasSwapped) then
                                self:swapTiles(x,y,x,y+1)
                                self.tiles[x][y].anim.y = 1
                                self.tiles[x][y].wasSwapped = false
                                self.tiles[x][y].anim.status = "swap"
                                self.tiles[x][y+1].anim.y = -1
                                self.tiles[x][y+1].wasSwapped = false
                                self.tiles[x][y+1].anim.status = "swap"
                            end
                        end
                    end
                    if (self.tiles[x][y].anim.y < 0) then
                        self.isAnimated = true
                        self.tiles[x][y].anim.y = self.tiles[x][y].anim.y + (5*dt)
                        if (self.tiles[x][y].anim.y >= 0) then
                            self.tiles[x][y].anim.y = 0
                            self.tiles[x][y].anim.status = ""
                        end
                    end
                end

                --Animation on removal
                if (self.tiles[x][y].matched == true) then
                    self.isAnimated = true
                    -- Explosion tile expands
                    if (self.tiles[x][y].type == "explosion") then
                        self.tiles[x][y].anim.size = self.tiles[x][y].anim.size + (20*dt)
                        if (self.tiles[x][y].anim.size > 3) then
                            self:removeTile(x,y)
                        end
                    -- Vertical glow
                    elseif (self.tiles[x][y].type == "vertical" and self.tiles[x][y].anim.status ~= "nolaser") then
                        self.tiles[x][y].anim.size = self.tiles[x][y].anim.size - (3.5*dt)
                        for i=1,self.grid_size do
                            self.animlaser[x][i].vertical = true
                            self.animlaser[x][i].sizeV = math.ceil(10*self.tiles[x][y].anim.size)
                            self.animlaser[x][i].colourV = self.tiles[x][y].anim.colour
                        end
                        if (self.tiles[x][y].anim.size <= 0.1) then
                            for i=1,self.grid_size do
                                self.animlaser[x][i].vertical = false
                            end
                            self:removeTile(x,y)
                        end
                    -- Horisontal glow
                    elseif (self.tiles[x][y].type == "horizontal" and self.tiles[x][y].anim.status ~= "nolaser") then
                        self.tiles[x][y].anim.size = self.tiles[x][y].anim.size - (3.5*dt)
                        for i=1,self.grid_size do
                            self.animlaser[i][y].horizontal = true
                            self.animlaser[i][y].sizeH = math.ceil(10*self.tiles[x][y].anim.size)
                            self.animlaser[i][y].colourH = self.tiles[x][y].anim.colour
                        end
                        if (self.tiles[x][y].anim.size <= 0.1) then
                            for i=1,self.grid_size do
                                self.animlaser[i][y].horizontal = false
                            end
                            self:removeTile(x,y)
                        end
                    -- Shrink/dissappear
                    else
                        self.tiles[x][y].anim.size = self.tiles[x][y].anim.size - (6*dt)
                        if (self.tiles[x][y].anim.size < 0.5) then
                            self.animtiles[x][y] = copyTable(self.tiles[x][y])
                            self:removeTile(x,y)
                        end
                    end
                end
            end
        end

        --Hint show/hide
        if (self.hint.active or self.hint.time >= 10) then
            self.hint.time = self.hint.time + dt
        end
        if (self.hint.time > 15) then
            self.hint.show = "no"
        end
        if (self.hint.time > 10 and self.hint.time <= 15 and self.hint.show == false) then
            local a
            a, self.hint.x, self.hint.y = self:hasMatch()
            self.hint.show = true
            self.hint.draw = true
        end
        --Fade in/out animation
        if (self.hint.show == true and self.hint.alpha < 1) then
            self.hint.alpha = self.hint.alpha + (2*dt)
            if (self.hint.alpha > 1) then
                self.hint.alpha = 1
            end
        elseif (self.hint.show == "no") then
            self.hint.alpha = self.hint.alpha - (2*dt)
            if (self.hint.alpha < 0) then
                self.hint.alpha = 0
                self.hint.time = 0
                self.hint.show = false
                self.hint.draw = false
            end
        end

        --Bop up and down
        self.hint.offset = math.abs(math.sin(self.hint.time*math.pi)/4)

    --Board suck in shuffle animation
    elseif (self.state == "preshuffle") then
        self.isAnimated = true
        --Banner fade in
        if (self.shuffle_alpha < 1) then
            self.shuffle_alpha = self.shuffle_alpha + dt
        else
            local mid = self.grid_size/2.0
            local done = 0
            for x=1,self.grid_size do
                for y=1,self.grid_size do
                    local Y = mid-y+0.5
                    if (self.tiles[x][y].anim.y < Y) then
                        self.tiles[x][y].anim.velocity = self.tiles[x][y].anim.velocity + dt/7
                        self.tiles[x][y].anim.y = self.tiles[x][y].anim.y + (self.tiles[x][y].anim.velocity*60*dt)
                        if (self.tiles[x][y].anim.y > Y) then
                            self.tiles[x][y].anim.y = Y
                            self.tiles[x][y].anim.velocity = 0
                        end
                    elseif (self.tiles[x][y].anim.y > Y) then
                        self.tiles[x][y].anim.velocity = self.tiles[x][y].anim.velocity - dt/7
                        self.tiles[x][y].anim.y = self.tiles[x][y].anim.y + (self.tiles[x][y].anim.velocity*60*dt)
                        if (self.tiles[x][y].anim.y < Y) then
                            self.tiles[x][y].anim.y = Y
                            self.tiles[x][y].anim.velocity = 0
                        end
                    else
                        done = done + 1
                    end
                end
            end
            if (done == self.grid_size*self.grid_size) then
                --Shuffle and then reset animation variables
                repeat
                    self:shuffle()
                until (self:hasMatch())
                --Set correct anim.x and .y values
                for x=1,self.grid_size do
                    for y=1,self.grid_size do
                        self.tiles[x][y].anim.y = mid-y+0.5
                    end
                end
                --Change animation cycle
                self.state = "postshuffle"
                self.shuffle_alpha = 1.3
                dt = 0
            end
        end

    --Board push out shuffle animation
    elseif (self.state == "postshuffle") then
        --Banner fade out
        if (self.shuffle_alpha > 0) then
            self.shuffle_alpha = self.shuffle_alpha - dt
        end
        local done = 0
        for x=1,self.grid_size do
            for y=1,self.grid_size do
                if (self.tiles[x][y].anim.y < 0) then
                    self.tiles[x][y].anim.velocity = self.tiles[x][y].anim.velocity + dt/6
                    self.tiles[x][y].anim.y = self.tiles[x][y].anim.y + (self.tiles[x][y].anim.velocity*60*dt)
                    if (self.tiles[x][y].anim.y > 0) then
                        self.tiles[x][y].anim.y = 0
                    end
                elseif (self.tiles[x][y].anim.y > 0) then
                    self.tiles[x][y].anim.velocity = self.tiles[x][y].anim.velocity - dt/6
                    self.tiles[x][y].anim.y = self.tiles[x][y].anim.y + (self.tiles[x][y].anim.velocity*60*dt)
                    if (self.tiles[x][y].anim.y < 0) then
                        self.tiles[x][y].anim.y = 0
                    end
                else
                    done = done + 1
                end
            end
        end
        if (done == self.grid_size*self.grid_size and self.shuffle_alpha < 0) then
            self.shuffle_alpha = 0
            self.state = "normal"
        end

    --"Obliterate" animation
    elseif (self.state == "preobliterate") then
        --Number of tiles finished animating
        local done = 0
        --Loop over each tile and animate
        for x=1,self.grid_size do
            local X = self.obX-x
            for y=1,self.grid_size do
                local Y = self.obY-y
                --Init special vars if necessary
                if (self.tiles[x][y].anim.velocityX == nil) then
                    self.tiles[x][y].anim.velocityX = 0
                    self.tiles[x][y].anim.velocityY = 0
                end
                --If to the left, move to right
                if (self.tiles[x][y].anim.x < X) then
                    self.tiles[x][y].anim.velocityX = self.tiles[x][y].anim.velocityX + dt/3
                    self.tiles[x][y].anim.x = self.tiles[x][y].anim.x + (self.tiles[x][y].anim.velocityX*60*dt)
                    if (self.tiles[x][y].anim.x > X) then
                        self.tiles[x][y].anim.x = X
                        self.tiles[x][y].anim.velocityX = 0
                    end
                --If to the right, move to left
                elseif (self.tiles[x][y].anim.x > X) then
                    self.tiles[x][y].anim.velocityX = self.tiles[x][y].anim.velocityX + dt/3
                    self.tiles[x][y].anim.x = self.tiles[x][y].anim.x - (self.tiles[x][y].anim.velocityX*60*dt)
                    if (self.tiles[x][y].anim.x < X) then
                        self.tiles[x][y].anim.x = X
                        self.tiles[x][y].anim.velocityX = 0
                    end
                --Otherwise must be in correct position (x)
                else
                    done = done + 1
                end
                --If above move down
                if (self.tiles[x][y].anim.y < Y) then
                    self.tiles[x][y].anim.velocityY = self.tiles[x][y].anim.velocityY + dt/3
                    self.tiles[x][y].anim.y = self.tiles[x][y].anim.y + (self.tiles[x][y].anim.velocityY*60*dt)
                    if (self.tiles[x][y].anim.y > Y) then
                        self.tiles[x][y].anim.y = Y
                        self.tiles[x][y].anim.velocityY = 0
                    end
                --If below move up
                elseif (self.tiles[x][y].anim.y > Y) then
                    self.tiles[x][y].anim.velocityY = self.tiles[x][y].anim.velocityY - dt/3
                    self.tiles[x][y].anim.y = self.tiles[x][y].anim.y + (self.tiles[x][y].anim.velocityY*60*dt)
                    if (self.tiles[x][y].anim.y < Y) then
                        self.tiles[x][y].anim.y = Y
                        self.tiles[x][y].anim.velocityY = 0
                    end
                --Otherwise must be in correct position (y)
                else
                    done = done + 1
                end
            end
        end
        --Increase size of "remover" slowly
        self.tiles[self.obX][self.obY].anim.size = self.tiles[self.obX][self.obY].anim.size + dt/3

        --When all tiles are finished moving, move onto the next step
        if (done == self.grid_size*self.grid_size*2) then
            self.state = "postobliterate"
        end

    --Grow and explode
    elseif (self.state == "postobliterate") then
        -- Enlarge image
        if (self.tiles[self.obX][self.obY].anim.size < 3.5) then
            self.tiles[self.obX][self.obY].anim.size = self.tiles[self.obX][self.obY].anim.size + 15*dt
        -- Once large enough, actually remove , etc...
        else
            -- Remove all tiles
            for i=1,self.grid_size do
                for j=1,self.grid_size do
                    --Add score
                    if (i == self.obX and j == self.obY) then
                        self.tiles[i][j].anim.colour = {1,1,1}
                        self:addScore(250*(self.grid_size*self.grid_size),0,i,j)
                    end
                    --Add particles
                    self:addParticles(self.obX,self.obY,5,10,self.tiles[i][j].anim.colour,true)
                    self.tiles[i][j] = new_placeholder()
                end
            end
            -- Need to recheck the board for new tiles to spawn
            self.doCheck = true
            self.state = "normal"
            -- Delete vars
            self.obX = nil
            self.obY = nil
        end
    end

    --Animations independent of game state
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            -- Shrink/disappear on 'animtiles'
            if (self.animtiles[x][y] ~= nil) then
                self.animtiles[x][y].anim.size = self.animtiles[x][y].anim.size - (6*dt)
                if (self.animtiles[x][y].anim.size < 0) then
                    self.animtiles[x][y] = nil
                end
            end

            --Score animation
            if (self.animscore[x][y] ~= nil) then
                self.animscore[x][y].offset = self.animscore[x][y].offset - (0.5*dt)
                if (self.animscore[x][y].offset < -0.4) then
                    self.animscore[x][y].alpha = self.animscore[x][y].alpha - (3*dt)
                    if (self.animscore[x][y].alpha < 0) then
                        self.animscore[x][y] = nil
                    end
                end
            end

            --Glow on explosion powerup
            if (self.tiles[x][y].type == "explosion" or self.tiles[x][y].type == "remover") then
                if (self.tiles[x][y].anim.glowOn) then
                    self.tiles[x][y].anim.glow = self.tiles[x][y].anim.glow + dt/2
                    if (self.tiles[x][y].anim.glow > 1.2) then
                        self.tiles[x][y].anim.glowOn = false
                    end
                else
                    self.tiles[x][y].anim.glow = self.tiles[x][y].anim.glow - dt/2
                    if (self.tiles[x][y].anim.glow < 0.3) then
                        self.tiles[x][y].anim.glowOn = true
                    end
                end
            end
        end
    end

    --Animate particles
    for k, v in pairs(self.animparticles) do
        if (v.y > 720) then
            table.remove(self.animparticles,k)
        else
            v.x = v.x + (v.vx*60*dt)
            v.y = v.y + (v.vy*60*dt)
            if (v.vx < 0) then
                v.vx = v.vx + (10*dt)
            else
                v.vx = v.vx - (10*dt)
            end
            v.vy = v.vy + (30*dt)
        end
    end

    --Remover colour changing animation
    self.removerTime = self.removerTime + dt
    self.removerColour[1] = math.sin(self.removerTime + 0) * 0.5 + 0.5
    self.removerColour[2] = math.sin(self.removerTime + 2) * 0.5 + 0.5
    self.removerColour[3] = math.sin(self.removerTime + 4) * 0.5 + 0.5

    --Selector animation things
    self.selector.time = self.selector.time + dt
    self.selector.size = 0.95 + 0.05*math.sin((self.selector.time*math.pi))
    --Move selector when held down
    self.selector.holdtime = self.selector.holdtime + dt
    if (self.selector.holdtime > 0.15 and self.selector.status == "hover") then
        if (self.selector.held.right and self.selector.x < self.grid_size) then
            self.selector.x = self.selector.x + 1
            self.selector.holdtime = 0
        end
        if (self.selector.held.left and self.selector.x > 1) then
            self.selector.x = self.selector.x - 1
            self.selector.holdtime = 0
        end
        if (self.selector.held.up and self.selector.y > 1) then
            self.selector.y = self.selector.y - 1
            self.selector.holdtime = 0
        end
        if (self.selector.held.down and self.selector.y < self.grid_size) then
            self.selector.y = self.selector.y + 1
            self.selector.holdtime = 0
        end
    end
    --Fade out animation
    if (self.selector.status == "fadeout") then
        self.selector.alpha = self.selector.alpha - (5.5*dt)
        if (self.selector.alpha < 0) then
            self.selector.alpha = 0
            self.selector.active = false
            self.selector.status = "hover"
        end
    --Fade in animation
    elseif (self.selector.status == "fadein") then
        self.selector.alpha = self.selector.alpha + (6.5*dt)
        if (self.selector.alpha > 1) then
            self.selector.alpha = 1
            self.selector.status = "hover"
        end
    end

    --Analyse the board if required
    if (self.isAnimated == true) then
        self.doCheck = true
    end
    if (self.doCheck == true and self.isAnimated == false) then
        local inc = self:analyse()
        if (inc == false) then
            self.score_multiplier = 1
            self.match_number = 1
            -- If no matches shuffle the board
            if (not self:hasMatch()) then
                self.state = "preshuffle"
            end
        end
        self.doCheck = false
    end
end

-- Draw the board with (self.x,self.y) being the top left corner
function Board:draw()
    --Setup coordinates
    love.graphics.push("all")
    love.graphics.translate(self.x,self.y)

    --Draw grid background
    love.graphics.setColor(1,1,1,0.7)
    love.graphics.draw(self.gridCanvas,0,0)

    --Draw border
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(ui_boarder,-20*(self.size/(ui_boarder:getWidth()-40)),-20*(self.size/(ui_boarder:getHeight()-40)),0,(self.size/(ui_boarder:getWidth()-40)),self.size/(ui_boarder:getHeight()-40))

    --Loop over each grid square and draw stuff ;)
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            --Draw shrinking animations first
            if (self.animtiles[x][y] ~= nil) then
                centeredImage(self.animtiles[x][y].img,(x-0.5+self.animtiles[x][y].anim.x)*self.grid_size_px,(y-0.5+self.animtiles[x][y].anim.y)*self.grid_size_px,self.animtiles[x][y].anim.size*(self.grid_size_px/self.animtiles[x][y].img:getWidth()),self.animtiles[x][y].anim.size*(self.grid_size_px/self.animtiles[x][y].img:getHeight()))
            end
            --Draw tiles
            if (self.tiles[x][y].img ~= nil) then
                if (self.tiles[x][y].type == "remover") then
                    love.graphics.setColor(self.removerColour[1],self.removerColour[2],self.removerColour[3],1)
                else
                    love.graphics.setColor(1,1,1,1)
                end
                centeredImage(self.tiles[x][y].img,(x-0.5+self.tiles[x][y].anim.x)*(self.grid_size_px),(y-0.5+self.tiles[x][y].anim.y)*(self.grid_size_px),self.tiles[x][y].anim.size*(self.grid_size_px/self.tiles[x][y].img:getWidth()),self.tiles[x][y].anim.size*(self.grid_size_px/self.tiles[x][y].img:getHeight()))
                --Draw glow
                if (self.tiles[x][y].type ~= nil) then
                    love.graphics.setColor(1,1,1,self.tiles[x][y].anim.glow)
                    centeredImage(tile_glow,(x-0.5+self.tiles[x][y].anim.x)*self.grid_size_px,(y-0.5+self.tiles[x][y].anim.y)*self.grid_size_px,1.2*(self.grid_size_px/tile_glow:getWidth()),1.2*(self.grid_size_px/tile_glow:getHeight()))
                end
            end
            --Draw 'replacetile'
            if (self.replacetile[x][y] ~= nil) then
                if (self.replacetile[x][y].type == "remover") then
                    love.graphics.setColor(self.removerColour[1],self.removerColour[2],self.removerColour[3],1)
                else
                    love.graphics.setColor(1,1,1,1)
                end
                centeredImage(self.replacetile[x][y].img,(x-0.5+self.replacetile[x][y].anim.x)*(self.grid_size_px),(y-0.5+self.replacetile[x][y].anim.y+self.replacetile[x][y].anim.y)*(self.grid_size_px),self.replacetile[x][y].anim.size*(self.grid_size_px/self.replacetile[x][y].img:getWidth()),self.replacetile[x][y].anim.size*(self.grid_size_px/self.replacetile[x][y].img:getHeight()))
            end
            --Draw selectors
            if (self.tiles[x][y].anim.status == "swap") then
                love.graphics.setColor(0.8,0.8,0.8,self.selector.alpha)
                centeredImage2(tile_select,self.grid_size_px*(self.tiles[x][y].anim.x+x-0.5),self.grid_size_px*(self.tiles[x][y].anim.y+y-0.5),0.85)
            end
            --Draw lasers
            if (self.animlaser[x][y].vertical) then
                love.graphics.setColor(self.animlaser[x][y].colourV[1]+0.4,self.animlaser[x][y].colourV[2]+0.4,self.animlaser[x][y].colourV[3]+0.4,1)
                centeredImage(_G["tile_laser_vertical_"..self.animlaser[x][y].sizeV],(x-0.5)*(self.grid_size_px),(y-0.5)*(self.grid_size_px),self.grid_size_px/100,self.grid_size_px/100)
                love.graphics.setColor(self.animlaser[x][y].colourV[1],self.animlaser[x][y].colourV[2],self.animlaser[x][y].colourV[3],1)
                centeredImage(_G["tile_laser_vertical_glow_"..self.animlaser[x][y].sizeV],(x-0.5)*(self.grid_size_px),(y-0.5)*(self.grid_size_px),self.grid_size_px/100,self.grid_size_px/100)
            end
            if (self.animlaser[x][y].horizontal) then
                love.graphics.setColor(self.animlaser[x][y].colourH[1]+0.4,self.animlaser[x][y].colourH[2]+0.4,self.animlaser[x][y].colourH[3]+0.4,1)
                centeredImage(_G["tile_laser_horizontal_"..self.animlaser[x][y].sizeH],(x-0.5)*(self.grid_size_px),(y-0.5)*(self.grid_size_px),self.grid_size_px/100,self.grid_size_px/100)
                love.graphics.setColor(self.animlaser[x][y].colourH[1],self.animlaser[x][y].colourH[2],self.animlaser[x][y].colourH[3],1)
                centeredImage(_G["tile_laser_horizontal_glow_"..self.animlaser[x][y].sizeH],(x-0.5)*(self.grid_size_px),(y-0.5)*(self.grid_size_px),self.grid_size_px/100,self.grid_size_px/100)
            end
            --Draw scores
            if (self.animscore[x][y] ~= nil) then
                love.graphics.setColor(self.animscore[x][y].col[1],self.animscore[x][y].col[2],self.animscore[x][y].col[3],self.animscore[x][y].alpha)
                local i,j=0,0
                --Find total width of number
                for digit in string.gmatch(self.animscore[x][y].pts, "%d") do
                    j = j + _G["font_VGERBold_"..digit]:getWidth()
                end
                --Vars reduce calculations
                local X = round(self.grid_size_px*(x-0.5)-(j/2))
                local Y = round(self.grid_size_px*(y-0.5+self.animscore[x][y].offset)-(font_VGERBold_0:getHeight()/2))
                --Draw each character
                for digit in string.gmatch(self.animscore[x][y].pts, "%d") do
                    love.graphics.draw(_G["font_VGERBold_"..digit],X+i,Y)
                    i = i + _G["font_VGERBold_"..digit]:getWidth()
                end
                love.graphics.setColor(1,1,1,1)
            end
        end
    end

    --Draw hint
    if (self.hint.draw) then
        love.graphics.setColor(1,1,1,self.hint.alpha)
        centeredImage(tile_hint,(self.hint.x-0.5)*self.grid_size_px,(self.hint.y-self.hint.offset-0.5)*self.grid_size_px,self.grid_size_px/tile_hint:getWidth(),self.grid_size_px/tile_hint:getHeight())
    end

    --Draw shuffling message
    if (self.state == "preshuffle" or self.state == "postshuffle") then
        love.graphics.setColor(1,1,1,self.shuffle_alpha)
        centeredImage(ui_shuffle,self.grid_size_px*self.grid_size/2,self.grid_size_px*self.grid_size/2,self.size/ui_shuffle:getWidth())
    end

    --Draw obliterate animations
    if (self.state == "preobliterate" or self.state == "postobliterate") then
        love.graphics.setColor(self.removerColour[1],self.removerColour[2],self.removerColour[3],1)
        centeredImage(tile_remover,(self.obX-0.5)*self.grid_size_px,(self.obY-0.5)*self.grid_size_px,self.tiles[self.obX][self.obY].anim.size*(self.grid_size_px/tile_remover:getWidth()),self.tiles[self.obX][self.obY].anim.size*(self.grid_size_px/tile_remover:getHeight()))
        love.graphics.setColor(1,1,1,self.tiles[self.obX][self.obY].anim.glow)
        centeredImage(tile_glow,(self.obX-0.5)*self.grid_size_px,(self.obY-0.5)*self.grid_size_px,1.2*(self.grid_size_px/tile_glow:getWidth()),1.2*(self.grid_size_px/tile_glow:getHeight()))
    end

    --Draw selector(s)
    if (self.selector.active) then
        --Draw 'main' selector
        love.graphics.setColor(1,1,1,self.selector.alpha)
        if (self.selector.status == "selected") then
            self.selector.size = 0.85
            love.graphics.setColor(0.8,0.8,0.8,self.selector.alpha)
        end
        centeredImage2(tile_select,self.grid_size_px*(self.selector.x-0.5),self.grid_size_px*(self.selector.y-0.5),self.selector.size)
        --If selected draw the second selection
        if (self.selector.status == "selected") then
            love.graphics.setColor(1,1,1,self.selector.alpha)
            centeredImage2(tile_select,self.grid_size_px*(self.selector.x2-0.5),self.grid_size_px*(self.selector.y2-0.5),self.selector.size)
        end
    end

    --Draw particles
    for k, v in pairs(self.animparticles) do
        love.graphics.setColor(v.col[1],v.col[2],v.col[3],1)
        love.graphics.draw(_G["tile_particle_"..v.img],v.x,v.y)
    end

    --Pop old coordinates
    love.graphics.pop()
end

-- Return true if a match is formed at (x,y) or false otherwise
function Board:matchAt(x,y)
    local col = self.tiles[x][y].colour
    if (col == "invisible") then
        return false, {X = 0, Y = 0}
    end
    local numX, numY = 1, 1
    local i = 0
    --Check horizontally to the left
    if (x > 1) then
        i = x-1
        while (self.tiles[i][y].colour == col and self.tiles[i][y].anim.y == 0) do
            i = i - 1
            numX = numX + 1
            if (i < 1) then break end
        end
    end
    --Check horizontally to the right
    if (x < self.grid_size) then
    i = x+1
        while (self.tiles[i][y].colour == col and self.tiles[i][y].anim.y == 0) do
            i = i + 1
            numX = numX + 1
            if (i > self.grid_size) then break end
        end
    end
    --Check vertically upwards
    if (y > 1) then
        i = y-1
        while (self.tiles[x][i].colour == col and self.tiles[x][i].anim.y == 0) do
            i = i - 1
            numY = numY + 1
            if (i < 1) then break end
        end
    end
    --Check vertically downwards
    if (y < self.grid_size) then
        i = y+1
        while (self.tiles[x][i].colour == col and self.tiles[x][i].anim.y == 0) do
            i = i + 1
            numY = numY + 1
            if (i > self.grid_size) then break end
        end
    end
    --Return if there is a match!!
    if (numX > 2 or numY > 2) then
        return true, {X = numX, Y = numY}
    else
        return false, {X = numX, Y = numY}
    end
end

--Handles stuff when the gamepad event is passed
function Board:gamepadPressed(button)
    --Activate if necessary
    if (not self.selector.active) then
        self.selector.active = true
        self.selector.status = "fadein"
        return
    end
    --If a is not held (ie selecting instead of 'swiping')
    if (not self.selector.held.a) then
        --Move selector (or second) right
        if (button == "dpright" and self.selector.x < self.grid_size) then
            if (self.selector.status == "selected") then
                if (self.selector.x2 < self.selector.x + 1 and self.selector.y2 == self.selector.y) then
                    self.selector.x2 = self.selector.x2 + 1
                end
            else
                self.selector.x = self.selector.x + 1
                self.selector.held.right = true
                self.selector.holdtime = -0.1
            end
        --Move selector (or second) left
        elseif (button == "dpleft" and self.selector.x > 1) then
            if (self.selector.status == "selected") then
                if (self.selector.x2 > self.selector.x - 1 and self.selector.y2 == self.selector.y) then
                    self.selector.x2 = self.selector.x2 - 1
                end
            else
                self.selector.x = self.selector.x - 1
                self.selector.held.left = true
                self.selector.holdtime = -0.1
            end
        --Move selector (or second) up
        elseif (button == "dpup" and self.selector.y > 1) then
            if (self.selector.status == "selected") then
                if (self.selector.y2 > self.selector.y - 1 and self.selector.x2 == self.selector.x) then
                    self.selector.y2 = self.selector.y2 - 1
                end
            else
                self.selector.y = self.selector.y - 1
                self.selector.held.up = true
                self.selector.holdtime = -0.1
            end
        --Move selector (or second) down
        elseif (button == "dpdown" and self.selector.y < self.grid_size) then
            if (self.selector.status == "selected") then
                if (self.selector.y2 < self.selector.y + 1 and self.selector.x2 == self.selector.x) then
                    self.selector.y2 = self.selector.y2 + 1
                end
            else
                self.selector.y = self.selector.y + 1
                self.selector.held.down = true
                self.selector.holdtime = -0.1
            end
        --Simulate touch on tile
        elseif (button == "a") then
            self.selector.held.a = true
            self:pressed("gamepad",self.x+self.selector.x*self.grid_size_px,self.y+self.selector.y*self.grid_size_px)
        end
    --Else if a is held ('swiping') move second selector to appropriate side
    else
        if (button == "dpright" and self.selector.x < self.grid_size) then
            self.selector.x2 = self.selector.x + 1
            self.selector.y2 = self.selector.y
        elseif (button == "dpleft" and self.selector.x > 1) then
            self.selector.x2 = self.selector.x - 1
            self.selector.y2 = self.selector.y
        elseif (button == "dpup" and self.selector.y > 1) then
            self.selector.y2 = self.selector.y - 1
            self.selector.x2 = self.selector.x
        elseif (button == "dpdown" and self.selector.y < self.grid_size) then
            self.selector.y2 = self.selector.y + 1
            self.selector.x2 = self.selector.x
        end
    end
end

--Handles stuff when the gamepad event is passed
function Board:gamepadReleased(button)
    --Release all held variables
    if (button == "dpright") then
        self.selector.held.right = false
    elseif (button == "dpleft") then
        self.selector.held.left = false
    elseif (button == "dpup") then
        self.selector.held.up = false
    elseif (button == "dpdown") then
        self.selector.held.down = false
    elseif (button == "a") then
        self.selector.held.a = false
        --If not 'pressing' on the selector, simulate press
        if (self.selector.x ~= self.selector.x2 or self.selector.y ~= self.selector.y2) then
            self:released("gamepad",self.x+self.selector.x2*self.grid_size_px,self.y+self.selector.y2*self.grid_size_px)
        else
            self:released("gamepad",self.x+self.selector.x*self.grid_size_px,self.y+self.selector.y*self.grid_size_px)
        end
    elseif (button == "b") then
        --Use b to cancel a selection
        if (self.selector.status == "selected") then
            self.selector.status = "hover"
            self.selector.x = self.selector.x2
            self.selector.y = self.selector.y2
            self.id = nil
        end
    end
end

--Handles stuff when the board is pressed
function Board:pressed(id,absX,absY)
    --self.id is used to prevent multiple touches on the board
    if (self.id == nil) then
        self.id = id
    end
    if (id == self.id) then
        if (absX < self.x or absY < self.y or absX > (self.x + self.size) or absY > (self.y + self.size) or self.doCheck) then
            self.touch_start = nil
            return
        end
        --Store coordinates of touch
        self.touch_start = {}
        self.touch_start.x = (absX-self.x)
        self.touch_start.y = (absY-self.y)
        self.touch_start.tx = math.ceil(self.touch_start.x/(self.size/self.grid_size))
        self.touch_start.ty = math.ceil(self.touch_start.y/(self.size/self.grid_size))

        --Place selector
        if (self.selector.status == "hover") then
            self.selector.active = true
            self.selector.status = "selected"
            self.selector.alpha = 1
            self.selector.x = self.touch_start.tx
            self.selector.y = self.touch_start.ty
            self.selector.x2 = self.selector.x
            self.selector.y2 = self.selector.y
        elseif (self.selector.status == "selected") then
            --Unselect if selecting selector ;)
            if (self.touch_start.tx == self.selector.x and self.touch_start.ty == self.selector.y and self.selector.x == self.selector.x2 and self.selector.y == self.selector.y2) then
                if (self.id == "gamepad") then
                    self.selector.status = "hover"
                else
                    self.selector.status = "fadeout"
                end
            elseif (self.id ~= "gamepad") then
                --Check if the selector can be moved based on press location
                local check = {{1,0},{-1,0},{0,1},{0,-1}} --(coords from selector)
                local move = true
                for i=1,#check do
                    local X = self.selector.x+check[i][1]
                    local Y = self.selector.y+check[i][2]
                    if (X < 1 or X > self.grid_size or Y < 1 or Y > self.grid_size) then
                    else
                        if (self.touch_start.tx == X and self.touch_start.ty == Y and self.selector.status) then
                            move = false
                        end
                    end
                end
                --Move the selector if allowed
                if (move) then
                    self.selector.x = self.touch_start.tx
                    self.selector.y = self.touch_start.ty
                    self.selector.x2 = self.selector.x
                    self.selector.y2 = self.selector.y
                end
            end
        end

        --Remove hint if touching the correct square
        if (self.hint.x == self.touch_start.tx) then
            self.hint.show = "no"
        end
    end
end

--Handles stuff when the board is released
function Board:released(id,absX,absY)
    if (id == self.id) then
        if (self.touch_start == nil) then
            return
        end
        --Store coordinates of touch
        self.touch_end = {}
        self.touch_end.x = (absX-self.x)
        self.touch_end.y = (absY-self.y)
        self.touch_end.tx = math.ceil(self.touch_end.x/(self.size/self.grid_size))
        self.touch_end.ty = math.ceil(self.touch_end.y/(self.size/self.grid_size))

        --If pressed (only called from touches)
        if (self.touch_start.tx == self.touch_end.tx and self.touch_start.ty == self.touch_end.ty and self.selector.status == "selected") then
            --Select right
            if (self.touch_end.tx == self.selector.x+1 and self.touch_end.ty == self.selector.y) then
                self:swapTiles(self.touch_end.tx-1,self.touch_end.ty,self.touch_end.tx,self.touch_end.ty,"right")
                self.selector.x = self.selector.x+1
                self.selector.status = "fadeout"
            --Select down
            elseif (self.touch_end.tx == self.selector.x and self.touch_end.ty == self.selector.y+1) then
                self:swapTiles(self.touch_end.tx,self.touch_end.ty-1,self.touch_end.tx,self.touch_end.ty,"down")
                self.selector.y = self.selector.y+1
                self.selector.status = "fadeout"
            --Select left
            elseif (self.touch_end.tx == self.selector.x-1 and self.touch_end.ty == self.selector.y) then
                self:swapTiles(self.touch_end.tx,self.touch_end.ty,self.touch_end.tx+1,self.touch_end.ty,"left")
                self.selector.x = self.selector.x-1
                self.selector.status = "fadeout"
            --Select up
            elseif (self.touch_end.tx == self.selector.x and self.touch_end.ty == self.selector.y-1) then
                self:swapTiles(self.touch_end.tx,self.touch_end.ty,self.touch_end.tx,self.touch_end.ty+1,"up")
                self.selector.y = self.selector.y-1
                self.selector.status = "fadeout"
            end
        --If swiped (not touch and gamepad)
        else
            --Variables used for swipe detection
            local dx = (absX-self.x)-self.touch_start.x
            local dy = (absY-self.y)-self.touch_start.y
            local len = math.floor(math.sqrt(math.pow(dx,2)+math.pow(dy,2)))
            local thr = math.floor(self.size/self.grid_size)/2
            --Swipe up
            if (dy < 0 and self.touch_start.ty > 1) then
                if ( ( (dx >= 0 and math.atan(dx/-dy) < (math.pi/6)) or (dx < 0 and math.atan(dx/-dy) > -(math.pi/6)) ) and (len > thr) ) then
                    self:swapTiles(self.touch_start.tx,self.touch_start.ty-1,self.touch_start.tx,self.touch_start.ty,"up")
                    self.selector.y = self.selector.y-1
                    if (self.id == "gamepad") then
                        self.selector.status = "hover"
                    else
                        self.selector.status = "fadeout"
                    end
                end
            end
            --Swipe down
            if (dy > 0 and self.touch_start.ty < self.grid_size) then
                if ( ( (dx >= 0 and math.atan(dx/-dy) > -(math.pi/6)) or (dx < 0 and math.atan(dx/-dy) < (math.pi/6)) ) and (len > thr) ) then
                    self:swapTiles(self.touch_start.tx,self.touch_start.ty,self.touch_start.tx,self.touch_start.ty+1,"down")
                    self.selector.y = self.selector.y+1
                    if (self.id == "gamepad") then
                        self.selector.status = "hover"
                    else
                        self.selector.status = "fadeout"
                    end
                end
            end
            --Swipe right
            if (dx > 0 and self.touch_start.tx < self.grid_size) then
                if ( ( (dy < 0 and math.atan(-dy/dx) < (math.pi/6)) or (dy >= 0 and math.atan(-dy/dx) > -(math.pi/6)) ) and (len > thr) ) then
                    self:swapTiles(self.touch_start.tx,self.touch_start.ty,self.touch_start.tx+1,self.touch_start.ty,"right")
                    self.selector.x = self.selector.x+1
                    if (self.id == "gamepad") then
                        self.selector.status = "hover"
                    else
                        self.selector.status = "fadeout"
                    end
                end
            end
            --Swipe left
            if (dx < 0 and self.touch_start.tx > 1) then
                if ( ( (dy < 0 and math.atan(-dy/dx) > -(math.pi/6)) or (dy >= 0 and math.atan(-dy/dx) < (math.pi/6)) ) and (len > thr) ) then
                    self:swapTiles(self.touch_start.tx-1,self.touch_start.ty,self.touch_start.tx,self.touch_start.ty,"left")
                    self.selector.x = self.selector.x-1
                    if (self.id == "gamepad") then
                        self.selector.status = "hover"
                    else
                        self.selector.status = "fadeout"
                    end
                end
            end
        end
        self.id = nil
    end
end

--Swap two tiles at the provided coordinates (topleft most, bottomright most)
function Board:swapTiles(x1,y1,x2,y2,dir)
    --If swapping a remover do something slightly different
    if (self.tiles[x1][y1].type == "remover") then
        if (self.tiles[x2][y2].type == "remover") then
            if (dir == "up" or dir == "left") then
                self.obX = x1
                self.obY = y1
            elseif (dir == "down" or dir == "right") then
                self.obX = x2
                self.obY = y2
            end
            self.state = "preobliterate"
        else
            self.tiles[x1][y1].colour = self.tiles[x2][y2].colour
            self.tiles[x1][y1].type2 = self.tiles[x2][y2].type
            self:removeTile(x1,y1)
        end
    elseif (self.tiles[x2][y2].type == "remover") then
        self.tiles[x2][y2].colour = self.tiles[x1][y1].colour
        self.tiles[x2][y2].type2 = self.tiles[x1][y1].type
        self:removeTile(x2,y2)
    else
        --Set animation variables
        self.tiles[x1][y1].anim.x = x1-x2
        self.tiles[x1][y1].anim.y = y1-y2
        self.tiles[x1][y1].anim.status = "swap"
        self.tiles[x2][y2].anim.x = x2-x1
        self.tiles[x2][y2].anim.y = y2-y1
        self.tiles[x2][y2].anim.status = "swap"
        --Actually swap
        local copy = self.tiles[x1][y1]
        self.tiles[x1][y1] = self.tiles[x2][y2]
        self.tiles[x2][y2] = copy
        self.tiles[x1][y1].wasSwapped = true
        self.tiles[x2][y2].wasSwapped = true
   end
end

-- Remove tile at the provided coordinates (actions depend on tile type)
function Board:removeTile(x,y)
    -- Vertical powerup
    if (self.tiles[x][y].type == "vertical") then
        for i=1,self.grid_size do
            -- Add score (and mark as matched) if necessary
            if (self.tiles[x][i].colour ~= "invisible" and not self.tiles[x][i].matched and i ~= y) then
                self:addScore(25,25,x,i)
                self.tiles[x][i].matched = true
                if (self.tiles[x][i].type == "vertical") then
                    self.tiles[x][i].anim.status = "nolaser"
                end
            end
            -- Add particle animations
            if (self.tiles[x][y].anim.status ~= "nolaser") then
                if (self.tiles[x][i].colour == "invisible") then
                    self:addParticles(x,i,15,25,self.tiles[x][y].anim.colour)
                else
                    self:addParticles(x,i,15,25,self.tiles[x][i].anim.colour)
                end
            end
        end
        self.score_multiplier = self.score_multiplier + 1

    -- Horizontal powerup
    elseif (self.tiles[x][y].type == "horizontal") then
        for i=1,self.grid_size do
            -- Add score (and mark as matched) if necessary
            if (self.tiles[i][y].colour ~= "invisible" and not self.tiles[i][y].matched and i ~= x) then
                self:addScore(25,25,i,y)
                self.tiles[i][y].matched = true
                if (self.tiles[i][y].type == "horizontal") then
                    self.tiles[i][y].anim.status = "nolaser"
                end
            end
            -- Add particle animations
            if (self.tiles[x][y].anim.status ~= "nolaser") then
                if (self.tiles[i][y].colour == "invisible") then
                    self:addParticles(i,y,15,25,self.tiles[x][y].anim.colour)
                else
                    self:addParticles(i,y,15,25,self.tiles[i][y].anim.colour)
                end
            end
        end
        self.score_multiplier = self.score_multiplier + 1

    -- Explosion powerup
    elseif (self.tiles[x][y].type == "explosion") then
        -- Add score for explosion only
        self:addScore(250,100,x,y)
        -- Mark surrounding tiles as matched and add particles
        for i=x-1,x+1 do
            for j=y-1,y+1 do
                if (i > 0 and i <= self.grid_size and j > 0 and j <= self.grid_size) then
                    if (self.tiles[i][j].colour ~= "invisible") then
                        self.tiles[i][j].matched = true
                        self:addParticles(i,j,20,30,self.tiles[i][j].anim.colour)
                    else
                        self:addParticles(i,j,20,30,self.tiles[x][y].anim.colour)
                    end
                end
            end
        end
        self.score_multiplier = self.score_multiplier + 1

    -- Remover powerup
    elseif (self.tiles[x][y].type == "remover") then
        -- If the tile has not been swapped, it needs to pick a random colour to remove
        if (self.tiles[x][y].colour == nil) then
            local col = love.math.random(1,7)
            if (col == 1) then
                self.tiles[x][y].colour = "red"
            elseif (col == 2) then
                self.tiles[x][y].colour = "orange"
            elseif (col == 3) then
                self.tiles[x][y].colour = "yellow"
            elseif (col == 4) then
                self.tiles[x][y].colour = "green"
            elseif (col == 5) then
                self.tiles[x][y].colour = "blue"
            elseif (col == 6) then
                self.tiles[x][y].colour = "purple"
            elseif (col == 7) then
                self.tiles[x][y].colour = "white"
            end
        end
        -- Set animation colour to match "colour" of remover
        if (self.tiles[x][y].colour == "red") then
            self.tiles[x][y].anim.colour = {1,0.3,0.3}
        elseif (self.tiles[x][y].colour == "orange") then
            self.tiles[x][y].anim.colour = {1,0.5,0.3}
        elseif (self.tiles[x][y].colour == "yellow") then
            self.tiles[x][y].anim.colour = {1,1,0.3}
        elseif (self.tiles[x][y].colour == "green") then
            self.tiles[x][y].anim.colour = {0.2,1,0.4}
        elseif (self.tiles[x][y].colour == "blue") then
            self.tiles[x][y].anim.colour = {0.2,0.4,1}
        elseif (self.tiles[x][y].colour == "purple") then
            self.tiles[x][y].anim.colour = {0.9,0.3,1}
        elseif (self.tiles[x][y].colour == "white") then
            self.tiles[x][y].anim.colour = {1,1,1}
        end
        -- Search the board and remove all of the same colour!
        for i=1,self.grid_size do
            for j=1,self.grid_size do
                if (i == x and j == y) then
                    self:addScore(500,100,x,y)
                else
                    if (self.tiles[i][j].colour == self.tiles[x][y].colour) then
                        --Change tiles type if matched with a powerup
                        if (self.tiles[x][y].type2 ~= nil) then
                            self.tiles[i][j].type = self.tiles[x][y].type2
                        end
                        --If normal tile destroyed, add score
                        if (self.tiles[i][j].type == nil) then
                            self:addScore(200,50,i,j)
                            self:addParticles(i,j,15,20,self.tiles[x][y].anim.colour)
                        end
                        self.tiles[i][j].matched = true
                    end
                end
            end
        end
        self.score_multiplier = self.score_multiplier + 1
    end

    --Replace with placeholder or tile depending on situation
    if (self.replacetile[x][y] ~= nil) then
        self.tiles[x][y] = copyTable(self.replacetile[x][y])
        self.replacetile[x][y] = nil
    else
        self.tiles[x][y] = new_placeholder()
    end

    --Reset hint
    self.hint.show = "no"
end

--Called to analyse the board for matches
function Board:analyse()
    --hasMatch can be used to determine if the current 'turn' is over
    local hasMatch = false
    -- Start by checking for any combinations which should create an "explosion" powerup
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            local isMatch, num = self:matchAt(x,y)
            if (num.X > 2 and num.Y > 2 and num.X < 5 and num.Y < 5 and not self.tiles[x][y].matched) then
                hasMatch = true
                -- A powerup should be placed at this location, mark all involved tiles for removal :D
                local col = self.tiles[x][y].colour
                self.tiles[x][y].matched = true
                self.replacetile[x][y] = new_tile(col, "explosion")
                self:addScore(250,100,x,y)
                self.tiles[x][y].analyzed = true
                -- Check -x
                local a = x-1
                while (a > 0) do
                    if (self.tiles[a][y].colour == self.tiles[x][y].colour) then
                        self.tiles[a][y].matched = true
                        self.tiles[a][y].analyzed = true
                        a = a - 1
                    else
                        break
                    end
                end
                -- Check +x
                local a = x+1
                while (a < self.grid_size+1) do
                    if (self.tiles[a][y].colour == self.tiles[x][y].colour) then
                        self.tiles[a][y].matched = true
                        self.tiles[a][y].analyzed = true
                        a = a + 1
                    else
                        break
                    end
                end
                -- Check -y
                local a = y-1
                while (a > 0) do
                    if (self.tiles[x][a].colour == self.tiles[x][y].colour) then
                        self.tiles[x][a].matched = true
                        self.tiles[x][a].analyzed = true
                        a = a - 1
                    else
                        break
                    end
                end
                -- Check +y
                local a = y+1
                while (a < self.grid_size+1) do
                    if (self.tiles[x][a].colour == self.tiles[x][y].colour) then
                        self.tiles[x][a].matched = true
                        self.tiles[x][a].analyzed = true
                        a = a + 1
                    else
                        break
                    end
                end
                -- playEffect("match"..self.match_number)
                if (self.match_number < 5) then
                    self.match_number = self.match_number
                end
                self.score_multiplier = self.score_multiplier + 1
            end
        end
    end
    -- And end by checking for all other types of matches
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            -- If a placeholder is here, adjust tiles as required
            if (self.tiles[x][y].colour == "invisible") then
                hasMatch = "?" --Can be anything but true or false so multiplier doesn't increase
                -- Shift each row down
                for j=y-1,1,-1 do
                    self.tiles[x][j+1] = self.tiles[x][j]
                    self.tiles[x][j+1].anim.y = self.tiles[x][j+1].anim.y - 1
                    self.tiles[x][j+1].anim.status = "falling"
                end
                -- Insert new tile
                self.tiles[x][1] = new_tile()
                self.tiles[x][1].anim.y = self.tiles[x][2].anim.y - 1.2
                self.tiles[x][1].anim.status = "falling"
            elseif (self.tiles[x][y].type == "remover" and (self.tiles[x][y].colour ~= nil or self.tiles[x][y].type2 == "obliterate")) then
                hasMatch = true
                self.tiles[x][y].matched = true
                self.score_multiplier = self.score_multiplier + 1
            else
                -- Check for match
                local isMatch, num = self:matchAt(x,y)
                if (isMatch and not self.tiles[x][y].analyzed) then
                    hasMatch = true
                    -- Remover powerup
                    if (num.X > 4) then
                        -- Determine if result of swap or random falling
                        local swp = false
                        for a=x,x+num.X-1 do
                            self.tiles[a][y].matched = true
                            if (self.tiles[a][y].wasSwapped) then
                                local typ = self.tiles[a][y].type
                                self.tiles[a][y].matched = true
                                self.replacetile[a][y] = new_tile(nil,"remover",typ)
                                self:addScore(300,300,a,y)
                                swp = true
                            end
                            self.tiles[a][y].analyzed = true
                        end
                        -- If not due to swap, place powerup randomly
                        if (not swp) then
                            local c = x+love.math.random(0,num.X)
                            if (c > self.grid_size) then
                                c = self.grid_size
                            end
                            local typ = self.tiles[c][y].type
                            self.tiles[c][y].matched = true
                            self.replacetile[c][y] = new_tile(nil,"remover",typ)
                            self:addScore(300,300,c,y)
                            self.tiles[c][y].analyzed = true
                        end
                    elseif (num.Y > 4) then
                        -- Determine if result of swap or random falling
                        local swp = false
                        for a=y,y+num.Y-1 do
                            self.tiles[x][a].matched = true
                            if (self.tiles[x][a].wasSwapped) then
                                local typ = self.tiles[x][a].type
                                self.tiles[x][a].matched = true
                                self.replacetile[x][a] = new_tile(nil,"remover",typ)
                                self:addScore(300,300,x,a)
                                swp = true
                            end
                            self.tiles[x][a].analyzed = true
                        end
                        -- If not due to swap, place powerup randomly
                        if (not swp) then
                            local c = y+love.math.random(0,num.Y)
                            if (c > self.grid_size) then
                                c = self.grid_size
                            end
                            local typ = self.tiles[x][c].type
                            self.tiles[x][c].matched = true
                            self.replacetile[x][c] = new_tile(nil,"remover",typ)
                            self:addScore(300,300,x,c)
                            self.tiles[x][c].analyzed = true
                        end

                    -- Horizontal powerup
                    elseif (num.Y == 4) then
                        -- Determine if result of swap or random falling
                        local swp = false
                        for a=y,y+3 do
                            self.tiles[x][a].matched = true
                            if (self.tiles[x][a].wasSwapped) then
                                local col = self.tiles[x][a].colour
                                self.tiles[x][a].matched = true
                                self.replacetile[x][a] = new_tile(col,"horizontal")
                                self:addScore(200,200,x,a)
                                swp = true
                            end
                            self.tiles[x][a].analyzed = true
                        end
                        -- If not due to swap, place powerup randomly
                        if (not swp) then
                            local c = y+love.math.random(0,3)
                            local col = self.tiles[x][c].colour
                            self.tiles[x][c].matched = true
                            self.replacetile[x][c] = new_tile(col,"horizontal")
                            self:addScore(200,200,x,c)
                            self.tiles[x][c].analyzed = true
                        end

                    -- Vertical powerup
                    elseif (num.X == 4) then
                        -- Determine if result of swap or random falling
                        local swp = false
                        for a=x,x+3 do
                            self.tiles[a][y].matched = true
                            if (self.tiles[a][y].wasSwapped) then
                                local col = self.tiles[a][y].colour
                                self.tiles[a][y].matched = true
                                self.replacetile[a][y] = new_tile(col,"vertical")
                                self:addScore(200,200,a,y)
                                swp = true
                            end
                            self.tiles[a][y].analyzed = true
                        end
                        -- If not due to swap, place powerup randomly
                        if (not swp) then
                            local c = x+love.math.random(0,3)
                            local col = self.tiles[c][y].colour
                            self.tiles[c][y].matched = true
                            self.replacetile[c][y] = new_tile(col,"vertical")
                            self:addScore(200,200,c,y)
                            self.tiles[c][y].analyzed = true
                        end

                    -- Else if normal match of 3 just remove :D
                    elseif (num.X == 3) then
                        for i=0,2,1 do
                            self.tiles[x+i][y].matched = true
                            self.tiles[x+i][y].analyzed = true
                        end
                        self:addScore(100,100,x+1,y)
                    elseif (num.Y == 3) then
                        for i=0,2,1 do
                            self.tiles[x][y+i].matched = true
                            self.tiles[x][y+i].analyzed = true
                        end
                        self:addScore(100,100,x,y+1)
                    end
                    -- playEffect("match"..self.match_number)
                    if (self.match_number < 5) then
                        self.match_number = self.match_number + 1
                    end
                    self.score_multiplier = self.score_multiplier + 1
                end
                -- Reset vars
                self.tiles[x][y].wasSwapped = false
                self.tiles[x][y].wasSwapped = false
                self.tiles[x][y].anim.velocity = 0
            end
        end
    end

    -- Reset "analyzed" variable prior to next analysis
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            self.tiles[x][y].analyzed = false
        end
    end

    return hasMatch
end

--Called to determine if matches are available (returns boolean and x,y of a match if there is one)
function Board:hasMatch()
    --Case 1: horizontal consecutive
    local check = {{-1,-1},{-2,0},{-1,1},{2,-1},{3,0},{2,1}} --(coords from left tile)
    for x=1,self.grid_size-1 do
        for y=1,self.grid_size do
            if (self.tiles[x][y].colour == self.tiles[x+1][y].colour) then
                --Check adjacent tiles
                for i=1,#check do
                    local X = x+check[i][1]
                    local Y = y+check[i][2]
                    if (X < 1 or X > self.grid_size or Y < 1 or Y > self.grid_size) then
                    else
                        if (self.tiles[x][y].colour == self.tiles[X][Y].colour) then
                            return true, X, Y
                        end
                    end
                end
            end
        end
    end
    --Case 2: vertical consecutive
    local check = {{-1,-1},{1,-1},{0,-2},{1,2},{-1,2},{0,3}} --(coords from top tile)
    for x=1,self.grid_size do
        for y=1,self.grid_size-1 do
            if (self.tiles[x][y].colour == self.tiles[x][y+1].colour) then
                --Check adjacent tiles
                for i=1,#check do
                    local X = x+check[i][1]
                    local Y = y+check[i][2]
                    if (X < 1 or X > self.grid_size or Y < 1 or Y > self.grid_size) then
                    else
                        if (self.tiles[x][y].colour == self.tiles[X][Y].colour) then
                            return true, X, Y
                        end
                    end
                end
            end
        end
    end
    --Case 3: horizontal adjacent
    local check = {{1,-1},{1,1}} --(coords from left tile)
    for x=1,self.grid_size-2 do
        for y=1,self.grid_size do
            if (self.tiles[x][y].colour == self.tiles[x+2][y].colour) then
                --Check adjacent tiles
                for i=1,#check do
                    local X = x+check[i][1]
                    local Y = y+check[i][2]
                    if (X < 1 or X > self.grid_size or Y < 1 or Y > self.grid_size) then
                    else
                        if (self.tiles[x][y].colour == self.tiles[X][Y].colour) then
                            return true, X, Y
                        end
                    end
                end
            end
        end
    end
    --Case 4: vertical adjacent
    local check = {{1,1},{-1,1}} --(coords from top tile)
    for x=1,self.grid_size do
        for y=1,self.grid_size-2 do
            if (self.tiles[x][y].colour == self.tiles[x][y+2].colour) then
                --Check adjacent tiles
                for i=1,#check do
                    local X = x+check[i][1]
                    local Y = y+check[i][2]
                    if (X < 1 or X > self.grid_size or Y < 1 or Y > self.grid_size) then
                    else
                        if (self.tiles[x][y].colour == self.tiles[X][Y].colour) then
                            return true, X, Y
                        end
                    end
                end
            end
        end
    end
    --Cases 5+: special gems
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            --Remover present = match
            if (self.tiles[x][y].type == "remover") then
                return true, x, y
            end
        end
    end
    return false, 0, 0
end

--Called to shuffle the board
function Board:shuffle()
    --Copy tiles and wipe table
    local copies = {}
    for x=1,self.grid_size do
        copies[x] = {}
        for y=1,self.grid_size do
            copies[x][y] = copyTable(self.tiles[x][y])
            self.tiles[x][y] = nil
        end
    end

    --Populate table randomly from copies
    local X = self.grid_size
    local Y = self.grid_size
    while (#copies > 0) do
        local ranX
        local ranY
        repeat
            ranX = love.math.random(1,self.grid_size)
            ranY = love.math.random(1,self.grid_size)
        until (self.tiles[ranX][ranY] == nil)
        self.tiles[ranX][ranY] = copyTable(copies[X][Y])
        Y = Y - 1
        if (Y == 0) then
            Y = self.grid_size
            copies[X] = nil
            X = X - 1
        end
    end
end

--Called to add to the score (manages all functions such as multiplier etc)
function Board:addScore(base,plus,x,y)
    --Insert relevant info into table
    local t = {}
    t.pts = base + (plus*(self.score_multiplier-1))
    t.offset = 0
    t.alpha = 1
    t.col = self.tiles[x][y].anim.colour
    self.animscore[x][y] = t
    --Increase score
    self.score = self.score + t.pts
end

--Called to add particles at relevant location
function Board:addParticles(x,y,min,max,colour,big)
    if (not self.showParticles) then
        return
    end
    local num = love.math.random(min,max)
    for a=1,max do
        --Velocity variables
        local VX
        local VY
        if (big) then
            VX = randomFloat(-15,15,2)
            VY = randomFloat(-18,3,2)
        else
            VX = randomFloat(-6,6,2)
            VY = randomFloat(-6,2,2)
        end
        table.insert(self.animparticles,{x = (x-0.5)*self.grid_size_px, y = (y-0.5)*self.grid_size_px, vx = VX, vy = VY, col = colour, img = love.math.random(0,1)})
    end
end