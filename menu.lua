
local composer = require( "composer" )

local scene = composer.newScene()

local tiled = require "com.ponywolf.ponytiled"

local json = require "json"

local scenesTransitions = require "scenesTransitions"

local menu

local newGameButton

local playButton

local fitScreen = require "fitScreen"
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	display.setDefault("magTextureFilter", "nearest")
  	display.setDefault("minTextureFilter", "nearest")
	local menuData = json.decodeFile(system.pathForFile("tiled/menu.json", system.ResourceDirectory))  -- load from json export

	menu = tiled.new(menuData, "tiled")

	newGameButton = menu:findObject("new game")
	playButton = menu:findObject("play")
	title = menu:findObject("title")

	sceneGroup:insert( menu )

	fitScreen:fitMenu( menu, newGameButton, playButton, title )

	playButton:addEventListener( "tap", scenesTransitions.gotoChooseGameFile )
	newGameButton:addEventListener( "tap", scenesTransitions.gotoNewGame )
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		

	elseif ( phase == "did" ) then
		
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
