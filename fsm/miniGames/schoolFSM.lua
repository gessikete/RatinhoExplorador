local fsm = require "com.fsm.src.fsm"

local gameFlow = require "fsm.gameFlow"

local feedback = require "fsm.feedback"

local sceneTransition = require "sceneTransition"

local schoolMessages = require "fsm.messages.schoolMessages"

local schoolAnimations = require "fsm.animations.schoolAnimations"

local M = { }

local animation = {}

local message = {}

function M.new( school, miniGameData, gameState, gamePanel, path )
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

		schoolFSM = fsm.create({
	  	  initial = "start",
	  	  events = {
	  	    {name = "showObligatoryMessage",  from = "start",  to = "teacherBubble_msg1", nextEvent = "showAnimation" },
	  	    {name = "showAnimation",  from = "teacherBubble_msg1",  to = "handOrganizerAnimation", nextEvent = "showObligatoryMessage" },
	  	  	{name = "showObligatoryMessage",  from = "handOrganizerAnimation",  to = "teacherBubble_msg2", nextEvent = "enableListeners" },
	  	  	{name = "enableListeners",  from = "teacherBubble_msg2",  to = "restartListeners"},-- nextEvent = "enableListeners" },
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
	  	          local stars = 3

	  	          gamePanel.stopExecutionListeners()
	  	          if ( ( from == "transitionState" ) and ( wait ) ) then 
	  	            timer.performWithDelay( wait, gameFlow.updateFSM )
	  	          end

	  	          if ( executeButton.instructionsCount[#executeButton.instructionsCount] ) then 
	  	            if ( ( executeButton.executionsCount == 1 ) and ( executeButton.instructionsCount[#executeButton.instructionsCount] == 1 ) ) then
	  	              stars = 3
	  	            elseif ( gamePanel.bikeWheel.maxCount == 0 ) then
	  	              stars = 2
	  	            else 
	  	              stars = 1
	  	            end
	  	          else
	  	            stars = 1
	  	          end

	  	          local function closure()
	  	            path:hidePath()
	  	            gamePanel:hideInstructions()
	  	            if ( messageBubble ) then 
	  	              messageBubble.alpha = 0
	  	              if ( messageBubble.blinkingDart ) then 
	  	                messageBubble.blinkingDart.alpha = 0
	  	              end
	  	            end
	  	          end
	  	          timer.performWithDelay( 1000, closure )
	  	          gamePanel.tiled:insert( feedback.showAnimation( "school", stars, gameFlow.updateFSM ) )
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
	  	        local repeatPoint = school:findObject("repeatPoint")
	  	        local startingPoint = school:findObject("start")

	  	        physics.pause()
	  	        physics.removeBody( character )
	  	        mom.x = startingPoint.x 
	  	        mom.y = startingPoint.y - tilesSize - 8
	  	        character.x = repeatPoint.x
	  	        character.y = repeatPoint.y - 6
	  	        physics.start()
	  	        physics.addBody( character )
	  	        path:hidePath()

	  	        gamePanel:hideInstructions()
	  	        if ( messageBubble ) then 
	  	          messageBubble.alpha = 0
	  	          if ( messageBubble.blinkingDart ) then 
	  	            messageBubble.blinkingDart.alpha = 0
	  	          end
	  	        end

	  	        --gamePanel:updateBikeMaxCount( 1 )
	  	        timer.performWithDelay( 2000, gameFlow.updateFSM )
	  	        --gamePanel:showDirectionButtons( true )
	  	    end,

	  	    on_enableListeners = 
	  	      function( self, event, from, to ) 
	  	        if ( to == "restartListeners" ) then 
	  	        	gamePanel.restartExecutionListeners()
	  	        end
	  	    end
	  	  }
	  	})

		gameFlow.new( schoolFSM, school )
		M.update = gameFlow.updateFSM
		M.schoolFSM = schoolFSM
		animation = schoolAnimations.new( school, gamePanel, path, schoolFSM, gameFlow )
	  	schoolFSM.showObligatoryMessage()

	end
end

return M