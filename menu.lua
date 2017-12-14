local composer = require( "composer" )

local scene = composer.newScene()

local tiled = require "com.ponywolf.ponytiled"

local json = require "json"

local sceneTransition = require "sceneTransition"

local listenersModule = require "listeners"

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local menu

local newGameButton

local playButton

local fitScreen = require "fitScreen"

local listeners = listenersModule:new()

-- -----------------------------------------------------------------------------------
-- Cenas
-- -----------------------------------------------------------------------------------
-- create()
function scene:create( event )

	local sceneGroup = self.view

	display.setDefault("magTextureFilter", "nearest")
  	display.setDefault("minTextureFilter", "nearest")
	local menuData = json.decodeFile(system.pathForFile("tiled/menu.json", system.ResourceDirectory))  -- load from json export

	menu = tiled.new(menuData, "tiled")

	newGameButton = menu:findObject("new game")
	playButton = menu:findObject("play")
	title = menu:findObject("title")
	info = menu:findObject("info")

	sceneGroup:insert( menu )

	fitScreen.fitMenu( menu, newGameButton, playButton, title )

	listeners:add( playButton, "tap",  sceneTransition.gotoChooseGameFile )
	listeners:add( newGameButton, "tap", sceneTransition.gotoNewGame )
	listeners:add( info, "tap", sceneTransition.gotoCredits )
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
		listeners:destroy()
	elseif ( phase == "did" ) then
		menu:removeSelf()
		composer.removeScene( "menu" )
	end
end


-- destroy()
function scene:destroy( event )
	local sceneGroup = self.view
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
