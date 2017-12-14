local composer = require( "composer" )

local perspective = require("com.perspective.perspective")

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

local listenersModule = require "listeners"

physics.start()
physics.setGravity( 0, 0 )
local listeners = listenersModule:new()
-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local camera = perspective.createView()

local map

local character

-- tamanho dos tiles usados no tiled
local tilesSize = 32

local messageBubble

local message = 
{
  teacher = 
  { "Olá! Que bom que sua mãe",
  "deixou que você viesse me ajudar.",
  "Os alunos fizeram uma bagunça",
  "na escola. Venha ver." },

  cook = {
    "Ah, que bom que você veio me", 
    "ajudar!",
    "Preciso fazer uma receita de",
    "macarrão, mas estou tendo",
    "dificuldades",
    "Vamos lá?" 
  },

  mom = {
    "Ah, que bom que você chegou!",
    "Vamos entrar em casa para",
    "ver a surpresa?",
  }

}

local function jumpingLoop( nextLevelCharacter, bubble, msg )
  local function closure()
    jumpingLoop( nextLevelCharacter, bubble, msg )
  end

  if ( nextLevelCharacter.cancelLoop == false ) then
    transition.to(  nextLevelCharacter, { time = 200, y = nextLevelCharacter.originalY - 8, 
      onComplete = 
      function()
        transition.to(  nextLevelCharacter, { time = 200, y = nextLevelCharacter.originalY, onComplete = closure } )
      end

      } )
  end
end

function setNextLevelCharacter()
  gameFileData.house.isComplete = true

  if ( ( gameFileData.house.isComplete == true ) and ( gameFileData.school.isComplete == false ) ) then 
    gamePanel:updateBikeMaxCount( 3 )
    teacher.alpha = 1
    teacher.originalY = teacher.y 
    physics.addBody( map:findObject( "teacher sensor" ), { isSensor = true, bodyType = "static" } )

    jumpingLoop( teacher, map:findObject( "teacherBubble" ), message.teacher )
  elseif ( ( gameFileData.school.isComplete == true ) and ( gameFileData.restaurant.isComplete == false ) ) then 
    gamePanel:updateBikeMaxCount( 1 )
    cook.alpha = 1
    cook.originalY = cook.y 
    physics.addBody( map:findObject( "cook sensor" ), { isSensor = true, bodyType = "static" } )

    jumpingLoop( cook, map:findObject( "cookBubble" ), message.cook )
  elseif ( ( gameFileData.restaurant.isComplete == true ) and ( gameFileData.house.shownCompletion == false ) ) then
    local characterLayer = map:findLayer( "characters" ) 
    characterLayer:insert( character )
    gamePanel:updateBikeMaxCount( 2 )
    mom.alpha = 1
    mom.originalY = mom.y 
    physics.addBody( map:findObject( "mom sensor" ), { isSensor = true, bodyType = "static" } )

    jumpingLoop( mom, map:findObject( "momBubble" ), message.mom )
  end
end
-- -----------------------------------------------------------------------------------
-- Funções de criação
-- -----------------------------------------------------------------------------------
-- Prepara a câmera para se mover de acordo com os movimentos do personagem
-- @TODO: Mudar os parâmetros de setCameraOffset e setBounds quando trocarmos o mapa 
local function setCamera()
  local layer
  camera:add( character, 1 )
  camera:add( map, 2 )

  layer = camera:layer(1)

  local mapX, mapY = map:localToContent( 0, 0 )
  layer:setCameraOffset( -98, -35 )

  layer = camera:layer(2)
  layer:setCameraOffset( -98, -35 )

  camera:setBounds( 170, 300, 150, 312 )
  camera:setFocus(character)
  camera:track()
  camera:toBack()
end

