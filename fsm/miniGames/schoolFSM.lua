local fsm = require "com.fsm.src.fsm"

local gameFlow = require "fsm.gameFlow"

local feedback = require "fsm.feedback"

local sceneTransition = require "sceneTransition"

local schoolMessages = require "fsm.messages.schoolMessages"

local schoolAnimations = require "fsm.animations.schoolAnimations"

local M = { }

local animation = {}

local message = {}

function M.new( school, character, supplies, listeners, collision, instructionsTable, miniGameData, gameState, gamePanel, path )
	local schoolFSM
	local teacher = school:findObject( "teacher" )  
	local tilesSize = 32
	local messageBubble
	local message = schoolMessages
	local animation

	function M.execute()
		local organizerHand = school:findObject( "organizerHand" )
		local bikeWheelMaxCount = 6

		organizerHand.originalX = organizerHand.x  
		organizerHand.originalY = organizerHand.y 

		gamePanel.tiled.alpha = 0

		M.waitFeedback = false

		gamePanel:updateBikeMaxCount( bikeWheelMaxCount )

		schoolFSM = fsm.create({
	  	  initial = "start",
	  	  events = {
	  	  	{ name = "showAnimation", from = "start", to = "enterHouseAnimation", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "enterHouseAnimation", to = "brotherAnimation", nextEvent = "showObligatoryMessage" },
	  	    { name = "showObligatoryMessage",  from = "brotherAnimation",  to = "brotherBubble_msg1", nextEvent = "showAnimation" },
	  	    { name = "showAnimation",  from = "brotherBubble_msg1",  to = "brotherLeaveAnimation", nextEvent = "showObligatoryMessage" },
	  	    { name = "showObligatoryMessage",  from = "brotherLeaveAnimation",  to = "teacherBubble_msg4", nextEvent = "showAnimation" },
	  	    { name = "transitionEvent",  from = "brotherAnimation",  to = "transitionState_100_1", nextEvent = "showObligatoryMessage" },
	  	    { name = "showObligatoryMessage",  from = "transitionState_100_1",  to = "teacherBubble_msg4", nextEvent = "showAnimation" },
	  	    { name = "showAnimation",  from = "teacherBubble_msg4",  to = "handOrganizerAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "handOrganizerAnimation",  to = "teacherBubble_msg5", nextEvent = "showAnimation" },
	  	  	
	  	  	{ name = "showAnimation", from = "teacherBubble_msg5", to = "teacherOrganizerAnimation", nextEvent = "showObligatoryMessage" },

	  	  	--{ name = "showAnimation", from = "start", to = "teacherOrganizerAnimation", nextEvent = "showObligatoryMessage"},
	  	  	{ name = "showObligatoryMessage",  from = "teacherOrganizerAnimation",  to = "teacherBubble_msg6", nextEvent = "showAnimation" },
	  	  	
	  	  	{ name = "showAnimation", from = "teacherBubble_msg6", to = "teacherChairCollision", nextEvent = "showObligatoryMessage" },
	  	  	--{ name = "showAnimation", from = "start", to = "teacherChairCollision", nextEvent = "showObligatoryMessage"},
	  	  	{ name = "showObligatoryMessage",  from = "teacherChairCollision",  to = "teacherBubble_msg7", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "teacherBubble_msg7", to = "fixChair", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "fixChair",  to = "teacherBubble_msg8", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "teacherBubble_msg8", to = "teacherGotoInitialPosition", nextEvent = "showGamePanel" },
	  	  	{ name = "showGamePanel", from = "teacherGotoInitialPosition", to = "gamePanel", nextEvent = "enableListeners" },
	  	  	
	  	  	{ name = "showGamePanel", from = "start", to = "gamePanel", nextEvent = "enableListeners" },
	  	  	
	  	  	{ name = "enableListeners",  from = "gamePanel",  to = "restartListeners", nextEvent = "checkFeedbackWait" },
	  	  	{ name = "checkFeedbackWait",  from = "restartListeners",  to = "checkWait", nextEvent = "showFeedback" },
	  	  	{ name = "showFeedback",  from = "checkWait",  to = "feedbackAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "checkFeedbackWait",  from = "repeat",  to = "checkWait", nextEvent = "showFeedback" },
	  	  	{ name = "repeatLevel", from = "feedbackAnimation", to = "repeat", nextEvent = "checkFeedbackWait" },
	  	  	{ name = "showObligatoryMessage",  from = "feedbackAnimation",  to = "teacherBubble_msg9", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "teacherBubble_msg9", to = "teacherJumpingAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "teacherJumpingAnimation",  to = "teacherBubble_msg10", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "teacherBubble_msg10", to = "leaveSchoolAnimation", nextEvent = "saveGame" },
	  	  	{ name = "saveGame",  from = "leaveSchoolAnimation",  to = "save", nextEvent = "finishLevel" },
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
	  	          	elseif ( self.current == "leaveSchoolAnimation" ) then 
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
	  	        local bubbleChar

	  	        if ( messageBubble == "brotherBubble" ) then 
	  	        	if ( character == school:findObject( "ada" ) ) then 
	  	        		messageBubble = school:findObject( "turingBubble" )
	  	        		bubbleChar = school:findObject( "turing" )
	  	        	else
	  	        		messageBubble = school:findObject( "adaBubble" )
	  	        		bubbleChar = school:findObject( "ada" )
	  	        	end
	  	        else 
	  	        	messageBubble = school:findObject( "teacherBubble" )
	  	        	bubbleChar = school:findObject( "teacher" )
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
	  	        	if ( character == school:findObject( "ada" ) ) then 
	  	        		messageBubble = school:findObject( "turingBubble" )
	  	        		bubbleChar = school:findObject( "turing" )
	  	        	else
	  	        		messageBubble = school:findObject( "adaBubble" )
	  	        		bubbleChar = school:findObject( "ada" )
	  	        	end
	  	        else 
	  	        	messageBubble = school:findObject( "teacherBubble" )
	  	        	bubbleChar = school:findObject( "teacher" )
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
	  	        	if ( character == school:findObject( "ada" ) ) then 
	  	        		messageBubble = school:findObject( "turingBubble" )
	  	        		bubbleChar = school:findObject( "turing" )
	  	        	else
	  	        		messageBubble = school:findObject( "adaBubble" )
	  	        		bubbleChar = school:findObject( "ada" )
	  	        	end
	  	        else 
	  	        	messageBubble = school:findObject( "teacherBubble" )
	  	        	bubbleChar = school:findObject( "teacher" )
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
	  	          	gamePanel.tiled:insert( feedback.showAnimation( "school", stars, msg, gameFlow.updateFSM ) )
	  	       		miniGameData.stars = stars
	  	       		local hand = school:findObject( "organizerHand" )
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
	  	        transition.cancel( character )
	  	        gamePanel:stopAllListeners()
	  	        character.stepping.point = "exit"
	  	        timer.performWithDelay( 800, sceneTransition.gotoMap )
	  	      end,

	  	    on_repeatLevel = 
	  	      function( self, event, from, to ) 
	  	        local startingPoint = school:findObject("start")
	  	        local chairs = school:findLayer( "chairs" )
	  	        local tables = school:findLayer( "tables" )

	  	        physics.removeBody( character )
	  	        character.x = startingPoint.x
	  	        character.y = startingPoint.y - 6
	  	        physics.addBody( character )
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
	  	  }
	  	})

		gameFlow.new( schoolFSM, listeners, school )
		M.updateFSM = gameFlow.updateFSM
		M.fsm = schoolFSM
		animation = schoolAnimations.new( school, character, gamePanel, path, schoolFSM, gameFlow )
	  	--schoolFSM.showObligatoryMessage()
	  	schoolFSM.showAnimation()
	  	--schoolFSM.showGamePanel()
	end
end

return M