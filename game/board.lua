Board = {}

function Board:new(x,y,grid_size,s)
    self.x = x
    self.y = y
    self.size = s
    self.grid_size = grid_size
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
end

function Board:update(dt)

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
            love.graphics.draw(self.tiles[x][y].img,(x-1)*(sz2),(y-1+self.tiles[x][y].offset)*(sz2),0,sz2/self.tiles[x][y].img:getWidth(),sz2/self.tiles[x][y].img:getHeight())
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
    if (absX < self.x or absY < self.y or absX > (self.x + self.size) or absY > (self.y + self.size)) then
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
            self:swapTiles(self.touch_start.tx,self.touch_start.ty+1,self.touch_start.tx,self.touch_start.ty)
        end
    end
    --Swipe right
    if (dx > 0 and self.touch_start.tx < self.grid_size) then
        if ( ( (dy < 0 and math.atan(-dy/dx) < (math.pi/6)) or (dy >= 0 and math.atan(-dy/dx) > -(math.pi/6)) ) and (len > thr) ) then
            self:swapTiles(self.touch_start.tx+1,self.touch_start.ty,self.touch_start.tx,self.touch_start.ty)
        end
    end
    --Swipe left
    if (dx < 0 and self.touch_start.tx > 1) then
        if ( ( (dy < 0 and math.atan(-dy/dx) > -(math.pi/6)) or (dy >= 0 and math.atan(-dy/dx) < (math.pi/6)) ) and (len > thr) ) then
            self:swapTiles(self.touch_start.tx-1,self.touch_start.ty,self.touch_start.tx,self.touch_start.ty)
        end
    end
    --Analyse the board for matches
    self:analyse()
end

--Swap two tiles at the provided coordinates
function Board:swapTiles(x1,y1,x2,y2)
    local copy = self.tiles[x1][y1]
    self.tiles[x1][y1] = self.tiles[x2][y2]
    self.tiles[x2][y2] = copy
end

--Called after each tile movement to check for matches
function Board:analyse()
    --Check if a shuffle is required and do if necessary
    --[[ local matches = 0
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            if (self:matchAt(x,y) == true) then
                matches = matches + 1
            end
        end
    end
    if (matches == 0) then
        self:shuffle()
    end]]

    --Remove matched tiles
    --Stores coordinates of matched tiles
    local match = {}
    for x=1,self.grid_size do
        for y=1,self.grid_size do
            if (self:matchAt(x,y) == true) then
                match[#match+1] = {x,y}
            end
        end
    end

    --Remove matched tiles
    for i=1,#match do
        for j=match[i][2],2,-1 do
            self.tiles[match[i][1]][j] = copyTable(self.tiles[match[i][1]][j-1])
        end
        self.tiles[match[i][1]][1] = new_tile()
    end

    --Reanalyse the board if necessary??
    if (#match ~= 0) then
        self:analyse()
    end
end

--Called to shuffle the board
function Board:shuffle()

end