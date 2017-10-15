local composer = require( "composer" )

local perspective = require("com.perspective.perspective")

local scene = composer.newScene()

local tiled = require "com.ponywolf.ponytiled"

local physics = require "physics"

local json = require "json"

local persistence = require "persistence"

local scenesTransitions = require "scenesTransitions"

local gamePanel = require "gamePanel"

local instructions = require "instructions"

local gameState = require "gameState"

local path = require "path"

local fitScreen = require "fitScreen"

physics.start()

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local house 

local character

local rope 

local ropeJoint

local tilesSize = 32

local stepDuration = 50
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local house

-- Trata dos tipos de colisão
local function onCollision( event )
  phase = event.phase
  local obj1 = event.object1
  local obj2 = event.object2

  if ( event.phase == "began" ) then
    if ( ( ( obj1.myName == "exit" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "exit" ) ) ) then 
      transition.cancel( )
      timer.performWithDelay( stepDuration, scenesTransitions.gotoMap )
    -- Colisão entre o personagem e os sensores dos tiles do caminho
	elseif ( ( ( obj1.myName == "entrace" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "entrance" ) ) ) then 
      transition.cancel( )
      timer.performWithDelay( stepDuration, scenesTransitions.gotoMap )
    elseif ( ( obj1.myName == "character" ) and ( obj2.myName ~= "collision" ) ) then 
      character.steppingX = obj1.x 
      character.steppingY = obj1.y 
      path:showTile( obj2.myName )
      --table.insert( markedPath, path[obj2.myName] )
    elseif ( ( obj2.myName == "character" ) and ( obj1.myName ~= "collision" ) ) then 
      character.steppingX = obj1.x 
      character.steppingY = obj1.y 
      path:showTile( obj1.myName )
      --table.insert( markedPath, path[obj1.myName] )
    -- Colisão com os demais objetos e o personagem (rope nesse caso)
    elseif ( ( ( obj1.myName == "collision" ) and ( obj2.myName == "rope" ) ) or ( ( obj1.myName == "rope" ) and ( obj2.myName == "collision" ) ) ) then 
      transition.cancel( )
    end
  end
  return true 
end

local function setHouse( )
	display.setDefault("magTextureFilter", "nearest")
  	display.setDefault("minTextureFilter", "nearest")
  	local houseTiledData = json.decodeFile(system.pathForFile("tiled/house.json", system.ResourceDirectory))

  	house = tiled.new(houseTiledData, "tiled")

  	fitScreen:fitDefault( house )
  	--local dragable = require "com.ponywolf.plugins.dragable"
  	--house = dragable.new(house)
end


local function setCharacter( )
	local rope 
  	local ropeJoint

  	-- lembrar: o myName (para os listeners) foi definido
  	-- no próprio tiled
  	character = house:findObject("character")

  	-- Objeto invisível que vai colidir com os objetos de colisão
  	-- @TODO: mudar posição e tamanho do rope quando substituirmos a imagem do personagem
  	rope = display.newRect( house:findLayer("character"), character.x, character.y + 4, 25, 20 )
  	physics.addBody( rope ) 
  	rope.gravityScale = 0 
  	rope.myName = "rope"
  	rope.isVisible = false
  	ropeJoint = physics.newJoint( "rope", rope, character, 0, 0 )
end

local function destroyHouse( )
  house:removeSelf( )
  house = nil 
end

local function destroyScene( )
  instructions:destroyInstructionsTable( )
  destroyHouse( )
  gamePanel:destroy( )

  Runtime:removeEventListener( "collision", onCollision )
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )
	local sceneGroup = self.view
	local markedPath
	setHouse( )
	setCharacter( )

	--loadGameFile( )
  gameState.new( "house", character, onCollision )
  gameState:load( )

  if ( ( character.xScale == -1 ) and ( character.steppingX ~= persistence.startingPoint("house") ) ) then
    character.xScale = 1
  end

	markedPath = path.new( house )
  path:setSensors( )
  instructionsTable = instructions.new( tilesSize, character, markedPath )

  sceneGroup:insert( house )
  sceneGroup:insert( gamePanel.new( instructions.executeInstructions ) )
  instructions:setGamePanelListeners( gamePanel.stopListeners, gamePanel.restartListeners )
end

-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		gamePanel:addDirectionListeners( )

	elseif ( phase == "did" ) then
		gamePanel:addButtonsListeners( )
    	gamePanel:addInstructionPanelListeners( )
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		transition.cancel( )
		gameState:save( character.steppingX, character.steppingY )
		destroyScene( )
	elseif ( phase == "did" ) then
    	composer.removeScene( "house" )
	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	--gamePanel:removeGoBackButton( )
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
