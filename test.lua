
local composer = require( "composer" )

local fsm = require "com.fsm.src.fsm"

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	

	local green = display.newCircle( sceneGroup, display.contentCenterX + 30, display.contentCenterY, 10 )
	green:setFillColor( 0, 1, 0 )

	local red = display.newCircle( sceneGroup, display.contentCenterX, display.contentCenterY, 10 )
	red:setFillColor( 1, 0, 0 )

	local blue = display.newCircle( sceneGroup, display.contentCenterX - 30, display.contentCenterY, 10 )
	blue:setFillColor( 0, 0, 1 )

	local orange = display.newCircle( sceneGroup, display.contentCenterX - 60, display.contentCenterY, 10 )
	orange:setFillColor( 1, 0.5, 0 )

	local yellow = display.newCircle( sceneGroup, display.contentCenterX + 60, display.contentCenterY, 10 )
	yellow:setFillColor( 1, 1, 0 )

	local pink = display.newCircle( sceneGroup, display.contentCenterX + 90, display.contentCenterY, 10 )
	pink:setFillColor( 1, 0.41, 0.7 )

	local plum = display.newCircle( sceneGroup, display.contentCenterX - 90, display.contentCenterY, 10 )
	plum:setFillColor( 0.87, 0.62, 0.87 )

	local alert = fsm.create({
	  initial = "start",
	  events = {
	    {name = "showMessage",  from = "start",  to = "msg1", nextEvent = "showAnimation" },
	    {name = "showAnimation", from = "msg1", to = "animation1", nextEvent = "showMessage" },
	    {name = "showMessage", from = "animation1", to = "msg2", nextEvent = "showAnimation" },
	    {name = "showAnimation", from = "msg2", to = "animation2", nextEvent = "showMessage" },
	    {name = "showMessage", from = "animation2", to = "msg3", nextEvent = "showAnimation" },
	    {name = "showAnimation", from = "msg3", to = "animation3", nextEvent = "showAnimation" },
	    {name = "showAnimation", from = "animation3", to = "animation4", nextEvent = "showAnimation" },
	    {name = "showAnimation", from = "animation4", to = "animation5", nextEvent = "showAnimation" },
	    {name = "showAnimation", from = "animation5", to = "animation6", nextEvent = "showAnimation" },
	    {name = "showAnimation", from = "animation6", to = "end" },

	  },
	  callbacks = {
	  	on_state = function( self, event, from, to, cor, posX, posY ) 
	
	  		if ( self.event == "showAnimation" ) then 
	  			transition.to( cor, { time = 2000, x = cor.x + posX, y = cor.y + posY } )
	  		end 
	  	end,
	  }
	})

	local msgNumber = 1
	local animation = { green, red, blue, orange, yellow, pink, plum }
	local posX = { math.random( -100, 100 ), math.random( -100, 100 ), math.random( -100, 100 ), math.random( -100, 100 ), math.random( -100, 100 ), math.random( -100, 100 ), math.random( -100, 100 ) }
	local posY = { math.random( -100, 100 ), math.random( -100, 100 ), math.random( -100, 100 ), math.random( -100, 100 ), math.random( -100, 100 ), math.random( -100, 100 ), math.random( -100, 100 ) }
	local animationNum = 1

	alert.showMessage()

	function executeControlsTutorial()
		print( alert.nextEvent )
		if ( animationNum <= #animation ) then 
			if ( alert.nextEvent == "showAnimation" ) then 
				alert.showAnimation( animation[ animationNum ], posX[animationNum], posY[animationNum] )
				animationNum = animationNum + 1
				timer.performWithDelay( 2000, executeControlsTutorial )
			elseif ( alert.nextEvent == "showMessage" ) then 
				alert.showMessage()
				executeControlsTutorial()
			elseif ( alert.nextEvent == "showFeedback" ) then
			end
		end
	end

	executeControlsTutorial()

	--alert.showMessage()
	--alert.showAnimation(red)


	
	--alert.clear()
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen

	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
