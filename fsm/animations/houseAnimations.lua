local persistence = require "persistence"

local M = { }

function M.new( house, character, puzzle, gamePanel, path, houseFSM, gameFlow ) 
	local animation = { }
	local mom = house:findObject( "mom" )
	local brother 
	local tilesSize = 32

	if ( character == house:findObject( "ada") ) then 
		brother = house:findObject( "turing")
	else
		brother = house:findObject( "ada") 
	end

	local function momAnimation( )
		local time = 5000
		transition.to( mom, { time = time, x = character.x, y = character.y - tilesSize } )

		return time + 500
	end

	local function handDirectionAnimation( time, wait, hand, initialX, initialY, x, y, state )
		if ( state ~= houseFSM.current ) then
		  return
		else 
		  hand.x = initialX
		  hand.y = initialY
		  transition.to( hand, { time = time, x = x, y = y } )
		  local closure = function ( ) return handDirectionAnimation( time, wait, hand, initialX, initialY, x, y, state ) end
		  timer.performWithDelay( time + wait, closure )
		end
	end

	local function handDirectionAnimation1( )
		local hand = gamePanel.directionHand
		local box = gamePanel.firstBox
		local time = 3000
		local wait = 800

		hand.x = hand.originalX 
		hand.y = hand.originalY
		hand.alpha = 1
		 

		handDirectionAnimation( time, wait, hand, hand.originalX, hand.originalY, hand.x, box.y - 5, houseFSM.current )
		
		gamePanel:addRightDirectionListener( gameFlow.updateFSM )
	end

	local function handDirectionAnimation2( )
		local hand = gamePanel.directionHand
		local box = gamePanel.secondBox
		local time = 3000
		local wait = 800

		hand.x = hand.originalX 
		hand.y = hand.originalY
		hand.alpha = 1
		 

		handDirectionAnimation( time, wait, hand, hand.originalX, hand.originalY, hand.x, box.y - 5, houseFSM.current )
		gamePanel:addRightDirectionListener( gameFlow.updateFSM )
	end

	local function handDirectionAnimation3( )
		local hand = gamePanel.directionHand
		local box = gamePanel.secondBox
		local time = 3000
		local wait = 800

		hand.x = hand.originalX - 20 
		hand.y = hand.originalY - 20
		hand.alpha = 1
		 

		handDirectionAnimation( time, wait, hand, hand.x, hand.y, hand.x, box.y - 5, houseFSM.current )
		gamePanel:addUpDirectionListener( gameFlow.updateFSM )
	end

	local function handExecuteAnimation( )
		local hand = gamePanel.executeHand
		local executeButton = gamePanel.executeButton
		local time = 1500
		local wait = 400

		hand.x = executeButton.x     
		hand.y = executeButton.y
		hand.alpha = 1 
		 
		collision = false
		transition.fadeIn( executeButton, { time = wait } )
		transition.fadeIn( gamePanel.gotoMenuButton, { time = wait } )
		handDirectionAnimation( time, wait, hand, executeButton.contentBounds.xMin + 2, executeButton.y, executeButton.contentBounds.xMin + 10, executeButton.y - 5, houseFSM.current )
		  
		gamePanel:addgotoMenuButtonListener()
		gamePanel:addExecuteButtonListener( gameFlow.updateFSM )
	end


	local function gamePanelAnimation()
		gamePanel:showDirectionButtons( true )
	end

	local function handBikeAnimation( time, hand, radius, initialX, initialY, state )
		if ( state ~= houseFSM.current ) then
		  return
		else 

		  transition.to( hand, { time = time, y = initialY + 2 * radius, transition = easing.inOutSine } )
		  transition.to( hand, { time = time*.5, x = initialX + radius, transition = easing.outSine, onComplete = 
		  function()
		    transition.to( hand, { time = time*.5, x = initialX, transition = easing.inSine, onComplete =
		      function()
		        transition.to( hand, { time = time, y = initialY - radius/2, transition = easing.inOutSine } )
		        transition.to( hand, { time = time*.5, x = initialX - radius - 10, transition = easing.outSine, onComplete = 
		        function()
		          transition.to( hand, { time = time*.5, x = initialX, transition = easing.inSine } )
		          end } )
		      end
		     } )
		   end } )
		  local closure = function ( ) return handBikeAnimation( time, hand, radius, initialX, initialY, state ) end
		  timer.performWithDelay(time * 2 + 400, closure)
		end
	end

	local function handBikeAnimation1()
		local hand = gamePanel.bikeHand
		local bikeWheel = gamePanel.bikeWheel
		local time = 1500
		local radius = bikeWheel.radius*.65
		local maxSteps = 2

		hand.x = bikeWheel.x - radius + 10
		hand.y = bikeWheel.contentBounds.yMin + 10
		hand.alpha = 1
		 
		handBikeAnimation( time, hand, radius, hand.x, hand.y, houseFSM.current )
		
		gamePanel:addBikeTutorialListener( maxSteps, gameFlow.updateFSM )
	end

	local function handBikeAnimation2()
		local hand = gamePanel.bikeHand
		local bikeWheel = gamePanel.bikeWheel
		local time = 1500
		local radius = bikeWheel.radius*.65
		local maxSteps = 3

		hand.x = bikeWheel.x - radius + 10
		hand.y = bikeWheel.contentBounds.yMin + 10
		hand.alpha = 1
		 
		handBikeAnimation( time, hand, radius, hand.x, hand.y, houseFSM.current )
		
		gamePanel:addBikeTutorialListener( maxSteps, gameFlow.updateFSM )
	end

	local function handExitAnimation()
		local hand = gamePanel.exitHand
		local time = 1000
		local wait = 200
		local exit = house:findObject( "exit" )

		hand.x = exit.contentBounds.xMin - 5
		hand.y = exit.contentBounds.yMax - 5
		hand.rotation = - 80
		hand.alpha = 1
		 
		gamePanel.executeButton.executionsCount = 0
		handDirectionAnimation( time, wait, hand, hand.x, hand.y, hand.x, hand.y + 5, houseFSM.current )
		gamePanel.restartExecutionListeners()
	end

	local function goBackAnimation()
		local steps = 3
		local time = steps * 400

		brother.animation = true 
		path:hidePath()
		character.xScale = -1
		transition.to( character, { time = time, x = character.x - tilesSize * steps } )

		return time
		end

		local function brotherChallengeAnimation()
		local steps = 4.5
		local time = 400 * steps
		local hidingWallLayer = house:findLayer( "hidingWall" ) 
		local brotherPosition = house:findObject( "brother" )

		path:hidePath()
		for i = 1, hidingWallLayer.numChildren do
		  hidingWallLayer[i].alpha = 1
		end 
		brother.alpha = 1
		brother.x = brotherPosition.x 
		brother.y = brotherPosition.y
		brother.xScale = - 1

		local function flipCharacter()
		  character.xScale = 1
		end

		local function closure()
			brother.animation = nil 
			timer.performWithDelay( 2400, flipCharacter )
		end

		transition.to( brother, { time = time, x = brother.x - tilesSize * steps, onComplete =  closure } )

		return time
	end

	local function brotherJumpingAnimation()
		local time = 1500

		transition.to( brother, { rotation = 7, time = time, y = brother.y - 5, transition = easing.inBounce,
		onComplete =  
		  function()
		    transition.to( brother, { rotation = 0, time = time, y = brother.y + 5, transition = easing.outBounce } )
		  end
		 } )

		return 0
	end

	local function brotherLeavingAnimation()
		local steps = 4.5
		local time = 400 * steps
		local hidingWallLayer = house:findLayer( "hidingWall" ) 

		brother.animation = true 
		brother.xScale = 1
		transition.to( brother, { time = time, x = brother.x + tilesSize * steps, onComplete = 
		  function()
		    for i = 1, hidingWallLayer.numChildren do
		      hidingWallLayer[i].alpha = 0
		    end 
		  end
		 } )

		return time
		end

		local function characterLeaveAnimation()
		local steps = 3
		local time = steps * 400
		character.xScale = 1
		transition.to( character, { time = time, x = character.x + tilesSize * steps } )

		return time
	end

	local function bikeAnimation()
		local time = 1000
		local bike = house:findObject( "bike" )
		local completePuzzle = house:findObject( "completePuzzle" )
		local xPos, yPos = persistence.startingPoint( "house" ) 
		local mom = house:findObject( "mom" )

		transition.fadeIn( completePuzzle, { time = time, 
		  onComplete =  
		    function()
		      for k, v in pairs( puzzle.bigPieces ) do
		        puzzle.bigPieces[k].alpha = 0
		      end
		      bike.alpha = 1
		      transition.fadeOut( completePuzzle, { time = time, 
		        onComplete =  
		          function()
		            characterLayer = house:findLayer("character")
		            characterLayer:insert( bike )
		            transition.scaleTo( bike, { time = time * 3, xScale = .5, yScale = .5, x = xPos, y = yPos,
		              onComplete = 
		                function()
		                  bikeLayer = house:findLayer("bike")
		                  bikeLayer:insert( bike )
		                end
		             } )
		          end
		        } )
		    end

		  } )

		return time * 7
	end

	local function gotoInitialPosition()
		local stepsX, stepsX2, stepsY
	    local flipX, flipX2, flipY
	    local time = 600
	    local bike = house:findObject( "bike" )

	    flipX = character.stepping.flipX
	    flipY = character.stepping.flipY
	    flipX2 = character.stepping.flipX2 

	    stepsX = character.stepping.stepsX
	    stepsY = character.stepping.stepsY
	    stepsX2 = character.stepping.stepsX2

	    path:hidePath()

	    local function hideBike()
	        transition.fadeOut( bike, { time = time } )
	    end

	    local function gotoSteps( x, y, time, onComplete, flip )
	      character.xScale = flip
	      transition.to( character, { time = math.abs(time), x = character.x + x, y = character.y + y, onComplete = onComplete } )
	    end

	    local function flip()
	      hideBike()
	      character.xScale = 1
	    end

	    local function gotoStepsX2()
	      gotoSteps( stepsX2 * tilesSize, 0, stepsX2 * 600, flip, flipX2 )
	    end

	    local function gotoStepsY()
	      gotoSteps( 0, stepsY * tilesSize, stepsY * 600, gotoStepsX2, flipY )
	    end

	    local function gotoStepsX()
	      gotoSteps( stepsX * tilesSize, 0, stepsX * 600, gotoStepsY, flipX )
	    end

	    gotoStepsX()

	    return math.abs( time*stepsX ) + math.abs( time*stepsY ) + math.abs( time*stepsX2 )
	end

	local function enterHouseAnimation( wonSurprise )
		local startingPoint = house:findObject("start")
		local time = 800

	  	physics.removeBody( character )
	  	character.x = startingPoint.x - tilesSize * 2 - 3
	  	character.y = startingPoint.y - 6
	  	mom.x = character.x 
	  	mom.y = character.y 
	  	character.xScale = 1

	  	transition.fadeIn( character, { delay = 1400, time = 400 } )
	  	transition.fadeIn( mom, { time = 400 } )
	  	transition.fadeIn( brother, { delay = 3000, time = 400 } )
	  	path:hidePath()
	  	transition.to( mom, { time = time * 2, x = mom.x + tilesSize * 2 + 5, 
	  		onComplete = 
	  			function()
	  				transition.to( mom, { time = time, y = mom.y - tilesSize } )
	  				transition.to( character, { time = time * 2, x = character.x + tilesSize * 2 + 3,
	  				onComplete =
	  					function()
	  						physics.addBody( character )
						  	character.isFixedRotation = true
						  	if ( wonSurprise == false ) then 
						  		timer.performWithDelay( 800, gameFlow.updateFSM )
						  	end
	  					end
	  				} )
	  			end
	  		} )

	  	if ( wonSurprise == true ) then 
	  		brother.xScale = 1
	  		brother.x = startingPoint.x - tilesSize * 2
	  		brother.y = startingPoint.y - 6
	  		transition.to( brother, { delay = 3000, time = time, x = brother.x + tilesSize,
	  		onComplete =
	  			function()
	  				transition.to( brother, { time = time, y = brother.y + tilesSize,
	  					onComplete = function()
	  						transition.to( brother, { time = time * 4, x = brother.x + tilesSize * 4,
	  						onComplete = function()
	  							brother.xScale = -1
	  							timer.performWithDelay( 800, gameFlow.updateFSM )
	  						end

	  						} )
	  					end
	  				} )
	  			end

	  		} )
	  	end 

	  	return math.huge
	end

	local function legoAnimation( wonSurprise )
		local xPos, yPos 


		if ( wonSurprise == true ) then
			xPos = character.x
			yPos = character.y + 20
		else 
			xPos = brother.x
			yPos = brother.y + 20
		end 

		local toy = house:findObject( "toy" )
		transition.fadeIn( toy, { time = 800, 
			onComplete = 
				function()
					transition.scaleTo( toy, { time = 2600, xScale = .25, yScale = .25, x = xPos, y = yPos,
						onComplete = 
							function()
								transition.fadeOut( toy, { time = 800, 
									onComplete =  
										function()
											timer.performWithDelay( 600, gameFlow.updateFSM )
										end
									} )
							end
					} )
				end
			} )

		return math.huge
	end

	animation["momAnimation"] = momAnimation
	animation["handDirectionAnimation1"] = handDirectionAnimation1
	animation["handDirectionAnimation2"] = handDirectionAnimation2
	animation["handDirectionAnimation3"] = handDirectionAnimation3
	animation["handExecuteAnimation"] = handExecuteAnimation
	animation["gamePanelAnimation"] = gamePanelAnimation
	animation["handBikeAnimation1"] = handBikeAnimation1
	animation["handBikeAnimation2"] = handBikeAnimation2 
	animation["handExitAnimation"] = handExitAnimation 
	animation["goBackAnimation"] = goBackAnimation
	animation["brotherChallengeAnimation"] = brotherChallengeAnimation
	animation["brotherJumpingAnimation"] = brotherJumpingAnimation
	animation["brotherLeavingAnimation"] = brotherLeavingAnimation
	animation["characterLeaveAnimation"] = characterLeaveAnimation
	animation["bikeAnimation"] = bikeAnimation
	animation["gotoInitialPosition"] = gotoInitialPosition
	animation["enterHouseAnimation"] = enterHouseAnimation
	animation["legoAnimation"] = legoAnimation

	return animation
end

return M