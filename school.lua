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

local listenersModule = require "listeners"

physics.start()
physics.setGravity( 0, 0 )
local listeners = listenersModule:new()

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local school 

local character

local teacher 

local tilesSize = 32

local supplies

local chairs = { }

local tables = { }

local organizerPositions = { }

local collision

local miniGameData

local originalMiniGameData

local function setSupplies()
  local suppliesLayer = school:findLayer( "supplies" )
  local suppliesSensorsLayer = school:findLayer( "supplies sensors" )

  supplies = { collected = { }, list = { }, sensors = { }, remaining = { } }

  for i = 1, suppliesLayer.numChildren do
    suppliesLayer[i].alpha = 1
    suppliesLayer[i].originalX = suppliesLayer[i].x 
    suppliesLayer[i].originalY = suppliesLayer[i].y 
    supplies.list[suppliesLayer[i].number] = suppliesLayer[i] 
    supplies.sensors[suppliesSensorsLayer[i].number] = suppliesSensorsLayer[i] 
  end

  school:findObject( "teacherSupply" ).alpha = 1
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
-- Trata dos tipos de colisão da escola
local function onCollision( event )
  phase = event.phase
  local obj1 = event.object1
  local obj2 = event.object2

  if ( event.phase == "began" ) then
    if ( ( ( obj1.myName == "exit" ) and ( obj2.isCharacter ) ) or ( ( obj1.isCharacter ) and ( obj2.myName == "exit" ) ) ) then 
      if ( miniGameData.isComplete == true ) then
        transition.cancel( character )
        character.stepping.point = "exit"
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 1000, sceneTransition.gotoMap )
      end
    elseif ( ( ( obj1.myName == "entrance" ) and ( obj2.isCharacter ) ) or ( ( obj1.isCharacter ) and ( obj2.myName == "entrance" ) ) ) then 
      if ( miniGameData.isComplete == true ) then
        transition.cancel( character )
        character.stepping.point = "entrance"
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 1000, sceneTransition.gotoMap )
      end

    elseif ( ( ( obj1.myName == "supply" ) and ( obj2.isCharacter ) ) or ( ( obj2.myName == "supply" ) and ( obj1.isCharacter ) ) ) then
      local obj
      local alreadyCollected = false 
      if ( obj1.myName == "supply" ) then obj = obj1 else obj = obj2 end

      if ( supplies.collected ) then
        for k, v in pairs( supplies.collected ) do
          if ( v == obj ) then alreadyCollected = true end 
        end 

        if ( alreadyCollected == false ) then 
          supplies.collected[ obj.number ] = supplies.list[ obj.number ]
          transition.fadeOut( supplies.list[ obj.number ], { time = 400 } )
        end
      end

    elseif ( ( ( obj1.myName == "table" ) and ( obj2.isCharacter ) ) or ( ( obj2.myName == "table" ) and ( obj1.isCharacter ) ) ) then
      local obj 
      if ( obj1.myName == "table" ) then obj = obj1 else obj = obj2 end
      if ( not tables[obj.number].isPhysics ) then
        transition.cancel( character ) 
        function closure()
          physics.addBody( tables[obj.number] )
          tables[obj.number].isPhysics = true 
        end 

        timer.performWithDelay( 100, closure )
        if ( collision ) then collision.table = true end 
      end

    elseif ( ( ( obj1.myName == "chair" ) and ( obj2.isCharacter ) ) or ( ( obj2.myName == "chair" ) and ( obj1.isCharacter ) ) ) then
      local obj
      if ( obj1.myName == "chair" ) then obj = obj1 else obj = obj2 end 
      if ( not chairs[obj.number].isPhysics ) then 
        transition.cancel( character )
        function closure()
          physics.addBody( chairs[obj.number] )
          chairs[obj.number].isPhysics = true 
        end 

        timer.performWithDelay( 100, closure )

        if ( collision ) then collision.chair = true end
      end
    elseif ( ( ( obj1.myName == "organizer" ) or ( obj2.myName == "organizer" ) ) ) then
      local obj 
      if ( obj1.myName == "organizer" ) then obj = obj1 else obj = obj2 end 
      local list = { }
      
      transition.cancel( character )
    
      if ( collision ) then 
        schoolFSM.waitFeedback = true 

        if ( collision.organizer == false ) then 
          for k, v in pairs( supplies.collected ) do
            v.x = organizerPositions[obj.number].x 
            v.y = organizerPositions[obj.number].y
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
            for j = 1, #list - 1  do 
                transition.fadeOut( list[j], { time = 800 } )
            end
            transition.fadeOut( list[#list], { time = 800, 
              onComplete = 
                function()
                  if ( instructionsTable.last < instructionsTable.executing ) then 
                    schoolFSM.updateFSM() 
                  else 
                    schoolFSM.waitFeedback = false 
                  end
                end
              } )
            return 
          end  
          list[i]:toFront()
          transition.fadeIn( list[i], { time = 800, 
            onComplete = 
              function()
                showSupply( i + 1 )
              end 
          } )
        end

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
        collision.obj = obj 
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
      else
        if ( ( obj.direction == "right" ) ) then 
          transition.to( character, { time = 0, x = character.x + .25 * tilesSize } )
        elseif ( ( obj.direction == "down" ) ) then 
          transition.to( character, { time = 0, y = character.y + .06 * tilesSize } )
        else
          transition.to( character, { time = 0, y = character.y - .35 * tilesSize } )
        end
      end
    -- Colisão entre o personagem e os sensores dos tiles do caminho
    elseif ( ( ( obj1.isCharacter ) and ( obj2.isPath ) ) or ( ( obj2.isCharacter ) and ( obj1.isPath ) ) ) then
      local obj 
      if ( obj1.isPath ) then obj = obj1 else obj = obj2 end

      character.stepping.x = obj.x 
      character.stepping.y = obj.y 
      character.stepping.point = "point"
      path:showTile( obj.myName )

    elseif ( ( ( obj1.isCollision ) and ( obj2.isCharacter ) ) or ( ( obj1.isCharacter ) and ( obj2.isCollision ) ) ) then 
      local obj
      if ( obj1.isCollision ) then obj = obj1 else obj = obj2 end 
      transition.cancel( character )
      if ( ( obj.direction == "right" ) ) then 
        transition.to( character, { time = 0, x = character.x + .20 * tilesSize } )
      elseif ( ( obj.direction == "left" ) ) then 
        transition.to( character, { time = 0, x = character.x - .20 * tilesSize } )
      elseif ( ( obj.direction == "up" ) ) then 
        transition.to( character, { time = 0, y = character.y - .23 * tilesSize } )
      elseif ( ( obj.direction == "down" ) ) then 
        transition.to( character, { time = 0, y = character.y + .22 * tilesSize } )
      end
    end
  end 
  return true 
