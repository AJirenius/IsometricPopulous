local M = {}
local config = require "game.game_config"

local grid = {}
M.grid = grid
local width = 10
local height = 10
local offset_x = 640
local offset_y = -00

local function print_tiles(table)
	for i,v in ipairs(table) do
		print(v.grid_x..",".. v.grid_y)
	end
end

local function add_to_circle(c,x,y)
	if M.grid[x] == nil then return end
	if M.grid[x][y] == nil then return end
	table.insert(c, M.grid[x][y])
end

function M.set_position(tile)
	tile.pos.x = (tile.grid_x-tile.grid_y) * config.TILE_WIDTH/2 + offset_x
	tile.pos.y = (tile.grid_y + tile.grid_x) * config.TILE_HEIGHT/2 +tile.height * config.HEIGHT_OFFSET + offset_y
	tile.pos.z = -tile.pos.y * 0.00001
	if tile.view then go.set_position(tile.pos, tile.view) end
end

function M.smooth_height(direction) -- 1 = up, -1 = down
	direction  = direction or 1
	local dirty = true
	while dirty == true do
		dirty = false
		for x = 1 , width do
			for y = 1, height do
				local tile = grid[x][y]
				for i, tt in ipairs(tile.circle) do
					if direction == 1 then
						if tile.height - tt.height > 1 then 
							tt.height = tile.height - 1 
							dirty = true	
							M.set_position(tt)
						end
					else
						if tt.height - tile.height > 1 then 
							tt.height = tile.height + 1 
							dirty = true	
							M.set_position(tt)	
						end
					end
				end
			end
		end
	end
end	

function M.update_tile_views()
	for i,col in ipairs(M.grid) do
		for ii,tile in ipairs(col) do
			msg.post(tile.view, "update_sprite")
		end
	end
end


function M.create()
	
	
	-- Create logic tile (one master point)
	for x = 1 , width do
		local column = {}
		for y = 1, height do
			local tile = {
				grid_x = x,
				grid_y = y,
				height = math.random(2),
			}
			if math.random(20) < 2 then
				tile.height = math.random(3)+2
			end
			
			tile.pos = vmath.vector3(
				(tile.grid_x-tile.grid_y) * config.TILE_WIDTH/2 + offset_x, 		-- x
				(tile.grid_y + tile.grid_x) * config.TILE_HEIGHT/2 +tile.height * config.HEIGHT_OFFSET + offset_y,				-- y
				0)
			tile.pos.z = -tile.pos.y * 0.00001
			table.insert(column, tile)
		end
		table.insert (grid, column)
	end
	
	-- Square of points
	for x = 1 , width do
		for y = 1, height do
			local tile = grid[x][y]
			if x > 1 and y > 1 then
				tile.square = {
					grid[x][y-1],
					grid[x-1][y-1],
					grid[x-1][y],
				}
			end
			-- circle of points
			tile.circle = {}
			local c = tile.circle
			add_to_circle(c,x+1,y)
			add_to_circle(c,x+1,y+1)
			add_to_circle(c,x,y+1)
			add_to_circle(c,x-1,y)
			add_to_circle(c,x-1,y-1)
			add_to_circle(c,x,y-1)
			add_to_circle(c,x+1,y-1)
			add_to_circle(c,x-1,y+1)
		end
	end
	
	M.smooth_height()
	
	-- create view
	for y = 1, height do
		for x = 1 , width do
			local tile = grid[x][y]
			tile.view = factory.create("/factories#tile", tile.pos, nil,  { grid_pos = vmath.vector3(tile.grid_x, tile.grid_y, 0) })
		end
	end
	
	-- create view columns (for mouse picking)
	M.view_columns = {}
	for y = 1, height do
		for x = 1 , width do
			local tile = grid[x][y]
			
			local ix = x-y+height

			if M.view_columns[ix] == nil then 
				M.view_columns[ix] = {
					pos_x = tile.pos.x,
					tiles = {}
				} 
			end
			local col = M.view_columns[ix]
			table.insert(col.tiles, tile)
		end
	end
end

function M.get_closest_tile(x,y)
	local c
	for i,col in ipairs(M.view_columns) do
		c = col
		if x < col.pos_x then
			if i > 1 then
				if math.abs(M.view_columns[i-1].pos_x-x) < math.abs(col.pos_x-x) then
					c = M.view_columns[i-1]
				end
			end
			break
		end	
	end
	
	local t
	for i,tile in ipairs(c.tiles) do
		if tile.pos.y > y then
			if i > 1 and math.abs(c.tiles[i-1].pos.y-y) < math.abs(tile.pos.y-y) then
				return c.tiles[i-1]
			end
			return tile
		end	
	end
	return c.tiles[#c.tiles]
end

function M.adjust_height(tile, offset)
	tile.height = tile.height + offset
	M.set_position(tile)
	M.smooth_height(offset)
	M.update_tile_views()
end



return M