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

local fsm = require "com.fsm.src.fsm"

physics.start()
physics.setGravity( 0, 0 )

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local house 

local character

local mom 

local rope 

local ropeJoint

local tilesSize = 32

local stepDuration = 50

local house

local puzzle = { bigPieces = { }, littlePieces = { count }, puzzleSensors = { } }

local miniGameData

local collectedPieces = { count = 0 }

local tutorialFSM

local messageBubble

local animation = {}

local message = {}

-- -----------------------------------------------------------------------------------
-- Remoções para limpar a tela
-- -----------------------------------------------------------------------------------
local function destroyScene()
  Runtime:removeEventListener( "collision", onCollision )
  gamePanel:destroy()

  instructions:destroyInstructionsTable()

  house:removeSelf()
  house = nil 

  if ( ( messageBubble ) and ( messageBubble.text ) ) then
    messageBubble.text:removeSelf()
    messageBubble.text = nil 
  end

  tutorialFSM = nil 
end

local function setPuzzle()
  local bigPiecesLayer = house:findLayer("big puzzle") 
  local littlePiecesLayer = house:findLayer("little puzzle") 
  local puzzleSensorsLayer = house:findLayer("puzzle sensors")
  
  for i = 1, bigPiecesLayer.numChildren do
    puzzle.bigPieces[ bigPiecesLayer[i].myName ] = bigPiecesLayer[i]
    puzzle.puzzleSensors[ puzzleSensorsLayer[i].puzzleNumber ] = puzzleSensorsLayer[i]
    physics.addBody( puzzleSensorsLayer[i], { bodyType = "static", isSensor = true } )  
    littlePiecesLayer[i].alpha = 1
    puzzle.littlePieces[ littlePiecesLayer[i].myName ] = littlePiecesLayer[i]
  end
  
  puzzle.littlePieces.count = bigPiecesLayer.numChildren
end

local function executeTutorial( event, alternativeEvent )
  if ( tutorialFSM ) then 

    if ( ( messageBubble ) and ( messageBubble.text ) ) then
      messageBubble.text:removeSelf()
      messageBubble.text = nil
      transition.cancel( messageBubble.blinkingDart )
      messageBubble.blinkingDart.alpha = 0
      messageBubble.blinkingDart = nil
    end

    if ( alternativeEvent ) then
      if ( alternativeEvent == "showMessage" ) then
        tutorialFSM.showMessage()
      elseif ( alternativeEvent == "transitionEvent" ) then
        tutorialFSM.transitionEvent()
        executeTutorial()
      end

    else
      if ( tutorialFSM.nextEvent == "showAnimation" ) then 
        tutorialFSM.showAnimation()
        timer.performWithDelay( animation[tutorialFSM.current](), executeTutorial )

      elseif ( tutorialFSM.nextEvent == "showMessage" ) then 
        tutorialFSM.showMessage()

      elseif ( tutorialFSM.nextEvent == "showObligatoryMessage" ) then 
        tutorialFSM.showObligatoryMessage()
      
      elseif ( tutorialFSM.nextEvent == "showMessageAndAnimation" ) then 
        tutorialFSM.showMessageAndAnimation()
        local _, animationName = tutorialFSM.current:match( "([^,]+)_([^,]+)" )
        local from, wait, n = tutorialFSM.from:match( "([^,]+)_([^,]+)_([^,]+)" )
        
        if ( ( from == "transitionState" ) and ( wait ) ) then 
          timer.performWithDelay( wait, animation[animationName] )
        else
          animation[animationName]()
        end
      
      elseif ( tutorialFSM.nextEvent == "transitionEvent" ) then 
        tutorialFSM.transitionEvent()
        executeTutorial()

      elseif ( tutorialFSM.nextEvent == "saveEvent" ) then
        tutorialFSM.saveEvent()
        miniGameData.controlsTutorial = "complete"
        --gameState:save( miniGameData )
        executeTutorial()

      elseif ( tutorialFSM.nextEvent == "showFeedback" ) then
        tutorialFSM.showFeedback()
        executeTutorial()

      elseif ( tutorialFSM.nextEvent == "nextTutorial" ) then
        tutorialFSM.nextTutorial()
      end
    end
  end
end


