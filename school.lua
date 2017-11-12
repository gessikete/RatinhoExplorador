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

local supplies

local chairs = { }

local tables = { }

local organizerPositions = { }

local collision

local miniGameData

local function setSupplies()
  local suppliesLayer = school:findLayer( "supplies" )
  local suppliesSensorsLayer = school:findLayer( "supplies sensors" )

  supplies = { collected = { }, list = { }, sensors = { }, remaining = { } }

  for i = 1, suppliesLayer.numChildren do
    supplies.list[suppliesLayer[i].number] = suppliesLayer[i] 
    supplies.sensors[suppliesSensorsLayer[i].number] = suppliesSensorsLayer[i] 
  end
end

local function setObstacles()
  local chairsLayer = school:findLayer( "chairs" )
  local chairsSensorsLayer = school:findLayer( "chairs sensors" )
  local tablesLayer = school:findLayer( "tables" )
  local tablesSensorsLayer = school:findLayer( "tables sensors" ) 
  local organizerPositionsLayer = school:findLayer( "organizer positions" ) 
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
    chairsLayer[i].originalX = chairsLayer[i].x
    chairsLayer[i].originalY = chairsLayer[i].y
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
    tablesLayer[i].originalX = tablesLayer[i].x
    tablesLayer[i].originalY = tablesLayer[i].y
    if ( sensors.x[xCenter][yCenter] ) then 
        sensors.x[xCenter][yCenter].number = i 
    else print (" Sensor nao encontrado em x = " .. xCenter .. " e y = " .. yCenter )
    end
    table.insert( tables, tablesLayer[i] )
  end

  for i = 1, organizerPositionsLayer.numChildren do 
    organizerPositions[ organizerPositionsLayer[i].number ] =  organizerPositionsLayer[i]
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
        transition.cancel( character )
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 800, sceneTransition.gotoMap )
      end
    elseif ( ( ( obj1.myName == "entrance" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "entrance" ) ) ) then 
      if ( miniGameData.isComplete == true ) then
        transition.cancel( character )
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 800, sceneTransition.gotoMap )
      end

    elseif ( ( obj1.myName == "supply" ) and ( obj2.myName == "character" ) ) then
      supplies.collected[ obj1.number ] = supplies.list[ obj1.number ]
      transition.fadeOut( supplies.list[ obj1.number ], { time = 400 } )
      print( "supply" )

    elseif ( ( obj2.myName == "supply" ) and ( obj1.myName == "character" ) ) then
      supplies.collected[ obj1.number ] = supplies.list[ obj2.number ]
      transition.fadeOut( supplies.list[ obj2.number ], { time = 400 } )
      print( "supply" )

    elseif ( obj1.myName == "table" ) then    
      if ( not tables[obj1.number].isPhysics ) then
        transition.cancel( character ) 
        function closure()
          physics.addBody( tables[obj1.number] )
          tables[obj1.number].isPhysics = true 
        end 

        timer.performWithDelay( 100, closure )
        collision.table = true 
      end

    elseif ( obj2.myName == "table" ) then
      if ( not tables[obj2.number].isPhysics ) then 
        transition.cancel( character )
        function closure()
          physics.addBody( tables[obj2.number] )
          tables[obj2.number].isPhysics = true 
        end 
        timer.performWithDelay( 100, closure )
        collision.table = true 
      end 

    elseif ( obj1.myName == "chair" ) then 
      if ( not chairs[obj1.number].isPhysics ) then 
        transition.cancel( character )
        function closure()
          physics.addBody( chairs[obj1.number] )
          chairs[obj1.number].isPhysics = true 
        end 

        timer.performWithDelay( 100, closure )

        collision.chair = true 
      end

    elseif ( obj2.myName == "chair" ) then
      if ( not chairs[obj2.number].isPhysics ) then 
        transition.cancel( character )
        function closure()
          physics.addBody( chairs[obj2.number] )
          chairs[obj2.number].isPhysics = true 
        end
        timer.performWithDelay( 100, closure )

        collision.chair = true 
      end

    elseif ( ( obj1.myName == "organizer" ) or ( obj2.myName == "organizer" ) ) then
      local obj 
      if ( obj1.myName == "organizer" ) then obj = obj1 else obj = obj2 end 
      local list = { }
        
      if ( instructionsTable.last < instructionsTable.executing ) then 
        schoolFSM.waitFeedback = true 
      end

      if ( collision.organizer == false ) then 
        for k, v in pairs( supplies.collected ) do
          table.insert( list, v )
        end
      else 
        for k, v in pairs( supplies.remaining ) do
          if ( v == supplies.collected[k] ) then
            table.insert( list, v )
          end
        end
      end

      local function showSupply( i )
        if ( i > #list ) then 
          for j = 1, #list  do 
            transition.fadeOut( list[j], { time = 800, onComplete = schoolFSM.updateFSM } )
          end
          return 
        end  
        list[i].x = organizerPositions[obj.number].x 
        list[i].y = organizerPositions[obj.number].y
        list[i]:toFront()
        transition.fadeIn( list[i], { time = 800, 
          onComplete = 
            function()
              showSupply( i + 1 )
            end 
        } )
      end

      transition.cancel( character )

      if ( ( obj.direction == "right" ) ) then 
        transition.to( character, { time = 0, x = character.x + .25 * tilesSize, 
          onComplete = 
            function()
              showSupply(1)
            end
          } )
        
      elseif ( ( obj.direction == "down" ) ) then 
        transition.to( character, { time = 0, y = character.y + .06 * tilesSize, 
          onComplete = 
            function()
              showSupply(1)
            end
          } )
      else
        transition.to( character, { time = 0, y = character.y - .35 * tilesSize, 
          onComplete = 
            function()
              showSupply(1)
            end
          } )
      end
      
      collision.organizer = true 
      local organizedAll = true 
      local organizedNone = true 
      local remaining = { }
      for k, v in pairs( supplies.list ) do 
        if ( supplies.list[k] ~= supplies.collected[k] ) then 
          organizedAll = false
          remaining[k] = supplies.list[k]
        else 
           organizedNone = false 
        end
      end
      supplies.remaining = remaining
      collision.organizedAll = organizedAll
      collision.organizedNone = organizedNone

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
      transition.cancel( character )
      --collision = true
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

  -- Perfect
  instructionsTable.steps = { 2, 9, 4, 8, 2, 2 }
  instructionsTable.direction = { "down", "right", "up", "left", "up", "left" }
  instructionsTable.last = 6

  --[[instructionsTable.steps = { 2, 3, 3, 8, 2, 2 }
  instructionsTable.direction = { "down", "right", "up", "left", "up", "left" }
  instructionsTable.last = 3]]

  --[[instructionsTable.steps = { 4, 3, 4 }
  instructionsTable.direction = { "right", "up", "down" }
  instructionsTable.last = 3]]


  -- Organizador de baixo
  --[[instructionsTable.steps = { 2, 9, 4, 10, 1 }
  instructionsTable.direction = { "down", "right", "up", "left", "up", "left", "up" }
  instructionsTable.last = 5]]

  -- Organizador de cima 
  --[[instructionsTable.steps = { 1, 7, 2, 2  }
  instructionsTable.direction = { "right", "up", "left", "down"  }
  instructionsTable.last = 4]]

  -- Foi até o organizador mais de uma vez, mas pegou tudo
  --[[instructionsTable.steps = { 2, 9, 4, 8, 1, 2, 1, 1, 2 }
  instructionsTable.direction = { "down", "right", "up", "left", "up", "left", "right", "up", "left" }
  instructionsTable.last = 9]]

  --[[instructionsTable.steps = { 1, 2, 2, 2, 5, 2, 1, 5, 5, 1, 1, 1, 1, 2, 2, 9, 9, 3, 2 }
  instructionsTable.direction = { "right", "down", "right", "left", "up", "left", "down", "right", "left", "up", "left", "right", "up", "left", "down", "right", "left", "up", "left" }
  instructionsTable.last = 19]]

  --Coletou todas as peças, mas não levou todas ao organizador
  --[[instructionsTable.steps = { 1, 2, 2, 2, 5, 2, 1, 5, 5, 1, 1, 1, 1, 2, 2, 9, 9, 3, 2 }
  instructionsTable.direction = { "right", "down", "right", "left", "up", "left", "down", "right", "left", "up", "left", "right", "up", "left", "down", "right", "left", "up", "left" }
  instructionsTable.last = 17]]

  --[[instructionsTable.steps = { 1, 4, 2, 4 }
  instructionsTable.direction = { "right", "up", "right", "left" }
  instructionsTable.last = 4]]

  --[[instructionsTable.steps = { 1, 3, 2, 4 }
  instructionsTable.direction = { "right", "up", "right", "left" }
  instructionsTable.last = 4]]

  --[[instructionsTable.steps = { 2, 9, 4, 8, 2, 2, 3, 2 }
  instructionsTable.direction = { "down", "right", "up", "left", "up", "left", "right", "up" }
  instructionsTable.last = 8]]
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
      setSupplies()
      collision = { table = false, chair = false, organizer = false, organizedAll = false, organizedNone = true }
      schoolFSM.new( school, supplies , collision, instructionsTable, miniGameData, gameState, gamePanel, path )
      schoolFSM.execute()
      instructions.updateFSM = schoolFSM.updateFSM
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