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

		gamePanel.tiled.alpha = 0

		M.waitFeedback = false

		gamePanel:updateBikeMaxCount( bikeWheelMaxCount )

		restaurantFSM = fsm.create({
	  	  initial = "start",
	  	  events = {
	  	  	{ name = "showAnimation", from = "start", to = "enterHouseAnimation", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "enterHouseAnimation", to = "brotherAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "brotherAnimation",  to = "brotherBubble_msg1", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation",  from = "brotherBubble_msg1",  to = "brotherLeaveAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "brotherLeaveAnimation",  to = "cookBubble_msg4", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation",  from = "cookBubble_msg4",  to = "recipeHandAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "recipeHandAnimation",  to = "cookBubble_msg5", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "cookBubble_msg5",  to = "cookBubble_msg6", nextEvent = "showGamePanel" },
	  	  	{ name = "showGamePanel", from = "cookBubble_msg6", to = "gamePanel", nextEvent = "enableListeners" },
	  	  	{ name = "enableListeners",  from = "gamePanel",  to = "restartListeners", nextEvent = "nextRecipe" },
	  	  	
	  	  	{ name = "nextRecipe",  from = "restartListeners",  to = "recipe1", nextEvent = "checkProgress" },
	  	  	{ name = "nextRecipe",  from = "repeat",  to = "recipe1", nextEvent = "checkProgress" },
	  	  	{ name = "checkProgress",  from = "recipe1",  to = "progress1", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "progress1",  to = "cookBubble_msg7", nextEvent = "nextRecipe" },
	  	  	{ name = "nextRecipe",  from = "cookBubble_msg7",  to = "recipe2", nextEvent = "checkProgress" },
	  	  	{ name = "checkProgress",  from = "recipe2",  to = "progress2", nextEvent = "showFeedback" },

	  	  	{ name = "showFeedback", from = "progress1", to = "feedbackAnimation", nextEvent = "nextRecipe" },
	  	  	{ name = "showFeedback", from = "progress2", to = "feedbackAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "feedbackAnimation",  to = "cookBubble_msg8", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "cookBubble_msg8", to = "cookJumpingAnimation", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "cookJumpingAnimation", to = "cookToStoveAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "repeatLevel", from = "feedbackAnimation", to = "repeat", nextEvent = "nextRecipe" },
	  	  	{ name = "showObligatoryMessage",  from = "cookToStoveAnimation",  to = "cookBubble_msg9", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "cookBubble_msg9", to = "pastaAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "pastaAnimation",  to = "cookBubble_msg10", nextEvent = "saveGame" },
	  	  	{ name = "saveGame",  from = "cookBubble_msg10",  to = "save", nextEvent = "finishLevel" },
	  	  	{ name = "finishLevel",  from = "save",  to = "finish" },
	  	  },
	  	  callbacks = {
	  	  	on_before_event = 
	  	      function( self, event, from, to ) 
	  	        if ( ( messageBubble ) and ( messageBubble.text ) ) then
			        if ( messageBubble.blinkingDart ) then 
				        transition.cancel( messageBubble.blinkingDart )
				        messageBubble.blinkingDart.alpha = 0
				        messageBubble.blinkingDart = nil
			    	end
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
	  	        local bubbleChar

	  	        if ( messageBubble == "brotherBubble" ) then 
	  	        	if ( character == restaurant:findObject( "ada" ) ) then 
	  	        		messageBubble = restaurant:findObject( "turingBubble" )
	  	        		bubbleChar = restaurant:findObject( "turing" )
	  	        	else
	  	        		messageBubble = restaurant:findObject( "adaBubble" )
	  	        		bubbleChar = restaurant:findObject( "ada" )
	  	        	end
	  	        else 
	  	        	messageBubble = restaurant:findObject( "cookBubble" )
	  	        	bubbleChar = restaurant:findObject( "cook" )
	  	        end

	  	        local function closure() 
	  	          	gamePanel.stopExecutionListeners()
	  	          	gameFlow.showText( messageBubble, message[ msg ], bubbleChar ) 
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
	  	        local bubbleChar

	  	        if ( messageBubble == "brotherBubble" ) then 
	  	        	if ( character == restaurant:findObject( "ada" ) ) then 
	  	        		messageBubble = restaurant:findObject( "turingBubble" )
	  	        		bubbleChar = restaurant:findObject( "turing" )
	  	        	else
	  	        		messageBubble = restaurant:findObject( "adaBubble" )
	  	        		bubbleChar = restaurant:findObject( "ada" )
	  	        	end
	  	        else 
	  	        	messageBubble = restaurant:findObject( "cookBubble" )
	  	        	bubbleChar = restaurant:findObject( "cook" )
	  	        end

	  	        local function closure() 
	  	          	gameFlow.showText( messageBubble, message[ msg ], bubbleChar ) 
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
				local bubbleChar

	  	        if ( messageBubble == "brotherBubble" ) then 
	  	        	if ( character == restaurant:findObject( "ada" ) ) then 
	  	        		messageBubble = restaurant:findObject( "turingBubble" )
	  	        		bubbleChar = restaurant:findObject( "turing" )
	  	        	else
	  	        		messageBubble = restaurant:findObject( "adaBubble" )
	  	        		bubbleChar = restaurant:findObject( "ada" )
	  	        	end
	  	        else 
	  	        	messageBubble = restaurant:findObject( "cookBubble" )
	  	        	bubbleChar = restaurant:findObject( "cook" )
	  	        end

	  	        gameFlow.showText( messageBubble, message[ msg ], bubbleChar )
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
			        if ( messageBubble.blinkingDart ) then 
				        transition.cancel( messageBubble.blinkingDart )
				        messageBubble.blinkingDart.alpha = 0
				        messageBubble.blinkingDart = nil
			    	end
			    end
	  	        gameFlow.updateFSM()
	  	      end,

	  	    on_showFeedback = 
	  	      function( self, event, from, to ) 
	  	          	local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )
	  	          	local executeButton = gamePanel.executeButton
	  	          	local stars = 0
	  	          	local msg = 1 

	  	          	local bikeCount = gamePanel.executeButton.bikeCount
	  	          	local instructionsCount = gamePanel.executeButton.instructionsCount

	  	          	if ( ( collision.wrongIngredient == true ) and ( collision.collectedAll == true ) ) then 
	  	          		stars = 0
	  	          		msg = 4 
	  	          	elseif ( collision.wrongIngredient == true ) then 
	  	          		stars = 0
	  	          		msg = 2
	  	          	elseif ( ( collision.collectedAll == false ) or ( collision.organizer == false ) ) then 
	  	          		stars = 0
	  	          	elseif ( collision.inOrder == false ) then
	  	          		stars = 0
	  	          		msg = 3 
	  	          	elseif ( ( instructionsCount[1] <= 5 ) and ( instructionsCount[2] <= 7 ) and ( ( ( collisionsList[1].otherObjects == false ) and ( ( collisionsList[2].otherObjects == false ) ) ) ) ) then
	  	          	    stars = 3
	  	          	elseif ( ( instructionsCount[1] <= 5 ) and ( instructionsCount[2] <= 7 ) and ( ( ( collisionsList[1].otherObjects == false ) and ( ( collisionsList[2].otherObjects == false ) ) ) ) ) then
	  	          		stars = 2
	  	          		msg = 2
	  	          	elseif ( ( bikeCount[1] > 0  ) and ( bikeCount[2] > 0 ) ) then 
	  	          		stars = 2
	  	          		if ( ( collisionsList[1].otherObjects == true ) or ( ( collisionsList[2].otherObjects == true ) ) ) then 
	  	          			msg = 2
	  	          		end
	  	          	else 
	  	          	    stars = 1

	  	          	    if ( ( collisionsList[1].otherObjects == true ) or ( ( collisionsList[2].otherObjects == true ) ) ) then
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
	  	      	gamePanel.restartExecutionListeners()
	  	      	gamePanel:updateBikeMaxCount( math.huge )
	  	      end,

	  	    on_repeatLevel = 
	  	      function( self, event, from, to ) 
	  	        local startingPoint = restaurant:findObject("start")

	  	        physics.removeBody( character )
	  	        character.x = startingPoint.x
	  	        character.y = startingPoint.y - 4
	  	        physics.addBody( character )
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

	  	        for k, v in pairs( ingredients.remaining ) do
	  	        	ingredients.remaining[k] = nil 
	  	        end
	  	        ingredients.collected = { }
	  	        gamePanel:updateBikeMaxCount( bikeWheelMaxCount )
	  	        gamePanel:resetExecutionButton()

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
	  	        gameFlow.updateFSM()
	  	    end,

	  	    on_enableListeners = 
	  	      function( self, event, from, to ) 
	  	        if ( to == "restartListeners" ) then 
	  	        	gamePanel.restartExecutionListeners()
	  	        end
	  	        gameFlow.updateFSM()
	  	    end,

	  	    on_showGamePanel = 
	  	      	function( self, event, from, to ) 
	  	        	transition.fadeIn( gamePanel.tiled, { time = 1400 } )
	  	        	gameFlow.updateFSM()
	  	    	end,

	  	    on_checkFeedbackWait = 
	  	    	function( self, event, from, to ) 
	  	        	if ( M.waitFeedback == false ) then 
		  	        	gameFlow.updateFSM()
	  	    		else
	  	    			M.waitFeedback = false
	  	    		end
	  	    	end,

	  	    on_checkProgress = 
	  	    	function( self, event, from, to ) 
	  	        	local function wait()
	  	        		if ( M.waitFeedback == false ) then 
		  	        		gameFlow.updateFSM()
		  	    		else
		  	    			M.waitFeedback = false
		  	    		end
	  	        	end

	  	        	print( "coll others: " .. tostring(collision.otherObjects) .. "; coll all: " .. tostring( collision.collectedAll ) .. "; coll none: " .. tostring( collision.collectedNone) .. " ; wrong: " .. tostring(collision.wrongIngredient) .. " ; organizer: " .. tostring(collision.organizer) )

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
				       	end

				       	self.nextEvent = "showFeedback"
				       	if ( collision.collectedNone == true ) then 
				       		gameFlow.updateFSM()
				       	else
				       		wait()
	        			end
	  	    		end
 	  	    	end,

 	  	    on_nextRecipe = 
	  	    	function( self, event, from, to ) 
	  	    		local tempCollision = { }

	  	    		for k, v in pairs( collision ) do
	  	    			tempCollision[k] = v
	  	    		end
	  	        	table.insert( collisionsList, tempCollision )

	  	        	gamePanel.restartExecutionListeners()

	  	        	if ( self.current == "recipe1" ) then
	  	        		transition.fadeIn( restaurant:findObject( "recipe1" ), { time = 800 } )

	  	        	elseif ( self.current == "recipe2" ) then 
	  	        		ingredients.collected = {}
	  	        		
	  	        		gamePanel:updateBikeMaxCount( 6 )
	  	        		transition.fadeOut( restaurant:findObject( "recipe1" ), { time = 800 } )
		  				transition.fadeIn( restaurant:findObject( "recipe2" ), { time = 800 } )
		  				for k, v in pairs( ingredients.uncheck.first ) do
			  				v.alpha = 0
		  				end
		  				for k, v in pairs( ingredients.check.first ) do
			  				v.alpha = 0
		  				end

		  				--[[instructionsTable:reset()
		  				instructionsTable.steps = { 2, 5, 6, 6, 6, 1, 3 }
		  				instructionsTable.direction = { "right", "up", "left", "down", "right", "up", "left" }
		  				instructionsTable.last = 7]]
	  	        	end

	  	        	resetCollision()
	  	    	end,
	  	  }
	  	})

		gameFlow.new( restaurantFSM, listeners, restaurant )
		M.updateFSM = gameFlow.updateFSM
		M.fsm = restaurantFSM
		animation = restaurantAnimations.new( restaurant, ingredients, character, gamePanel, path, restaurantFSM, gameFlow )

	  	restaurantFSM.showAnimation()
	  	--character.alpha = 1
	  	--restaurantFSM.showGamePanel()
	end

	function M.destroy( ) 
		if ( restaurantFSM ) then 
			if ( restaurantFSM.messageBubble ) and ( restaurantFSM.messageBubble.text ) then 
				local text = restaurantFSM.messageBubble.text
				text:removeSelf()
			end

			for k, v in pairs( restaurantFSM ) do
				restaurantFSM[k] = nil 
			end
			restaurantFSM = nil 
		end
	end
end

return M