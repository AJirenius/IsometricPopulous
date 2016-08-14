local M = {}
local config = require "game.game_config"

local grid = {}
local width = 10
local height = 10
local offset_x = 640
local offset_y = -00

local function add_to_circle(c,x,y)
	if M.grid[x] == nil then return end
	if M.grid[x][y] == nil then return end
	table.insert(c, M.grid[x][y])
end

function M.set_position(tile)
	tile.pos.x = (tile.grid_x-tile.grid_y) * config.TILE_WIDTH/2 + offset_x
	tile.pos.y = (tile.grid_y + tile.grid_x) * config.TILE_HEIGHT/2 +tile.height * config.HEIGHT_OFFSET + offset_y
	tile.pos.z = -tile.pos.y * 0.00001
end

function M.smooth_height()
	local dirty = true
	while dirty == true do
		dirty = false
		for x = 1 , width do
			for y = 1, height do
				local tile = grid[x][y]
				for i, tt in ipairs(tile.circle) do
					if tile.height - tt.height > 1 then 
						tt.height = tile.height - 1 
						dirty = true
					end
					M.set_position(tile)
				end
			end
		end
	end
end	


function M.create()
	M.grid = grid
	
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
	


end


return M