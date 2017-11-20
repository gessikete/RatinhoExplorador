local fsm = require "com.fsm.src.fsm"

local gameFlow = require "fsm.gameFlow"

local feedback = require "fsm.feedback"

local sceneTransition = require "sceneTransition"

local restaurantMessages = require "fsm.messages.restaurantMessages"

local restaurantAnimations = require "fsm.animations.restaurantAnimations"



local M = { }

local animation = {}

local message = {}

function M.new( restaurant, ingredients, listeners, collision, instructionsTable, miniGameData, gameState, gamePanel, path )
	local restaurantFSM
	local character = restaurant:findObject( "character" )
	local cook = restaurant:findObject( "cook" )  
	local tilesSize = 32
	local messageBubble
	local message = restaurantMessages
	local animation
	local collisionsList = { }

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
	  	  	{ name = "enableListeners",  from = "start",  to = "restartListeners", nextEvent = "checkProgress" },
	  	  	{ name = "checkProgress",  from = "restartListeners",  to = "progress2", nextEvent = "nextRecipe" },
	  	  	{ name = "nextRecipe",  from = "progress2",  to = "recipe2", nextEvent = "checkProgress" },
	  	  	{ name = "checkProgress",  from = "recipe2",  to = "progress3", nextEvent = "nextRecipe" },
	  	  	{ name = "nextRecipe",  from = "progress3",  to = "recipe3"},-- nextEvent = "nextRecipe" },
	  	  	


	  	  	--{ name = "checkFeedbackWait",  from = "restartListeners",  to = "checkWait", nextEvent = "showFeedback" },
	  	  	{ name = "showFeedback",  from = "checkWait",  to = "feedbackAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "checkFeedbackWait",  from = "repeat",  to = "checkWait", nextEvent = "showFeedback" },
	  	  	{ name = "repeatLevel", from = "feedbackAnimation", to = "repeat", nextEvent = "checkFeedbackWait" },
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
	  	        local function closure() 
	  	          	gamePanel.stopExecutionListeners()
	  	          	gameFlow.showText( restaurant:findObject( messageBubble ), message[ msg ] ) 
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
	  	        local function closure() 
	  	          	gameFlow.showText( restaurant:findObject( messageBubble ), message[ msg ] ) 
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

	  	        gameFlow.showText( restaurant:findObject( messageBubble ), message[ msg ] )
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

	  	          	if ( collision.organizedAll == false ) then 
	  	          		stars = 0
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
	  	       		local hand = restaurant:findObject( "organizerHand" )
	  	       		hand.stop = true 
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
	  	        local chairs = restaurant:findLayer( "chairs" )
	  	        local tables = restaurant:findLayer( "tables" )

	  	        --physics.pause()
	  	        character.ropeJoint:removeSelf()
	  	        physics.removeBody( character )
	  	        physics.removeBody( character.rope )
	  	        character.x = startingPoint.x
	  	        character.y = startingPoint.y - 6
	  	        character.rope.x, character.rope.y = character.x, character.y + 4
	  	        physics.start()
	  	        physics.addBody( character )
	  	        physics.addBody( character.rope )
	  	        character.ropeJoint = physics.newJoint( "rope", character.rope, character, 0, 0 )
	  	        character.isFixedRotation = true 
	  	        character.xScale = 1

	  	        collision.table = false
	  	        collision.chair = false
	  	        collision.organizer = false 
	  	        collision.obj = nil 
	  	        collision.organizedAll = false 
	  	        collision.organizedNone = true

	  	        for i = 1, chairs.numChildren do 
	  	        	if ( chairs[i].isPhysics ) then 
	  	        		physics.removeBody( chairs[i] )
	  	        		chairs[i].isPhysics = nil
	  	        	end
	  	        	chairs[i].x = chairs[i].originalX
	  	        	chairs[i].y = chairs[i].originalY
	  	        	chairs[i].rotation = 0
	  	        end

	  	        for i = 1, tables.numChildren do 
	  	        	if ( tables[i].isPhysics ) then 
	  	        		physics.removeBody( tables[i] )
	  	        		tables[i].isPhysics = nil 
	  	        	end
	  	        	tables[i].x = tables[i].originalX
	  	        	tables[i].y = tables[i].originalY
	  	        	tables[i].rotation = 0 
	  	        end

	  	        if ( messageBubble ) then 
	  	          	messageBubble.alpha = 0
	  	          	if ( messageBubble.blinkingDart ) then 
	  	          	  messageBubble.blinkingDart.alpha = 0
	  	          	end
	  	        end

	  	        for k, v in pairs( supplies.collected ) do
	  	        	supplies.collected[k].x = supplies.collected[k].originalX
	  	        	supplies.collected[k].y = supplies.collected[k].originalY
	  	        	supplies.collected[k].alpha = 1
	  	        	supplies.collected[k] = nil 
	  	        end

	  	        for k, v in pairs( supplies.remaining ) do
	  	        	supplies.remaining[k] = nil 
	  	        end
	  	        gamePanel:updateBikeMaxCount( bikeWheelMaxCount )
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

	  	    		if ( collision.collectedAll == true ) then 
	  	    			if ( M.waitFeedback == false ) then 
		  	        		gameFlow.updateFSM()
		  	    		else
		  	    			M.waitFeedback = false
		  	    		end
	  	    		else 
	  	    			collisionsList = { }
	  	    			--repeat phase
	  	    		end 
 	  	    	end,

 	  	    on_nextRecipe = 
	  	    	function( self, event, from, to ) 
	  	        	table.insert( collisionsList, collision )
	  	        	print( self.current )
	  	        	if ( self.current == "recipe2" ) then 
	  	        		ingredients.collected = {}
	  	        		
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
	  	        		
	  	        		transition.fadeOut( restaurant:findObject( "recipe2" ), { time = 800 } )
		  				transition.fadeIn( restaurant:findObject( "recipe3" ), { time = 800 } )
		  				transition.fadeIn( ingredients.third[1], { time = 800 } )
		  				for k, v in pairs( ingredients.uncheck.second ) do
			  				v.alpha = 0
		  				end
		  				for k, v in pairs( ingredients.check.second ) do
			  				v.alpha = 0
		  				end
	  	        	end
	  	    	end,
	  	  }
	  	})

		gameFlow.new( restaurantFSM, listeners, restaurant )
		M.updateFSM = gameFlow.updateFSM
		M.fsm = restaurantFSM
		animation = restaurantAnimations.new( restaurant, gamePanel, path, restaurantFSM, gameFlow )
	  	--restaurantFSM.showObligatoryMessage()
	  	--restaurantFSM.showAnimation()
	  	--restaurantFSM.showGamePanel()
	  	restaurantFSM.enableListeners()
	end
end

return M