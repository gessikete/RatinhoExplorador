
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local composer = require( "composer" )

local scene = composer.newScene()

local tiled = require "com.ponywolf.ponytiled"

local json = require "json"

local sceneTransition = require "sceneTransition"

local listenersModule = require "listeners"

local credits

local newGameButton

local playButton

local fitScreen = require "fitScreen"

local listeners = listenersModule:new()
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )
	local sceneGroup = self.view

	display.setDefault("magTextureFilter", "nearest")
  	display.setDefault("minTextureFilter", "nearest")
	local creditsData = json.decodeFile(system.pathForFile("tiled/credits.json", system.ResourceDirectory))  -- load from json export

	credits = tiled.new(creditsData, "tiled")

	gotoMenuButton = credits:findObject("gotoMenuButton")

	sceneGroup:insert( credits )

	listeners:add( gotoMenuButton, "tap",  sceneTransition.gotoMenu )

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
		credits:removeSelf()
		composer.removeScene( "credits" )
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
