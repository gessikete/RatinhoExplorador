local composer = require( "composer" )

local tiled = require "com.ponywolf.ponytiled"

local json = require "json"

local persistence = require "persistence"

local scene = composer.newScene()

local sceneTransition = require "sceneTransition"

local fitScreen = require "fitScreen"

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local gotoMenuButton

local chooseGameFile

local gameFiles = { box = { }, text = { } }

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

	-- Verifica em qual minigame o jogo estava quando foi salvo
	if ( gameFile.currentMiniGame == "map" ) then
		timer.performWithDelay( 400, sceneTransition.gotoMap )
	elseif ( gameFile.currentMiniGame == "house" ) then
		timer.performWithDelay( 400, sceneTransition.gotoHouse )
	elseif ( gameFile.currentMiniGame == "school" ) then
		timer.performWithDelay( 400, sceneTransition.gotoSchool )
	elseif ( gameFile.currentMiniGame == "restaurant" ) then
		timer.performWithDelay( 400, sceneTransition.gotoRestaurant )
	end 
end

-- Remove os objetos
local function destroyScene()
  	chooseGameFile:removeSelf()
	chooseGameFile = nil

	for k, v in pairs( gameFiles.box ) do
		gameFiles.box[k]:removeEventListener( "tap", loadGameFile )
		gameFiles.box[k] = nil 
	end

	for k, v in pairs( gameFiles.text ) do
		gameFiles.text[k] = nil 
	end

	gameFiles = nil 
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

	gotoMenuButton = chooseGameFile:findObject("gotoMenuButton")

	fitScreen.fitBackground(chooseGameFile)

	sceneGroup:insert( chooseGameFile )
end


-- show()
function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		gotoMenuButton:addEventListener( "tap", sceneTransition.gotoMenu )
	elseif ( phase == "did" ) then

	end
end


-- hide()
function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
	elseif ( phase == "did" ) then
		destroyScene()
		composer.removeScene( "chooseGameFile" )
	end
end


-- destroy()
function scene:destroy( event )
	local sceneGroup = self.view
	gotoMenuButton:removeEventListener( "tap", sceneTransition.gotoMenu )
	gotoMenuButton = nil
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
