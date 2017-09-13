
local composer = require( "composer" )

local scene = composer.newScene()

local tiled = require "com.ponywolf.ponytiled"
--local physics = require "physics"
local json = require "json"

-- if you use physics bodies in your map, you must
-- start() physics before you load your map
physics.start()

-- Load a "pixel perfect" map from a JSON export
display.setDefault("magTextureFilter", "nearest")
display.setDefault("minTextureFilter", "nearest")
local mapData = json.decodeFile(system.pathForFile("maps/tiles/tilemap.json", system.ResourceDirectory))  -- load from json export
local map = tiled.new(mapData, "maps/tiles")

local personagem
local joystickRight
local joystickLeft
local joystickDown
local joystickUp

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local function moveCharacter( event )
  local move = event.target

  if ( move.myName == "right" ) then
    personagem.x = personagem.x + 20

  elseif ( move.myName == "left" ) then
    personagem.x = personagem.x - 20

  elseif ( move.myName == "up" ) then
    personagem.y = personagem.y - 20

  elseif ( move.myName == "down" ) then
    personagem.y = personagem.y + 20
  end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

  -- PONYTAIL center the map on screen
  map.x, map.y = display.contentCenterX - map.designedWidth/2, display.contentCenterY - map.designedHeight/2

  -- criar referências para os objetos
  personagem = map:findObject("character")
  personagem.myName = "character"

  joystickRight = map:findObject("right")
  joystickRight.myName = "right"

  joystickLeft = map:findObject("left")
  joystickLeft.myName = "left"

  joystickDown = map:findObject("down")
  joystickDown.myName = "down"

  joystickUp = map:findObject("up")
  joystickUp.myName = "up"

  --lugares onde não pode andar
  camadaColisao = map:findLayer("collision")

end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
    -- criar os listeners para mover o personagem por meio do joystick
    joystickRight:addEventListener( "tap", moveCharacter )
    joystickLeft:addEventListener( "tap", moveCharacter )
    joystickDown:addEventListener( "tap", moveCharacter )
    joystickUp:addEventListener( "tap", moveCharacter )
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
