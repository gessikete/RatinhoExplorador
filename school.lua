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

local schoolFSM = require "fsm.miniGames.schoolFSM"

physics.start()
physics.setGravity( 0, 0 )

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local school 

local character

local teacher 

local rope 

local ropeJoint

local tilesSize = 32

local stepDuration = 50

local supplies = { collected = { } }

local chairs = { }

local tables = { }

local collision = false 

local miniGameData


local function setObstacles()
  local chairsLayer = school:findLayer( "chairs" )
  local chairsSensorsLayer = school:findLayer( "chairs sensors" )
  local tablesLayer = school:findLayer( "tables" )
  local tablesSensorsLayer = school:findLayer( "tables sensors" ) 
  local sensors = { x = { } }
  
  for i = 1, chairsSensorsLayer.numChildren do

    local xCenter, yCenter = chairsSensorsLayer[i]:localToContent( 0, 0 )

    if ( sensors.x[xCenter] == nil ) then
        local y = { }
        table.insert( y, yCenter, chairsSensorsLayer[i] )
        table.insert( sensors.x, xCenter, y )
    else
      table.insert( sensors.x[xCenter], yCenter, chairsSensorsLayer[i] )
    end
  end

  for i = 1, chairsLayer.numChildren do
    local xCenter, yCenter = chairsLayer[i]:localToContent( 0, 0 )

    chairsLayer[i].number = i 
    if ( sensors.x[xCenter][yCenter] ) then 
        sensors.x[xCenter][yCenter].number = i 
    else print (" Sensor nao encontrado em x = " .. xCenter .. " e y = " .. yCenter )
    end
    table.insert( chairs, chairsLayer[i] )
  end


  sensors = { x = { } }
  for i = 1, tablesSensorsLayer.numChildren do

    local xCenter, yCenter = tablesSensorsLayer[i]:localToContent( 0, 0 )

    if ( sensors.x[xCenter] == nil ) then
        local y = { }
        table.insert( y, yCenter, tablesSensorsLayer[i] )
        table.insert( sensors.x, xCenter, y )
    else
      table.insert( sensors.x[xCenter], yCenter, tablesSensorsLayer[i] )
    end
  end

  for i = 1, tablesLayer.numChildren do
    local xCenter, yCenter = tablesLayer[i]:localToContent( 0, 0 )

    tablesLayer[i].number = i 
    if ( sensors.x[xCenter][yCenter] ) then 
        sensors.x[xCenter][yCenter].number = i 
    else print (" Sensor nao encontrado em x = " .. xCenter .. " e y = " .. yCenter )
    end
    table.insert( tables, tablesLayer[i] )
  end

end


-- -----------------------------------------------------------------------------------
-- Listeners
-- -----------------------------------------------------------------------------------
-- Trata dos tipos de colisão da casa
local function onCollision( event )
  phase = event.phase
  local obj1 = event.object1
  local obj2 = event.object2

  if ( event.phase == "began" ) then
    if ( ( ( obj1.myName == "character" ) and ( obj2.myName == "rope" ) ) or ( ( obj2.myName == "character" ) and ( obj1.myName == "rope" ) ) ) then 
    -- Volta para o mapa quando o personagem chega na saída/entrada da escola
    elseif ( ( ( obj1.myName == "exit" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "exit" ) ) ) then 
      if ( miniGameData.isComplete == true ) then
        transition.cancel()
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 800, sceneTransition.gotoMap )
      elseif ( ( miniGameData.controlsTutorial == "complete" ) and ( tutorialFSM ) )then
        local _, animationName = tutorialFSM.current:match( "([^,]+)_([^,]+)" ) 

        if ( animationName == "handExitAnimation" ) then
          transition.fadeOut( gamePanel.hand, { time = 450 } )
          executeTutorial()
        end
      end

    elseif ( ( ( obj1.myName == "entrance" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "entrance" ) ) ) then 
      if ( miniGameData.isComplete == true ) then
        transition.cancel()
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 800, sceneTransition.gotoMap )
      end

    elseif ( obj1.myName == "table" ) then --( ( obj1.myName == "character" ) and ( obj2.myName == "table" ) ) then 
      transition.cancel()
      function closure()
        physics.addBody( tables[obj1.number] )
        function _closure()
          physics.removeBody( obj1 )
        end
        timer.performWithDelay( 100, _closure )
      end 

      timer.performWithDelay( 100, closure )

    elseif ( obj2.myName == "table" ) then --( ( obj1.myName == "table" ) and ( obj2.myName == "character" ) ) then 
      transition.cancel()
      function closure()
        physics.addBody( tables[obj2.number] )
        function _closure()
          physics.removeBody( obj2 )
        end
        timer.performWithDelay( 100, _closure )
      end 
      timer.performWithDelay( 100, closure )

    elseif ( obj1.myName == "chair" ) then 
      transition.cancel()
      function closure()
        physics.addBody( chairs[obj1.number] )
        function _closure()
          physics.removeBody( obj1 )
        end
        timer.performWithDelay( 100, _closure )
      end 

      timer.performWithDelay( 100, closure )

    elseif ( obj2.myName == "chair" ) then
      transition.cancel()
      function closure()
        physics.addBody( chairs[obj2.number] )
        function _closure()
          physics.removeBody( obj2 )
        end
        timer.performWithDelay( 100, _closure )
      end
      timer.performWithDelay( 100, closure )


    -- Colisão entre o personagem e os sensores dos tiles do caminho
    elseif ( ( obj1.myName == "character" ) and ( obj2.isPath ) ) then
      character.steppingX = obj2.x 
      character.steppingY = obj2.y 
      path:showTile( obj2.myName )

    elseif ( ( obj2.myName == "character" ) and ( obj1.isPath ) ) then 
      character.steppingX = obj1.x 
      character.steppingY = obj1.y 
      path:showTile( obj1.myName )

    -- Colisão com os demais objetos e o personagem (rope nesse caso)
    elseif ( ( ( obj1.myName == "collision" ) and ( obj2.myName == "rope" ) ) or ( ( obj1.myName == "rope" ) and ( obj2.myName == "collision" ) ) ) then 
      transition.cancel()
      collision = true
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

  school:removeSelf()
  school = nil 

  if ( ( messageBubble ) and ( messageBubble.text ) ) then
    messageBubble.text:removeSelf()
    messageBubble.text = nil 
  end

  schoolFSM = nil 
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

  local sceneGroup = self.view
  persistence.setCurrentFileName( "ana" )

  school, character, rope, ropeJoint, gamePanel, gameState, path, instructions, instructionsTable, miniGameData = gameScene:set( "school", onCollision )


  sceneGroup:insert( school )
  sceneGroup:insert( gamePanel.tiled )

  setObstacles()
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
    if ( miniGameData.isComplete == false ) then
      schoolFSM.new( school, miniGameData, gameState, gamePanel, path )
      schoolFSM.execute()
    end
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
