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

local restaurantFSM = require "fsm.miniGames.restaurantFSM"

local listenersModule = require "listeners"

physics.start()
physics.setGravity( 0, 0 )
local listeners = listenersModule:new()
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local restaurant

local character

local cook 

local tilesSize = 32

local supplies

local ingredients = { first = { }, second = { }, collected = { }, remaining = { }, check = { first = { }, second = { } }, uncheck = { first = { }, second = { } } }

local organizers = { }

local collision

local miniGameData

local originalMiniGameData


local function setIngredients()
	local ingredientsLayer
	--local ingredientsSensorsLayer

	ingredientsLayer = restaurant:findLayer( "ingredients" )
  ingredientsSensorsLayer = restaurant:findLayer( "ingredients sensors" )
	organizersLayer = restaurant:findLayer( "organizers" )
	checkedLayer = restaurant:findLayer( "check" )
	uncheckedLayer = restaurant:findLayer( "uncheck" )

	for i = 1, ingredientsLayer.numChildren do 
    ingredientsLayer[i].originalX = ingredientsLayer[i].x 
    ingredientsLayer[i].originalY = ingredientsLayer[i].y
    ingredientsLayer[i].alpha = 1

		if ( ingredientsLayer[i].recipe == 1 ) then 
			ingredients.first[ ingredientsLayer[i].number ] = ingredientsLayer[i]
		elseif ( ingredientsLayer[i].recipe == 2 ) then 
			ingredients.second[ ingredientsLayer[i].number ] = ingredientsLayer[i]
		end
	end

  for i = 1,  ingredientsSensorsLayer.numChildren do
    physics.addBody( ingredientsSensorsLayer[i], "static", { isSensor = true } )
  end

	for i = 1, checkedLayer.numChildren do 
		if ( checkedLayer[i].recipe == 1 ) then 
			ingredients.check.first[ checkedLayer[i].number ] = checkedLayer[i]
		elseif ( checkedLayer[i].recipe == 2 ) then 
			ingredients.check.second[ checkedLayer[i].number ] = checkedLayer[i]
		end
	end

	for i = 1, uncheckedLayer.numChildren do 
		if ( uncheckedLayer[i].recipe == 1 ) then 
			ingredients.uncheck.first[ uncheckedLayer[i].number ] = uncheckedLayer[i]
		elseif ( uncheckedLayer[i].recipe == 2 ) then 
			ingredients.uncheck.second[ uncheckedLayer[i].number ] = uncheckedLayer[i]
		end
	end

	for i = 1, organizersLayer.numChildren do 
		organizers[ organizersLayer[i].myName ] = organizersLayer[i]
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
    elseif ( ( obj1.myName == "ingredient" ) or ( obj2.myName == "ingredient" ) ) then 
    	local obj, ingredient, list 
      if ( restaurantFSM ) then 
      local recipe = restaurantFSM.fsm.current

    	if ( obj1.myName == "ingredient" ) then obj = obj1 else obj = obj2 end 
    	if ( obj.recipe == 1 ) then 
    		ingredient = ingredients.first[ obj.number ]
    		list = ingredients.first
    		check = ingredients.check.first[ obj.number ]
    		uncheck = ingredients.uncheck.first
    	elseif ( obj.recipe == 2 ) then 
    		ingredient = ingredients.second[ obj.number ]
    		list = ingredients.second
    		check = ingredients.check.second[ obj.number ]
    		uncheck = ingredients.uncheck.second
    	end

      if ( recipe == "recipe" .. ingredient.recipe ) then 
        local alreadyCollected = false

        for i = 1, #ingredients.collected do 
          if ( ingredients.collected[i] == ingredient ) then
            alreadyCollected = true 
          end
        end 

        if ( alreadyCollected == false ) then 
      	  table.insert( ingredients.collected, ingredient )
          if ( list[ #ingredients.collected ] == ingredient ) then 
            check.alpha = 1
          else
            uncheck[ #ingredients.collected ].alpha = 1
            uncheck[ obj.number ].alpha = 1
          end 
        end
      elseif ( recipe == "recipe1" ) then 
        collision.wrongIngredient = true 
        for i = 1, #ingredients.uncheck.first do
          if ( ( ingredients.check.first[i].alpha == 0 ) and ( ingredients.uncheck.first[i].alpha == 0 ) ) then 
            ingredients.uncheck.first[i].alpha = 1
            break
          end
        end
      end

    	transition.fadeOut( ingredient, { time = 400 } )
      end
    elseif ( ( ( obj1.myName == "cook" ) and ( obj2.isCharacter ) ) or ( ( obj2.myName == "cook" ) and ( obj1.isCharacter ) ) ) then
    	if ( obj1.myName == "cook" ) then obj = obj1 else obj = obj2 end 
      
      transition.cancel( character )
      if ( ( obj.direction == "right" ) ) then 
        transition.to( character, { time = 0, x = character.x + .09 * tilesSize } )
        cook.xScale = 1
        cook.characterBlocking = true 
  
      elseif ( ( obj.direction == "left" ) ) then 
        transition.to( character, { time = 0, x = character.x - .16 * tilesSize } )
        cook.xScale = -1
        cook.characterBlocking = false 

      elseif ( ( obj.direction == "up" ) ) then 
        transition.to( character, { time = 0, y = character.y - .1 * tilesSize } )
        cook.characterBlocking = false 

      elseif ( ( obj.direction == "down" ) ) then 
        transition.to( character, { time = 0, y = character.y + .07 * tilesSize } )
        cook.characterBlocking = false 
      end

    	if ( collision ) then 
        local list = { }
        local recipe = restaurantFSM.fsm.current
    
        if ( ( ( recipe == "recipe1" ) ) or ( ( recipe == "recipe2" ) ) ) then
          gamePanel.stopExecutionListeners()
          restaurantFSM.waitFeedback = true 

      		for k, v in pairs( ingredients.collected ) do
            local cookLayer = restaurant:findLayer( "cook" )
            cookLayer:insert( v )
      	  	table.insert( list, v )
      		end

      		for k, v in pairs( ingredients.remaining ) do
    	  		if ( v == ingredients.collected[k] ) then
    	  	  		table.insert( list, v )
    	  		end
    			end

          local function showIngredient( i )
          	local number

          	if ( i > #list ) then 
        	  	for j = 1, #list - 1  do 
        	  	    transition.fadeOut( list[j], { time = 800 } )
        	  	end
        	  	transition.fadeOut( list[#list], { time = 800, 
              onComplete = 
                function()
                  if ( instructionsTable.last < instructionsTable.executing ) then 
                    restaurantFSM.updateFSM() 
                  else 
                    restaurantFSM.waitFeedback = false 
                  end
                end
              } )
        	  	return 
        	  end 

          	list[i].x = organizers[1].x 
          	list[i].y = organizers[1].y
          	list[i]:toFront()
          	transition.fadeIn( list[i], { time = 800, 
          	  	onComplete = 
          	  	  function()
          	  	    showIngredient( i + 1 )
          	  	  end 
          	} )
          end

          showIngredient(1)
          
          collision.organizer = true 
          local collectedAll = true 
          local collectedNone = true 
          local remaining = { }
          local ingredientsList
          local inOrder = true 

          if ( recipe == "recipe1" ) then 
          	ingredientsList = ingredients.first 
         	elseif ( recipe == "recipe2" ) then 
         		ingredientsList = ingredients.second
         	end

          for k, v in pairs( ingredientsList ) do 
            local found = false 
          	if ( ingredientsList[k] ~=  ingredients.collected[k] ) then inOrder = false end 
  	        for r, s in pairs( ingredients.collected ) do
              if v == s then found = true end 
            end

            if ( found == true ) then 
              collectedNone = false 
            else 
              remaining[k] = ingredientsList[k]
              collectedAll = false 
            end 
          end
          ingredients.remaining = remaining
          collision.collectedAll = collectedAll
          collision.collectedNone = collectedNone
          collision.inOrder = inOrder
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

      if ( collision ) then 
        collision.otherObjects = true 
      end
    end
  end 
  return true 
end

local function destroyScene()
  gamePanel:destroy()

  instructions:destroyInstructionsTable()
  instructions = nil 

  restaurant:removeSelf()
  restaurant = nil 

  if ( ( restaurantFSM ) and ( restaurantFSM.destroy ) ) then 
    restaurantFSM.destroy()
  end
end
-- -----------------------------------------------------------------------------------
-- Cenas
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )
	local sceneGroup = self.view
	
	--persistence.setCurrentFileName( "ana" )

  restaurant, character, gamePanel, gameState, path, instructions, instructionsTable, miniGameData = gameScene:set( "restaurant" )


  sceneGroup:insert( restaurant )
  sceneGroup:insert( gamePanel.tiled )

  	--miniGameData.isComplete = false 
  	--miniGameData.onRepeat = false 

	if ( miniGameData.onRepeat == true ) then
	    miniGameData.isComplete = false 
	    originalMiniGameData = miniGameData
	end

	path:hidePath()

  --[[gamePanel.createInstruction( "left", 8 )
  gamePanel.createInstruction( "up", 5 )
  gamePanel.createInstruction( "right", 7 )
  gamePanel.createInstruction( "down", 3 )
  gamePanel.createInstruction( "left", 4 )]]

  --[[gamePanel.createInstruction( "left", 10 )
  gamePanel.createInstruction( "up", 5 )
  gamePanel.createInstruction( "right", 8 )
  gamePanel.createInstruction( "down", 3 )
  gamePanel.createInstruction( "left", 4 )]]
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase
	cook = restaurant:findObject( "cook" )

	if ( phase == "will" ) then
		if ( miniGameData.isComplete == false ) then
      local brother, brotherPosition

      if ( character == restaurant:findObject( "ada") ) then 
        brother = restaurant:findObject( "turing")
      else
        brother = restaurant:findObject( "ada") 
      end

      brotherPosition = restaurant:findObject( "brother" )
      if ( miniGameData.previousStars < 3 )  then 
        brother.x, brother.y = brotherPosition.x, brotherPosition.y - 10
        brother.xScale = 1
        brother.alpha = 1
      end

      setIngredients()
      --gamePanel.tiled.alpha = 0
      --character.alpha = 1 --TIRAR
    else
      cook.alpha = 1
      character.alpha = 1
      gamePanel:addDirectionListeners()
      --local suppliesSensorsLayer = school:findLayer( "supplies sensors" )

      --[[for i = 1, suppliesSensorsLayer.numChildren do
        physics.removeBody( suppliesSensorsLayer[i] )
      end]]
    end
    listeners:add( Runtime, "collision", onCollision )

	elseif ( phase == "did" ) then
	    gamePanel:addButtonsListeners()
	    gamePanel:addInstructionPanelListeners()
	    if ( miniGameData.isComplete == false ) then
		    collision = { obj = false, otherObjects = false, organizer = false, collectedAll = false, collectedNone = true, inOrder = true, wrongIngredient = false }
		    restaurantFSM.new( restaurant, character, ingredients, listeners, collision, instructionsTable, miniGameData, gameState, gamePanel, path )
		    restaurantFSM.execute()
		    instructions.updateFSM = restaurantFSM.updateFSM
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
    composer.removeScene( "restaurant" )
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
