local persistence = require "persistence"

local M = { }

function M.new( restaurant, character, gamePanel, path, restaurantFSM, gameFlow ) 
	local animation = { }
	local cook = restaurant:findObject( "cook" )
	--local character = restaurant:findObject( "character" )
	local tilesSize = 32

	local function momAnimation( )
		local time = 5000
		transition.to( mom, { time = time, x = character.x, y = character.y - tilesSize } )

		return time + 500
	end

	animation["momAnimation"] = momAnimation

	return animation
end

return M