local function showSubText( event )
  messageBubble = event.target

  if ( messageBubble.message[messageBubble.shownText] ) then 
    messageBubble.text:removeSelf()

    if ( ( tutorialFSM.current == "msg6" ) and ( messageBubble.message[messageBubble.shownText] == "Mas ainda falta" ) ) then 
      local remainingPieces = puzzle.littlePieces.count - collectedPieces.count

      if ( remainingPieces > 1 ) then
        messageBubble.options.text = messageBubble.message[messageBubble.shownText] .. "m " .. remainingPieces .. " peças."
      else
        messageBubble.options.text = messageBubble.message[messageBubble.shownText] .. " " .. remainingPieces .. " peça."
      end
    else
      messageBubble.options.text = messageBubble.message[messageBubble.shownText]
    end

    local newText = display.newText( messageBubble.options ) 
    newText.x = newText.x + newText.width/2
    newText.y = newText.y + newText.height/2

    messageBubble.text = newText
    messageBubble.shownText = messageBubble.shownText + 1

    messageBubble.blinkingDart.x = messageBubble.x + 33
    messageBubble.blinkingDart.y = messageBubble.y + 12 

  else
    if ( tutorialFSM.event == "showObligatoryMessage" ) then
      transition.fadeOut( messageBubble.text, { time = 400 } )
      transition.fadeOut( messageBubble, { time = 400, onComplete = executeTutorial } )
      messageBubble.text:removeSelf()
      messageBubble.text = nil
      messageBubble.listener = false
      messageBubble:removeEventListener( "tap", showSubText )

      transition.cancel( messageBubble.blinkingDart )
      messageBubble.blinkingDart.alpha = 0
      messageBubble.blinkingDart = nil
    else
      if ( messageBubble.text ) then
        transition.fadeOut( messageBubble.text, { time = 400 } )
        transition.fadeOut( messageBubble, { time = 400 } )
        messageBubble.text:removeSelf()
        messageBubble.text = nil
        messageBubble.listener = false
        messageBubble:removeEventListener( "tap", showSubText )

        transition.cancel( messageBubble.blinkingDart )
        messageBubble.blinkingDart.alpha = 0
        messageBubble.blinkingDart = nil
      end
    end
  end
end

local function showText( bubble, message )
  messageBubble = bubble 
  local options = {
      text = " ",
      x = messageBubble.contentBounds.xMin + 15, 
      y = messageBubble.contentBounds.yMin + 10,
      fontSize = 12.5,
      width = messageBubble.width - 27,
      height = 0,
      align = "left" 
  }
  options.text = message[1]

  if ( ( not messageBubble.listener ) or ( ( messageBubble.listener ) and ( messageBubble.listener == false ) ) ) then
    transition.fadeIn( messageBubble, { time = 400 } )
    messageBubble.listener = true
    messageBubble:addEventListener( "tap", showSubText )
  end 

  local newText = display.newText( options ) 
  newText.x = newText.x + newText.width/2
  newText.y = newText.y + newText.height/2

  messageBubble.message = message 
  messageBubble.text = newText
  messageBubble.shownText = 1
  messageBubble.options = options

  local time 
  if ( not messageBubble.blinkingDart ) then 
    if ( tutorialFSM.event == "showObligatoryMessage" ) then 
      time = 500
      messageBubble.blinkingDart = house:findObject( "obligatoryBlinkingDart" ) 
    else
      time = 2000
      messageBubble.blinkingDart = house:findObject( "regularBlinkingDart" ) 
    end
    messageBubble.blinkingDart.x = messageBubble.x + 33
    messageBubble.blinkingDart.y = messageBubble.y + 12

    messageBubble.blinkingDart.alpha = 1
    transition.blink( messageBubble.blinkingDart, { time = time } )
  end

end

local function momAnimation( )
  local time = 5 --5000
  transition.to( house:findObject("mom"), { time = time, x = character.x, y = character.y - tilesSize } )

  return time --+ 500
end

local function handDirectionAnimation( time, wait, hand, initialX, initialY, x, y, state )
  if ( state ~= tutorialFSM.current ) then
    return
  else 
    hand.x = initialX
    hand.y = initialY
    transition.to( hand, { time = time, x = x, y = y } )
    local closure = function ( ) return handDirectionAnimation( time, wait, hand, initialX, initialY, x, y, state ) end
    timer.performWithDelay(time + wait, closure)
  end
