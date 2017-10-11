local composer = require( "composer" )

local tiled = require "com.ponywolf.ponytiled"

local json = require "json"

local persistence = require "persistence"

local scene = composer.newScene()

local scenesTransitions = require "scenesTransitions"

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local goBackButton

local chooseGameFile

local gameFiles = { box = { }, text = { } }


local function loadGameFile( event )
	persistence.setCurrentFileName( event.target.myName )
	scenesTransitions.gotoMap( )
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )
	local sceneGroup = self.view
	
	display.setDefault("magTextureFilter", "nearest")
  	display.setDefault("minTextureFilter", "nearest")
	local chooseGameData = json.decodeFile(system.pathForFile("tiled/chooseGameFile.json", system.ResourceDirectory))  -- load from json export

	chooseGameFile = tiled.new(chooseGameData, "tiled")

	local filesNames = persistence.filesNames()

	local gameFilesLayer = chooseGameFile:findLayer("gameFiles")

	for i = 1, gameFilesLayer.numChildren do
		local text

		table.insert( gameFiles.box, gameFilesLayer[i] )

		if ( ( filesNames ~= nil ) and ( filesNames[i] ~= nil ) ) then
			text = display.newText( chooseGameFile, filesNames[i], gameFilesLayer[i].x, gameFilesLayer[i].y, system.nativeFont, 30 )
			table.insert(gameFiles.text, text ) 
			gameFiles.box[#gameFiles.box].myName = filesNames[i]
			gameFiles.box[#gameFiles.box]:addEventListener( "tap", loadGameFile )
		end 
	end

	goBackButton = chooseGameFile:findObject("goBackButton")

	sceneGroup:insert( chooseGameFile )
end


-- show()
function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		goBackButton:addEventListener( "tap", scenesTransitions.gotoMenu )
	elseif ( phase == "did" ) then

	end
end


-- hide()
function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
	elseif ( phase == "did" ) then
		chooseGameFile:removeSelf( )
		chooseGameFile = nil 
		composer.removeScene( "chooseGameFile" )
	end
end


-- destroy()
function scene:destroy( event )
	local sceneGroup = self.view
	goBackButton:removeEventListener( "tap", scenesTransitions.gotoMenu )
	goBackButton = nil
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
