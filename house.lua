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

local function getQuadrant( dx, dy )
  if ( ( dx > 0) and ( dy > 0 ) ) then
    return 2
  elseif ( ( dx > 0 ) and ( dy < 0 ) ) then
    return 1
  elseif ( ( dx < 0 ) and ( dy > 0 ) ) then
    return 3
  elseif ( ( dx < 0 ) and ( dy < 0 ) ) then
    return 4
  end
end

local function l( event )
  local circle = event.target
  local phase = event.phase
  local centerX, centerY = circle:localToContent( 0, 0 )

  if ( "began" == phase ) then
    display.currentStage:setFocus( circle )

    local dx = event.x - centerX
    local dy = event.y - centerY 
    local radius = math.sqrt( math.pow( dx, 2 ) + math.pow( dy, 2 ) )
    local ds, dt = ( circle.radius * dx ) / radius, ( circle.radius * dy ) / radius

    adjustment = math.atan2( dt, ds ) * 180 / math.pi - circle.rotation

    circle.quadrant = getQuadrant( ds, dt )
  
  elseif ( "moved" == phase ) then
    if ( adjustment ) then 
      local dx = event.x - centerX 
      local dy = event.y - centerY
      local radius = math.sqrt( math.pow( dx, 2 ) + math.pow( dy, 2 ) )
      local ds, dt = ( circle.radius * dx ) / radius, ( circle.radius * dy ) / radius
      local quadrant = getQuadrant( dx, dy )

      if ( quadrant ~= circle.quadrant ) then
        if ( ( circle.quadrant == 4 ) and ( quadrant == 1 ) ) then 
          circle.steps = circle.steps + 0.5

          p5 = display.newCircle( house, circle.x + ds, circle.y + dt, 5 )
          p5:setFillColor( 0.1, 0.9, 1 )
        elseif ( ( circle.quadrant == 1 ) and ( quadrant == 4 ) ) then 
          if ( circle.steps > 0 ) then
            circle.steps = circle.steps - 0.5

            p5 = display.newCircle( house, circle.x + ds, circle.y + dt, 5 )
            p5:setFillColor( 0.7, 0.3, 0.6 )
          end
        elseif ( quadrant > circle.quadrant ) then 
          circle.steps = circle.steps + 0.5

          p5 = display.newCircle( house, circle.x + ds, circle.y + dt, 5 )
          p5:setFillColor( 0.1, 0.9, 1 )
        elseif ( quadrant < circle.quadrant ) then 
          if ( circle.steps > 0 ) then
            circle.steps = circle.steps - 0.5

            p5 = display.newCircle( house, circle.x + ds, circle.y + dt, 5 )
            p5:setFillColor( 0.7, 0.3, 0.6 )
          end
        end 
      end

      circle.quadrant = quadrant

      if ( circle.steps > 0 ) then
        circle.rotation = ( math.atan2( dt, ds ) * 180 / math.pi ) - adjustment 
      end
 
      t.text = math.floor(circle.steps)
    end 
  
  elseif ( "ended" == phase or "cancelled" == phase ) then
      display.currentStage:setFocus( nil )
  end

  return true 
end

local function c( )
  bikeWheel  = house:findObject("bikeWheel")
  bikeWheel.radius = bikeWheel.width/2
  bikeWheel.quadrant = 1
  bikeWheel.steps = 0

  t = display.newText( house, bikeWheel.steps, display.contentCenterX, display.contentCenterY, system.nativeFontBold, 30 )
  t:setFillColor( 0, 0, 0 )

  bikeWheel:addEventListener( "touch", l )
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