end

local function handDirectionAnimation1( )
  local hand = gamePanel.hand
  local box = gamePanel.firstBox
  local time = 1500
  local wait = 400

  hand.x = hand.originalX 
  hand.y = hand.originalY
  hand.alpha = 1
   

  handDirectionAnimation( time, wait, hand, hand.originalX, hand.originalY, hand.x, box.y - 5, tutorialFSM.current )
  
  gamePanel:addRightDirectionListener( executeTutorial )
end

local function handDirectionAnimation2( )
  local hand = gamePanel.hand
  local box = gamePanel.secondBox
  local time = 1500
  local wait = 400

  hand.x = hand.originalX 
  hand.y = hand.originalY
  hand.alpha = 1
   

  handDirectionAnimation( time, wait, hand, hand.originalX, hand.originalY, hand.x, box.y - 5, tutorialFSM.current )
  gamePanel:addRightDirectionListener( executeTutorial )
end

local function handDirectionAnimation3( )
  local hand = gamePanel.hand
  local box = gamePanel.secondBox
  local time = 3000
  local wait = 400

  hand.x = hand.originalX - 20 
  hand.y = hand.originalY - 20
  hand.alpha = 1
   

  handDirectionAnimation( time, wait, hand, hand.x, hand.y, hand.x, box.y - 5, tutorialFSM.current )
  gamePanel:addUpDirectionListener( executeTutorial )
end

local function handWalkAnimation( )
  local hand = gamePanel.hand
  local executeButton = gamePanel.executeButton
  local time = 1500
  local wait = 400

  hand.x = executeButton.x 
  hand.y = executeButton.y
  hand.alpha = 1
   

  handDirectionAnimation( time, wait, hand, executeButton.contentBounds.xMin + 2, executeButton.y, executeButton.contentBounds.xMin + 10, executeButton.y - 5, tutorialFSM.current )
    

  gamePanel:addExecuteButtonListener( executeTutorial )
end


local function gamePanelAnimation()
  gamePanel:showDirectionButtons( true )
end

local function handBikeAnimation( time, hand, radius, initialX, initialY, state )
  if ( state ~= tutorialFSM.current ) then
    return
  else 

    transition.to( hand, { time = time, y = initialY + 2 * radius, transition = easing.inOutSine } )
    transition.to( hand, { time = time*.5, x = initialX + radius, transition = easing.outSine, onComplete = 
    function()
      transition.to( hand, { time = time*.5, x = initialX, transition = easing.inSine, onComplete =
        function()
          transition.to( hand, { time = time, y = initialY - radius/2, transition = easing.inOutSine } )
          transition.to( hand, { time = time*.5, x = initialX - radius - 10, transition = easing.outSine, onComplete = 
          function()
            transition.to( hand, { time = time*.5, x = initialX, transition = easing.inSine } )
            end } )
        end
       } )
     end } )
    local closure = function ( ) return handBikeAnimation( time, hand, radius, initialX, initialY, state ) end
    timer.performWithDelay(time * 2 + 400, closure)
  end
end

local function handBikeAnimation1()
  local hand = gamePanel.hand
  local bikeWheel = gamePanel.bikeWheel
  local time = 1500
  local radius = bikeWheel.radius/2
  local maxSteps = 2

  hand.x = bikeWheel.x - radius + 2
  hand.y = bikeWheel.contentBounds.yMin - 2
  hand.alpha = 1
   
  handBikeAnimation( time, hand, radius, hand.x, hand.y, tutorialFSM.current )
  
  gamePanel:addBikeTutorialListener( maxSteps, executeTutorial )
end

local function handBikeAnimation2()
  local hand = gamePanel.hand
  local bikeWheel = gamePanel.bikeWheel
  local time = 1500
  local radius = bikeWheel.radius/2
  local maxSteps = 3

  hand.x = bikeWheel.x - radius + 2
  hand.y = bikeWheel.contentBounds.yMin - 2
  hand.alpha = 1
   
  handBikeAnimation( time, hand, radius, hand.x, hand.y, tutorialFSM.current )
  
  gamePanel:addBikeTutorialListener( maxSteps, executeTutorial )
