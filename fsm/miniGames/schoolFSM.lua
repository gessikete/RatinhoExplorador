local fsm = require "com.fsm.src.fsm"

local gameFlow = require "fsm.gameFlow"

local feedback = require "fsm.feedback"

local sceneTransition = require "sceneTransition"

local schoolMessages = require "fsm.messages.schoolMessages"

local schoolAnimations = require "fsm.animations.schoolAnimations"

local M = { }

local animation = {}

local message = {}

function M.new( school, supplies, collision, instructionsTable, miniGameData, gameState, gamePanel, path )
	local schoolFSM
	local character = school:findObject( "character" )
	local teacher = school:findObject( "teacher" )  
	local tilesSize = 32
	local messageBubble
	local message = schoolMessages
	local animation

	function M.execute()
		local organizerHand = school:findObject( "organizerHand" )


		organizerHand.originalX = organizerHand.x  
		organizerHand.originalY = organizerHand.y 

		gamePanel.tiled.alpha = 0

		M.waitFeedback = false

		schoolFSM = fsm.create({
	  	  initial = "start",
	  	  events = {
	  	    { name = "showObligatoryMessage",  from = "start",  to = "teacherBubble_msg1", nextEvent = "showAnimation" },
	  	    { name = "showAnimation",  from = "teacherBubble_msg1",  to = "handOrganizerAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "handOrganizerAnimation",  to = "teacherBubble_msg2", nextEvent = "showAnimation" },
	  	  	
	  	  	{ name = "showAnimation", from = "teacherBubble_msg2", to = "teacherOrganizerAnimation", nextEvent = "showObligatoryMessage" },

	  	  	--{ name = "showAnimation", from = "start", to = "teacherOrganizerAnimation", nextEvent = "showObligatoryMessage"},
	  	  	{ name = "showObligatoryMessage",  from = "teacherOrganizerAnimation",  to = "teacherBubble_msg3", nextEvent = "showAnimation" },
	  	  	
	  	  	{ name = "showAnimation", from = "teacherBubble_msg3", to = "teacherChairCollision", nextEvent = "showObligatoryMessage" },
	  	  	--{ name = "showAnimation", from = "start", to = "teacherChairCollision", nextEvent = "showObligatoryMessage"},
	  	  	{ name = "showObligatoryMessage",  from = "teacherChairCollision",  to = "teacherBubble_msg4", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "teacherBubble_msg4", to = "fixChair", nextEvent = "showObligatoryMessage" },
	  	  	{ name = "showObligatoryMessage",  from = "fixChair",  to = "teacherBubble_msg5", nextEvent = "showAnimation" },
	  	  	{ name = "showAnimation", from = "teacherBubble_msg5", to = "teacherGotoInitialPosition", nextEvent = "showGamePanel" },
	  	  	{ name = "showGamePanel", from = "start", to = "gamePanel", nextEvent = "enableListeners" },
	  	  	{ name = "enableListeners",  from = "gamePanel",  to = "restartListeners", nextEvent = "checkFeedbackWait" },
	  	  	{ name = "checkFeedbackWait",  from = "restartListeners",  to = "checkWait", nextEvent = "showFeedback" },
	  	  	{ name = "showFeedback",  from = "checkWait",  to = "feedbackAnimation"},--, nextEvent = "repeatLevel" },
	  	  	{ name = "checkFeedbackWait",  from = "repeat",  to = "checkWait", nextEvent = "showFeedback" },
	  	  	{ name = "repeatLevel", from = "feedbackAnimation", to = "repeat", nextEvent = "checkFeedbackWait" },
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
	  	          	if ( animation[self.current]() ~= math.huge ) then 
	  	          		timer.performWithDelay( animation[self.current](), gameFlow.updateFSM ) 
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
	  	          	gameFlow.showText( school:findObject( messageBubble ), message[ msg ] ) 
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
	  	          	gameFlow.showText( school:findObject( messageBubble ), message[ msg ] ) 
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

	  	        gameFlow.showText( school:findObject( messageBubble ), message[ msg ] )
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

	  	          	
	  	          	if ( ( from == "transitionState" ) and ( wait ) ) then 
	  	          	  timer.performWithDelay( wait, gameFlow.updateFSM )
	  	          	end

	  	          	if ( collision.organizedNone == true ) then 
	  	          		stars = 0
	  	          	elseif ( ( instructionsTable.last == 6 ) and ( collision.table == false ) and ( collision.table == false ) ) then
	  	          	    stars = 3
	  	          	elseif ( instructionsTable.last == 6 ) then
	  	          	    stars = 2
	  	          	else 
	  	          	    stars = 1
	  	          	end
	  	          	

	  	          	local function closure()
	  	          	  --path:hidePath()
	  	          	  --gamePanel:hideInstructions()
	  	          	  if ( messageBubble ) then 
	  	          	    messageBubble.alpha = 0
	  	          	    if ( messageBubble.blinkingDart ) then 
	  	          	      messageBubble.blinkingDart.alpha = 0
	  	          	    end
	  	          	  end
	  	          	end
	  	          	timer.performWithDelay( 1000, closure )
	  	          	gamePanel.tiled:insert( feedback.showAnimation( "school", stars, msg, gameFlow.updateFSM ) )
	  	        end,

	  	    on_saveGame = 
	  	      function( self, event, from, to ) 
	  	        miniGameData.bikeTutorial = "complete"
	  	        miniGameData.isComplete = true 
	  	        --gameState:save( miniGameData )
	  	        gameFlow.updateFSM()
	  	      end,

	  	    on_endTutorial = 
	  	      function( self, event, from, to ) 
	  	        transition.cancel()
	  	        gamePanel:stopAllListeners()
	  	        timer.performWithDelay( 800, sceneTransition.gotoMap )
	  	      end,

	  	    on_repeatLevel = 
	  	      function( self, event, from, to ) 
	  	        local startingPoint = school:findObject("start")
	  	        local chairs = school:findLayer( "chairs" )
	  	        local tables = school:findLayer( "tables" )

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
	  	        collision.organizedAll = false 
	  	        collision.organizedNone = true

	  	        for i = 1, chairs.numChildren do 
	  	        	if ( chairs[i].isPhysics ) then 
	  	        		physics.removeBody( chairs[i] )
	  	        		chairs[i].isPhysics = nil
	  	        	end
	  	        	chairs[i].x = chairs[i].originalX
	  	        	chairs[i].y = chairs[i].originalY
	  	        end

	  	        for i = 1, tables.numChildren do 
	  	        	if ( tables[i].isPhysics ) then 
	  	        		physics.removeBody( tables[i] )
	  	        		tables[i].isPhysics = nil 
	  	        	end
	  	        	tables[i].x = tables[i].originalX
	  	        	tables[i].y = tables[i].originalY
	  	        end

	  	        if ( messageBubble ) then 
	  	          	messageBubble.alpha = 0
	  	          	if ( messageBubble.blinkingDart ) then 
	  	          	  messageBubble.blinkingDart.alpha = 0
	  	          	end
	  	        end

	  	        for k, v in pairs( supplies.collected ) do
	  	        	supplies.collected[k] = nil 
	  	        end

	  	        for k, v in pairs( supplies.remaining ) do
	  	        	supplies.remaining[k] = nil 
	  	        end
	  	        --gamePanel:updateBikeMaxCount( 1 )
	  	        --timer.performWithDelay( 2000, gameFlow.updateFSM )
	  	        --gamePanel:showDirectionButtons( true )
	  	    end,

	  	    on_enableListeners = 
	  	      function( self, event, from, to ) 
	  	        if ( to == "restartListeners" ) then 
	  	        	--gamePanel.restartExecutionListeners()
	  	        end
	  	    end,

	  	    on_showGamePanel = 
	  	      	function( self, event, from, to ) 
	  	        	transition.fadeIn( gamePanel.tiled, { time = 400 } )
	  	        	gameFlow.updateFSM()
	  	    	end,

	  	    on_checkFeedbackWait = 
	  	    	function( self, event, from, to ) 
	  	        	--transition.fadeOut( gamePanel.tiled, { time = 400 } )
	  	        	if ( M.waitFeedback == false ) then 
		  	        	gameFlow.updateFSM()
		  	        	print( "organizedAll: " .. tostring(collision.organizedAll) .. "; organizedNone: ".. tostring(collision.organizedNone) .. " ; chair: " .. tostring(collision.chair) .. "; table: " .. tostring(collision.table) .. "; organizer: " .. tostring(collision.organizer) )
	  	    		else
	  	    			M.waitFeedback = false
	  	    		end
	  	    	end,
	  	  }
	  	})

		gameFlow.new( schoolFSM, school )
		M.updateFSM = gameFlow.updateFSM
		M.fsm = schoolFSM
		animation = schoolAnimations.new( school, gamePanel, path, schoolFSM, gameFlow )
	  	--schoolFSM.showObligatoryMessage()
	  	schoolFSM.showGamePanel()
	end
end

return M