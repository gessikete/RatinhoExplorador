local composer = require( "composer" )

local tiled = require "com.ponywolf.ponytiled"

local json = require "json"

local persistence = require "persistence"

local scene = composer.newScene()

local sceneTransition = require "sceneTransition"

local fitScreen = require "fitScreen"

local listenersModule = require "listeners"
-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local gotoMenuButton

local chooseGameFile

local gameFiles = { box = { }, text = { }, trashcan = { } }

local listeners = listenersModule:new()

-- -----------------------------------------------------------------------------------
-- Funções
-- -----------------------------------------------------------------------------------
-- Transfere controle para o gamefile escolhido
local function loadGameFile( event )
	local fileName = event.target.myName
	local gameFile 
	
	persistence.setCurrentFileName( fileName ) 
	gameFile = persistence.loadGameFile()

	print( "-------------------------------------------------------------------" )
	print( "ARQUIVO ESCOLHIDO: " .. fileName )
	timer.performWithDelay( 400, sceneTransition.gotoProgress )
end

-- Remove os objetos
local function destroyScene()
  	chooseGameFile:removeSelf()
	chooseGameFile = nil

	for k, v in pairs( gameFiles.box ) do
		gameFiles.box[k] = nil 
	end

	for k, v in pairs( gameFiles.text ) do
		gameFiles.text[k] = nil 
	end

	gameFiles = nil 
end

local function deleteGameFile( event )
	local fileName = event.target.myName
	local gameFilesLayer = chooseGameFile:findLayer("gameFiles listeners")
	local trashcanLayer = chooseGameFile:findLayer("trash listeners")
	local trashcanImagesLayer = chooseGameFile:findLayer("trash")
	local filesNames

	persistence.deleteFile( fileName )

	filesNames = persistence.filesNames()
	for i = 1, #gameFiles.box do
		if ( ( filesNames ) and ( filesNames[i] ) ) then
			gameFiles.text[i].text = filesNames[i]
			gameFiles.box[i].myName = filesNames[i]
			gameFiles.trashcan[i].myName = filesNames[i]
		else
			if ( gameFiles.text[i] ) then 
				gameFiles.text[i]:removeSelf()
				gameFiles.text[i] = nil
				trashcanImagesLayer[i].alpha = 0 

				listeners:remove( gameFiles.box[i], "tap", loadGameFile )
				listeners:remove( gameFiles.trashcan[i], "tap", deleteGameFile )
			end
		end 
	end 
	
	return true 
end

local function setFiles()
	local filesNames = persistence.filesNames()

	local gameFilesLayer = chooseGameFile:findLayer("gameFiles listeners")

	local trashcanLayer = chooseGameFile:findLayer("trash listeners")

	local trashcanImagesLayer = chooseGameFile:findLayer("trash")

	local gameFilesImagesLayer = chooseGameFile:findLayer("gameFiles")

	for i = 1, gameFilesLayer.numChildren do
		local text

		table.insert( gameFiles.box, gameFilesLayer[i] )

		if ( ( filesNames ) and ( filesNames[i] ) ) then
			text = display.newText( chooseGameFile:findLayer( "gameFiles" ), filesNames[i], gameFilesImagesLayer[i].x, gameFilesImagesLayer[i].y, system.nativeFont, 30 )
			table.insert( gameFiles.text, text ) 
			table.insert( gameFiles.trashcan, trashcanLayer[i] )
			trashcanLayer[i].myName = filesNames[i]
			gameFiles.box[i].myName = filesNames[i]

			listeners:add( gameFiles.box[i], "tap", loadGameFile )
			listeners:add( trashcanLayer[i], "tap", deleteGameFile )
		else 
			trashcanImagesLayer[i].alpha = 0
		end 
	end
end


-- -----------------------------------------------------------------------------------
-- Cenas
-- -----------------------------------------------------------------------------------
-- create()
function scene:create( event )
	local sceneGroup = self.view
	
	display.setDefault("magTextureFilter", "nearest")
  	display.setDefault("minTextureFilter", "nearest")
	local chooseGameData = json.decodeFile(system.pathForFile("tiled/chooseGameFile.json", system.ResourceDirectory))  -- load from json export

	chooseGameFile = tiled.new(chooseGameData, "tiled")

	gotoMenuButton = chooseGameFile:findObject("gotoMenuButton")

	fitScreen.fitBackground(chooseGameFile)

	setFiles()

	sceneGroup:insert( chooseGameFile )
end


-- show()
function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		listeners:add( gotoMenuButton, "tap", sceneTransition.gotoMenu )
	elseif ( phase == "did" ) then
	
	end
end


-- hide()
function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
	elseif ( phase == "did" ) then
		listeners:destroy()
		destroyScene()
		composer.removeScene( "chooseGameFile" )
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