end

local function handExitAnimation()
  local hand = gamePanel.hand
  local time = 1000
  local wait = 200
  local exit = house:findObject( "exit" )

  hand.x = exit.contentBounds.xMin - 5
  hand.y = exit.contentBounds.yMax - 20
  hand.rotation = - 80
  hand.alpha = 1
   
  handDirectionAnimation( time, wait, hand, hand.x, hand.y, hand.x, hand.y + 5, tutorialFSM.current )
  gamePanel.restartExecutionListeners()
end

animation["momAnimation"] = momAnimation
animation["handDirectionAnimation1"] = handDirectionAnimation1
animation["handDirectionAnimation2"] = handDirectionAnimation2
animation["handDirectionAnimation3"] = handDirectionAnimation3
animation["handWalkAnimation"] = handWalkAnimation
animation["gamePanelAnimation"] = gamePanelAnimation
animation["handBikeAnimation1"] = handBikeAnimation1
animation["handBikeAnimation2"] = handBikeAnimation2 
animation["handExitAnimation"] = handExitAnimation 

message["msg1"] = { "Tenho um presente para você.",
                  "Encontre todas as peças de",
                  "quebra-cabeça que escondi",
                  "pela casa para descobrir",
                  "o que é." }

message["msg2"] = { "Arraste a seta da direita para", 
                    "o retângulo laranja para andar",
                    "um quadradinho" }

message["msg3"] = { "Muito bem! Arraste mais uma",
                    "seta para completar o caminho." }

message["msg4"] = { "Agora aper-te no botão \"andar\"." }

message["msg5"] = { "Parabéns! Agora tente pegar as",
                    "outras peças usando", 
                    "também outras setas." }

message["msg6"] = { "Muito bem! Você está perto de",
                    "descobrir qual é o presente.",
                    "Mas ainda falta" }

message["msg7"] = { "Parabéns! Você ga-nhou uma",
                    "bicicleta." }

message["msg8"] = { "Vamos aprender a usar",
                    "a sua nova bicicleta?" }

message["msg9"] = { "Use o que você aprendeu ",
                    "antes.",
                    "Arraste a seta para o retângulo",
                    "laranja." }

message["msg10"] = { "Agora gire a roda da bicicleta",
                     "para aumentar o número de",
                     "quadrados que você vai andar." }

message["msg11"] = { "Isso! Agora vamos fazer o",
                      "mesmo para ir para cima." }

message["msg12"] = { "Gire a roda novamente." }

message["msg13"] = { "Aperte no botão de andar." }

message["msg14"] = { "Agora por que você não vai lá",
                     "fora?",
                     "Seu professor precisa de", 
                     "ajuda.",
                     "Ele está na frente da sua escola.",
                     "Vá até lá ajudá-lo." }

message["msg15"] = { "Para sair de casa, chegue ao", 
                     "quadradinho vermelho." }

message["msg16"] = { "Ah, quase me esqueci!",
                     "Se você voltar logo para", 
                     "casa, vou te dar outro presente.",
                     "Mas só volte depois de ajudar",
                     "Todo mundo da cidade que precisar",
                     "de ajuda." }

