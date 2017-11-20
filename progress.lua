
local composer = require( "composer" )

local scene = composer.newScene()

local tiled = require "com.ponywolf.ponytiled"

local json = require "json"

local persistence = require "persistence"

local fitScreen = require "fitScreen"

local sceneTransition = require "sceneTransition"

local listenersModule = require "listeners"


local miniGamesData

local menuButton

local listeners = listenersModule:new()

local function gotoHouse()
	miniGamesData.house.onRepeat = true 
	persistence.saveGameFile( miniGamesData )

	sceneTransition.gotoHouse()
end

local function gotoRestaurant()
	miniGamesData.restaurant.onRepeat = true 
	persistence.saveGameFile( miniGamesData )

	sceneTransition.gotoRestaurant()
end

local function gotoSchool()
	miniGamesData.school.onRepeat = true 
	persistence.saveGameFile( miniGamesData )

	sceneTransition.gotoSchool()
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen
	display.setDefault("magTextureFilter", "nearest")
  	display.setDefault("minTextureFilter", "nearest")
  	local progressData = json.decodeFile(system.pathForFile("tiled/progress.json", system.ResourceDirectory))

  	progress = tiled.new( progressData, "tiled" )
  	fitScreen.fitProgress( progress )

  	--persistence.setCurrentFileName( "ana" )
  	miniGamesData = persistence.loadGameFile()

  	sceneGroup:insert( progress )


  	menuButton = progress:findObject( "menuButton" )

  	if ( miniGamesData.house.stars > 0 ) then progress:findObject( "star_level1_1" ).alpha = 1 end
  	if ( miniGamesData.house.stars >= 2 ) then progress:findObject( "star_level1_2" ).alpha = 1 end
  	if ( miniGamesData.house.stars == 3 ) then progress:findObject( "star_level1_3" ).alpha = 1 end

  	if ( miniGamesData.school.stars > 0 ) then progress:findObject( "star_level2_1" ).alpha = 1 end 
  	if ( miniGamesData.school.stars >= 2 ) then progress:findObject( "star_level2_2" ).alpha = 1 end
  	if ( miniGamesData.school.stars == 3 ) then progress:findObject( "star_level2_3" ).alpha = 1 end

  	if ( miniGamesData.restaurant.stars > 0 ) then progress:findObject( "star_level3_1" ).alpha = 1 end 
  	if ( miniGamesData.restaurant.stars >= 2 ) then progress:findObject( "star_level3_2" ).alpha = 1 end 
  	if ( miniGamesData.restaurant.stars == 3 ) then progress:findObject( "star_level3_3" ).alpha = 1 end

end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		local level1 = progress:findObject( "level1" )

		listeners:add( level1, "tap", gotoHouse )

		if ( miniGamesData.house.stars > 0 ) then
			local level2 = progress:findObject( "level2" )
			local locked = progress:findObject( "level2_locked" )
			
			level2.alpha = 1
			locked.alpha = 0

			listeners:add( level2, "tap", gotoSchool )
		end 

		if ( miniGamesData.school.stars > 0 ) then 
			local level3
			local locked = progress:findObject( "level3_locked" )

			level3 = progress:findObject( "level3" )
			level3.alpha = 1
			locked.alpha = 0

			listeners:add( level3, "tap", gotoRestaurant )
		end
		
		listeners:add( menuButton, "tap", sceneTransition.gotoMenu )
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
		progress:removeSelf()
  		progress = nil
  		listeners:destroy()
  		composer.removeScene( "progress" )
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
