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

    --Initalise tile array
    self.tiles = {}
    for i = 1,self.grid_size do
        self.tiles[i] = {}
        for j = 1,self.grid_size do
            self.tiles[i][j] = new_tile()
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

--Update is literally only used for animations :D
function Board:update(dt)
    --Animation stuff
    self.isAnimated = false
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            --Falling animation stuff
            if (self.tiles[x][y].offset < 0) then
                self.isAnimated = true
                self.tiles[x][y].velocity = self.tiles[x][y].velocity *(1+5*dt)
                self.tiles[x][y].offset = self.tiles[x][y].offset + self.tiles[x][y].velocity
            end
            if (self.tiles[x][y].offset > 0) then
                self.tiles[x][y].offset = 0
            end
            --Swipe animation
            if (self.tiles[x][y].swap.x > 0) then
                self.isAnimated = true
                self.tiles[x][y].swap.x = self.tiles[x][y].swap.x - (5*dt)
                if (self.tiles[x][y].swap.x <= 0) then
                    self.tiles[x][y].swap.x = 0
                    --Swap back if no match (x axis)
                    if (not self:matchAt(x,y) and not self:matchAt(x+1,y) and not self.tiles[x][y].swapped and not self.tiles[x+1][y].swapped) then
                        self.tiles[x][y].swap.x = -1
                        self.tiles[x][y].swapped = true
                        self.tiles[x+1][y].swap.x = 1
                        self.tiles[x+1][y].swapped = true
                        self:swapTiles(x,y,x+1,y)
                    end
                end
            end
            if (self.tiles[x][y].swap.x < 0) then
                self.isAnimated = true
                self.tiles[x][y].swap.x = self.tiles[x][y].swap.x + (5*dt)
                if (self.tiles[x][y].swap.x >= 0) then
                    self.tiles[x][y].swap.x = 0
                end
            end
            if (self.tiles[x][y].swap.y > 0) then
                self.isAnimated = true
                self.tiles[x][y].swap.y = self.tiles[x][y].swap.y - (5*dt)
                if (self.tiles[x][y].swap.y <= 0) then
                    self.tiles[x][y].swap.y = 0
                    --Swap back if no match (y axis)
                    if (not self:matchAt(x,y) and not self:matchAt(x,y+1) and not self.tiles[x][y].swapped and not self.tiles[x][y+1].swapped) then
                        self.tiles[x][y].swap.y = -1
                        self.tiles[x][y].swapped = true
                        self.tiles[x][y+1].swap.y = 1
                        self.tiles[x][y+1].swapped = true
                        self:swapTiles(x,y,x,y+1)
                    end
                end
            end
            if (self.tiles[x][y].swap.y < 0) then
                self.isAnimated = true
                self.tiles[x][y].swap.y = self.tiles[x][y].swap.y + (5*dt)
                if (self.tiles[x][y].swap.y >= 0) then
                    self.tiles[x][y].swap.y = 0
                end
            end
            --Shrink/dissappear animation
            if (self.tiles[x][y].matched == true) then
                self.isAnimated = true
                self.tiles[x][y].size = self.tiles[x][y].size - 0.1
                if (self.tiles[x][y].size < 0) then
                    self:removeTile(x,y)
                end
            end
        end
    end
    --Analyse the board if gems aren't moving
    if (self.isAnimated == false) then
        self:analyse()
    end
end

-- Draw the board with (x,y) being the top left corner
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
            centeredImage(self.tiles[x][y].img,(x-0.5+self.tiles[x][y].swap.x)*(sz2),(y-0.5+self.tiles[x][y].offset+self.tiles[x][y].swap.y)*(sz2),self.tiles[x][y].size*(sz2/self.tiles[x][y].img:getWidth()),self.tiles[x][y].size*(sz2/self.tiles[x][y].img:getHeight()))
        end
    end
    --Pop old coordinates
    love.graphics.pop()
end

