
local composer = require( "composer" )

local scene = composer.newScene()


local movePath = {}
movePath[1] = { x=200, y=0 }
movePath[2] = { x=0, y=200 }
movePath[3] = { x=200, y=0, time=500 }
movePath[4] = { x=0, y=300, time=500 }
movePath[5] = { x=150, y=0, time=250, easingMethod=easing.inOutExpo }
movePath[6] = { x=0, y=100, time=2000 }
movePath[7] = { x=100, y=0, time=500 }
movePath[8] = { x=0, y=0, time=500, easingMethod=easing.outQuad }
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local function distBetween( x1, y1, x2, y2 )
	local xFactor = x2 - x1
	local yFactor = y2 - y1
	local dist = math.sqrt( (xFactor*xFactor) + (yFactor*yFactor) )
	return dist
end

local function setPath( object, path, params )
 
   local delta = params.useDelta or nil
   local deltaX = 0
   local deltaY = 0
   local constant = params.constantTime or nil
   local ease = params.easingMethod or easing.linear
   local tag = params.tag or nil
   local delay = params.delay or 0
   local speedFactor = 1

   -- opt
    if ( delta ) then
      deltaX = object.x
      deltaY = object.y
   	end

    if ( constant ) then
      local dist = distBetween( object.x, object.y, deltaX+path[1].x, deltaY+path[1].y )
      speedFactor = constant/dist
   	end

   	for i = 1,#path do
      	local segmentTime = 500
 
      	--if "constant" is defined, refactor transition time based on distance between points
      	if ( constant ) then
	        local dist
	        if ( i == 1 ) then
	            dist = distBetween( object.x, object.y, deltaX+path[i].x, deltaY+path[i].y )
	        else
	            dist = distBetween( path[i-1].x, path[i-1].y, path[i].x, path[i].y )
	        end
	        segmentTime = dist*speedFactor
	    else
         	--if this path segment has a custom time, use it
         	if ( path[i].time ) then segmentTime = path[i].time end
      	end
      	
      	--if this segment has custom easing, override the default method (if any)
      	if ( path[i].easingMethod ) then ease = path[i].easingMethod end

      	transition.to( object, { tag=tag, time=segmentTime, x=deltaX+path[i].x, y=deltaY+path[i].y, delay=delay, transition=ease } )
      	transition.pause( "moveObject" )
      	delay = delay + segmentTime
	end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		local circle1 = display.newCircle( 60, 100, 15 )
		circle1:setFillColor( 1, 0, 0.4 )
		local circle2 = display.newCircle( 120, 100, 15 )
		circle2:setFillColor( 1, 0.8, 0.4 )

		

		setPath( circle1, movePath, { tag="moveObject" } )
		setPath( circle2, movePath, { tag="lol" } )

		setPath( circle1, movePath, { tag="moveObject" } )
		setPath( circle2, movePath, { tag="moveObject" } )

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
