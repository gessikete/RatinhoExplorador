local persistence = require "persistence"

local M = { }


function M.new( school, gamePanel, path, schoolFSM, gameFlow ) 
	local animation = { }
	local teacher = school:findObject( "teacher" )
	local character = school:findObject( "character" )
	local tilesSize = 32

	local function handAnimation( time, count, wait, hand, initialX, initialY, x, y, state )
		--[[if ( count <= 0 ) then
		  return
		else]] 
		  hand.x = initialX
		  hand.y = initialY
		  transition.to( hand, { time = time, x = x, y = y } )
		  local closure = function ( ) return handAnimation( time, count - 1, wait, hand, initialX, initialY, x, y, state ) end
		  timer.performWithDelay( time + wait, closure )
		--end
	end

	local function handOrganizerAnimation()
		local hand = school:findObject( "organizerHand" )
		local organizer = school:findObject( "firstOrganizer" )
		local time = 3000
		local count = 3
		local wait = 800

		hand.x = hand.originalX 
		hand.y = hand.originalY
		hand.alpha = 1
		 

		handAnimation( time, count, wait, hand, hand.originalX, hand.originalY, hand.x, organizer.y + tilesSize * 3, schoolFSM.current )
		
		--gamePanel:addRightDirectionListener( gameFlow.updateFSM )

		return 0 
	end


	animation["handOrganizerAnimation"] = handOrganizerAnimation

	return animation
end

return M