local persistence = require "persistence"

local M = { }

function M.new( restaurant, ingredients, character, gamePanel, path, restaurantFSM, gameFlow ) 
	local animation = { }
	local cook = restaurant:findObject( "cook" )
	local tilesSize = 32
	local brother

	if ( character == restaurant:findObject( "ada") ) then 
		brother = restaurant:findObject( "turing")
	else
		brother = restaurant:findObject( "ada") 
	end

	local function flip( delay, character, scale )
		local function closure()
			character.xScale = scale
		end
		
		timer.performWithDelay( delay, closure )
	end

	local function enterHouseAnimation()
		local startingPoint = restaurant:findObject("start")
		local time = 800

	  	physics.removeBody( character )
	  	character.x = startingPoint.x + tilesSize * 2
	  	character.y = startingPoint.y - 6
	  	cook.x = character.x - 2
	  	cook.y = character.y 
	  	cook.alpha = 1
	  	cook.xScale = -1
	  	character.xScale = -1

	  	path:hidePath()
	  	transition.fadeIn( character, { delay = time * 2 } )
		transition.to( character, { delay = time * 2, time = time * 2, x = character.x - tilesSize * 2,
			onComplete =
				function()
					physics.addBody( character )
			  	character.isFixedRotation = true 
			  	timer.performWithDelay( 800, gameFlow.updateFSM )
				end
			} )
	  	transition.to( cook, { time = time * 4, x = cook.x - tilesSize * 4 + 5, 
	  		onComplete = 
	  			function()
	  				transition.to( cook, { time = time * 2, y = cook.y - tilesSize * 2, 
	  					onComplete =  
	  						function()
	  							transition.to( cook, { time = time * 2, x = cook.x - tilesSize * 2, 
	  								onComplete = 
	  								function()
	  									cook.xScale = 1
	  								end
	  								} )
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
			brother.x = character.x + tilesSize * 2
        	brother.y = character.y

			transition.to( brother, { time = time, x = brother.x - tilesSize, 
				onComplete = 
					function()
						transition.to( brother, { time = time, y = brother.y + tilesSize,
							onComplete = 
								function()
									transition.to( brother, { time = time * 6, x = brother.x - tilesSize * 6, 
										onComplete = 
											function()
												flip( 300, brother, 1 )
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
		elseif ( stars == 1 ) then
			message["msg1"] = message["msg3"] 
			brotherJumpingAnimation()
		else
			gameFlow.updateFSM( _, "transitionEvent" )
		end 

		
		return math.huge

	end

	local function brotherLeaveAnimation()
		local time = 500

		brother.animation = true 
		brother.xScale = -1
		local function closure()
			transition.to( brother, { time = time * 3, x = brother.x - tilesSize * 3, 
				onComplete =  
					function()
						transition.to( brother, { time = time * 2, y = brother.y - tilesSize * 2, 
							onComplete =  
								function()
									transition.to( brother, { time = time * 6, x = brother.x - tilesSize * 6, 
										onComplete = 
											function()
												brother.alpha = 0
												gameFlow.updateFSM()
											end
										} )
								end
							} )
					end
				})
		end
		timer.performWithDelay( 600, closure )

		return math.huge
	end

	local function handAnimation( time, count, wait, hand, initialX, initialY, x, y, state )
		if ( ( hand.stop == true ) or ( count == 0 ) ) then
			transition.fadeOut( hand, { time = 800 } )
		  return
		else 
		  hand.x = initialX
		  hand.y = initialY
		  transition.to( hand, { time = time, x = x, y = y } )
		  local closure = function ( ) return handAnimation( time, count - 1, wait, hand, initialX, initialY, x, y, state ) end
		  timer.performWithDelay( time + wait, closure )
		end
	end

	local function recipeHandAnimation()
		local hand = restaurant:findObject( "recipeHand" )
		local recipe = restaurant:findObject( "recipe1" )
		local time = 1500
		local count = 3
		local wait = 800

		hand.originalX = hand.x 
		hand.originalY = hand.y
		hand.alpha = 1
		 
		transition.fadeIn( recipe, { time = 800 } )

		handAnimation( time, count, wait, hand, hand.originalX, hand.originalY, hand.x, recipe.y + 10, restaurantFSM.current )
		
		--gamePanel:addRightDirectionListener( gameFlow.updateFSM )

		return time + wait 
	end

	local function cookToStoveAnimation( )
		local time = 500
		local stepsX = 4
		local stepsX2 = 0
		local stepsY = 0
		local stepsY2 = -2

		for k, v in pairs( ingredients.second ) do
			transition.fadeOut( v, { time = 400 } )
		end

		for k, v in pairs( ingredients.check.second ) do
			transition.fadeOut( v, { time = 400 } )
		end

		for k, v in pairs( ingredients.uncheck.second ) do
			transition.fadeOut( v, { time = 400 } )
		end

		transition.fadeOut( restaurant:findObject( "recipe2" ), { time = 400 } )

		cook.animation = true 
		characterLayer = restaurant:findLayer( "character" )
		characterLayer:insert( cook )
		if ( cook.characterBlocking == true ) then 
			stepsY = 1
			stepsY2 = -3
		end

		cook.xScale = 1

		flip( 800, character, 1 )

		local function showPasta()
			transition.fadeIn( restaurant:findObject( "pasta" ), { delay = 400, time = 800, 
				onComplete =
					function()
						cook.animation = false 
						gameFlow.updateFSM()
					end
				} )
		end

		local function showIngredients( ingredient, number )
			if ( ingredient[number] ) then 
				local stove = restaurant:findObject( "stove" )
				ingredient[number].x = stove.x 
				ingredient[number].y = stove.y
				ingredient[number].alpha = 0
				transition.fadeIn( ingredient[ number ], { time = 800, onComplete =
					function()
						showIngredients( ingredient, number + 1 )
					end 
				} )

			elseif ( ingredient == ingredients.first ) then 
				showIngredients( ingredients.second, 1 )

			else 
				for i = 1, #ingredients.first do
					if ( i == #ingredients.first ) then 
						timer.performWithDelay( 800, showPasta )
					end
					transition.fadeOut( ingredients.first[i], { time = 800 } )
				end

				for i = 1, #ingredients.second do
					transition.fadeOut( ingredients.second[i], { time = 800 } )
				end
			end
		end

		local function bounce()
			transition.to( cook, { time = 50, x = cook.x + tilesSize * .1, 
				onComplete =  
					function()
						transition.to( cook, { time = 50, x = cook.x - tilesSize * .1, 
							onComplete = function()
								showIngredients( ingredients.first, 1 )
							end 
							} )
					end
			} )
		end

		local function gotoSteps( x, y, time, onComplete )
	      	transition.to( cook, { time = math.abs(time), x = cook.x + x, y = cook.y + y, onComplete = onComplete } )
	    end

	    local function gotoStepsX2()
	      	gotoSteps( stepsX2 * tilesSize, 0, stepsX2 * 600, bounce )
	    end

	    local function gotoStepsY2()
	      	gotoSteps( 0, stepsY2 * tilesSize, stepsY2 * 600, gotoStepsX2 )
	    end

	    local function gotoStepsX()
	      	gotoSteps( stepsX * tilesSize, 0, stepsX * 600, gotoStepsY2 )
	    end

	    local function gotoStepsY()
	    	local bubble = restaurant:findObject( "cookBubble" )
	    	bubble.x = bubble.x + tilesSize * 4
	    	bubble.y = bubble.y - tilesSize * 2
	      	gotoSteps( 0, stepsY * tilesSize, stepsY * 600, gotoStepsX )
	    end

	    gotoStepsY()

	    return math.huge
	end

	local function cookJumpingAnimation()
		local time = 1800

		transition.to( cook, { time = time, y = cook.y - 7, transition = easing.inBounce,
		onComplete =  
		  function()
		    transition.to( cook, { time = time, y = cook.y + 7, transition = easing.outBounce } )
		  end
		 } )

		return time * 2 + 400
	end 


	local function pastaAnimation()
		local pasta = restaurant:findObject( "pasta" )
		timeX = math.abs( pasta.x - character.x )/32 * 600
		timeY = math.abs( pasta.y - character.y + 20 )/32 * 600

		transition.to( pasta, { time = timeX + timeY, x = character.x, y = character.y + 20, 
			onComplete = 
				function()
					transition.fadeOut( pasta, { time = 800 } )
				end

			} )

		return timeX + timeY + 400
	end


	animation["cookToStoveAnimation"] = cookToStoveAnimation
	animation["enterHouseAnimation"] = enterHouseAnimation
	animation["brotherAnimation"] = brotherAnimation
	animation["brotherLeaveAnimation"] = brotherLeaveAnimation
	animation["recipeHandAnimation"] = recipeHandAnimation
	animation["cookJumpingAnimation"] = cookJumpingAnimation
	animation["pastaAnimation"] = pastaAnimation

	return animation
end

return M