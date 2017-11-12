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

	local function teacherOrganizerAnimation()
		local time = 500
		local teacherSupply = school:findObject( "teacherSupply" )

		local function releaseSupply()
			local firstOrganizer = school:findObject( "firstOrganizer" )

			teacherSupply.x = firstOrganizer.x 
			teacherSupply.y = firstOrganizer.y + tilesSize * 3
			transition.fadeIn( teacherSupply, { time = 400, 
				onComplete =  
					function()
						transition.to( teacher, { time = time, x = teacher.x + .5 * tilesSize, 
							onComplete = 
								function()
									transition.fadeOut( teacherSupply, { time = time * 3, 
										onComplete = 
										function()
											local teacherBubble = school:findObject( "teacherBubble" )
											teacherBubble.y = teacherBubble.y - tilesSize * 1.7
											gameFlow.updateFSM()
										end 
										} )
								end
							} )
					end
				} )
		end

		local function gotoOrganizer()
			transition.to( teacher, { time = time * 2, y = teacher.y - tilesSize * 2, 
				onComplete = 
					function()
						teacher.xScale = -1
						transition.to( teacher, { time = time * 1.5, x = teacher.x - tilesSize * 1.5, onComplete = releaseSupply } )
					end
			 	} )
		end

		local function closureCatchSupply()
			transition.fadeOut( teacherSupply, { time = 400, onComplete = gotoOrganizer } )
		end

		transition.to( teacher, { time = time, x = teacher.x + tilesSize, onComplete = closureCatchSupply } )
		--[[local hand = school:findObject( "organizerHand" )
		local organizer = school:findObject( "firstOrganizer" )
		local time = 3000
		local count = 3
		local wait = 800

		hand.x = hand.originalX 
		hand.y = hand.originalY
		hand.alpha = 1
		 

		handAnimation( time, count, wait, hand, hand.originalX, hand.originalY, hand.x, organizer.y + tilesSize * 3, schoolFSM.current )
		
		gamePanel:addRightDirectionListener( gameFlow.updateFSM )]]

		return math.huge 
	end

	local function teacherChairCollision()
		local time = 500 
		local chair = school:findObject( "teacherChair" )
		teacher.xScale = -1

		local function goForward()
			teacher.xScale = 1
			transition.to( teacher, { time = time, x = teacher.x - tilesSize * .25, onComplete = gameFlow.updateFSM } )
		end

		local function moveChair()
			transition.to( chair, { time = time, x = chair.x + tilesSize * .25, rotation = 3, onComplete = goForward } )
		end

		transition.to( teacher, { time = time * 2, x = teacher.x + tilesSize * 1.2, onComplete = moveChair } )

		return math.huge
	end

	local function fixChair()
		local time = 500 
		local chair = school:findObject( "teacherChair" )

		transition.to( teacher, { time = time, x = teacher.x + tilesSize * .25, 
			onComplete =
				function()
					transition.to( teacher, { time = time, x = teacher.x - tilesSize * .25 } ) 
					transition.to( chair, { time = time, x = chair.x - tilesSize * .25, rotation = 0 } )
				end
		 	} )
		return time * 2
	end

	local function teacherGotoInitialPosition()
		time = 500 

		transition.to( teacher, { time = time * 2, y = teacher.y + tilesSize * 2, 
			onComplete = 
				function()
					teacher.xScale = -1
					transition.to( teacher, { time = time, x = teacher.x - tilesSize, 
						onComplete =  
							function()
								local teacherBubble = school:findObject( "teacherBubble" )
								teacher.xScale = 1
								teacherBubble.y = teacherBubble.y + tilesSize * 1.7
								gameFlow.updateFSM()
							end
						})
				end
		 	} )		

		return math.huge
	end

	animation["handOrganizerAnimation"] = handOrganizerAnimation
	animation["teacherOrganizerAnimation"] = teacherOrganizerAnimation
	animation["teacherChairCollision"] = teacherChairCollision
	animation["fixChair"] = fixChair
	animation["teacherGotoInitialPosition"] = teacherGotoInitialPosition

	return animation
end

return M