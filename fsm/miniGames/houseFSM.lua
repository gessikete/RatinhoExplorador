local fsm = require "com.fsm.src.fsm"

local gameFlow = require "fsm.gameFlow"

local feedback = require "fsm.feedback"

local sceneTransition = require "sceneTransition"

local houseMessages = require "fsm.messages.houseMessages"

local houseAnimations = require "fsm.animations.houseAnimations"

local M = { }

local animation = {}

local message = {}

function M.new( house, puzzle, miniGameData, gameState, gamePanel, path )
	local tutorialFSM
	local character = house:findObject( "character" )
	local mom = house:findObject( "mom" )  
	local tilesSize = 32
	local messageBubble
	local message = houseMessages
	local animation

	local function showSubText( event )
		messageBubble = event.target

		if ( messageBubble.message[messageBubble.shownText] ) then 
		    messageBubble.text:removeSelf()

		    if ( ( tutorialFSM.current == "momBubble_msg6" ) and ( messageBubble.message[messageBubble.shownText] == "Mas ainda falta" ) ) then 
		      local remainingPieces = puzzle.littlePieces.count - puzzle.collectedPieces.count

		      if ( remainingPieces > 1 ) then
		        messageBubble.options.text = messageBubble.message[messageBubble.shownText] .. "m " .. remainingPieces .. " peças."
		      else
		        messageBubble.options.text = messageBubble.message[messageBubble.shownText] .. " " .. remainingPieces .. " peça."
		      end
		    else
		      messageBubble.options.text = messageBubble.message[messageBubble.shownText]
		    end

		    local newText = display.newText( messageBubble.options ) 
		    newText.x = newText.x + newText.width/2
		    newText.y = newText.y + newText.height/2

		    messageBubble.text = newText
		    messageBubble.shownText = messageBubble.shownText + 1

		    messageBubble.blinkingDart.x = messageBubble.x + 33
		    messageBubble.blinkingDart.y = messageBubble.y + 12 

		else
		    if ( tutorialFSM.event == "showObligatoryMessage" ) then
		      transition.fadeOut( messageBubble.text, { time = 400 } )
		      transition.fadeOut( messageBubble, { time = 400, onComplete = gameFlow.updateFSM } )
		      messageBubble.text:removeSelf()
		      messageBubble.text = nil
		      messageBubble.listener = false
		      messageBubble:removeEventListener( "tap", showSubText )

		      transition.cancel( messageBubble.blinkingDart )
		      messageBubble.blinkingDart.alpha = 0
		      messageBubble.blinkingDart = nil
		    else
		      if ( messageBubble.text ) then
		        transition.fadeOut( messageBubble.text, { time = 400 } )
		        transition.fadeOut( messageBubble, { time = 400 } )
		        messageBubble.text:removeSelf()
		        messageBubble.text = nil
		        messageBubble.listener = false
		        messageBubble:removeEventListener( "tap", showSubText )

		        transition.cancel( messageBubble.blinkingDart )
		        messageBubble.blinkingDart.alpha = 0
		        messageBubble.blinkingDart = nil
		      end
		    end
		end

	  	return true 
	end

	local function showText( bubble, message ) 
	  local options = {
	      text = " ",
	      x = bubble.contentBounds.xMin + 15, 
	      y = bubble.contentBounds.yMin + 10,
	      fontSize = 12.5,
	      width = bubble.width - 27,
	      height = 0,
	      align = "left" 
	  }
	  options.text = message[1]

	  if ( bubble.alpha == 0 ) then
	    transition.fadeIn( bubble, { time = 400 } )
	  end

	  if ( ( not bubble.listener ) or ( ( bubble.listener ) and ( bubble.listener == false ) ) ) then
	    bubble.listener = true
	    bubble:addEventListener( "tap", showSubText )
	  end 

	  local newText = display.newText( options ) 
	  newText.x = newText.x + newText.width/2
	  newText.y = newText.y + newText.height/2

	  bubble.message = message 
	  bubble.text = newText
	  bubble.shownText = 1
	  bubble.options = options

	  local time 
	  if ( not bubble.blinkingDart ) then 
	    if ( tutorialFSM.event == "showObligatoryMessage" ) then 
	      time = 500
	      bubble.blinkingDart = house:findObject( "obligatoryBlinkingDart" ) 
	    else
	      time = 2000
	      if ( bubble == house:findObject( "momBubble" ) ) then 
	        bubble.blinkingDart = house:findObject( "momBlinkingDart" ) 
	      else
	        bubble.blinkingDart = house:findObject( "momBlinkingDart" ) 
	      end
	    end
	    bubble.blinkingDart.x = bubble.x + 33
	    bubble.blinkingDart.y = bubble.y + 12

	    bubble.blinkingDart.alpha = 1
	    transition.blink( bubble.blinkingDart, { time = time } )
	  end

	  if ( ( messageBubble ) and ( messageBubble ~= bubble ) ) then
	    messageBubble.listener = false 
	    messageBubble:removeEventListener( "tap", showSubText )

	    messageBubble = bubble
	  elseif ( not messageBubble ) then 
	    messageBubble = bubble
	  end
	end

	function M.bikeTutorial()
	  	local start = house:findObject( "start" )


	  	if ( not tutorialFSM ) then 
	  	  transition.to( character, { time = 0, x = 80, y = 296} )
	  	  mom.x, mom.y = character.x, character.y - tilesSize
	  	  gamePanel:showDirectionButtons( false )
	  	else 
	  	  path:hidePath()

	  	  gamePanel:showBikewheel ( true )
	  	  gamePanel:hideInstructions()
	  	end
	  	
	  	gamePanel:updateBikeMaxCount( 3 )
	  	gamePanel:stopAllListeners()

	  	tutorialFSM = fsm.create({
	  	  initial = "start",
	  	  events = {
	  	    {name = "showObligatoryMessage",  from = "start",  to = "momBubble_msg8", nextEvent = "showMessageAndAnimation" },
	  	    {name = "showMessageAndAnimation",  from = "momBubble_msg8",  to = "momBubble_msg9_handDirectionAnimation1", nextEvent = "showMessageAndAnimation" },
	  	    {name = "showMessageAndAnimation",  from = "momBubble_msg9_handDirectionAnimation1",  to = "momBubble_msg10_handBikeAnimation1", nextEvent = "transitionEvent" },
	  	    {name = "transitionEvent",  from = "momBubble_msg10_handBikeAnimation1",  to = "transitionState_100_1", nextEvent = "showMessageAndAnimation" },
	  	    {name = "showMessageAndAnimation",  from = "transitionState_100_1",  to = "momBubble_msg11_handDirectionAnimation3", nextEvent = "showMessageAndAnimation" },
	  	    {name = "showMessageAndAnimation",  from = "momBubble_msg11_handDirectionAnimation3",  to = "momBubble_msg12_handBikeAnimation2", nextEvent = "showMessageAndAnimation" },
	  	    {name = "showMessageAndAnimation",  from = "momBubble_msg12_handBikeAnimation2",  to = "momBubble_msg13_handExecuteAnimation", nextEvent = "transitionEvent" },
	  	    {name = "transitionEvent",  from = "momBubble_msg13_handExecuteAnimation",  to = "transitionState_1800_2", nextEvent = "showObligatoryMessage" },
	  	    {name = "showObligatoryMessage",  from = "transitionState_1800_2",  to = "momBubble_msg14", nextEvent = "showMessageAndAnimation" },
	  	    {name = "showObligatoryMessage",  from = "repeat",  to = "momBubble_msg14", nextEvent = "showMessageAndAnimation" },
	  	    {name = "showMessageAndAnimation",  from = "momBubble_msg14",  to = "momBubble_msg15_handExitAnimation", nextEvent = "showFeedback" },
	  	    {name = "showFeedback",  from = "momBubble_msg15_handExitAnimation",  to = "feedbackAnimation", nextEvent = "showObligatoryMessage" },
	  	    {name = "showObligatoryMessage",  from = "feedbackAnimation",  to = "momBubble_msg16", nextEvent = "showAnimation" },
	  	    {name = "repeatLevel", from = "feedbackAnimation", to = "repeat", nextEvent = "showObligatoryMessage" },
	  	    {name = "showAnimation",  from = "momBubble_msg16",  to = "goBackAnimation", nextEvent = "showObligatoryMessage" },
	  	    {name = "showObligatoryMessage",  from = "goBackAnimation",  to = "momBubble_msg17", nextEvent = "showAnimation" },
	  	    {name = "showAnimation",  from = "momBubble_msg17",  to = "momBubble_msg15_brotherChallengeAnimation", nextEvent = "showObligatoryMessage" }, 
	  	    {name = "showAnimation",  from = "momBubble_msg17",  to = "brotherChallengeAnimation", nextEvent = "showObligatoryMessage" }, 
	  	    {name = "showObligatoryMessage",  from = "brotherChallengeAnimation",  to = "brotherBubble_msg18", nextEvent = "showAnimation" },
	  	    {name = "showAnimation",  from = "brotherBubble_msg18",  to = "brotherJumpingAnimation", nextEvent = "showObligatoryMessage" },
	  	    {name = "showObligatoryMessage",  from = "brotherJumpingAnimation",  to = "brotherBubble_msg19", nextEvent = "showAnimation" },
	  	    {name = "showAnimation",  from = "brotherBubble_msg19",  to = "brotherLeavingAnimation", nextEvent = "showObligatoryMessage" },
	  	    {name = "showObligatoryMessage",  from = "brotherLeavingAnimation",  to = "momBubble_msg20", nextEvent = "showAnimation" },
	  	    {name = "showAnimation",  from = "momBubble_msg20",  to = "characterLeaveAnimation", nextEvent = "saveGame" },
	  	    {name = "saveGame",  from = "characterLeaveAnimation",  to = "save", nextEvent = "endTutorial" },
	  	    {name = "endTutorial",  from = "save",  to = "end" },
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
	  	            timer.performWithDelay( animation[self.current](), gameFlow.updateFSM ) 
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
	  	            showText( house:findObject( messageBubble ), message[ msg ] ) 
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
	  	            showText( house:findObject( messageBubble ), message[ msg ] ) 
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

	  	        showText( house:findObject( messageBubble ), message[ msg ] )
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
	  	            local stars

	  	            gamePanel.stopExecutionListeners()
	  	            if ( ( from == "transitionState" ) and ( wait ) ) then 
	  	              	timer.performWithDelay( wait, gameFlow.updateFSM )
	  	            end

	  	            --executeButton.executionsCount MUDAR
	  	            if ( executeButton.instructionsCount[#executeButton.instructionsCount] ) then 
	  	              	if ( ( executeButton.executionsCount == 1 ) and ( executeButton.instructionsCount[#executeButton.instructionsCount] == 1 ) ) then
	  	                	stars = 3
	  	              elseif ( gamePanel.bikeWheel.maxCount == 0 ) then
	  	                	stars = 2
	  	              else 
	  	                	stars = 1
	  	              end
	  	            end

	  	            local function closure()
	  	              	if ( messageBubble ) then 
	  	                	messageBubble.alpha = 0
	  	                	if ( messageBubble.blinkingDart ) then 
	  	                 		messageBubble.blinkingDart.alpha = 0
	  	                	end
	  	              end
	  	            end
	  	            timer.performWithDelay( 1000, closure )
	  	            gamePanel.tiled:insert( feedback.showAnimation( "house", stars, 1, gameFlow.updateFSM ) )
	  	        	miniGameData.stars = stars
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
	  	        local repeatPoint = house:findObject("repeatPoint")
	  	        local startingPoint = house:findObject("start")

	  	        --[[physics.pause()
	  	        physics.removeBody( character )
	  	        character.x = startingPoint.x 
	  	        character.y = startingPoint.y - tilesSize - 8
	  	        
	  	        physics.start()
	  	        physics.addBody( character )]]
	  	        --path:hidePath()

	  	        --gamePanel:hideInstructions()

	  	        character.ropeJoint:removeSelf()
	  	        physics.removeBody( character )
	  	        physics.removeBody( character.rope )
	  	        character.x = startingPoint.x + tilesSize * 2
	  	        character.y = startingPoint.y - tilesSize * 3 - 6
	  	        character.rope.x, character.rope.y = character.x, character.y + 4
	  	        physics.start()
	  	        physics.addBody( character )
	  	        physics.addBody( character.rope )
	  	        character.ropeJoint = physics.newJoint( "rope", character.rope, character, 0, 0 )
	  	        character.isFixedRotation = true 
	  	        character.xScale = 1

	  	        gamePanel:updateBikeMaxCount( 1 )
	  	        timer.performWithDelay( 2000, gameFlow.updateFSM )
	  	    end
	  	  }
	  	})

		gameFlow.new( tutorialFSM )
		M.update = gameFlow.updateFSM
		M.tutorialFSM = tutorialFSM
		animation = houseAnimations.new( house, puzzle, gamePanel, path, tutorialFSM, gameFlow )
	  	tutorialFSM.showObligatoryMessage()
	end

	function M.controlsTutorial()
	  	tutorialFSM = fsm.create( {
	  	  initial = "start",
	  	  events = {
	  	    { name = "showAnimation",  from = "start",  to = "momAnimation", nextEvent = "showObligatoryMessage" },
	  	    { name = "showObligatoryMessage",  from = "momAnimation",  to = "momBubble_msg1", nextEvent = "showMessageAndAnimation" },
	  	    { name = "showMessageAndAnimation",  from = "momBubble_msg1",  to = "momBubble_msg2_handDirectionAnimation1", nextEvent = "transitionEvent" },
	  	    { name = "transitionEvent",  from = "momBubble_msg2_handDirectionAnimation1",  to = "transitionState_100_1", nextEvent = "showMessageAndAnimation" },
	  	    { name = "showMessageAndAnimation",  from = "transitionState_100_1",  to = "momBubble_msg3_handDirectionAnimation2", nextEvent = "transitionEvent" },
	  	    { name = "transitionEvent",  from = "momBubble_msg3_handDirectionAnimation2",  to = "transitionState_100_2", nextEvent = "showMessageAndAnimation" },
	  	    { name = "showMessageAndAnimation",  from = "transitionState_100_2",  to = "momBubble_msg4_handExecuteAnimation", nextEvent = "transitionEvent" },
	  	    { name = "transitionEvent",  from = "momBubble_msg4_handExecuteAnimation",  to = "transitionState_100_3", nextEvent = "showMessageAndAnimation" },
	  	    { name = "showMessageAndAnimation",  from = "transitionState_100_3",  to = "momBubble_msg5_gamePanelAnimation", nextEvent = "showMessage" },
	  	    { name = "showMessage",  from = "momBubble_msg5_gamePanelAnimation",  to = "momBubble_msg6", nextEvent = "showMessage" },
	  	    { name = "showMessage",  from = "momBubble_msg6",  to = "momBubble_msg6", nextEvent = "showMessage" },
	  	    { name = "transitionEvent",  from = "momBubble_msg6",  to = "transitionState4", nextEvent = "saveGame" },
	  	    { name = "saveGame",  from = "transitionState4",  to = "save", nextEvent = "showObligatoryMessage" },
	  	    { name = "showObligatoryMessage",  from = "save",  to = "momBubble_msg7", nextEvent = "showAnimation" },
	  	    { name = "showAnimation", from = "momBubble_msg7", to = "bikeAnimation", nextEvent = "showAnimation" },
	  	    { name = "showAnimation", from = "bikeAnimation", to = "gotoInitialPosition", nextEvent = "nextTutorial"  },
	  	    { name = "nextTutorial",  from = "gotoInitialPosition",  to = "tutorial" },
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
	  	            timer.performWithDelay( animation[self.current](), gameFlow.updateFSM ) 
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
	  	            showText( house:findObject( messageBubble ), message[ msg ] ) 
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
	  	            showText( house:findObject( messageBubble ), message[ msg ] ) 
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

	  	        showText( house:findObject( messageBubble ), message[ msg ] )

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

	  	            gamePanel.stopExecutionListeners()
	  	            if ( ( from == "transitionState" ) and ( wait ) ) then 
	  	              timer.performWithDelay( wait, gameFlow.updateFSM )
	  	            else
	  	              gameFlow.updateFSM()
	  	            end
	  	        end,

	  	    on_nextTutorial = 
	  	      function( self, event, from, to ) 
	  	        M.bikeTutorial()
	  	      end,

	  	    on_saveGame = 
	  	      function( self, event, from, to ) 
	  	        miniGameData.controlsTutorial = "complete"
	  	        --gameState:save( miniGameData )
	  	        gameFlow.updateFSM()
	  	      end,
	  	  }
	  	})

		mom.originalX = mom.x 
		mom.originalY = mom.y
	  	
	  	gameFlow.new( tutorialFSM )
	  	M.tutorialFSM = tutorialFSM
	  	M.update = gameFlow.updateFSM
	  	animation = houseAnimations.new( house, puzzle, gamePanel, path, tutorialFSM, gameFlow )
	  	tutorialFSM.showAnimation()
	end
end


return M