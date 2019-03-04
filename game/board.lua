Board = {}

function Board:new(x,y,grid_size,s)
    self.x = x or 0
    self.y = y or 0
    self.grid_size = grid_size or 8
    self.size = s or height
    --Generate background
    self.grid_image = love.graphics.newCanvas(720,720)
    love.graphics.setCanvas(self.grid_image)
    local sz = 720/self.grid_size
    for i=1,self.grid_size do
        for j=1,self.grid_size do
            if ((i+j)%2 == 0) then
                love.graphics.setColor(0,0,0,1)
            else
                love.graphics.setColor(0.05,0.05,0.05,1)
            end
            love.graphics.rectangle("fill",(i-1)*sz,(j-1)*sz,sz,sz)
        end
    end
    love.graphics.setCanvas()

    --Initalise tile array (and another array for animations)
    self.tiles = {}
    self.animtiles = {}
    for i = 1,self.grid_size do
        self.tiles[i] = {}
        self.animtiles[i] = {}
        for j = 1,self.grid_size do
            self.tiles[i][j] = new_tile()
            self.animtiles[i][j] = nil
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

    --True if there are animations running (don't analyse while running!)
    self.isAnimated = false
    --Obvious
    self.score = 0
end

--Update is literally only used for animations (and analysing when not animating) :D
function Board:update(dt)
    --Animation stuff
    self.isAnimated = false
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            --Falling animation
            if (self.tiles[x][y].anim.offset < 0) then
                self.isAnimated = true
                self.tiles[x][y].anim.velocity = self.tiles[x][y].anim.velocity + (0.4*dt)
                self.tiles[x][y].anim.offset = self.tiles[x][y].anim.offset + self.tiles[x][y].anim.velocity
            end
            if (self.tiles[x][y].anim.offset > 0) then
                self.tiles[x][y].anim.offset = 0
            end
            --Swipe animation
            --x (and swap back)
            if (self.tiles[x][y].anim.swap.x > 0) then
                self.isAnimated = true
                self.tiles[x][y].anim.swap.x = self.tiles[x][y].anim.swap.x - (5*dt)
                if (self.tiles[x][y].anim.swap.x <= 0) then
                    self.tiles[x][y].anim.swap.x = 0
                    --Swap back if no match (x axis)
                    if (not self:matchAt(x,y) and not self:matchAt(x+1,y) and not self.tiles[x][y].anim.swapped and not self.tiles[x+1][y].anim.swapped) then
                        self.tiles[x][y].anim.swap.x = -1
                        self.tiles[x][y].anim.swapped = true
                        self.tiles[x+1][y].anim.swap.x = 1
                        self.tiles[x+1][y].anim.swapped = true
                        self:swapTiles(x,y,x+1,y)
                    end
                end
            end
            --y (and swap back)
            if (self.tiles[x][y].anim.swap.y > 0) then
                self.isAnimated = true
                self.tiles[x][y].anim.swap.y = self.tiles[x][y].anim.swap.y - (5*dt)
                if (self.tiles[x][y].anim.swap.y <= 0) then
                    self.tiles[x][y].anim.swap.y = 0
                    --Swap back if no match (y axis)
                    if (not self:matchAt(x,y) and not self:matchAt(x,y+1) and not self.tiles[x][y].anim.swapped and not self.tiles[x][y+1].anim.swapped) then
                        self.tiles[x][y].anim.swap.y = -1
                        self.tiles[x][y].anim.swapped = true
                        self.tiles[x][y+1].anim.swap.y = 1
                        self.tiles[x][y+1].anim.swapped = true
                        self:swapTiles(x,y,x,y+1)
                    end
                end
            end
            if (self.tiles[x][y].anim.swap.x < 0) then
                self.isAnimated = true
                self.tiles[x][y].anim.swap.x = self.tiles[x][y].anim.swap.x + (5*dt)
                if (self.tiles[x][y].anim.swap.x >= 0) then
                    self.tiles[x][y].anim.swap.x = 0
                end
            end
            if (self.tiles[x][y].anim.swap.y < 0) then
                self.isAnimated = true
                self.tiles[x][y].anim.swap.y = self.tiles[x][y].anim.swap.y + (5*dt)
                if (self.tiles[x][y].anim.swap.y >= 0) then
                    self.tiles[x][y].anim.swap.y = 0
                end
            end
            --Shrink/dissappear animation
            if (self.tiles[x][y].matched == true) then
                self.isAnimated = true
                self.tiles[x][y].anim.size = self.tiles[x][y].anim.size - (6*dt)
                if (self.tiles[x][y].anim.size < 0.5) then
                    self.animtiles[x][y] = copyTable(self.tiles[x][y])
                    self:removeTile(x,y)
                end
            end
            if (self.animtiles[x][y] ~= nil) then
                self.animtiles[x][y].anim.size = self.animtiles[x][y].anim.size - (6*dt)
                if (self.animtiles[x][y].anim.size < 0) then
                    self.animtiles[x][y] = nil
                end
            end
        end
    end
    --Analyse the board if no animation
    if (self.isAnimated == false) then
        self:analyse()
    end
end

-- Draw the board with (self.x,self.y) being the top left corner
function Board:draw()
    --Setup coordinates
    love.graphics.push("all")
    love.graphics.translate(self.x,self.y)
    --Draw grid background
    local sz = self.size/self.grid_image:getWidth()
    love.graphics.setColor(1,1,1,0.7)
    love.graphics.draw(self.grid_image,0,0,0,sz,sz)
    love.graphics.setColor(1,1,1,1)
    --Draw gems
    local sz2 = self.size/self.grid_size
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            --Draw animations first?
            if (self.animtiles[x][y] ~= nil) then
                centeredImage(self.animtiles[x][y].img,(x-0.5+self.animtiles[x][y].anim.swap.x)*(sz2),(y-0.5+self.animtiles[x][y].anim.offset+self.animtiles[x][y].anim.swap.y)*(sz2),self.animtiles[x][y].anim.size*(sz2/self.animtiles[x][y].img:getWidth()),self.animtiles[x][y].anim.size*(sz2/self.animtiles[x][y].img:getHeight()))
            end
            if (self.tiles[x][y].img ~= nil) then
                centeredImage(self.tiles[x][y].img,(x-0.5+self.tiles[x][y].anim.swap.x)*(sz2),(y-0.5+self.tiles[x][y].anim.offset+self.tiles[x][y].anim.swap.y)*(sz2),self.tiles[x][y].anim.size*(sz2/self.tiles[x][y].img:getWidth()),self.tiles[x][y].anim.size*(sz2/self.tiles[x][y].img:getHeight()))
            end
        end
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
        while (self.tiles[i][y].colour == col and self.tiles[i][y].anim.offset == 0) do
            i = i - 1
            numX = numX + 1
            if (i < 1) then break end
        end
    end
    --Check horizontally to the right
    if (x < self.grid_size) then
    i = x+1
        while (self.tiles[i][y].colour == col and self.tiles[i][y].anim.offset == 0) do
            i = i + 1
            numX = numX + 1
            if (i > self.grid_size) then break end
        end
    end
    --Check vertically upwards
    if (y > 1) then
        i = y-1
        while (self.tiles[x][i].colour == col and self.tiles[x][i].anim.offset == 0) do
            i = i - 1
            numY = numY + 1
            if (i < 1) then break end
        end
    end
    --Check vertically downwards
    if (y < self.grid_size) then
        i = y+1
        while (self.tiles[x][i].colour == col and self.tiles[x][i].anim.offset == 0) do
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

--Handles stuff when the board is pressed
function Board:pressed(absX,absY)
    if (self.no_matches) then
        self:shuffle()
        self:analyse()
    end
    if (absX < self.x or absY < self.y or absX > (self.x + self.size) or absY > (self.y + self.size) or self.isAnimated) then
        self.touch_start = nil
        return
    end
    --Store coordinates of touch
    self.touch_start = {}
    self.touch_start.x = (absX-self.x)
    self.touch_start.y = (absY-self.y)
    self.touch_start.tx = math.ceil(self.touch_start.x/(self.size/self.grid_size))
    self.touch_start.ty = math.ceil(self.touch_start.y/(self.size/self.grid_size))
end

--Handles stuff when the board is released
function Board:released(absX,absY)
    if (self.touch_start == nil) then
        return
    end
    --Store coordinates of touch
    self.touch_end = {}
    self.touch_end.x = (absX-self.x)
    self.touch_end.y = (absY-self.y)
    self.touch_end.tx = math.ceil(self.touch_end.x/(self.size/self.grid_size))
    self.touch_end.ty = math.ceil(self.touch_end.y/(self.size/self.grid_size))
    --Variables used for swipe detection
    local dx = (absX-self.x)-self.touch_start.x
    local dy = (absY-self.y)-self.touch_start.y
    local len = math.floor(math.sqrt(math.pow(dx,2)+math.pow(dy,2)))
    local thr = math.floor(self.size/self.grid_size)/2
    --Swipe up
    if (dy < 0 and self.touch_start.ty > 1) then
        if ( ( (dx >= 0 and math.atan(dx/-dy) < (math.pi/6)) or (dx < 0 and math.atan(dx/-dy) > -(math.pi/6)) ) and (len > thr) ) then
            self:swapTiles(self.touch_start.tx,self.touch_start.ty-1,self.touch_start.tx,self.touch_start.ty)
        end
    end
    --Swipe down
    if (dy > 0 and self.touch_start.ty < self.grid_size) then
        if ( ( (dx >= 0 and math.atan(dx/-dy) > -(math.pi/6)) or (dx < 0 and math.atan(dx/-dy) < (math.pi/6)) ) and (len > thr) ) then
            self:swapTiles(self.touch_start.tx,self.touch_start.ty,self.touch_start.tx,self.touch_start.ty+1)
        end
    end
    --Swipe right
    if (dx > 0 and self.touch_start.tx < self.grid_size) then
        if ( ( (dy < 0 and math.atan(-dy/dx) < (math.pi/6)) or (dy >= 0 and math.atan(-dy/dx) > -(math.pi/6)) ) and (len > thr) ) then
            self:swapTiles(self.touch_start.tx,self.touch_start.ty,self.touch_start.tx+1,self.touch_start.ty)
        end
    end
    --Swipe left
    if (dx < 0 and self.touch_start.tx > 1) then
        if ( ( (dy < 0 and math.atan(-dy/dx) > -(math.pi/6)) or (dy >= 0 and math.atan(-dy/dx) < (math.pi/6)) ) and (len > thr) ) then
            self:swapTiles(self.touch_start.tx-1,self.touch_start.ty,self.touch_start.tx,self.touch_start.ty)
        end
    end
end

--Swap two tiles at the provided coordinates (topleft most, bottomright most)
function Board:swapTiles(x1,y1,x2,y2)
    if (self.tiles[x1][y1].type == "remover") then
        self.tiles[x1][y1].colour = self.tiles[x2][y2].colour
        self.tiles[x1][y1].matched = true
    elseif (self.tiles[x2][y2].type == "remover") then
        self.tiles[x2][y2].colour = self.tiles[x1][y1].colour
        self.tiles[x2][y2].matched = true
    else
        --Set animation variables
        self.tiles[x1][y1].anim.swap.x = x1-x2
        self.tiles[x1][y1].anim.swap.y = y1-y2
        self.tiles[x2][y2].anim.swap.x = x2-x1
        self.tiles[x2][y2].anim.swap.y = y2-y1
    --Actually swap
        local copy = self.tiles[x1][y1]
        self.tiles[x1][y1] = self.tiles[x2][y2]
        self.tiles[x2][y2] = copy
        self.tiles[x1][y1].wasSwapped = true
        self.tiles[x2][y2].wasSwapped = true
    end
end

--Delete (remove) tile at the provided coordinates
--VARIES BASED ON TILE TYPE
function Board:removeTile(x,y)
    if (self.tiles[x][y].type == "vertical") then
        for i=1,self.grid_size do
            if (self.tiles[x][i].colour ~= "invisible") then
                self.tiles[x][i].matched = true
            end
        end
    elseif (self.tiles[x][y].type == "horizontal") then
        for i=1,self.grid_size do
            if (self.tiles[i][y].colour ~= "invisible") then
                self.tiles[i][y].matched = true
            end
        end
    elseif (self.tiles[x][y].type == "explosion") then
        for i=x-1,x+1 do
            for j=y-1,y+1 do
                if (i > 0 and i <= self.grid_size and j > 0 and j <= self.grid_size and self.tiles[i][j].colour ~= "invisible") then
                    self.tiles[i][j].matched = true
                end
            end
        end
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
        -- Search the board and remove all of the same colour!
        for i=1,self.grid_size do
            for j=1,self.grid_size do
                if (i == x and j == y) then
                else
                    if (self.tiles[i][j].colour == self.tiles[x][y].colour) then
                        self:removeTile(i,j)
                    end
                end
            end
        end
    end
    --Replace with placeholder
    self.tiles[x][y] = new_placeholder()
end

--Called to analyse the board for matches
function Board:analyse()
    -- Start by checking for any combinations which should create an "explosion" powerup
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            local isMatch, num = self:matchAt(x,y)
            if (num.X > 2 and num.Y > 2 and not self.tiles[x][y].matched) then
                -- A powerup should be placed at this location, mark all involved tiles for removal :D
                self.tiles[x][y] = new_tile(self.tiles[x][y].colour, "explosion")
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
                while (a > self.grid_size+1) do
                    if (self.tiles[x][a].colour == self.tiles[x][y].colour) then
                        self.tiles[x][a].matched = true
                        self.tiles[x][a].analyzed = true
                        a = a + 1
                    else
                        break
                    end
                end
            end
        end
    end
    -- And end by checking for all other types of matches
    local remX, remY = 0,0
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            -- If a placeholder is here, adjust tiles as required
            if (self.tiles[x][y].colour == "invisible") then
                -- Shift each row down
                for j=y-1,1,-1 do
                    self.tiles[x][j+1] = self.tiles[x][j]
                    self.tiles[x][j+1].anim.offset = self.tiles[x][j+1].anim.offset - 1
                end
                -- Insert new tile
                self.tiles[x][1] = new_tile()
                self.tiles[x][1].anim.offset = self.tiles[x][2].anim.offset - 1
            else
                -- Check for match
                local isMatch, num = self:matchAt(x,y)
                if (isMatch and not self.tiles[x][y].analyzed) then
                    -- Remover powerup
                    if (num.X > 4) then
                        -- Determine if result of swap or random falling
                        local swp = false
                        for a=x,x+num.X-1 do
                            self.tiles[a][y].matched = true
                            if (self.tiles[a][y].wasSwapped) then
                                self.tiles[a][y] = new_tile(self.tiles[a][y].colour,"remover")
                                remX, remY = a, y
                                swp = true
                            end
                            self.tiles[a][y].analyzed = true
                        end
                        -- If not due to swap, place powerup randomly
                        if (not swp) then
                            local c = x+love.math.random(0,num.X)
                            self.tiles[c][y] = new_tile(self.tiles[c][y].colour,"remover")
                            remX, remY = c, y
                            self.tiles[c][y].analyzed = true
                        end
                    elseif (num.Y > 4) then
                        -- Determine if result of swap or random falling
                        local swp = false
                        for a=y,y+num.Y-1 do
                            self.tiles[x][a].matched = true
                            if (self.tiles[x][a].wasSwapped) then
                                self.tiles[x][a] = new_tile(self.tiles[x][a].colour,"remover")
                                remX, remY = x, a
                                swp = true
                            end
                            self.tiles[x][a].analyzed = true
                        end
                        -- If not due to swap, place powerup randomly
                        if (not swp) then
                            local c = y+love.math.random(0,num.Y)
                            self.tiles[x][c] = new_tile(self.tiles[x][c].colour,"remover")
                            remX, remY = x, c
                            self.tiles[x][c].analyzed = true
                        end

                    -- Horizontal powerup
                    elseif (num.Y == 4) then
                        -- Determine if result of swap or random falling
                        local swp = false
                        for a=y,y+3 do
                            self.tiles[x][a].matched = true
                            if (self.tiles[x][a].wasSwapped) then
                                self.tiles[x][a] = new_tile(self.tiles[x][a].colour,"horizontal")
                                swp = true
                            end
                            self.tiles[x][a].analyzed = true
                        end
                        -- If not due to swap, place powerup randomly
                        if (not swp) then
                            local c = y+love.math.random(0,3)
                            self.tiles[x][c] = new_tile(self.tiles[x][c].colour,"horizontal")
                            self.tiles[x][c].analyzed = true
                        end

                    -- Vertical powerup
                    elseif (num.X == 4) then
                        -- Determine if result of swap or random falling
                        local swp = false
                        for a=x,x+3 do
                            self.tiles[a][y].matched = true
                            if (self.tiles[a][y].wasSwapped) then
                                self.tiles[a][y] = new_tile(self.tiles[a][y].colour,"vertical")
                                swp = true
                            end
                            self.tiles[a][y].analyzed = true
                        end
                        -- If not due to swap, place powerup randomly
                        if (not swp) then
                            local c = x+love.math.random(0,3)
                            self.tiles[c][y] = new_tile(self.tiles[c][y].colour,"vertical")
                            self.tiles[c][y].analyzed = true
                        end

                    -- Else if normal match of 3 just remove :D
                    else
                        -- Else mark tile for deletion
                        self.tiles[x][y].matched = true
                    end
                end
                -- Reset vars
                self.tiles[x][y].anim.swapped = false
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
    if (remX ~= 0 and remY ~= 0) then
        self.tiles[remX][remY].colour = nil
    end

    --Check if a shuffle is required and do if necessary
    self.no_matches = true
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
                            self.no_matches = false
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
                            self.no_matches = false
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
                            self.no_matches = false
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
                            self.no_matches = false
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
                self.no_matches = false
            end
        end
    end
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