local function bikeTutorial()
  local start = house:findObject( "start" )

  if ( not mom ) then 
    mom = house:findObject( "mom" )
    mom.x = character.x
    mom.y = character.y - tilesSize
  else 
    physics.removeBody( character )
    character.x = mom.x 
    character.y = mom.y + tilesSize

    physics.addBody( character )
    path:hidePath()

    gamePanel:showBikewheel ( true )
    gamePanel:hideInstructions()
  end
  
  gamePanel:stopAllListeners()

  tutorialFSM = fsm.create({
    initial = "start",
    events = {
      {name = "showObligatoryMessage",  from = "start",  to = "momBubble_msg8", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "momBubble_msg8",  to = "momBubble_msg9_handDirectionAnimation1", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "momBubble_msg9_handDirectionAnimation1",  to = "momBubble_msg10_handBikeAnimation1", nextEvent = "transitionEvent" },
      
      {name = "transitionEvent",  from = "momBubble_msg10_handBikeAnimation1",  to = "transitionState_100_1", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "transitionState_100_1",  to = "momBubble_msg11_handDirectionAnimation3", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "momBubble_msg11_handDirectionAnimation3",  to = "momBubble_msg12_handBikeAnimation2", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "momBubble_msg12_handBikeAnimation2",  to = "momBubble_msg13_handWalkAnimation", nextEvent = "showObligatoryMessage" },
      {name = "showObligatoryMessage",  from = "momBubble_msg13_handWalkAnimation",  to = "momBubble_msg14", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "momBubble_msg14",  to = "momBubble_msg15_handExitAnimation" },-- nextEvent = "showObligatoryMessage" },
      
      {name = "showMessage",  from = "start",  to = "momBubble_msg10", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "momBubble_msg10",  to = "momBubble_msg15_handExitAnimation", nextEvent = "showObligatoryMessage" },
      {name = "showObligatoryMessage",  from = "momBubble_msg15_handExitAnimation",  to = "momBubble_msg16"},-- nextEvent = "showMessageAndAnimation" },
      
    },
    callbacks = {
      on_showMessage = function( self, event, from, to ) 
        local messageBubble, msg = tutorialFSM.current:match( "([^,]+)_([^,]+)" ) 
        showText( house:findObject( messageBubble ), message[msg] )
      end,
      on_showObligatoryMessage = function( self, event, from, to ) 
        local messageBubble, msg = tutorialFSM.current:match( "([^,]+)_([^,]+)" ) 
        showText( house:findObject( messageBubble ), message[msg] )
      end,
      on_showMessageAndAnimation = function( self, event, from, to )
        local messageBubble, msg, animationName = tutorialFSM.current:match( "([^,]+)_([^,]+)_([^,]+)" ) 
        
        showText( house:findObject( messageBubble ), message[msg] )

        return animationName
      end
    }
  })

  --tutorialFSM.showObligatoryMessage()
  tutorialFSM.showMessage() ----tirar
  executeTutorial()         ----tirar

end

