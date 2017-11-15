local persistence = require "persistence"

local M = { }

function M.new( house, puzzle, gamePanel, path, tutorialFSM, gameFlow ) 
	local animation = { }
	local mom = house:findObject( "mom" )
	local character = house:findObject( "character" )
	local tilesSize = 32

	local function momAnimation( )
		local time = 5000
		transition.to( mom, { time = time, x = character.x, y = character.y - tilesSize } )

		return time + 500
	end

	local function handDirectionAnimation( time, wait, hand, initialX, initialY, x, y, state )
		if ( state ~= tutorialFSM.current ) then
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
		 

		handDirectionAnimation( time, wait, hand, hand.originalX, hand.originalY, hand.x, box.y - 5, tutorialFSM.current )
		
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
		 

		handDirectionAnimation( time, wait, hand, hand.originalX, hand.originalY, hand.x, box.y - 5, tutorialFSM.current )
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
		 

		handDirectionAnimation( time, wait, hand, hand.x, hand.y, hand.x, box.y - 5, tutorialFSM.current )
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
		handDirectionAnimation( time, wait, hand, executeButton.contentBounds.xMin + 2, executeButton.y, executeButton.contentBounds.xMin + 10, executeButton.y - 5, tutorialFSM.current )
		  

		gamePanel:addExecuteButtonListener( gameFlow.updateFSM )
	end


	local function gamePanelAnimation()
		gamePanel:showDirectionButtons( true )
	end

	local function handBikeAnimation( time, hand, radius, initialX, initialY, state )
		if ( state ~= tutorialFSM.current ) then
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
		local radius = bikeWheel.radius/2
		local maxSteps = 2

		hand.x = bikeWheel.x - radius + 2
		hand.y = bikeWheel.contentBounds.yMin - 2
		hand.alpha = 1
		 
		handBikeAnimation( time, hand, radius, hand.x, hand.y, tutorialFSM.current )
		
		gamePanel:addBikeTutorialListener( maxSteps, gameFlow.updateFSM )
	end

	local function handBikeAnimation2()
		local hand = gamePanel.bikeHand
		local bikeWheel = gamePanel.bikeWheel
		local time = 1500
		local radius = bikeWheel.radius/2
		local maxSteps = 3

		hand.x = bikeWheel.x - radius + 2
		hand.y = bikeWheel.contentBounds.yMin - 2
		hand.alpha = 1
		 
		handBikeAnimation( time, hand, radius, hand.x, hand.y, tutorialFSM.current )
		
		gamePanel:addBikeTutorialListener( maxSteps, gameFlow.updateFSM )
	end

	local function handExitAnimation()
		local hand = gamePanel.exitHand
		local time = 1000
		local wait = 200
		local exit = house:findObject( "exit" )

		hand.x = exit.contentBounds.xMin - 5
		hand.y = exit.contentBounds.yMax - 20
		hand.rotation = - 80
		hand.alpha = 1
		 
		gamePanel.executeButton.executionsCount = 0
		handDirectionAnimation( time, wait, hand, hand.x, hand.y, hand.x, hand.y + 5, tutorialFSM.current )
		gamePanel.restartExecutionListeners()
	end

	local function goBackAnimation()
		local steps = 3
		local time = steps * 400

		path:hidePath()
		character.xScale = -1
		transition.to( character, { time = time, x = character.x - tilesSize * steps } )

		return time
		end

		local function brotherChallengeAnimation()
		local brother = house:findObject( "brother" )
		local steps = 4.5
		local time = 400 * steps
		local hidingWallLayer = house:findLayer( "hidingWall" ) 

		path:hidePath()
		for i = 1, hidingWallLayer.numChildren do
		  hidingWallLayer[i].alpha = 1
		end 
		brother.alpha = 1

		local function flipCharacter()
		  character.xScale = 1
		end

		transition.to( brother, { time = time, x = brother.x - tilesSize * steps, onComplete =  timer.performWithDelay( 2400, flipCharacter ) } )

		return time
	end

	local function brotherJumpingAnimation()
		local brother = house:findObject( "brother" )

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
		local brother = house:findObject( "brother" )
		local steps = 4.5
		local time = 400 * steps
		local hidingWallLayer = house:findLayer( "hidingWall" ) 

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
		local stepsX, stepsY 
		local time = 600
		local bike = house:findObject( "bike" )

		path:hidePath()
		local function flip()
		  character.xScale = 1
		end

		local function delayedflip()
			  timer.performWithDelay( 200, flip )
		end

		local function hideBike()
			  transition.fadeOut( bike, { time = time } )
		end


		if ( puzzle.collectedPieces.last == "2" ) then
		stepsX = 2
		  stepsY = 3

		  transition.to( character, { time = stepsY * time, y = character.y + stepsY * tilesSize,
		    onComplete = 
		      function()
		        character.xScale = -1 
		        transition.to( character, { time = stepsX * time, x = character.x - stepsX * tilesSize, 
		          onComplete = 
		            function()
		              hideBike()
		              delayedflip()
		            end
		          } )
		      end
		    } )
		elseif ( puzzle.collectedPieces.last == "3" ) then 
		  stepsX = 4
		  stepsY = 3
		  stepsX2 = 2

		  character.xScale = -1
		  transition.to( character, { time = stepsX * time, x = character.x - stepsX * tilesSize,
		    onComplete = 
		      function()
		        transition.to( character, { time = stepsY * time, y = character.y + stepsY * tilesSize,
		        onComplete = 
		          function()
		            transition.to( character, { time = stepsX2 * time, x = character.x - stepsX2 * tilesSize, 
		              onComplete = 
		                function()
		                  gamePanel:updateBikeMaxCount( 3 )
		                  hideBike()
		                  delayedflip()
		                end 
		              } )
		          end
		         } )
		      end
		    } )
		  stepsX = stepsX + stepsX2
		elseif ( puzzle.collectedPieces.last == "4" ) then 
		  stepsX = 4
		  stepsY = 0
		  character.xScale = -1
		  transition.to( character, { time = stepsX * time, x = character.x - stepsX * tilesSize, onComplete = hideBike } )
		end


		return time * stepsX + time*stepsY
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

	return animation
end

return M