local function gotoNextLevel()
  local executeButton = gamePanel.tiled:findObject( "executeButton" )

  transition.fadeOut( gamePanel.tiled, { time = 800 } )
  if ( ( gameFileData.house.isComplete == true ) and ( gameFileData.school.isComplete == false ) ) then 
    teacher.xScale = 1
    transition.to( character, { time = 100, x = character.x + 5 } )
    transition.to( teacher, { time = 100, x = teacher.x + 5, onComplete = sceneTransition.gotoSchool } )
    
    if ( ( executeButton.executionsCount == 1 ) and ( executeButton.instructionsCount[#executeButton.instructionsCount] == 3 ) ) then
      gameFileData.school.previousStars = 3  
    elseif ( gamePanel.bikeWheel.maxCount == 0 ) then
      gameFileData.school.previousStars = 2 
    else 
      gameFileData.school.previousStars = 1
    end
  elseif ( ( gameFileData.school.isComplete == true ) and ( gameFileData.restaurant.isComplete == false ) ) then 
    cook.xScale = -1
    transition.to( character, { time = 100, y = character.y + 5 } )
    transition.to( cook, { time = 100, x = cook.x - 5, onComplete = sceneTransition.gotoRestaurant } )
    
    if ( ( executeButton.executionsCount == 1 ) and ( executeButton.instructionsCount[#executeButton.instructionsCount] == 3 ) ) then
      gameFileData.restaurant.previousStars = 3  
    elseif ( gamePanel.bikeWheel.maxCount == 0 ) then
      gameFileData.restaurant.previousStars = 2 
    else 
      gameFileData.restaurant.previousStars = 1
    end
  elseif ( ( gameFileData.restaurant.isComplete == true ) and ( gameFileData.house.shownCompletion == false ) ) then 
    local wonCount = 0
    transition.to( character, { time = 100, y = character.y - 5 } )
    transition.to( mom, { time = 100, y = mom.y - 5, onComplete = sceneTransition.gotoHouse } )
    
    gameFileData.house.isGameComplete = true 
    if ( ( executeButton.executionsCount == 1 ) and ( executeButton.instructionsCount[#executeButton.instructionsCount] == 2 ) ) then
      gameFileData.house.previousStars = 3  
    elseif ( gamePanel.bikeWheel.maxCount == 0 ) then
      gameFileData.house.previousStars = 2 
    else 
      gameFileData.house.previousStars = 1
    end

    if ( gameFileData.house.previousStars >= 3 ) then 
      wonCount = wonCount + 1
    end

    if ( gameFileData.school.previousStars >= 3 ) then 
      wonCount = wonCount + 1
    end

    if ( gameFileData.restaurant.previousStars >= 3 ) then 
      wonCount = wonCount + 1
    end 

    if ( wonCount >= 2 ) then
      gameFileData.house.wonSurprise = true 
    else 
      gameFileData.house.wonSurprise = false
    end
  end 
end
 
-- -----------------------------------------------------------------------------------
-- Funções que mostram texto
-- -----------------------------------------------------------------------------------
local function showSubText( event )
    messageBubble = event.target

    if ( messageBubble.message[messageBubble.shownText] ) then 
      messageBubble.text:removeSelf()
      messageBubble.options.text = messageBubble.message[messageBubble.shownText]

      local newText = display.newText( messageBubble.options ) 
      newText.x = newText.x + newText.width/2
      newText.y = newText.y + newText.height/2
      if ( messageBubble.options.color ) then 
        newText:setFillColor( messageBubble.options.color[1], messageBubble.options.color[2], messageBubble.options.color[3] )
      end

      messageBubble.text = newText
      messageBubble.shownText = messageBubble.shownText + 1

      if ( not messageBubble.message[ messageBubble.shownText ] ) then
          if ( messageBubble.blinkingDart ) then 
            transition.cancel( messageBubble.blinkingDart )
            messageBubble.blinkingDart.alpha = 0
            messageBubble.blinkingDart = nil
          end
      end

    else
      transition.fadeOut( messageBubble.text, { time = 400 } )
      transition.fadeOut( messageBubble, { time = 400, onComplete = gotoNextLevel } )
      messageBubble.text:removeSelf()
      messageBubble.text = nil
      listeners:remove( messageBubble, "tap", showSubText )
    end

    return true
  end

  local function showMessageAgain( event )
    local target = event.target
    if ( ( messageBubble ) and ( messageBubble.alpha == 1 ) and ( messageBubble.myName == target.bubble ) ) then 
      messageBubble.text:removeSelf()
      messageBubble.options.text = messageBubble.message[1]

      local newText = display.newText( messageBubble.options ) 
      newText.x = newText.x + newText.width/2
      newText.y = newText.y + newText.height/2
      if ( messageBubble.options.color ) then 
        newText:setFillColor( messageBubble.options.color[1], messageBubble.options.color[2], messageBubble.options.color[3] )
      end

      messageBubble.text = newText
      messageBubble.shownText = 1

      if ( not messageBubble.blinkingDart ) then 
        time = 500

        messageBubble.blinkingDart = map:findObject( "blinkingDart" ) 
        messageBubble.blinkingDart.x = messageBubble.x + 33
        messageBubble.blinkingDart.y = messageBubble.y + 12

        messageBubble.blinkingDart.alpha = 1
        transition.blink( messageBubble.blinkingDart, { time = time } )
      end
    end
  end

  function showText( bubble, message, bubbleChar ) 
    local options = {
        text = " ",
        x = bubble.contentBounds.xMin + 15, 
        y = bubble.contentBounds.yMin + 10,
        fontSize = 12.5,
        width = bubble.width - 27,
        height = 0,
        align = "left" 
    }
    options.text = message[1]

    if ( bubble.myName == "cookBubble" ) then 
      options.color = { 0.2, 0.2, 0 }
    end

    if ( bubble.alpha == 0 ) then
      transition.fadeIn( bubble, { time = 400 } )
    end

    listeners:add( bubble, "tap", showSubText )
    listeners:add( bubbleChar, "tap", showMessageAgain )


    local newText = display.newText( options ) 
    newText.x = newText.x + newText.width/2
    newText.y = newText.y + newText.height/2
    if ( options.color ) then 
      newText:setFillColor( options.color[1], options.color[2], options.color[3] )
    end

    bubble.message = message 
    bubble.text = newText
    bubble.shownText = 1
    bubble.options = options

    local time 
    if ( not bubble.blinkingDart ) then 
      time = 500

      bubble.blinkingDart = map:findObject( "blinkingDart" ) 
      bubble.blinkingDart.x = bubble.x + 33
      bubble.blinkingDart.y = bubble.y + 12

      bubble.blinkingDart.alpha = 1
      transition.blink( bubble.blinkingDart, { time = time } )
    end

    if ( ( messageBubble ) and ( messageBubble ~= bubble ) ) then
      listeners:remove( messageBubble, "tap", showSubText )
      messageBubble = bubble
    elseif ( not messageBubble ) then 
      messageBubble = bubble
    end
  end

local function nextLevelCharacterCollision( nextLevelCharacter, bubble, msg )
  if ( instructionsTable.last < instructionsTable.executing ) then 
    local cancelLoop = nextLevelCharacter.cancelLoop
    nextLevelCharacter.cancelLoop = true
    instructionsTable.stop = true
    transition.cancel( character )

    if ( nextLevelCharacter == teacher ) then 
      transition.to( character, { x = character.x - .45 * tilesSize } )
    elseif  ( nextLevelCharacter == cook ) then
      transition.to( character, { time = 100, y = character.y - 0.4 * tilesSize } )
    elseif  ( nextLevelCharacter == mom ) then
      transition.to( character, { time = 100, y = character.y + 0.05 * tilesSize } )
    end
    local function closure()
      if ( cancelLoop == false ) then 
        showText( bubble, msg, nextLevelCharacter )
      end
    end
    
    transition.to( nextLevelCharacter, { y = nextLevelCharacter.originalY, onComplete = closure } )
  else
    transition.cancel()
    if ( nextLevelCharacter == teacher ) then 
      transition.to( character, { x = character.x - .45 * tilesSize } )
    elseif  ( nextLevelCharacter == cook ) then
      transition.to( character, { time = 100, y = character.y - 0.4 * tilesSize } )
    elseif  ( nextLevelCharacter == mom ) then
      transition.to( character, { time = 100, y = character.y + 0.05 * tilesSize } )
    end 
    jumpingLoop( nextLevelCharacter, bubble, msg )
  end  
end
-- -----------------------------------------------------------------------------------
-- Listeners
-- -----------------------------------------------------------------------------------
-- Trata dos tipos de colisão
local function onCollision( event )
  phase = event.phase
  local obj1 = event.object1
  local obj2 = event.object2
 
  if ( event.phase == "began" ) then
    if ( ( ( obj1.myName == "house" ) and ( obj2.isCharacter ) ) or ( ( obj1.isCharacter ) and ( obj2.myName == "house" ) ) ) then 
      transition.cancel()
      local obj
      if ( obj1.myName == "house" ) then obj = obj1 else obj = obj2 end
      character.stepping.point = obj.point

      if ( ( obj.point == "exit" ) or ( gameFileData.house.isGameComplete == true ) ) then 
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 800, sceneTransition.gotoHouse )
      end

    elseif ( ( ( obj1.myName == "school" ) and ( obj2.isCharacter ) ) or ( ( obj1.isCharacter ) and ( obj2.myName == "school" ) ) ) then
      if ( gameFileData.school.isComplete == true ) then 
        transition.cancel()
        if ( obj1.point ) then character.stepping.point = obj1.point else character.stepping.point = obj2.point end 
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 800, sceneTransition.gotoSchool ) 
      end

    elseif ( ( ( obj1.myName == "restaurant" ) and ( obj2.isCharacter ) ) or ( ( obj1.isCharacter ) and ( obj2.myName == "restaurant" ) ) ) then
      if ( gameFileData.restaurant.isComplete == true ) then 
        transition.cancel()
        if ( obj1.point ) then character.stepping.point = obj1.point else character.stepping.point = obj2.point end 
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 800, sceneTransition.gotoRestaurant ) 
      end
    -- Colisão entre o personagem e os sensores dos tiles do caminho
    elseif ( ( ( obj1.isCharacter ) and ( obj2.isPath ) ) or ( ( obj2.isCharacter ) and ( obj1.isPath ) ) ) then
      local obj 
      if ( obj1.isPath ) then obj = obj1 else obj = obj2 end

      character.stepping.x = obj.x 
      character.stepping.y = obj.y 
      character.stepping.point = "point"
      path:showTile( obj.myName )
    
    elseif ( ( ( obj1.myName == "teacher" ) and ( obj2.isCharacter ) ) or ( ( obj2.myName == "teacher" ) and ( obj1.isCharacter ) ) ) then 
      nextLevelCharacterCollision( teacher, map:findObject( "teacherBubble" ), message.teacher )

    elseif ( ( ( obj1.myName == "cook" ) and ( obj2.isCharacter ) ) or ( ( obj2.myName == "cook" ) and ( obj1.isCharacter ) ) ) then
      nextLevelCharacterCollision( cook, map:findObject( "cookBubble" ), message.cook )

    elseif ( ( ( obj1.myName == "mom" ) and ( obj2.isCharacter ) ) or ( ( obj2.myName == "mom" ) and ( obj1.isCharacter ) ) ) then
      nextLevelCharacterCollision( mom, map:findObject( "momBubble" ), message.mom )

    elseif ( ( ( obj1.isCollision ) and ( obj2.isCharacter ) ) or ( ( obj1.isCharacter ) and ( obj2.isCollision ) ) ) then 
      local obj
      if ( obj1.isCollision ) then obj = obj1 else obj = obj2 end 
      
      transition.cancel( character )
      if ( ( obj.direction == "right" ) ) then 
        transition.to( character, { time = 0, x = character.x + .18 * tilesSize } )
      elseif ( ( obj.direction == "left" ) ) then 
        transition.to( character, { time = 0, x = character.x - .18 * tilesSize } )
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
local function destroyMap()
  camera:destroy()
  camera = nil 
  map:removeSelf()

  map = nil 
  character = nil 

  path:destroy()
end

local function destroyScene()
  if ( messageBubble ) then
    if ( messageBubble.text ) then 
      text = messageBubble.text
      text:removeSelf()
    end
  end
  listeners:remove( Runtime, "collision", onCollision )
  gamePanel:destroy()

  instructions:destroyInstructionsTable()

  destroyMap()
end

-- -----------------------------------------------------------------------------------
-- Cenas
-- -----------------------------------------------------------------------------------
-- create()
function scene:create( event )
  sceneGroup = self.view

  map, character, gamePanel, gameState, path, instructions, instructionsTable, gameFileData = gameScene:set( "map" )

  teacher = map:findObject( "teacher" )
  cook = map:findObject( "cook" )
  mom = map:findObject( "mom" )
  character.alpha = 1

  sceneGroup:insert( map )
  sceneGroup:insert( gamePanel.tiled )
  gamePanel.tiled.y = gamePanel.tiled.y - 10
  gamePanel.tiled.x = gamePanel.tiled.x + 5
end

-- show()
function scene:show( event )
  local sceneGroup = self.view
  local phase = event.phase

  if ( phase == "will" ) then
    listeners:add( Runtime, "collision", onCollision )
    gamePanel:addDirectionListeners()

    setNextLevelCharacter()

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
    character.name = gameFileData.character.name
    gameFileData.character = character
    gameState:save( gameFileData )
    destroyScene()
    listeners:destroy()
  elseif ( phase == "did" ) then
    composer.removeScene( "map" )
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