local function controlsTutorial( )
  tutorialFSM = fsm.create({
    initial = "start",
    events = {
      {name = "showAnimation",  from = "start",  to = "momAnimation", nextEvent = "showObligatoryMessage" },
      {name = "showObligatoryMessage",  from = "momAnimation",  to = "msg1", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "msg1",  to = "msg2_handDirectionAnimation1", nextEvent = "transitionEvent" },
      {name = "transitionEvent",  from = "msg2_handDirectionAnimation1",  to = "transitionState_100_1", nextEvent = "showMessageAndAnimation" },
      
      {name = "showMessageAndAnimation",  from = "transitionState_100_1",  to = "msg3_handDirectionAnimation2", nextEvent = "transitionEvent" },
      {name = "transitionEvent",  from = "msg3_handDirectionAnimation2",  to = "transitionState_100_2", nextEvent = "showMessageAndAnimation" },
      
      {name = "showMessageAndAnimation",  from = "transitionState_100_2",  to = "msg4_handWalkAnimation", nextEvent = "transitionEvent" },
      {name = "transitionEvent",  from = "msg4_handWalkAnimation",  to = "transitionState_100_3", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "transitionState_100_3",  to = "msg5_gamePanelAnimation", nextEvent = "showMessage" },

      {name = "showMessage",  from = "msg5_gamePanelAnimation",  to = "msg6", nextEvent = "showMessage" },

      {name = "showMessage",  from = "msg6",  to = "msg6", nextEvent = "showMessage" },
      {name = "transitionEvent",  from = "msg6",  to = "transitionState4", nextEvent = "saveEvent" },
      {name = "saveEvent",  from = "transitionState4",  to = "save", nextEvent = "showObligatoryMessage" },
      {name = "showObligatoryMessage",  from = "save",  to = "msg7", nextEvent = "showFeedback" },
      {name = "showFeedback",  from = "msg7",  to = "feedback", nextEvent = "nextTutorial" },
      {name = "nextTutorial",  from = "feedback",  to = "tutorial" },
    },
    callbacks = {
      on_showMessage = function( self, event, from, to ) 
        showText( house:findObject("message"), message[self.current] )
      end,
      on_showObligatoryMessage = function( self, event, from, to ) 
        showText( house:findObject("message"), message[self.current] )
      end,
      on_showMessageAndAnimation = function( self, event, from, to )
        local msg, animationName = tutorialFSM.current:match( "([^,]+)_([^,]+)" ) 
        showText( house:findObject("message"), message[msg] )

        return animationName
      end,
      on_nextTutorial = function( self, event, from, to ) 
         bikeTutorial()
      end
    }
  })

  mom = house:findObject( "mom" )
  mom.originalX = mom.x 
  mom.originalY = mom.y
  
  tutorialFSM.showAnimation()
  timer.performWithDelay( animation[tutorialFSM.current](), executeTutorial )
  

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
    if ( ( obj1.myName == "puzzle" ) and ( obj2.myName == "character" ) ) then
      if ( collectedPieces[obj1.puzzleNumber] == nil ) then 
        puzzle.bigPieces[obj1.puzzleNumber].alpha = 1
        puzzle.littlePieces[ obj1.puzzleNumber ].alpha = 0
        collectedPieces[ obj1.puzzleNumber ] = puzzle.littlePieces[ obj1.puzzleNumber ]
        local remainingPieces = puzzle.littlePieces.count - (collectedPieces.count + 1)

        if ( ( collectedPieces.count ~= 0 ) and ( remainingPieces > 0 ) ) then
          executeTutorial()
        elseif ( remainingPieces <= 0 ) then 
          executeTutorial( _, "transitionEvent" )
        end
        collectedPieces.count = collectedPieces.count + 1

        print( "collectedPieces: " .. collectedPieces.count .. "; remain: " .. remainingPieces )
      end 
    elseif ( ( obj1.myName == "character" ) and ( obj2.myName == "puzzle" ) ) then 
      if ( collectedPieces[obj2.puzzleNumber] == nil ) then
        puzzle.bigPieces[obj2.puzzleNumber].alpha = 1
        puzzle.littlePieces[ obj2.puzzleNumber ]. alpha = 0
        collectedPieces[ obj2.puzzleNumber ] = puzzle.littlePieces[ obj2.puzzleNumber ]
        local remainingPieces = puzzle.littlePieces.count - (collectedPieces.count + 1)


        if ( ( collectedPieces.count ~= 0 ) and ( remainingPieces > 0 ) ) then
          executeTutorial()
        elseif ( remainingPieces <= 0 ) then 
          executeTutorial( _, "transitionEvent" )
        end
        collectedPieces.count = collectedPieces.count + 1
      end

    -- Volta para o mapa quando o personagem chega na saída/entrada da casa
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

    elseif ( ( ( obj1.myName == "entrace" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "entrance" ) ) ) then 
      if ( miniGameData.isComplete == true ) then
        transition.cancel()
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 800, sceneTransition.gotoMap )
      end
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
-- Cenas
-- -----------------------------------------------------------------------------------
-- create()
function scene:create( event )
	local sceneGroup = self.view

  --print( display.actualContentWidth )
  --print( display.actualContentHeight )

  persistence.setCurrentFileName( "ana" )

	house, character, rope, ropeJoint, gamePanel, gameState, path, instructions, instructionsTable, miniGameData = gameScene:set( "house", onCollision )

  if ( character.flipped == true ) then
    character.xScale = -1
  end

  miniGameData.controlsTutorial = "complete"

  sceneGroup:insert( house )
  sceneGroup:insert( gamePanel.tiled )

  if ( miniGameData.controlsTutorial == "incomplete" ) then 
    setPuzzle()
  end
end

-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
    if ( miniGameData.controlsTutorial == "complete" ) then
		  gamePanel:addDirectionListeners()
    end

	elseif ( phase == "did" ) then
    if ( miniGameData.controlsTutorial == "complete" ) then
      gamePanel:showDirectionButtons( false )
		  gamePanel:addButtonsListeners()
      gamePanel:addInstructionPanelListeners()

      if ( miniGameData.bikeTutorial == "incomplete" ) then
        gamePanel:showBikewheel ( false )
        bikeTutorial()
      end

    else
      if ( miniGameData.controlsTutorial == "incomplete" ) then
        controlsTutorial()
      end
      --gamePanel:addGoBackButtonListener()
    end
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		physics.stop( )
		gameState:save( miniGameData )
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