-- Return true if a match is formed at (x,y) or false otherwise
function Board:matchAt(x,y)
    local col = self.tiles[x][y].type
    local numX, numY = 1, 1
    local i = 0
    --Check horizontally to the left
    if (x > 1) then
        i = x-1
        while (self.tiles[i][y].type == col) do
            i = i - 1
            numX = numX + 1
            if (i < 1) then break end
        end
    end
    --Check horizontally to the right
    if (x < self.grid_size) then
    i = x+1
        while (self.tiles[i][y].type == col) do
            i = i + 1
            numX = numX + 1
            if (i > self.grid_size) then break end
        end
    end
    --Check vertically upwards
    if (y > 1) then
        i = y-1
        while (self.tiles[x][i].type == col) do
            i = i - 1
            numY = numY + 1
            if (i < 1) then break end
        end
    end
    --Check vertically downwards
    if (y < self.grid_size) then
        i = y+1
        while (self.tiles[x][i].type == col) do
            i = i + 1
            numY = numY + 1
            if (i > self.grid_size) then break end
        end
    end
    --Return if there is a match!!
    if (numX > 2 or numY > 2) then
        return true
    else
        return false
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
            self.tiles[self.touch_start.tx][self.touch_start.ty-1].swap.y = 1
            self.tiles[self.touch_start.tx][self.touch_start.ty].swap.y = -1
        end
    end
    --Swipe down
    if (dy > 0 and self.touch_start.ty < self.grid_size) then
        if ( ( (dx >= 0 and math.atan(dx/-dy) > -(math.pi/6)) or (dx < 0 and math.atan(dx/-dy) < (math.pi/6)) ) and (len > thr) ) then
            self:swapTiles(self.touch_start.tx,self.touch_start.ty+1,self.touch_start.tx,self.touch_start.ty)
            self.tiles[self.touch_start.tx][self.touch_start.ty+1].swap.y = -1
            self.tiles[self.touch_start.tx][self.touch_start.ty].swap.y = 1
        end
    end
    --Swipe right
    if (dx > 0 and self.touch_start.tx < self.grid_size) then
        if ( ( (dy < 0 and math.atan(-dy/dx) < (math.pi/6)) or (dy >= 0 and math.atan(-dy/dx) > -(math.pi/6)) ) and (len > thr) ) then
            self:swapTiles(self.touch_start.tx+1,self.touch_start.ty,self.touch_start.tx,self.touch_start.ty)
            self.tiles[self.touch_start.tx][self.touch_start.ty].swap.x = 1
            self.tiles[self.touch_start.tx+1][self.touch_start.ty].swap.x = -1
        end
    end
    --Swipe left
    if (dx < 0 and self.touch_start.tx > 1) then
        if ( ( (dy < 0 and math.atan(-dy/dx) > -(math.pi/6)) or (dy >= 0 and math.atan(-dy/dx) < (math.pi/6)) ) and (len > thr) ) then
            self:swapTiles(self.touch_start.tx-1,self.touch_start.ty,self.touch_start.tx,self.touch_start.ty)
            self.tiles[self.touch_start.tx-1][self.touch_start.ty].swap.x = 1
            self.tiles[self.touch_start.tx][self.touch_start.ty].swap.x = -1
        end
    end
end

--Swap two tiles at the provided coordinates
function Board:swapTiles(x1,y1,x2,y2)
    local copy = self.tiles[x1][y1]
    self.tiles[x1][y1] = self.tiles[x2][y2]
    self.tiles[x2][y2] = copy
end

--Delete (remove) tile at the provided coordinates
function Board:removeTile(x,y)
    --Shift tiles down one row
    for j=y,2,-1 do
        self.tiles[x][j] = copyTable(self.tiles[x][j-1])
        self.tiles[x][j].offset = self.tiles[x][j].offset - 1
        self.tiles[x][j].velocity = 0.03 - (0.002*(y-j))
    end
    --Spawn new tile at top
    self.tiles[x][1] = new_tile()
    if (self.tiles[x][2].offset == 0) then
        self.tiles[x][1].offset = -1.5
    else
        self.tiles[x][1].offset = self.tiles[x][2].offset - 0.5
    end
    self.tiles[x][1].velocity = self.tiles[x][2].velocity - 0.002
    if (self.tiles[x][1].velocity < 0) then
        self.tiles[x][1].velocity = 0.03
    end
end

--Called to analyse the board for matches
function Board:analyse()
    --Store coordinates of matched tiles
    local match = {}
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            if (self:matchAt(x,y) == true) then
                match[#match+1] = {x,y}
            end
            --Reset "swapped" variable
            self.tiles[x][y].swapped = false
        end
    end
    --Remove (mark) the tiles
    for i=1,#match do
        self.tiles[match[i][1]][match[i][2]].matched = true
    end

    --Check if a shuffle is required and do if necessary
    self.no_matches = true
    --Case 1: horizontal consecutive
    local check = {{-1,-1},{-2,0},{-1,1},{2,-1},{3,0},{2,1}} --(coords from left tile)
    for x=1,self.grid_size-1 do
        for y=1,self.grid_size do
            if (self.tiles[x][y].type == self.tiles[x+1][y].type) then
                --Check adjacent tiles
                for i=1,#check do
                    local X = x+check[i][1]
                    local Y = y+check[i][2]
                    if (X < 1 or X > self.grid_size or Y < 1 or Y > self.grid_size) then
                    else
                        if (self.tiles[x][y].type == self.tiles[X][Y].type) then
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
            if (self.tiles[x][y].type == self.tiles[x][y+1].type) then
                --Check adjacent tiles
                for i=1,#check do
                    local X = x+check[i][1]
                    local Y = y+check[i][2]
                    if (X < 1 or X > self.grid_size or Y < 1 or Y > self.grid_size) then
                    else
                        if (self.tiles[x][y].type == self.tiles[X][Y].type) then
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
            if (self.tiles[x][y].type == self.tiles[x+2][y].type) then
                --Check adjacent tiles
                for i=1,#check do
                    local X = x+check[i][1]
                    local Y = y+check[i][2]
                    if (X < 1 or X > self.grid_size or Y < 1 or Y > self.grid_size) then
                    else
                        if (self.tiles[x][y].type == self.tiles[X][Y].type) then
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
            if (self.tiles[x][y].type == self.tiles[x][y+2].type) then
                --Check adjacent tiles
                for i=1,#check do
                    local X = x+check[i][1]
                    local Y = y+check[i][2]
                    if (X < 1 or X > self.grid_size or Y < 1 or Y > self.grid_size) then
                    else
                        if (self.tiles[x][y].type == self.tiles[X][Y].type) then
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
        print(X,Y,#copies)
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