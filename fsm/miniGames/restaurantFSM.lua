local fsm = require "com.fsm.src.fsm"

local gameFlow = require "fsm.gameFlow"

local feedback = require "fsm.feedback"

local sceneTransition = require "sceneTransition"

local restaurantMessages = require "fsm.messages.restaurantMessages"

local restaurantAnimations = require "fsm.animations.restaurantAnimations"



local M = { }

local animation = {}

local message = {}


function M.new( restaurant, character, ingredients, listeners, collision, instructionsTable, miniGameData, gameState, gamePanel, path )
	local restaurantFSM
	--local character = restaurant:findObject( "character" )
	local cook = restaurant:findObject( "cook" )  
	local tilesSize = 32
	local messageBubble
	local message = restaurantMessages
	local animation
	local collisionsList = { }

	local function resetCollision()
		collision.bench = false
		collision.otherObjects = false
		collision.organizer = false
		collision.collectedAll = false 
		collision.collectedNone = true 
		collision.inOrder = true
		collision.wrongIngredient = false
	end

	function M.execute()
		local organizerHand = restaurant:findObject( "organizerHand" )
		local bikeWheelMaxCount = 5

		organizerHand.originalX = organizerHand.x  
		organizerHand.originalY = organizerHand.y 

		--gamePanel.tiled.alpha = 0

		M.waitFeedback = false

		gamePanel:updateBikeMaxCount( bikeWheelMaxCount )

		restaurantFSM = fsm.create({
	  	  initial = "start",
	  	  events = {
	  	  	{ name = "showAnimation", from = "start", to = "enterHouseAnimation", nextEvent = "showAnimation" },

	  	  	{ name = "showGamePanel", from = "start", to = "gamePanel", nextEvent = "enableListeners" },
	  	  	--{ name = "enableListeners",  from = "gamePanel",  to = "restartListeners", nextEvent = "checkFeedbackWait" },
	  	  	{ name = "enableListeners",  from = "start",  to = "restartListeners", nextEvent = "nextRecipe" },
	  	  	{ name = "nextRecipe",  from = "restartListeners",  to = "recipe1", nextEvent = "checkProgress" },
	  	  	{ name = "nextRecipe",  from = "repeat",  to = "recipe1", nextEvent = "checkProgress" },
	  	  	{ name = "checkProgress",  from = "recipe1",  to = "progress1", nextEvent = "nextRecipe" },
	  	  	{ name = "nextRecipe",  from = "progress1",  to = "recipe2", nextEvent = "checkProgress" },
	  	  	{ name = "checkProgress",  from = "recipe2",  to = "progress2", nextEvent = "nextRecipe" },
	  	  	{ name = "nextRecipe",  from = "progress2",  to = "recipe3", nextEvent = "checkProgress" },
	  	  	{ name = "checkProgress",  from = "recipe3",  to = "progress3" },-- nextEvent = "nextRecipe" },

	  	  	{ name = "showFeedback", from = "progress1", to = "feedbackAnimation", nextEvent = "nextRecipe" },
	  	  	{ name = "showFeedback", from = "progress2", to = "feedbackAnimation", nextEvent = "nextRecipe" },
	  	  	{ name = "showFeedback", from = "progress3", to = "feedbackAnimation", nextEvent = "nextRecipe" },
	  	  	{ name = "repeatLevel", from = "feedbackAnimation", to = "repeat", nextEvent = "nextRecipe" },
	  	  	--{ name = "checkProgress",  from = "repeat",  to = "progress_repeat", nextEvent = "nextRecipe" },

	  	  	--{ name = "checkFeedbackWait",  from = "restartListeners",  to = "checkWait", nextEvent = "showFeedback" },
	  	  	{ name = "showFeedback",  from = "checkWait",  to = "feedbackAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "checkFeedbackWait",  from = "repeat",  to = "checkWait", nextEvent = "showFeedback" },
	  	  	--{ name = "repeatLevel", from = "feedbackAnimation", to = "repeat", nextEvent = "checkFeedbackWait" },
	  	  	{ name = "showObligatoryMessage",  from = "feedbackAnimation",  to = "teacherBubble_msg9", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "teacherBubble_msg9", to = "cookJumpingAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "cookJumpingAnimation",  to = "teacherBubble_msg10", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "teacherBubble_msg10", to = "leaverestaurantAnimation", nextEvent = "saveGame" },
	  	  	{ name = "saveGame",  from = "leaverestaurantAnimation",  to = "save", nextEvent = "finishLevel" },
	  	  	{ name = "finishLevel",  from = "save",  to = "finish" },
	  	  },
	  	  callbacks = {
	  	  	on_before_event = 
	  	      function( self, event, from, to ) 
	  	        if ( ( messageBubble ) and ( messageBubble.text ) ) then
			        messageBubble.text:removeSelf()
			        messageBubble.text = nil
			        transition.cancel( messageBubble.blinkingDart )
			        messageBubble.blinkingDart.alpha = 0
			        messageBubble.blinkingDart = nil
			    end
	  	      end,

	  	    on_showAnimation = 
	  	      function( self, event, from, to ) 
	  	        local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )
	  	        local function closure() 
	  	          	gamePanel.stopExecutionListeners()
	  	          	local animationWait
	  	          	if ( self.current == "brotherAnimation" ) then 
	  	          		animationWait = animation[self.current]( miniGameData.previousStars, message )
	  	          	elseif ( self.current == "leaverestaurantAnimation" ) then 
	  	          		animationWait = animation[self.current]( collision.obj )
	  	          	else 
	  	          		animationWait = animation[self.current]()
	  	          	end

	  	          	if ( animationWait ~= math.huge ) then 
	  	          		timer.performWithDelay( animationWait, gameFlow.updateFSM ) 
	  	      	  	end
	  	        end

	  	        if ( ( from == "transitionState" ) and ( wait ) ) then 
	  	          	timer.performWithDelay( wait, closure )
	  	        else
	  	          	closure()
	  	        end
	  	      end,

	  	    on_showMessage = 
	  	      function( self, event, from, to ) 
	  	        local messageBubble, msg = self.current:match( "([^,]+)_([^,]+)" )
	  	        local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )
	  	        
	  	        if ( messageBubble == "brotherBubble" ) then 
	  	        	if ( character == restaurant:findObject( "Ada" ) ) then 
	  	        		messageBubble = restaurant:findObject( "turingBubble" )
	  	        	else
	  	        		messageBubble = restaurant:findObject( "adaBubble" )
	  	        	end
	  	        else 
	  	        	messageBubble = restaurant:findObject( "cookBubble" )
	  	        end

	  	        local function closure() 
	  	          	gamePanel.stopExecutionListeners()
	  	          	gameFlow.showText( messageBubble, message[ msg ] ) 
	  	        end

	  	        if ( ( from == "transitionState" ) and ( wait ) ) then 
	  	          	timer.performWithDelay( wait, closure )
	  	        else
	  	          	closure()
	  	        end

	  	      end,

	  	    on_showObligatoryMessage = 
	  	      function( self, event, from, to ) 
	  	        local messageBubble, msg = self.current:match( "([^,]+)_([^,]+)" )
	  	        local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )
	  	        
	  	        if ( messageBubble == "brotherBubble" ) then 
	  	        	if ( character == restaurant:findObject( "Ada" ) ) then 
	  	        		messageBubble = restaurant:findObject( "turingBubble" )
	  	        	else
	  	        		messageBubble = restaurant:findObject( "adaBubble" )
	  	        	end
	  	        else 
	  	        	messageBubble = restaurant:findObject( "cookBubble" )
	  	        end

	  	        local function closure() 
	  	          	gameFlow.showText( messageBubble, message[ msg ] ) 
	  	          	gamePanel.stopExecutionListeners()
	  	        end

	  	        if ( ( from == "transitionState" ) and ( wait ) ) then 
	  	          	timer.performWithDelay( wait, closure )
	  	        else 
	  	          	closure()
	  	        end
	  	      end,

	  	    on_showMessageAndAnimation = 
	  	      function( self, event, from, to )
	  	        local messageBubble, msg, animationName = self.current:match( "([^,]+)_([^,]+)_([^,]+)" ) 
	  	        local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )

	  	        if ( messageBubble == "brotherBubble" ) then 
	  	        	if ( character == restaurant:findObject( "Ada" ) ) then 
	  	        		messageBubble = restaurant:findObject( "turingBubble" )
	  	        	else
	  	        		messageBubble = restaurant:findObject( "adaBubble" )
	  	        	end
	  	        else 
	  	        	messageBubble = restaurant:findObject( "cookBubble" )
	  	        end

	  	        gameFlow.showText( messageBubble, message[ msg ] )
	  	        gamePanel.stopExecutionListeners()
	  	        if ( ( from == "transitionState" ) and ( wait ) ) then 
	  	          	timer.performWithDelay( wait, animation[animationName] )
	  	        else
	  	          	animation[animationName]()
	  	        end
	  	      end,

	  	    on_transitionEvent = 
	  	      function( self, event, from, to ) 
	  	        local _, _, animationName = self.from:match( "([^,]+)_([^,]+)_([^,]+)" ) 
	  	        
	  	        gamePanel.stopExecutionListeners()
	  	        if ( ( animationName ) and ( animationName == "handExecuteAnimation" ) ) then
	  	          	transition.fadeOut( messageBubble, { time = 400 } )
	  	        end

	  	        if ( ( messageBubble ) and ( messageBubble.text ) ) then
	  	          	transition.fadeOut( messageBubble.text, { time = 400 } )
	  	          	transition.fadeOut( messageBubble, { time = 400 } )
	  	          	messageBubble.text:removeSelf()
	  	          	messageBubble.text = nil
	  	          	transition.cancel( messageBubble.blinkingDart )
	  	          	messageBubble.blinkingDart.alpha = 0
	  	          	messageBubble.blinkingDart = nil
	  	        end
	  	        gameFlow.updateFSM()
	  	      end,

	  	    on_showFeedback = 
	  	      function( self, event, from, to ) 
	  	          	local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )
	  	          	local executeButton = gamePanel.executeButton
	  	          	local stars = 0
	  	          	local msg = 1 

	  	          	print( "feedback" )
	  	          	if ( ( collision.wrongIngredient == true ) and ( collision.collectedAll == true ) ) then 
	  	          		stars = 0
	  	          		msg = 4 
	  	          	elseif ( collision.wrongIngredient == true ) then 
	  	          		stars = 0
	  	          		msg = 2
	  	          	elseif ( ( collision.collectedAll == false ) or ( collision.organizer == false ) ) then 
	  	          		stars = 0
	  	          		msg = 1
	  	          	elseif ( collision.inOrder == false ) then
	  	          		stars = 0
	  	          		msg = 3 
	  	          	elseif ( ( instructionsTable.last == 6 ) and ( collision.table == false ) and ( collision.table == false ) ) then
	  	          	    stars = 3
	  	          	elseif ( ( instructionsTable.last == 6 ) ) then 
	  	          		stars = 2
	  	          		msg = 1
	  	          	elseif ( gamePanel.bikeWheel.maxCount < bikeWheelMaxCount ) then
	  	          	    stars = 2

	  	          	    if (  ( collision.table == true ) or ( collision.table == true )  ) then
	  	          	    	msg = 3
	  	          	    else
	  	          	    	msg = 2
	  	          	    end
	  	          	
	  	          	else 
	  	          	    stars = 1

	  	          	    if (  ( collision.table == true ) or ( collision.table == true )  ) then
	  	          	    	msg = 2
	  	          	    end
	  	          	end
	  	          	gamePanel.tiled:insert( feedback.showAnimation( "restaurant", stars, msg, gameFlow.updateFSM ) )
	  	       		miniGameData.stars = stars 
	  	        end,

	  	    on_saveGame = 
	  	      function( self, event, from, to ) 
	  	        miniGameData.isComplete = true 
	  	        gameState:save( miniGameData )
	  	        gameFlow.updateFSM()
	  	      end,

	  	    on_finishLevel = 
	  	      function( self, event, from, to ) 
	  	        transition.cancel()
	  	        gamePanel:stopAllListeners()
	  	        character.stepping.point = "exit"
	  	        timer.performWithDelay( 800, sceneTransition.gotoMap )
	  	      end,

	  	    on_repeatLevel = 
	  	      function( self, event, from, to ) 
	  	        local startingPoint = restaurant:findObject("start")

	  	        print( "ONREPEAT" )
	  	        --physics.pause()
	  	        character.ropeJoint:removeSelf()
	  	        physics.removeBody( character )
	  	        physics.removeBody( character.rope )
	  	        character.x = startingPoint.x
	  	        character.y = startingPoint.y - 3
	  	        character.rope.x, character.rope.y = character.x, character.y + 4
	  	        physics.start()
	  	        physics.addBody( character )
	  	        physics.addBody( character.rope )
	  	        character.ropeJoint = physics.newJoint( "rope", character.rope, character, 0, 0 )
	  	        character.isFixedRotation = true 
	  	        character.xScale = - 1

	  	        resetCollision()
	  	        collisionsList = { }

	  	        if ( messageBubble ) then 
	  	          	messageBubble.alpha = 0
	  	          	if ( messageBubble.blinkingDart ) then 
	  	          	  messageBubble.blinkingDart.alpha = 0
	  	          	end
	  	        end

	  	        for k, v in pairs( ingredients.first ) do
	  	        	v.x = v.originalX
	  	        	v.y = v.originalY
	  	        	v.alpha = 1
	  	        end

	  	        for k, v in pairs( ingredients.second ) do
	  	        	v.x = v.originalX
	  	        	v.y = v.originalY
	  	        	v.alpha = 1
	  	        end

	  	        for k, v in pairs( ingredients.third ) do
	  	        	v.alpha = 0
	  	        end

	  	        for k, v in pairs( ingredients.remaining ) do
	  	        	ingredients.remaining[k] = nil 
	  	        end
	  	        ingredients.collected = { }
	  	        gamePanel:updateBikeMaxCount( bikeWheelMaxCount )

	  	        transition.fadeOut( restaurant:findObject( "recipe2" ), { time = 800 } )
	  	        transition.fadeOut( restaurant:findObject( "recipe3" ), { time = 800 } )

	  	        for k, v in pairs( ingredients.check ) do
	  	        	for r, s in pairs( v ) do
	  	        		s.alpha = 0
	  	        	end
	  	        end

	  	        for k, v in pairs( ingredients.uncheck ) do
	  	        	for r, s in pairs( v ) do
	  	        		s.alpha = 0
	  	        	end
	  	        end
	  	        gameFlow.updateFSM()  --tirar?

	  	        --[[instructionsTable:reset()
	  	        instructionsTable.steps = { 5, 1, 9, 2, 1, 1, 4, 3, 1 } 
			  	instructionsTable.direction = { "up", "right", "left", "right", "up", "left", "down", "right", "up" }
			  	instructionsTable.last = 9]]
	  	    end,

	  	    on_enableListeners = 
	  	      function( self, event, from, to ) 
	  	        if ( to == "restartListeners" ) then 
	  	        	gamePanel.restartExecutionListeners()
	  	        end
	  	    end,

	  	    on_showGamePanel = 
	  	      	function( self, event, from, to ) 
	  	        	transition.fadeIn( gamePanel.tiled, { time = 1400 } )
	  	        	gameFlow.updateFSM()
	  	    	end,

	  	    on_checkFeedbackWait = 
	  	    	function( self, event, from, to ) 
	  	        	--transition.fadeOut( gamePanel.tiled, { time = 400 } )
	  	        	if ( M.waitFeedback == false ) then 
		  	        	gameFlow.updateFSM()
	  	    		else
	  	    			M.waitFeedback = false
	  	    		end
	  	    	end,

	  	    on_checkProgress = 
	  	    	function( self, event, from, to ) 
	  	        	--transition.fadeOut( gamePanel.tiled, { time = 400 } )
	  	        	local function wait()
	  	        		if ( M.waitFeedback == false ) then 
		  	        		gameFlow.updateFSM()
		  	    		else
		  	    			M.waitFeedback = false
		  	    		end
	  	        	end

	  	        	print( "coll all: " .. tostring( collision.collectedAll ) .. "; coll none: " .. tostring( collision.collectedNone) .. " ; wrong: " .. tostring(collision.wrongIngredient) .. " ; organizer: " .. tostring(collision.organizer) )

	  	    		if ( ( collision.collectedAll == true ) and ( collision.wrongIngredient == false ) and ( collision.organizer == true ) and ( collision.inOrder == true ) )  then 
	  	    			timer.performWithDelay( 400, wait )
	  	    		else
	  	    			local ingredientsList, uncheck
	  	    			if ( ( self.current == "progress1" ) or ( self.current == "progress_repeat" ) ) then 
				        	ingredientsList = ingredients.first 
				        	uncheck = ingredients.uncheck.first
				       	elseif ( self.current == "progress2" ) then 
				       		ingredientsList = ingredients.second
				       		uncheck = ingredients.uncheck.second
				       	elseif ( self.current == "progress3" ) then 
				       		ingredientsList = ingredients.third
				       		uncheck = ingredients.uncheck.third
				       	end

				       	self.nextEvent = "showFeedback"
				       	if ( collision.collectedNone == true ) then 
				       		gameFlow.updateFSM()
				       	elseif ( ( collision.wrongIngredient == true ) or ( collision.organizer == false ) ) then 
				       		wait()
				       	else 
					       	local found
		  	    			for k, v in pairs( ingredientsList ) do
		  	    				found = false
		 
		  	    				for r, s in pairs( ingredients.collected ) do
		  	    					if v == s then found = true end 
		  	    				end 

		  	    				if ( found == false ) then 
									transition.fadeIn( uncheck[ v.number ], { time = 400, delay = 400 * ( k - 1 ), 
										onComplete = 
											function()
												if ( k == #ingredientsList ) then timer.performWithDelay( 600, wait ) end
											end
										} )
	        					end
	        				end
	        			end
	  	    		end
 	  	    	end,

 	  	    on_nextRecipe = 
	  	    	function( self, event, from, to ) 
	  	        	table.insert( collisionsList, collision )

	  	        	gamePanel.restartExecutionListeners()

	  	        	if ( self.current == "recipe1" ) then
	  	        		transition.fadeIn( restaurant:findObject( "recipe1" ), { time = 800 } )

	  	        	elseif ( self.current == "recipe2" ) then 
	  	        		ingredients.collected = {}
	  	        		
	  	        		gamePanel:updateBikeMaxCount( 9 )
	  	        		transition.fadeOut( restaurant:findObject( "recipe1" ), { time = 800 } )
		  				transition.fadeIn( restaurant:findObject( "recipe2" ), { time = 800 } )
		  				transition.fadeIn( ingredients.third[2], { time = 800 } )
		  				for k, v in pairs( ingredients.uncheck.first ) do
			  				v.alpha = 0
		  				end
		  				for k, v in pairs( ingredients.check.first ) do
			  				v.alpha = 0
		  				end

		  			elseif ( self.current == "recipe3" ) then 
	  	        		ingredients.collected = {}
	  	        		
	  	        		gamePanel:updateBikeMaxCount( 6 )
	  	        		transition.fadeOut( restaurant:findObject( "recipe2" ), { time = 800 } )
		  				transition.fadeIn( restaurant:findObject( "recipe3" ), { time = 800 } )
		  				transition.fadeIn( ingredients.third[1], { time = 800 } )
		  				for k, v in pairs( ingredients.uncheck.second ) do
			  				v.alpha = 0
		  				end
		  				for k, v in pairs( ingredients.check.second ) do
			  				v.alpha = 0
		  				end

		  				physics.addBody( restaurant:findObject( "stove" ), { bodyType = "static", isSensor = true } )
	  	        	end

	  	        	resetCollision()
	  	    	end,
	  	  }
	  	})

		gameFlow.new( restaurantFSM, listeners, restaurant )
		M.updateFSM = gameFlow.updateFSM
		M.fsm = restaurantFSM
		animation = restaurantAnimations.new( restaurant, character, gamePanel, path, restaurantFSM, gameFlow )
	  	--restaurantFSM.showObligatoryMessage()
	  	--restaurantFSM.showAnimation()
	  	--restaurantFSM.showGamePanel()
	  	restaurantFSM.enableListeners()
	  	restaurantFSM.nextRecipe()
	end
end

return M