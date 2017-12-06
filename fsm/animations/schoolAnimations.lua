local persistence = require "persistence"

local M = { }


function M.new( school, character, gamePanel, path, schoolFSM, gameFlow ) 
	local animation = { }
	local teacher = school:findObject( "teacher" )
	local tilesSize = 32
	local brother

	if ( character == school:findObject( "ada") ) then 
		brother = school:findObject( "turing")
	else
		brother = school:findObject( "ada") 
	end

	local function flip( delay, character )
		local function closure()
			if ( character.xScale == 1 ) then character.xScale = -1
			else character.xScale = 1 end 
		end
		
		timer.performWithDelay( delay, closure )
	end

	local function enterHouseAnimation()
		local startingPoint = school:findObject("start")
		local time = 800

	  	physics.removeBody( character )
	  	character.x = startingPoint.x - tilesSize * 2 - 3
	  	character.y = startingPoint.y - 6
	  	teacher.x = character.x 
	  	teacher.y = character.y 
	  	character.xScale = 1

	  	transition.fadeIn( character, { time = 400 } )
	  	transition.fadeIn( teacher, { time = 400 } )
	  	path:hidePath()
	  	transition.to( teacher, { time = time * 2, x = teacher.x + tilesSize * 2 + 5, 
	  		onComplete = 
	  			function()
	  				transition.to( teacher, { time = time, y = teacher.y - tilesSize } )
	  				transition.to( character, { time = time * 2, x = character.x + tilesSize * 2 + 3,
	  				onComplete =
	  					function()
	  						physics.addBody( character )
						  	character.isFixedRotation = true 
						  	timer.performWithDelay( 800, gameFlow.updateFSM )
	  					end
	  				} )
	  			end
	  		} )
	  	return math.huge
	end

	local function brotherJumpingAnimation()
		local time = 1500

		gameFlow.updateFSM()
		transition.to( brother, { rotation = 7, time = time, y = brother.y - 5, transition = easing.inBounce,
		onComplete =  
		  function()
		    transition.to( brother, { rotation = 0, time = time, y = brother.y + 5, transition = easing.outBounce } )
		  end
		 } )
	end

	local function brotherAnimation( stars, message )
		local time = 450

		if ( stars == 3 ) then 
			brother.alpha = 1
			brother.x = character.x - tilesSize * 2
        	brother.y = character.y - 3
        	--flip( 0, brother )

			transition.to( brother, { time = time, x = brother.x + tilesSize, 
				onComplete = 
					function()
						transition.to( brother, { time = time * 2, y = brother.y + tilesSize * 2 ,
							onComplete = 
								function()
									transition.to( brother, { time = time * 6, x = brother.x + tilesSize * 6, 
										onComplete = 
											function()
												flip( 300, brother )
												timer.performWithDelay( 800, gameFlow.updateFSM )
											end 
										} )
								end

							} )
					end
				} )
		elseif ( stars == 2 ) then 
			message["msg1"] = message["msg2"]
			brotherJumpingAnimation()
		elseif ( stars <= 1 ) then
			message["msg1"] = message["msg3"] 
			brotherJumpingAnimation()
		end 

		
		return math.huge

	end

	local function brotherLeaveAnimation()
		local time = 500

		brother.animation = true 
		flip( 300, brother )
		local function closure()
			transition.to( brother, { time = time * 15, x = brother.x + tilesSize * 15, 
				onComplete =  
					function()
						brother.alpha = 0 
					end
				})
		end
		timer.performWithDelay( 600, closure )

		return time * 12
	end

	local function handAnimation( time, count, wait, hand, initialX, initialY, x, y, state )
		if ( hand.stop == true ) then
			hand.alpha = 0
		  return
		else 
		  hand.x = initialX
		  hand.y = initialY
		  transition.to( hand, { time = time, x = x, y = y } )
		  local closure = function ( ) return handAnimation( time, count - 1, wait, hand, initialX, initialY, x, y, state ) end
		  timer.performWithDelay( time + wait, closure )
		end
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

		teacher.animation = true 
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
											teacher.animation = nil 
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
						flip( 0, teacher )
						transition.to( teacher, { time = time * 1.5, x = teacher.x - tilesSize * 1.5, onComplete = releaseSupply } )
					end
			 	} )
		end

		local function closureCatchSupply()
			transition.fadeOut( teacherSupply, { time = 400, onComplete = gotoOrganizer } )
		end

		transition.to( teacher, { time = time, x = teacher.x + tilesSize, onComplete = closureCatchSupply } )

		return math.huge 
	end

	local function teacherChairCollision()
		local time = 500 
		local chair = school:findObject( "teacherChair" )

		teacher.animation = true 
		local function goForward()
			flip( 0, teacher )
			teacher.animation = nil 
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

		teacher.animation = true 
		transition.to( teacher, { time = time * 2, y = teacher.y + tilesSize * 2, 
			onComplete = 
				function()
					flip( 0, teacher )
					transition.to( teacher, { time = time, x = teacher.x - tilesSize, 
						onComplete =  
							function()
								local teacherBubble = school:findObject( "teacherBubble" )
								flip( 0, teacher )
								teacherBubble.y = teacherBubble.y + tilesSize * 1.7
								teacher.animation = nil 
								gameFlow.updateFSM()
							end
						})
				end
		 	} )		

		return math.huge
	end

	local function teacherJumpingAnimation()
		local time = 1800

		transition.to( teacher, { time = time, y = teacher.y - 7, transition = easing.inBounce,
		onComplete =  
		  function()
		    transition.to( teacher, { time = time, y = teacher.y + 7, transition = easing.outBounce } )
		  end
		 } )

		return time * 2 
	end

	local function leaveSchoolAnimation( organizer )
		local time = 500 
		local stepsX
		local stepsY 

		if ( organizer.direction == "right" ) then
			stepsX = 1
		else 
			stepsX = 2
		end

		flip( 0, character )
		transition.to( character, { time = stepsX * time, x = character.x + stepsX * tilesSize,
			onComplete =
				function()
					stepsX = 8
					if ( organizer.number == 1 ) then 
						if ( organizer.direction == "right" ) then 
							stepsY = 9
						else
							stepsY = 8
						end
					elseif ( organizer.number == 2 ) then 
						stepsY = 7
					elseif ( organizer.number == 3 ) then 
						stepsY = 6 
					elseif ( organizer.number == 4 ) then 
						if ( organizer.direction == "right" ) then stepsY = 5
						else
							stepsY = 4
						end
					end

					transition.to( character, { time = time * stepsY, y = character.y + stepsY * tilesSize, 
						onComplete = 
							function()
								transition.to( character, { time = time * stepsX, x = character.x + stepsX * tilesSize, onComplete = gameFlow.updateFSM } )
							end
						} )
				end
			} )

		return math.huge
	end

	animation["handOrganizerAnimation"] = handOrganizerAnimation
	animation["teacherOrganizerAnimation"] = teacherOrganizerAnimation
	animation["teacherChairCollision"] = teacherChairCollision
	animation["fixChair"] = fixChair
	animation["teacherGotoInitialPosition"] = teacherGotoInitialPosition
	animation["teacherJumpingAnimation"] = teacherJumpingAnimation
	animation["enterHouseAnimation"] = enterHouseAnimation
	animation["brotherAnimation"] = brotherAnimation
	animation["brotherLeaveAnimation"] = brotherLeaveAnimation
	animation["leaveSchoolAnimation"] = leaveSchoolAnimation
 
	return animation
end

return M