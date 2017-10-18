local composer = require( "composer" )

local scene = composer.newScene()

local tiled = require "com.ponywolf.ponytiled"

local physics = require "physics"

local json = require "json"

local persistence = require "persistence"

local sceneTransition = require "sceneTransition"

local gamePanel = require "gamePanel"

local instructions = require "instructions"

local gameState = require "gameState"

local path = require "path"

local gameScene = require "gameScene"

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

local house

local puzzle = { bigPieces = { }, littlePieces = { }, puzzleSensors = { } }

-- -----------------------------------------------------------------------------------
-- Listeners
-- -----------------------------------------------------------------------------------
-- Trata dos tipos de colisão da casa
local function onCollision( event )
  phase = event.phase
  local obj1 = event.object1
  local obj2 = event.object2

  if ( event.phase == "began" ) then
    if ( ( obj1.myName == "puzzle" ) and ( obj2.myName == "character" ) ) then
      puzzle.bigPieces[obj1.puzzleNumber].alpha = 1
      puzzle.littlePieces[ obj1.puzzleNumber ]. alpha = 0
    elseif ( ( obj1.myName == "character" ) and ( obj2.myName == "puzzle" ) ) then 
      puzzle.bigPieces[obj2.puzzleNumber].alpha = 1
      puzzle.littlePieces[ obj2.puzzleNumber ]. alpha = 0
    -- Volta para o mapa quando o personagem chega na saída/entrada da casa
    elseif ( ( ( obj1.myName == "exit" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "exit" ) ) ) then 
      transition.cancel()
      instructions:destroyInstructionsTable()
      gamePanel:stopAllListeners()
      timer.performWithDelay( 400, sceneTransition.gotoMap )

	  elseif ( ( ( obj1.myName == "entrace" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "entrance" ) ) ) then 
      transition.cancel()
      instructions:destroyInstructionsTable()
      gamePanel:stopAllListeners()
      timer.performWithDelay( 400, sceneTransition.gotoMap )

    -- Colisão entre o personagem e os sensores dos tiles do caminho
    elseif ( ( obj1.myName == "character" ) and ( obj2.myName ~= "collision" ) ) then 
      character.steppingX = obj2.x 
      character.steppingY = obj2.y 
      path:showTile( obj2.myName )

    elseif ( ( obj2.myName == "character" ) and ( obj1.myName ~= "collision" ) ) then 
      character.steppingX = obj1.x 
      character.steppingY = obj1.y 
      path:showTile( obj1.myName )

    -- Colisão com os demais objetos e o personagem (rope nesse caso)
    elseif ( ( ( obj1.myName == "collision" ) and ( obj2.myName == "rope" ) ) or ( ( obj1.myName == "rope" ) and ( obj2.myName == "collision" ) ) ) then 
      transition.cancel()
    end
  end
  return true 
end

-- -----------------------------------------------------------------------------------
-- Remoções para limpar a tela
-- -----------------------------------------------------------------------------------
local function destroyScene()
  Runtime:removeEventListener( "collision", onCollision )
  gamePanel:destroy()

  instructions:destroyInstructionsTable()

  house:removeSelf()
  house = nil 
end

local function setPuzzle()
  local bigPiecesLayer = house:findLayer("big puzzle") 
  local littlePiecesLayer = house:findLayer("little puzzle") 
  local puzzleSensorsLayer = house:findLayer("puzzle sensors")

  for i = 1, bigPiecesLayer.numChildren do
    puzzle.bigPieces[ bigPiecesLayer[i].myName ] = bigPiecesLayer[i]
    puzzle.puzzleSensors[ puzzleSensorsLayer[i].puzzleNumber ] = puzzleSensorsLayer[i]
    puzzle.littlePieces[ bigPiecesLayer[i].myName ] = littlePiecesLayer[i]
  end
end

local function l( event )
  local circle = event.target
  local phase = event.phase
  local centerX, centerY = circle:localToContent( 0, 0 )


  --print("circle.x: " .. centerX .. "; event.x: " .. event.x )
  --print("circle.y: " .. centerY .. "; event.y: " .. event.y )
  if ( "began" == phase ) then
    display.currentStage:setFocus( circle )

    local dx = event.x - centerX
    local dy = event.y - centerY 
    circle.dx = dx
    circle.dy = dy 
    adjustment = math.atan2( dy, dx ) * 180 / math.pi - circle.rotation
    --circle.touchOffsetX = event.x - circle.x
    print( "dx: " .. dx .. ", dy: " .. dy ) 
  
  elseif ( "moved" == phase ) then
    local dx = event.x - centerX 
    local dy = event.y - centerY

    --if ( circle.dx < dx ) and ( circle.dy > dy ) then 
      --sentido horário

    --elseif ( ) then

    --end 

    print( "-----------------------" ) 
    --print( "circle.dx: " .. circle.dx .. ", circle.dy: " .. circle.dy ) 
    --print( "dx: " .. dx .. ", dy: " .. dy ) 
    print( "-----------------------" )
    
    --print( circle.dif + ( ( math.atan2( dy, dx ) * 180 / math.pi ) - adjustment ) )
    --circle.rotation = ( math.atan2( dy, dx ) * 180 / math.pi ) - adjustment
    --circle.rotation = 180
    --print("rotation: " .. circle.rotation)

    --circle.x = event.x - circle.touchOffsetX
  
  elseif ( "ended" == phase or "cancelled" == phase ) then
      display.currentStage:setFocus( nil )
  end

  return true -- prevents touch propagation to underlying objects
end

local function c( )
  ue  = house:findObject("ue")

  p = display.newCircle( house:findLayer("ue"), ue.x, ue.y, 5 )
  p:setFillColor( 0.2, 1, 0.9 )

  --branco
  p1 = display.newCircle( house:findLayer("ue"), ue.x, ue.y + ue.height/2, 5 )

  -- preto
  p2 = display.newCircle( house:findLayer("ue"), ue.x, ue.y - ue.height/2, 5 )
  p2:setFillColor( 0, 0, 0 )

  -- roxo
  p3 = display.newCircle( house:findLayer("ue"), ue.x + ue.width/2, ue.y, 5 )
  p3:setFillColor( 0.7, 0.3, 0.6 )

  -- azul
  p4 = display.newCircle( house:findLayer("ue"), ue.x - ue.width/2, ue.y, 5 )
  p4:setFillColor( 0.1, 0.9, 1 )

  ue:addEventListener( "touch", l )
end

-- -----------------------------------------------------------------------------------
-- Cenas
-- -----------------------------------------------------------------------------------
-- create()
function scene:create( event )
	local sceneGroup = self.view

	house, character, rope, ropeJoint, gamePanel, gameState, path, instructions, instructionsTable = gameScene:set( "house", onCollision )

  if ( character.flipped == true ) then
    character.xScale = -1
  end

  setPuzzle()

  c()

  sceneGroup:insert( house )
  sceneGroup:insert( gamePanel.tiled )
end

-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		gamePanel:addDirectionListeners()

	elseif ( phase == "did" ) then
		gamePanel:addButtonsListeners()
    gamePanel:addInstructionPanelListeners()
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		physics.stop( )
		gameState:save()
		destroyScene()
	elseif ( phase == "did" ) then
    composer.removeScene( "house" )
	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	--gamePanel:removeGoBackButton()
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