end

-- -----------------------------------------------------------------------------------
-- Remoções para limpar a tela
-- -----------------------------------------------------------------------------------
local function destroyScene()
  gamePanel:destroy()

  instructions:destroyInstructionsTable()

  school:removeSelf()
  school = nil 

  if ( ( schoolFSM ) and ( schoolFSM.destroy ) ) then 
    schoolFSM.destroy()
  end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

  local sceneGroup = self.view
  
  --persistence.setCurrentFileName( "ana" )

  school, character, gamePanel, gameState, path, instructions, instructionsTable, miniGameData = gameScene:set( "school" )

  sceneGroup:insert( school )
  sceneGroup:insert( gamePanel.tiled )

  --miniGameData.isComplete = false 
  --miniGameData.onRepeat = false 

  if ( miniGameData.onRepeat == true ) then
    miniGameData.isComplete = false 
    originalMiniGameData = miniGameData
  end

  setObstacles()
  path:hidePath()

end


-- show()
function scene:show( event )
  local sceneGroup = self.view
  local phase = event.phase

  if ( phase == "will" ) then
    if ( miniGameData.isComplete == false ) then
      local brother, brotherPosition

      if ( character == school:findObject( "ada") ) then 
        brother = school:findObject( "turing")
      else
        brother = school:findObject( "ada") 
      end

      brotherPosition = school:findObject( "brother" )
      if ( miniGameData.previousStars < 3 )  then 
        brother.x, brother.y = brotherPosition.x, brotherPosition.y
        brother.xScale = -1
        brother.alpha = 1
      end

      setSupplies()
      gamePanel.tiled.alpha = 0
    else
      teacher = school:findObject( "teacher" )
      teacher.alpha = 1
      character.alpha = 1
      gamePanel:addDirectionListeners()
      local suppliesSensorsLayer = school:findLayer( "supplies sensors" )

      for i = 1, suppliesSensorsLayer.numChildren do
        physics.removeBody( suppliesSensorsLayer[i] )
      end
    end
    listeners:add( Runtime, "collision", onCollision )

  elseif ( phase == "did" ) then
    gamePanel:addButtonsListeners()
    gamePanel:addInstructionPanelListeners()
    if ( miniGameData.isComplete == false ) then
      collision = { table = false, chair = false, organizer = false, organizedAll = false, organizedNone = true }
      schoolFSM.new( school, character, supplies , listeners, collision, instructionsTable, miniGameData, gameState, gamePanel, path )
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
    if ( miniGameData.onRepeat == true ) then
      miniGameData.onRepeat = false

      if ( miniGameData.isComplete == false ) then 
        miniGameData = originalMiniGameData
      end
    end

    gameState:save( miniGameData )
    destroyScene()
    listeners:destroy()
  elseif ( phase == "did" ) then
    composer.removeScene( "school" )
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
