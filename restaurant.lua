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

local ingredients = { first = { }, second = { }, third ={ }, collected = { }, remaining = { }, check = { first = { }, second = { }, third ={ } }, uncheck = { first = { }, second = { }, third ={ } } }

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
		if ( ingredientsLayer[i].recipe == 1 ) then 
			ingredients.first[ ingredientsLayer[i].number ] = ingredientsLayer[i]
		elseif ( ingredientsLayer[i].recipe == 2 ) then 
			ingredients.second[ ingredientsLayer[i].number ] = ingredientsLayer[i]
		elseif ( ingredientsLayer[i].recipe == 3 ) then 
			ingredients.third[ ingredientsLayer[i].number ] = ingredientsLayer[i]
		end
	end

	for i = 1, checkedLayer.numChildren do 
		if ( checkedLayer[i].recipe == 1 ) then 
			ingredients.check.first[ checkedLayer[i].number ] = checkedLayer[i]
		elseif ( checkedLayer[i].recipe == 2 ) then 
			ingredients.check.second[ checkedLayer[i].number ] = checkedLayer[i]
		elseif ( checkedLayer[i].recipe == 3 ) then 
			ingredients.check.third[ checkedLayer[i].number ] = checkedLayer[i]
		end
	end

	for i = 1, uncheckedLayer.numChildren do 
		if ( uncheckedLayer[i].recipe == 1 ) then 
			ingredients.uncheck.first[ uncheckedLayer[i].number ] = uncheckedLayer[i]
		elseif ( uncheckedLayer[i].recipe == 2 ) then 
			ingredients.uncheck.second[ uncheckedLayer[i].number ] = uncheckedLayer[i]
		elseif ( uncheckedLayer[i].recipe == 3 ) then 
			ingredients.uncheck.third[ uncheckedLayer[i].number ] = uncheckedLayer[i]
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
    if ( ( ( obj1.myName == "character" ) and ( obj2.myName == "rope" ) ) or ( ( obj2.myName == "character" ) and ( obj1.myName == "rope" ) ) ) then 
    -- Volta para o mapa quando o personagem chega na saída/entrada da escola
    elseif ( ( ( obj1.myName == "exit" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "exit" ) ) ) then 
      if ( miniGameData.isComplete == true ) then
        transition.cancel( character )
        character.stepping.point = "exit"
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 1000, sceneTransition.gotoMap )
      end
    elseif ( ( ( obj1.myName == "entrance" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "entrance" ) ) ) then 
      if ( miniGameData.isComplete == true ) then
        transition.cancel( character )
        character.stepping.point = "entrance"
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 1000, sceneTransition.gotoMap )
      end

    --elseif ( ( miniGameData.isComplete == false ) and ( ( obj1.isOrganizer ) or ( obj2.isOrganizer ) ) ) then
      --[[local obj 
      if ( obj1.isOrganizer ) then obj = obj1 else obj = obj2 end 
      local list = { }
      
      transition.cancel( character )

      if ( collision ) then 
        if ( instructionsTable.last < instructionsTable.executing ) then 
          	--schoolFSM.waitFeedback = true 
        end

        if ( collision.bench == false ) then 
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

        local function showIngredients( i )
          	if ( i > #list ) then 
          	  	for j = 1, #list - 1  do 
          	  	    transition.fadeOut( list[j], { time = 800 } )
          	  	end
          	  	transition.fadeOut( list[#list], { time = 800, onComplete = schoolFSM.updateFSM } )
          	  	return 
          	end  
          	list[i].x = benchPositions[obj.number].x 
          	list[i].y = benchPositions[obj.number].y
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
          	  	    --showSupply(1)
          	  	  end
          	  	} )
        
        if ( ( obj.direction == "left" ) ) then 
          	transition.to( character, { time = 0, x = character.x - .25 * tilesSize, 
          	  	onComplete = 
          	  	  function()
          	  	    --showSupply(1)
          	  	  end
          	  	} )

        elseif ( ( obj.direction == "down" ) ) then 
          	transition.to( character, { time = 0, y = character.y + .06 * tilesSize, 
          	  	onComplete = 
          	  	  function()
          	  	    --showSupply(1)
          	  	  end
          	  	} )
        elseif ( ( obj.direction == "up" ) ) then 
          	transition.to( character, { time = 0, y = character.y - .35 * tilesSize, 
          	  	onComplete = 
          	  	  function()
          	  	    --showSupply(1)
          	  	  end
          	  	} )
        end
        
        collision.bench = true 
        collision.obj = obj 
        local collectedAll = true 
        local collectedNone = true 
        local remaining = { }
        for k, v in pairs( supplies.list ) do 
          	if ( supplies.list[k] ~= supplies.collected[k] ) then 
          	  	collectedAll = false
          	  	remaining[k] = supplies.list[k]
          	else 
          	  	 collectedNone = false 
          	end
        end
        supplies.remaining = remaining
        collision.collectedAll = collectedAll
        collision.collectedNone = collectedNone
      end]]
    elseif ( ( obj1.myName == "ingredient" ) or ( obj2.myName == "ingredient" ) ) then 
    	local obj, ingredient, list 

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
      	elseif ( obj.recipe == 3 ) then 
      		ingredient = ingredients.third[ obj.number ]
      		list = ingredients.third
      		check = ingredients.check.third[ obj.number ]
      		uncheck = ingredients.uncheck.third[ obj.number ]
      	end

      	print( obj.direction )

      	table.insert( ingredients.collected, ingredient )
      	if ( list[#ingredients.collected] == ingredient ) then 
      		check.alpha = 1
      	else
      		uncheck.alpha = 1
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

    elseif ( ( ( obj1.myName == "cook" ) and ( obj2.myName == "character" ) ) or ( ( obj2.myName == "cook" ) and ( obj1.myName == "character" ) ) ) then
    	transition.cancel( character )

    	if ( obj1.myName == "cook" ) then obj = obj1 else obj = obj2 end 
      	local list = { }
      
      	transition.cancel( character )

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
          	  	if ( recipe == 1 ) then 
    		        	 instructionsTable:reset()
    		           instructionsTable.steps = { 1, 6, 2, 1, 8, 3, 3, 1, 6, 1, 2, 1, 3, 3, 3 } 
    		  			   instructionsTable.direction = { "down", "right", "up", "down", "left", "up", "left", "up", "right", "up", "left", "up", "left", "down", "right" }
    		  			   instructionsTable.last = 15
    		  			   recipe = 2
                elseif ( recipe == 2 ) then 
                    instructionsTable:reset()
                   instructionsTable.steps = { 2, 3, 2, 1, 2, 1, 3, 1, 1 } 
                   instructionsTable.direction = { "left", "up", "right", "down", "right", "down", "right", "down", "right" }
                   instructionsTable.last = 9
                   recipe = 3
  				      end
          	  	return 
          	end 
 
          	if ( recipe == 1 ) then 
          		number = 2
         	  elseif ( recipe == 2 ) then 
         		  number = 1
         	  else
         		  number = 3 
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
        
        collision.cook = true 
        collision.obj = obj 
        local collectedAll = true 
        local collectedNone = true 
        local remaining = { }
        local ingredientsList
        local inOrder = true 

        if ( recipe == 1 ) then 
        	ingredientsList = ingredients.first 
       	elseif ( recipe == 2 ) then 
       		ingredientsList = ingredients.second
       	else 
       		ingredientsList = ingredients.third
       	end

        for k, v in pairs( ingredientsList ) do 
        	if ( ingredientsList[k] ~=  ingredients.collected[k] ) then inOrder = false end 
	        if ( ingredientsList[k] ~= ingredients.collected[ ingredients.collected[k].number ] ) then 
	          	  	collectedAll = false
	          	  	remaining[k] = ingredientsList[k]
	        else 
	          	  	 collectedNone = false 
	        end
        end
        ingredients.remaining = remaining
        collision.collectedAll = collectedAll
        collision.collectedNone = collectedNone
        collision.inOrder = inOrder

        print( "inOrder: " .. tostring(collision.inOrder) .. "; all: " .. tostring(collision.collectedAll) .. "; none: " .. tostring(collision.collectedNone) )

    -- Colisão entre o personagem e os sensores dos tiles do caminho
    elseif ( ( obj1.myName == "character" ) and ( obj2.isPath ) ) then
      character.stepping.x = obj2.x 
      character.stepping.y = obj2.y 
      character.stepping.point = "point"
      path:showTile( obj2.myName )

    elseif ( ( obj2.myName == "character" ) and ( obj1.isPath ) ) then 
      character.stepping.x = obj1.x 
      character.stepping.y = obj1.y 
      character.stepping.point = "point"
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
-- Cenas
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )
	local sceneGroup = self.view
	
	persistence.setCurrentFileName( "ana" )

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
  	--[[instructionsTable.steps = { 1, 1, 2, 1, 4, 1, 2, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 1, 2, 2 }
  	instructionsTable.direction = { "up", "right", "up", "left", "up", "right", "down", "left", "down","left", "up", "left", "down", "left", "up", "left", "down", "left", "up", "left", "down", "left" }
  	instructionsTable.last = 22]]

  	-- Primeira receita
  	--[[instructionsTable.steps = { 5, 1, 9, 2, 1, 1, 4, 3, 1 } 
  	instructionsTable.direction = { "up", "right", "left", "right", "up", "left", "down", "right", "up" }
  	instructionsTable.last = 9]]

  	-- + Segunda receita
  	--[[instructionsTable.steps = { 5, 1, 9, 2, 1, 1, 3, 2, 1, 6, 2, 1, 8, 3, 2, 1, 6, 1, 2, 1  } 
  	instructionsTable.direction = { "up", "right", "left", "right", "up", "left", "down", "right", "down", "right", "up", "down", "left", "up", "left", "up", "left", "up" }
  	instructionsTable.last = 20]]

  	-- + Segunda receita
  	--[[instructionsTable.steps = { 5, 1, 9, 2, 1, 1, 4, 3, 0, 5, 2, 1, 8, 3, 3, 1, 6, 1, 2, 1, 3, 3, 3 } 
  	instructionsTable.direction = { "up", "right", "left", "right", "up", "left", "down", "right", "up", "right", "up", "down", "left", "up", "left", "up", "right", "up", "left", "up", "left", "down", "right" }
  	instructionsTable.last = 23]]

  	instructionsTable.steps = { 5, 1, 6, 1, 3, 3, 4 } 
  	instructionsTable.direction = { "up", "right", "left", "up", "left", "down", "right", "up" }
  	instructionsTable.last = 7
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase
	cook = restaurant:findObject( "cook" )

	if ( phase == "will" ) then
		if ( miniGameData.isComplete == false ) then
      		setIngredients()
      		--gamePanel.tiled.alpha = 0
      		character.alpha = 1 --TIRAR
      		local brother = restaurant:findObject( "brother" )
      	if ( ( miniGameData.previousStars == 1 ) or ( miniGameData.previousStars == 2 ) )  then 
        	brother.alpha = 1
      	end
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
	    	restaurant:findObject( "recipe1" ).alpha = 1 
		    collision = { bench = false, otherObjects = false, cook = false, collectedAll = false, collectedNone = true, inOrder = true }
		    restaurantFSM.new( restaurant, ingredients, listeners, collision, instructionsTable, miniGameData, gameState, gamePanel, path )
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
