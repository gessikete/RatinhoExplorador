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
	organizersLayer = restaurant:findLayer( "organizers" )
	checkedLayer = restaurant:findLayer( "check" )
	uncheckedLayer = restaurant:findLayer( "uncheck" )

	for i = 1, ingredientsLayer.numChildren do 
    ingredientsLayer[i].originalX = ingredientsLayer[i].x 
    ingredientsLayer[i].originalY = ingredientsLayer[i].y

		if ( ingredientsLayer[i].recipe == 1 ) then 
			ingredients.first[ ingredientsLayer[i].number ] = ingredientsLayer[i]
		elseif ( ingredientsLayer[i].recipe == 2 ) then 
			ingredients.second[ ingredientsLayer[i].number ] = ingredientsLayer[i]
		end
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
      local recipe = restaurantFSM.fsm.current

      print( restaurantFSM.fsm.current )

      	if ( obj1.myName == "ingredient" ) then obj = obj1 else obj = obj2 end 
      	if ( obj.recipe == 1 ) then 
      		ingredient = ingredients.first[ obj.number ]
      		list = ingredients.first
      		check = ingredients.check.first[ obj.number ]
      		uncheck = ingredients.uncheck.first[ obj.number ]
      	elseif ( obj.recipe == 2 ) then 
      		ingredient = ingredients.second[ obj.number ]
      		list = ingredients.second
      		check = ingredients.check.second[ obj.number ]
      		uncheck = ingredients.uncheck.second[ obj.number ]
      	end

        if ( recipe == "recipe" .. ingredient.recipe ) then 
      	  table.insert( ingredients.collected, ingredient )
          if ( list[#ingredients.collected] == ingredient ) then 
            check.alpha = 1
          else
            uncheck.alpha = 1
          end 
        elseif ( recipe == "recipe1" ) then 
          collision.wrongIngredient = true 
        end

      	transition.cancel( character )
      	transition.fadeOut( ingredient, { time = 400 } )

      	if ( ( obj.direction == "right" ) ) then 
          		transition.to( character, { time = 0, x = character.x + .09 * tilesSize } )
    
        elseif ( ( obj.direction == "left" ) ) then 
          		transition.to( character, { time = 0, x = character.x - .16 * tilesSize } )

        elseif ( ( obj.direction == "up" ) ) then 
          		transition.to( character, { time = 0, y = character.y - .1 * tilesSize } )
        elseif ( ( obj.direction == "down" ) ) then 
          		transition.to( character, { time = 0, y = character.y + .07 * tilesSize } )
        end

    elseif ( ( ( obj1.myName == "cook" ) and ( obj2.isCharacter ) ) or ( ( obj2.myName == "cook" ) and ( obj1.isCharacter ) ) or
           ( ( obj1.myName == "stove" ) and ( obj2.isCharacter ) ) or ( ( obj2.myName == "stove" ) and ( obj1.isCharacter ) ) ) then

    	if ( ( obj1.myName == "cook" ) or ( obj1.myName == "stove" ) ) then obj = obj1 else obj = obj2 end 
      	local list = { }
        local recipe = restaurantFSM.fsm.current
      
      	transition.cancel( character )
        gamePanel.stopExecutionListeners()
        --instructionsTable:reset()

        if ( ( obj.direction == "right" ) ) then 
              transition.to( character, { time = 0, x = character.x + .09 * tilesSize } )
    
        elseif ( ( obj.direction == "left" ) ) then 
              transition.to( character, { time = 0, x = character.x - .16 * tilesSize } )

        elseif ( ( obj.direction == "up" ) ) then 
              transition.to( character, { time = 0, y = character.y - .1 * tilesSize } )
        elseif ( ( obj.direction == "down" ) ) then 
              transition.to( character, { time = 0, y = character.y + .07 * tilesSize } )
        end

      	if ( collision ) then 
	        if ( instructionsTable.last < instructionsTable.executing ) then 
	          	restaurantFSM.waitFeedback = true 
	        end

	        if ( collision.bench == false ) then 
	          		for k, v in pairs( ingredients.collected ) do
	          	  		table.insert( list, v )
	          		end
        	else 
	          		for k, v in pairs( ingredients.remaining ) do
	          	  		if ( v == ingredients.collected[k] ) then
	          	  	  		table.insert( list, v )
	          	  		end
          			end
          		end
        end

        local function showIngredient( i )
        	local number

          	if ( i > #list ) then 
          	  	for j = 1, #list - 1  do 
          	  	    transition.fadeOut( list[j], { time = 800 } )
          	  	end
          	  	transition.fadeOut( list[#list], { time = 800, onComplete = restaurantFSM.updateFSM } )
          	  	--instructionsTable:reset()
                --===================================
                --[[if ( recipe == "recipe1" ) then
    		        	 instructionsTable:reset()
                   instructionsTable.steps = { 5, 2, 1, 8, 3, 2, 1, 6, 1, 2, 1, 3, 3, 3 } 
                   instructionsTable.direction = { "right", "up", "down", "left", "up", "left", "up", "right", "up", "left", "up", "left", "down","right" }
                   instructionsTable.last = 14
                elseif ( recipe == "recipe2" ) then 
                    instructionsTable:reset()
                   instructionsTable.steps = { 2, 3, 2, 1, 2, 1, 3, 1, 1 } 
                   instructionsTable.direction = { "left", "up", "right", "down", "right", "down", "right", "down", "right" }
                   instructionsTable.last = 9
  				      end]]
                --===================================
          	  	return 
          	end 
 
          	if ( recipe == "recipe1" ) then 
          		number = 2
         	  elseif ( recipe == "recipe2" ) then 
         		  number = 1
         	  end 

          	list[i].x = organizers[ number ].x 
          	list[i].y = organizers[ number ].y
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
        collision.obj = obj 
        local collectedAll = true 
        local collectedNone = true 
        local remaining = { }
        local ingredientsList
        local inOrder = true 

        print( "RECIPE: " .. recipe )
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

    -- Colisão entre o personagem e os sensores dos tiles do caminho
    elseif ( ( obj1.isCharacter ) and ( obj2.isPath ) ) then
      character.stepping.x = obj2.x 
      character.stepping.y = obj2.y 
      character.stepping.point = "point"
      path:showTile( obj2.myName )

    elseif ( ( obj2.isCharacter ) and ( obj1.isPath ) ) then 
      character.stepping.x = obj1.x 
      character.stepping.y = obj1.y 
      character.stepping.point = "point"
      path:showTile( obj1.myName )

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

local function destroyScene()
  gamePanel:destroy()

  instructions:destroyInstructionsTable()

  restaurant:removeSelf()
  restaurant = nil 

  if ( ( restaurantFSM.fsm.messageBubble ) and ( restaurantFSM.fsm.messageBubble.text ) ) then 
    local text = restaurantFSM.fsm.messageBubble.text
    text:removeSelf()
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

  	--miniGameData.isComplete = true 
  	--miniGameData.onRepeat = false 

	if ( miniGameData.onRepeat == true ) then
	    miniGameData.isComplete = false 
	    originalMiniGameData = miniGameData
	end

  	--setObstacles()
  	path:hidePath()

  	recipe = 1

    --[[instructionsTable.steps = { 3, 1, 2, 1, 2, 1, 2, 1, 2, 1, 3, 1, 1, 2, 4   }
    instructionsTable.direction = { "up", "right", "up", "right", "left", "up", "left", "up", "left", "up", "left", "down", "left", "down", "right"  }
    instructionsTable.last = 15]]

    --[[instructionsTable.steps = { 1, 1 }
    instructionsTable.direction = { "up", "left" }
    instructionsTable.last = 2]]

  	--[[instructionsTable.steps = { 1, 1, 2, 1, 4, 1, 2, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 1, 2, 2 }
  	instructionsTable.direction = { "up", "right", "up", "left", "up", "right", "down", "left", "down","left", "up", "left", "down", "left", "up", "left", "down", "left", "up", "left", "down", "left" }
  	instructionsTable.last = 22]]

    --[[instructionsTable.steps = { 7, 4, 2 } 
    instructionsTable.direction = { "left", "up", "left" }
    instructionsTable.last = 3]]

  	-- Primeira receita
  	--[[instructionsTable.steps = { 5, 1, 9, 2, 1, 1, 4, 3, 1 } 
  	instructionsTable.direction = { "up", "right", "left", "right", "up", "left", "down", "right", "up" }
  	instructionsTable.last = 9]]

    -- Primeira receita (sem chegar no organizador + item incorreto)
    --[[instructionsTable.steps = { 5, 1, 9, 2, 1, 1, 1, 2 } 
    instructionsTable.direction = { "up", "right", "left", "right", "up", "left", "down", "left" }
    instructionsTable.last = 8]]

    -- Primeira receita (chegando no organizador + item incorreto)
    --[[instructionsTable.steps = { 5, 1, 9, 2, 1, 1, 1, 2, 2, 4 } 
    instructionsTable.direction = { "up", "right", "left", "right", "up", "left", "down", "left", "down", "right" }
    instructionsTable.last = 10]]

    --[[instructionsTable.steps = { 5, 1, 9, 2, 1, 3, 4 } 
    instructionsTable.direction = { "up", "right", "left", "right", "left", "down", "right" }
    instructionsTable.last = 7]]

  	-- + Segunda receita
  	--[[instructionsTable.steps = { 5, 1, 9, 2, 1, 1, 3, 2, 1, 6, 2, 1, 8, 3, 2, 1, 6, 1, 2, 1  } 
  	instructionsTable.direction = { "up", "right", "left", "right", "up", "left", "down", "right", "down", "right", "up", "down", "left", "up", "left", "up", "left", "up" }
  	instructionsTable.last = 20]]

  	-- + Segunda receita
  	--[[instructionsTable.steps = { 5, 1, 9, 2, 1, 1, 4, 3, 0, 5, 2, 1, 8, 3, 3, 1, 6, 1, 2, 1, 3, 3, 3 } 
  	instructionsTable.direction = { "up", "right", "left", "right", "up", "left", "down", "right", "up", "right", "up", "down", "left", "up", "left", "up", "right", "up", "left", "up", "left", "down", "right" }
  	instructionsTable.last = 23]]

  	--[[instructionsTable.steps = { 5, 1, 6, 1, 3, 3, 4 } 
  	instructionsTable.direction = { "up", "right", "left", "up", "left", "down", "right", "up" }
  	instructionsTable.last = 7]]
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
      if ( miniGameData.previousStars < 6 )  then 
        brother.x, brother.y = brotherPosition.x, brotherPosition.y
        brother.xScale = 1
        brother.alpha = 1
      end

      setIngredients()
      --gamePanel.tiled.alpha = 0
      character.alpha = 1 --TIRAR
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
		    collision = { bench = false, otherObjects = false, organizer = false, collectedAll = false, collectedNone = true, inOrder = true, wrongIngredient = false }
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
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen

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
