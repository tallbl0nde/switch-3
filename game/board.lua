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
            self.animtiles[i][j] = false
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

    self.tiles[1][2] = new_tile("red")
    self.tiles[2][2] = new_tile("red")
    self.tiles[3][1] = new_tile("red")
    self.tiles[4][1] = new_tile("red")
    self.tiles[3][2] = new_tile("orange")
    self.tiles[4][2] = new_tile("orange")
    self.tiles[6][2] = new_tile("orange")

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
            if (self.animtiles[x][y] ~= false) then
                self.animtiles[x][y].anim.size = self.animtiles[x][y].anim.size - (6*dt)
                if (self.animtiles[x][y].anim.size < 0) then
                    self.animtiles[x][y] = false
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
            centeredImage(self.tiles[x][y].img,(x-0.5+self.tiles[x][y].anim.swap.x)*(sz2),(y-0.5+self.tiles[x][y].anim.offset+self.tiles[x][y].anim.swap.y)*(sz2),self.tiles[x][y].anim.size*(sz2/self.tiles[x][y].img:getWidth()),self.tiles[x][y].anim.size*(sz2/self.tiles[x][y].img:getHeight()))
            if (self.animtiles[x][y] ~= false) then
                centeredImage(self.animtiles[x][y].img,(x-0.5+self.animtiles[x][y].anim.swap.x)*(sz2),(y-0.5+self.animtiles[x][y].anim.offset+self.animtiles[x][y].anim.swap.y)*(sz2),self.animtiles[x][y].anim.size*(sz2/self.animtiles[x][y].img:getWidth()),self.animtiles[x][y].anim.size*(sz2/self.animtiles[x][y].img:getHeight()))
            end
        end
    end
    --Pop old coordinates
    love.graphics.pop()
end

-- Return true if a match is formed at (x,y) or false otherwise
function Board:matchAt(x,y)
    local col = self.tiles[x][y].colour
    local numX, numY = 1, 1
    local i = 0
    --Check horizontally to the left
    if (x > 1) then
        i = x-1
        while (self.tiles[i][y].colour == col) do
            i = i - 1
            numX = numX + 1
            if (i < 1) then break end
        end
    end
    --Check horizontally to the right
    if (x < self.grid_size) then
    i = x+1
        while (self.tiles[i][y].colour == col) do
            i = i + 1
            numX = numX + 1
            if (i > self.grid_size) then break end
        end
    end
    --Check vertically upwards
    if (y > 1) then
        i = y-1
        while (self.tiles[x][i].colour == col) do
            i = i - 1
            numY = numY + 1
            if (i < 1) then break end
        end
    end
    --Check vertically downwards
    if (y < self.grid_size) then
        i = y+1
        while (self.tiles[x][i].colour == col) do
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

--Delete (remove) tile at the provided coordinates
--VARIES BASED ON TILE TYPE
function Board:removeTile(x,y)
    if (self.tiles[x][y].type == "verticaal") then

    else
        --Default to 'normal' tile
        --Shift tiles down one row
        for j=y,2,-1 do
            self.tiles[x][j] = copyTable(self.tiles[x][j-1])
            self.tiles[x][j].anim.offset = self.tiles[x][j].anim.offset - 1
            self.tiles[x][j].anim.velocity = 0.01
        end
        --Spawn new tile at top
        self.tiles[x][1] = new_tile()
        if (self.tiles[x][2].anim.offset == 0) then
            self.tiles[x][1].anim.offset = -1.5
        else
            self.tiles[x][1].anim.offset = self.tiles[x][2].anim.offset - 0.5
        end
        self.tiles[x][1].anim.velocity = self.tiles[x][2].anim.velocity - 0.002
        if (self.tiles[x][1].anim.velocity < 0) then
            self.tiles[x][1].anim.velocity = 0.03
        end
    end
end

--Called to analyse the board for matches
function Board:analyse()
    --Check for matches and place powerups when required
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            -- Check for match
            local isMatch, num = self:matchAt(x,y)
            if (isMatch and not self.tiles[x][y].matched) then
                -- Check if the tile has been swapped and if so check for powerup conditions
                if (self.tiles[x][y].wasSwapped == true) then
                    -- Vertical powerup
                    if (num.X > 3 and num.Y < 2) then
                        self.tiles[x][y] = new_tile(self.tiles[x][y].colour,"vertical")
                    -- Horizontal powerup
                    elseif (num.X < 2 and num.Y > 3) then
                        self.tiles[x][y] = new_tile(self.tiles[x][y].colour,"horizontal")
                    -- Explosion powerup
                    elseif (num.X > 2 and num.Y > 2) then
                        self.tiles[x][y] = new_tile(self.tiles[x][y].colour,"explosion")
                    else
                        -- Else mark tile for deletion
                        self.tiles[x][y].matched = true
                    end
                else
                    --Explosion powerup
                    if (num.X > 2 and num.Y > 2) then
                        self.tiles[x][y] = new_tile(self.tiles[x][y].colour,"explosion")
                    else
                        -- Mark tile for deletion
                        self.tiles[x][y].matched = true
                    end
                end
            end
            -- Reset vars
            self.tiles[x][y].anim.swapped = false
            self.tiles[x][y].wasSwapped = false
        end
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
    --Case 5: special gems
    --TODO

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