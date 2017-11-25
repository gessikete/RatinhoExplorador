
local composer = require( "composer" )

local scene = composer.newScene()

local tiled = require "com.ponywolf.ponytiled"

local json = require "json"

local persistence = require "persistence"

local sceneTransition = require "sceneTransition"

local fitScreen = require "fitScreen"

local listenersModule = require "listeners"


-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local textField
local playButton
local playBioButton
local gotoMenuButton
local gotoMenuBioButton
local goBackButton
local listeners = listenersModule:new()
local character
local newGame

local bios 

-- -----------------------------------------------------------------------------------
-- Funções
-- -----------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------
-- Listeners
-- -----------------------------------------------------------------------------------
local function textListener( event )
 
    if ( event.phase == "began" ) then
 
    elseif ( event.phase == "ended" or event.phase == "submitted" ) then
        textField.string = event.target.text
 
    elseif ( event.phase == "editing" ) then
    end
end

local function chooseCharacter( event )
	transition.cancel()
	if ( event.target.myName == "ada" ) then 
		character = "Ada"
	else
		character = "Turing"
	end

	transition.fadeOut( newGame:findObject( "characters" ), { time = 800 } )
	bios()
end

local function showCharacters()
	transition.fadeIn( newGame:findObject( "characters" ), { time = 800 } )
	transition.fadeIn( gotoMenuButton, { time = 800 } )

	listeners:add( newGame:findObject( "ada" ), "tap", chooseCharacter )
	listeners:add( newGame:findObject( "turing" ), "tap", chooseCharacter )
	listeners:add( gotoMenuButton, "tap", sceneTransition.gotoMenu )
end

-- Cria um novo arquivo de jogo 
local function createFile()	
	if ( ( textField.text ~= nil ) and ( not tostring( textField.text ):find( "^%s*$" ) ) ) then 
		if ( persistence.fileExists( textField.text ) == false ) then
			transition.fadeOut( newGame:findObject( "messageBubble" ), { time = 800 } )
			persistence.newGameFile( textField.text, character )
			sceneTransition.gotoHouse()
		else 
			transition.fadeIn( newGame:findObject( "messageBubble" ), { time = 800 } )
		end
	end
end

local function showTextField()
	transition.fadeOut( goBackButton, { time = 800 } )
	transition.fadeOut( gotoMenuBioButton, { time = 800 } )
	transition.fadeOut( playBioButton, { time = 800 } )
	transition.fadeOut( newGame:findObject( "adaBio" ), { time = 800 } )
	transition.fadeOut( newGame:findObject( "turingBio" ), { time = 800 } )
	newGame:findObject( "background" ).alpha = 1
	gotoMenuButton.alpha = 1
	playButton.alpha = 1

	listeners:add( playButton, "tap", createFile )
	listeners:add( gotoMenuButton, "tap", sceneTransition.gotoMenu )

	textField = native.newTextField( 3*display.contentCenterX/4, display.contentCenterY/2, display.contentWidth/2, 30 )

	textField.inputType = "default"
	textField.string = " "
	newGame:insert( textField )

	listeners:add( textField, "userInput", textListener )
end

local function gotoShowCharacters()
	transition.fadeOut( playBioButton, { time = 800 } )
	transition.fadeOut( goBackButton, { time = 800 } )
	transition.fadeOut( gotoMenuBioButton, { time = 800 } )
	transition.fadeOut( newGame:findObject( "adaBio" ), { time = 800 } )
	transition.fadeOut( newGame:findObject( "turingBio" ), { time = 800 } )
	showCharacters()
end

local function showBios()
	if ( character == "Ada" ) then 
		newGame:findObject( "adaBio" ).alpha = 1
	else
		newGame:findObject( "turingBio").alpha = 1
	end 

	transition.fadeIn( gotoMenuBioButton, { time = 800} )
	transition.fadeIn( goBackButton, { time = 800} )
	transition.fadeIn( playBioButton, {time = 800} )
	gotoMenuButton.alpha = 0
	playButton.alpha = 0
	listeners:add( goBackButton, "tap", gotoShowCharacters )
	listeners:add( gotoMenuBioButton, "tap", sceneTransition.gotoMenu )
	listeners:add( playBioButton, "tap", showTextField )
	listeners:remove ( gotoMenuButton, "tap", sceneTransition.gotoMenu )
	listeners:remove( newGame:findObject( "ada" ), "tap", chooseCharacter )
	listeners:remove( newGame:findObject( "turing" ), "tap", chooseCharacter )
end
 

-- -----------------------------------------------------------------------------------
-- Cenas
-- -----------------------------------------------------------------------------------
-- create()
function scene:create( event )
	local sceneGroup = self.view

	display.setDefault("magTextureFilter", "nearest")
  	display.setDefault("minTextureFilter", "nearest")
	local newGameData = json.decodeFile(system.pathForFile("tiled/newGame.json", system.ResourceDirectory))  -- load from json export

	newGame = tiled.new(newGameData, "tiled" )

	playButton = newGame:findObject( "play" )

	playBioButton = newGame:findObject( "playBioButton" )

	gotoMenuButton = newGame:findObject( "gotoMenuButton" )

	goBackButton = newGame:findObject( "goBackButton" )

	gotoMenuBioButton = newGame:findObject( "gotoMenuBioButton" )

	sceneGroup:insert( newGame )

	showCharacters()

	bios = showBios
	--fitScreen:fitBackground( newGame )
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
		native.setKeyboardFocus( nil )
		display.remove( textField )
		textField = nil	
	elseif ( phase == "did" ) then
		newGame:removeSelf()
		listeners:destroy()
		composer.removeScene( "newGame" )
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
