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

local feedback = require "feedback"

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

local collision = false 

local miniGameData

local collectedPieces = { count = 0 }

local tutorialFSM

local messageBubble

local animation = {}

local message = {}


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
    local nextEvent

    if ( alternativeEvent ) then nextEvent = alternativeEvent else nextEvent = tutorialFSM.nextEvent end

    if ( ( messageBubble ) and ( messageBubble.text ) ) then
      messageBubble.text:removeSelf()
      messageBubble.text = nil
      transition.cancel( messageBubble.blinkingDart )
      messageBubble.blinkingDart.alpha = 0
      messageBubble.blinkingDart = nil
    end

    if ( nextEvent == "showAnimation" ) then 
      tutorialFSM.showAnimation()

    elseif ( nextEvent == "showMessage" ) then 
      tutorialFSM.showMessage()

    elseif ( nextEvent == "showObligatoryMessage" ) then 
      tutorialFSM.showObligatoryMessage()
    
    elseif ( nextEvent == "showMessageAndAnimation" ) then 
      tutorialFSM.showMessageAndAnimation()
    
    elseif ( nextEvent == "transitionEvent" ) then 
      tutorialFSM.transitionEvent()

    elseif ( nextEvent == "saveGame" ) then
      tutorialFSM.saveGame()

    elseif ( nextEvent == "showFeedback" ) then
      tutorialFSM.showFeedback()

    elseif ( nextEvent == "nextTutorial" ) then
      tutorialFSM.nextTutorial()

    elseif ( nextEvent == "endTutorial" ) then
      tutorialFSM.endTutorial()

    elseif ( nextEvent == "repeatLevel" ) then 
      tutorialFSM.repeatLevel()
    end
  end
end


local function showSubText( event )
  messageBubble = event.target

  if ( messageBubble.message[messageBubble.shownText] ) then 
    messageBubble.text:removeSelf()

    if ( ( tutorialFSM.current == "momBubble_msg6" ) and ( messageBubble.message[messageBubble.shownText] == "Mas ainda falta" ) ) then 
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

  if ( bubble.alpha == 0 ) then
    transition.fadeIn( bubble, { time = 400 } )
  end

  if ( ( not bubble.listener ) or ( ( bubble.listener ) and ( bubble.listener == false ) ) ) then
    bubble.listener = true
    bubble:addEventListener( "tap", showSubText )
  end 

  local newText = display.newText( options ) 
  newText.x = newText.x + newText.width/2
  newText.y = newText.y + newText.height/2

  bubble.message = message 
  bubble.text = newText
  bubble.shownText = 1
  bubble.options = options

  local time 
  if ( not bubble.blinkingDart ) then 
    if ( tutorialFSM.event == "showObligatoryMessage" ) then 
      time = 500
      bubble.blinkingDart = house:findObject( "obligatoryBlinkingDart" ) 
    else
      time = 2000
      if ( bubble == house:findObject( "momBubble" ) ) then 
        bubble.blinkingDart = house:findObject( "momBlinkingDart" ) 
      else
        bubble.blinkingDart = house:findObject( "momBlinkingDart" ) 
      end
    end
    bubble.blinkingDart.x = bubble.x + 33
    bubble.blinkingDart.y = bubble.y + 12

    bubble.blinkingDart.alpha = 1
    transition.blink( bubble.blinkingDart, { time = time } )
  end

  if ( ( messageBubble ) and ( messageBubble ~= bubble ) ) then
    messageBubble.listener = false 
    messageBubble:removeEventListener( "tap", showSubText )

    messageBubble = bubble
  elseif ( not messageBubble ) then 
    messageBubble = bubble
  end

  --[[if ( ( tutorialFSM ) and ( tutorialFSM.event == "showObligatoryMessage" ) ) then
    gamePanel.stopExecutionListeners()
  end]]
end

local function momAnimation( )
  local time = 5000
  transition.to( house:findObject("mom"), { time = time, x = character.x, y = character.y - tilesSize } )

  return time + 500
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

local function handExecuteAnimation( )
  local hand = gamePanel.hand
  local executeButton = gamePanel.executeButton
  local time = 1500
  local wait = 400

  hand.x = executeButton.x 
  hand.y = executeButton.y
  hand.alpha = 1
   
  collision = false 
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
   
  gamePanel.executeButton.executionsCount = 0
  handDirectionAnimation( time, wait, hand, hand.x, hand.y, hand.x, hand.y + 5, tutorialFSM.current )
  gamePanel.restartExecutionListeners()
end

local function goBackAnimation()
  local steps = 3
  local time = steps * 400

  path:hidePath()
  character.xScale = -1
  transition.to( character, { time = time, x = character.x - tilesSize * steps } )

  return time
end

local function brotherChallengeAnimation()
  local brother = house:findObject( "brother" )
  local steps = 4.5
  local time = 400 * steps
  local hidingWallLayer = house:findLayer( "hidingWall" ) 

  path:hidePath()
  for i = 1, hidingWallLayer.numChildren do
    hidingWallLayer[i].alpha = 1
  end 
  brother.alpha = 1

  local function flipCharacter()
    character.xScale = 1
  end

  transition.to( brother, { time = time, x = brother.x - tilesSize * steps, onComplete =  timer.performWithDelay( 2400, flipCharacter ) } )

  return time
end

local function brotherJumpingAnimation()
  local brother = house:findObject( "brother" )

  local time = 1500

  transition.to( brother, { rotation = 7, time = time, y = brother.y - 5, transition = easing.inBounce,
  onComplete =  
    function()
      transition.to( brother, { rotation = 0, time = time, y = brother.y + 5, transition = easing.outBounce } )
    end
   } )

  return 0
end

local function brotherLeavingAnimation()
  local brother = house:findObject( "brother" )
  local steps = 4.5
  local time = 400 * steps
  local hidingWallLayer = house:findLayer( "hidingWall" ) 

  brother.xScale = 1
  transition.to( brother, { time = time, x = brother.x + tilesSize * steps, onComplete = 
    function()
      for i = 1, hidingWallLayer.numChildren do
        hidingWallLayer[i].alpha = 0
      end 
    end
   } )

  return time
end

local function characterLeaveAnimation()
  local steps = 3
  local time = steps * 400
  character.xScale = 1
  transition.to( character, { time = time, x = character.x + tilesSize * steps } )

  return time
end

local function bikeAnimation()
  local time = 1000
  local bike = house:findObject( "bike" )
  local completePuzzle = house:findObject( "completePuzzle" )
  local xPos, yPos = persistence.startingPoint( "house" ) 
  local mom = house:findObject( "mom" )

  transition.fadeIn( completePuzzle, { time = time, 
    onComplete =  
      function()
        for k, v in pairs( puzzle.bigPieces ) do
          puzzle.bigPieces[k].alpha = 0
        end
        bike.alpha = 1
        transition.fadeOut( completePuzzle, { time = time, 
          onComplete =  
            function()
              characterLayer = house:findLayer("character")
              characterLayer:insert( bike )
              transition.scaleTo( bike, { time = time * 3, xScale = .5, yScale = .5, x = xPos, y = yPos,
                onComplete = 
                  function()
                    bikeLayer = house:findLayer("bike")
                    bikeLayer:insert( bike )
                  end
               } )
            end
          } )
      end

    } )

  return time * 7
end

local function gotoInitialPosition()
  local stepsX, stepsY 
  local time = 600
  local bike = house:findObject( "bike" )

  path:hidePath()
  local function flip()
    character.xScale = 1
  end

  local function delayedflip()
    timer.performWithDelay( 200, flip )
  end

  local function hideBike()
    transition.fadeOut( bike, { time = time } )
  end


  if ( collectedPieces.last == "2" ) then
    stepsX = 2
    stepsY = 3

    transition.to( character, { time = stepsY * time, y = character.y + stepsY * tilesSize,
      onComplete = 
        function()
          character.xScale = -1 
          transition.to( character, { time = stepsX * time, x = character.x - stepsX * tilesSize, 
            onComplete = 
              function()
                hideBike()
                delayedflip()
              end
            } )
        end
      } )
  elseif ( collectedPieces.last == "3" ) then 
    stepsX = 4
    stepsY = 3
    stepsX2 = 2

    character.xScale = -1
    transition.to( character, { time = stepsX * time, x = character.x - stepsX * tilesSize,
      onComplete = 
        function()
          transition.to( character, { time = stepsY * time, y = character.y + stepsY * tilesSize,
          onComplete = 
            function()
              transition.to( character, { time = stepsX2 * time, x = character.x - stepsX2 * tilesSize, 
                onComplete = 
                  function()
                    gamePanel:updateBikeMaxCount( 3 )
                    hideBike()
                    delayedflip()
                  end 
                } )
            end
           } )
        end
      } )
    stepsX = stepsX + stepsX2
  elseif ( collectedPieces.last == "4" ) then 
    stepsX = 4
    stepsY = 0
    character.xScale = -1
    transition.to( character, { time = stepsX * time, x = character.x - stepsX * tilesSize, onComplete = hideBike } )
  end


  return time * stepsX + time*stepsY
end

animation["momAnimation"] = momAnimation
animation["handDirectionAnimation1"] = handDirectionAnimation1
animation["handDirectionAnimation2"] = handDirectionAnimation2
animation["handDirectionAnimation3"] = handDirectionAnimation3
animation["handExecuteAnimation"] = handExecuteAnimation
animation["gamePanelAnimation"] = gamePanelAnimation
animation["handBikeAnimation1"] = handBikeAnimation1
animation["handBikeAnimation2"] = handBikeAnimation2 
animation["handExitAnimation"] = handExitAnimation 
animation["goBackAnimation"] = goBackAnimation
animation["brotherChallengeAnimation"] = brotherChallengeAnimation
animation["brotherJumpingAnimation"] = brotherJumpingAnimation
animation["brotherLeavingAnimation"] = brotherLeavingAnimation
animation["characterLeaveAnimation"] = characterLeaveAnimation
animation["bikeAnimation"] = bikeAnimation
animation["gotoInitialPosition"] = gotoInitialPosition

message["msg1"] = { "Tenho um presente para você.",
                  "Encontre todas as peças de",
                  "quebra-cabeça que escondi",
                  "pela casa para descobrir",
                  "o que é." }

message["msg2"] = { "Arraste a seta da direita para", 
                    "o retângulo laranja para andar",
                    "um quadradinho" }

message["msg3"] = { "Muito bem! Arraste mais uma",
                    "seta para pegar a peça ao lado." }

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

message["msg16"] = { "Ah, quase me esqueci!" }

message["msg17"] = { "Se você voltar logo para", 
                     "casa, vou te dar outro presente.",
                     "Mas só volte depois de ajudar",
                     "todo mundo da cidade que precisar",
                     "da sua ajuda." }

message["msg18"] = { "Humpf! Eu ouvi presente?",
                     "Acho que eu deveria ganhá-lo!",
                     "Ei, por que não fazemos uma aposta?",
                     "Se eu chegar antes de você em",
                     "casa, eu fico com o seu presente." }

message["msg19"] = { "Hahaha! Te vejo mais tarde",
                      "com o meu presente!" }

message["msg20"] = { "Esse seu irmão não tem jeito!",
                     "É melhor você correr para",
                     "alcançá-lo.",
                     "Até mais tarde." }

local function bikeTutorial()
  local start = house:findObject( "start" )

  if ( not mom ) then 
    mom = house:findObject( "mom" )
  else 
    transition.to( character, { time = 0, x = 80, y = 296} )
    mom.x, mom.y = character.x, character.y - tilesSize

    path:hidePath()

    gamePanel:showBikewheel ( true )
    gamePanel:hideInstructions()
  end
  
  gamePanel:stopAllListeners()

  tutorialFSM = fsm.create({
    initial = "start",
    events = {
      --{ name = "showFeedback", from = "start", to = "feedbackAnimation", nextEvent = "showObligatoryMessage" },
      {name = "showObligatoryMessage",  from = "start",  to = "momBubble_msg8", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "momBubble_msg8",  to = "momBubble_msg9_handDirectionAnimation1", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "momBubble_msg9_handDirectionAnimation1",  to = "momBubble_msg10_handBikeAnimation1", nextEvent = "transitionEvent" },
      
      {name = "transitionEvent",  from = "momBubble_msg10_handBikeAnimation1",  to = "transitionState_100_1", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "transitionState_100_1",  to = "momBubble_msg11_handDirectionAnimation3", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "momBubble_msg11_handDirectionAnimation3",  to = "momBubble_msg12_handBikeAnimation2", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "momBubble_msg12_handBikeAnimation2",  to = "momBubble_msg13_handExecuteAnimation", nextEvent = "transitionEvent" },
      
      {name = "transitionEvent",  from = "momBubble_msg13_handExecuteAnimation",  to = "transitionState_1800_2", nextEvent = "showObligatoryMessage" },
      {name = "showObligatoryMessage",  from = "transitionState_1800_2",  to = "momBubble_msg14", nextEvent = "showMessageAndAnimation" },
      {name = "showObligatoryMessage",  from = "repeat",  to = "momBubble_msg14", nextEvent = "showMessageAndAnimation" },
      

      --{name = "showMessageAndAnimation",  from = "momBubble_msg14",  to = "momBubble_msg15_handExitAnimation", nextEvent = "showObligatoryMessage" },
      
      {name = "showMessageAndAnimation",  from = "momBubble_msg14",  to = "momBubble_msg15_handExitAnimation", nextEvent = "showFeedback" },
      {name = "showFeedback",  from = "momBubble_msg15_handExitAnimation",  to = "feedbackAnimation", nextEvent = "showObligatoryMessage" },
      {name = "showObligatoryMessage",  from = "feedbackAnimation",  to = "momBubble_msg16", nextEvent = "showAnimation" },
      

      { name = "repeatLevel", from = "feedbackAnimation", to = "repeat", nextEvent = "showObligatoryMessage" },
      
      {name = "showAnimation",  from = "momBubble_msg16",  to = "goBackAnimation", nextEvent = "showObligatoryMessage" },
      {name = "showObligatoryMessage",  from = "goBackAnimation",  to = "momBubble_msg17", nextEvent = "showAnimation" },
      
      {name = "showAnimation",  from = "momBubble_msg17",  to = "momBubble_msg15_brotherChallengeAnimation", nextEvent = "showObligatoryMessage" }, 
    
      {name = "showAnimation",  from = "momBubble_msg17",  to = "brotherChallengeAnimation", nextEvent = "showObligatoryMessage" }, 
      {name = "showObligatoryMessage",  from = "brotherChallengeAnimation",  to = "brotherBubble_msg18", nextEvent = "showAnimation" },
      {name = "showAnimation",  from = "brotherBubble_msg18",  to = "brotherJumpingAnimation", nextEvent = "showObligatoryMessage" },
      {name = "showObligatoryMessage",  from = "brotherJumpingAnimation",  to = "brotherBubble_msg19", nextEvent = "showAnimation" },
      {name = "showAnimation",  from = "brotherBubble_msg19",  to = "brotherLeavingAnimation", nextEvent = "showObligatoryMessage" },
      {name = "showObligatoryMessage",  from = "brotherLeavingAnimation",  to = "momBubble_msg20", nextEvent = "showAnimation" },
      {name = "showAnimation",  from = "momBubble_msg20",  to = "characterLeaveAnimation", nextEvent = "saveGame" },
      {name = "saveGame",  from = "characterLeaveAnimation",  to = "save", nextEvent = "endTutorial" },
      {name = "endTutorial",  from = "save",  to = "end" },
    },
    callbacks = {
      on_showAnimation = 
        function( self, event, from, to ) 
          local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )
          local function closure() 
            gamePanel.stopExecutionListeners()
            timer.performWithDelay( animation[self.current](), executeTutorial ) 
          end

          if ( ( from == "transitionState" ) and ( wait ) ) then 
            timer.performWithDelay( wait, closure )
          else
            closure()
          end
        end,

      on_showMessage = 
        function( self, event, from, to ) 
          local messageBubble, msg = self.current:match( "([^,]+)_([^,]+)" )
          local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )
          local function closure() 
            gamePanel.stopExecutionListeners()
            showText( house:findObject( messageBubble ), message[ msg ] ) 
          end

          if ( ( from == "transitionState" ) and ( wait ) ) then 
            timer.performWithDelay( wait, closure )
          else
            closure()
          end

        end,

      on_showObligatoryMessage = 
        function( self, event, from, to ) 
          local messageBubble, msg = self.current:match( "([^,]+)_([^,]+)" )
          local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )
          local function closure() 
            showText( house:findObject( messageBubble ), message[ msg ] ) 
            gamePanel.stopExecutionListeners()
          end


          if ( ( from == "transitionState" ) and ( wait ) ) then 
            timer.performWithDelay( wait, closure )
          else 
            closure()
          end
        end,

      on_showMessageAndAnimation = 
        function( self, event, from, to )
          local messageBubble, msg, animationName = self.current:match( "([^,]+)_([^,]+)_([^,]+)" ) 
          local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )

          showText( house:findObject( messageBubble ), message[ msg ] )

          --local _, animationName = tutorialFSM.current:match( "([^,]+)_([^,]+)" )

          gamePanel.stopExecutionListeners()
          if ( ( from == "transitionState" ) and ( wait ) ) then 
            timer.performWithDelay( wait, animation[animationName] )
          else
            animation[animationName]()
          end

          --return animationName
        end,

      on_transitionEvent = 
        function( self, event, from, to ) 
          local _, _, animationName = self.from:match( "([^,]+)_([^,]+)_([^,]+)" ) 
          
          gamePanel.stopExecutionListeners()
          if ( ( animationName ) and ( animationName == "handExecuteAnimation" ) ) then
            transition.fadeOut( messageBubble, { time = 400 } )
          end

          if ( ( messageBubble ) and ( messageBubble.text ) ) then
            transition.fadeOut( messageBubble.text, { time = 400 } )
            transition.fadeOut( messageBubble, { time = 400 } )
            messageBubble.text:removeSelf()
            messageBubble.text = nil
            transition.cancel( messageBubble.blinkingDart )
            messageBubble.blinkingDart.alpha = 0
            messageBubble.blinkingDart = nil
          end
          executeTutorial()
        end,

      on_showFeedback = 
        function( self, event, from, to ) 
            local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )
            local executeButton = gamePanel.executeButton
            local stars = 3

            gamePanel.stopExecutionListeners()
            if ( ( from == "transitionState" ) and ( wait ) ) then 
              timer.performWithDelay( wait, executeTutorial )
            end

            if ( executeButton.instructionsCount[#executeButton.instructionsCount] ) then 
              if ( ( executeButton.executionsCount == 1 ) and ( executeButton.instructionsCount[#executeButton.instructionsCount] == 1 ) ) then
                stars = 3
              elseif ( gamePanel.bikeWheel.maxCount == 0 ) then
                stars = 2
              else 
                stars = 1
              end
            else
              stars = 1
            end

            local function closure()
              path:hidePath()
              gamePanel:hideInstructions()
              if ( messageBubble ) then 
                messageBubble.alpha = 0
                if ( messageBubble.blinkingDart ) then 
                  messageBubble.blinkingDart.alpha = 0
                end
              end
            end
            timer.performWithDelay( 1000, closure )
            gamePanel.tiled:insert( feedback.showAnimation( "house", stars, executeTutorial ) )
          end,

      on_saveGame = 
        function( self, event, from, to ) 
          miniGameData.bikeTutorial = "complete"
          miniGameData.isComplete = true 
          --gameState:save( miniGameData )
          executeTutorial()
        end,

      on_endTutorial = 
        function( self, event, from, to ) 
          transition.cancel()
          instructions:destroyInstructionsTable()
          gamePanel:stopAllListeners()
          timer.performWithDelay( 800, sceneTransition.gotoMap )
        end,

      on_repeatLevel = 
        function( self, event, from, to ) 
          local repeatPoint = house:findObject("repeatPoint")
          local startingPoint = house:findObject("start")

          physics.pause()
          physics.removeBody( character )
          mom.x = startingPoint.x 
          mom.y = startingPoint.y - tilesSize - 8
          character.x = repeatPoint.x
          character.y = repeatPoint.y - 6
          physics.start()
          physics.addBody( character )
          path:hidePath()

          gamePanel:hideInstructions()
          if ( messageBubble ) then 
            messageBubble.alpha = 0
            if ( messageBubble.blinkingDart ) then 
              messageBubble.blinkingDart.alpha = 0
            end
          end

          gamePanel:updateBikeMaxCount( 1 )
          timer.performWithDelay( 2000, executeTutorial )
          gamePanel:showDirectionButtons( true )
      end
    }
  })

  tutorialFSM.showObligatoryMessage()
  --tutorialFSM.showFeedback()
  --tutorialFSM.showMessage() ----tirar
  --executeTutorial()         ----tirar

end

local function controlsTutorial( )
  tutorialFSM = fsm.create( {
    initial = "start",
    events = {
      --{ name = "showAnimation", from = "start", to = "bikeAnimation", nextEvent = "showAnimation" },
      --{ name = "showAnimation", from = "bikeAnimation", to = "gotoInitialPosition" },
      { name = "showAnimation",  from = "start",  to = "momAnimation", nextEvent = "showObligatoryMessage" },
      { name = "showObligatoryMessage",  from = "momAnimation",  to = "momBubble_msg1", nextEvent = "showMessageAndAnimation" },
      { name = "showMessageAndAnimation",  from = "momBubble_msg1",  to = "momBubble_msg2_handDirectionAnimation1", nextEvent = "transitionEvent" },
      { name = "transitionEvent",  from = "momBubble_msg2_handDirectionAnimation1",  to = "transitionState_100_1", nextEvent = "showMessageAndAnimation" },
      
      { name = "showMessageAndAnimation",  from = "transitionState_100_1",  to = "momBubble_msg3_handDirectionAnimation2", nextEvent = "transitionEvent" },
      { name = "transitionEvent",  from = "momBubble_msg3_handDirectionAnimation2",  to = "transitionState_100_2", nextEvent = "showMessageAndAnimation" },
      
      { name = "showMessageAndAnimation",  from = "transitionState_100_2",  to = "momBubble_msg4_handExecuteAnimation", nextEvent = "transitionEvent" },
      { name = "transitionEvent",  from = "momBubble_msg4_handExecuteAnimation",  to = "transitionState_100_3", nextEvent = "showMessageAndAnimation" },
      { name = "showMessageAndAnimation",  from = "transitionState_100_3",  to = "momBubble_msg5_gamePanelAnimation", nextEvent = "showMessage" },

      { name = "showMessage",  from = "momBubble_msg5_gamePanelAnimation",  to = "momBubble_msg6", nextEvent = "showMessage" },

      { name = "showMessage",  from = "momBubble_msg6",  to = "momBubble_msg6", nextEvent = "showMessage" },
      { name = "transitionEvent",  from = "momBubble_msg6",  to = "transitionState4", nextEvent = "saveGame" },
      { name = "saveGame",  from = "transitionState4",  to = "save", nextEvent = "showObligatoryMessage" },
      { name = "showObligatoryMessage",  from = "save",  to = "momBubble_msg7", nextEvent = "showAnimation" },
      { name = "showAnimation", from = "momBubble_msg7", to = "bikeAnimation", nextEvent = "showAnimation" },
      { name = "showAnimation", from = "bikeAnimation", to = "gotoInitialPosition", nextEvent = "nextTutorial"  },
      { name = "nextTutorial",  from = "gotoInitialPosition",  to = "tutorial" },
    },
    callbacks = {
      on_showAnimation = 
        function( self, event, from, to ) 
          local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )
          local function closure() 
            gamePanel.stopExecutionListeners()
            timer.performWithDelay( animation[self.current](), executeTutorial ) 
          end

          if ( ( from == "transitionState" ) and ( wait ) ) then 
            timer.performWithDelay( wait, closure )
          else
            closure()
          end
        end,

      on_showMessage = 
        function( self, event, from, to ) 
          local messageBubble, msg = self.current:match( "([^,]+)_([^,]+)" )
          local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )
          local function closure() 
            gamePanel.stopExecutionListeners()
            showText( house:findObject( messageBubble ), message[ msg ] ) 
          end

          if ( ( from == "transitionState" ) and ( wait ) ) then 
            timer.performWithDelay( wait, closure )
          else
            closure()
          end

        end,

      on_showObligatoryMessage = 
        function( self, event, from, to ) 
          local messageBubble, msg = self.current:match( "([^,]+)_([^,]+)" )
          local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )
          local function closure() 
            showText( house:findObject( messageBubble ), message[ msg ] ) 
            gamePanel.stopExecutionListeners()
          end

          if ( ( from == "transitionState" ) and ( wait ) ) then 
            timer.performWithDelay( wait, closure )
          else
            closure()
          end
        end,

      on_showMessageAndAnimation = 
        function( self, event, from, to )
          local messageBubble, msg, animationName = self.current:match( "([^,]+)_([^,]+)_([^,]+)" ) 
          local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )

          showText( house:findObject( messageBubble ), message[ msg ] )

          gamePanel.stopExecutionListeners()
          if ( ( from == "transitionState" ) and ( wait ) ) then 
            timer.performWithDelay( wait, animation[animationName] )
          else
            animation[animationName]()
          end
        end,

      on_transitionEvent = 
        function( self, event, from, to ) 
          local _, _, animationName = self.from:match( "([^,]+)_([^,]+)_([^,]+)" ) 
          
          gamePanel.stopExecutionListeners()
          --[[if ( ( animationName ) and ( animationName == "handExecuteAnimation" ) ) then
            transition.fadeOut( messageBubble, { time = 400 } )
          end]]

          if ( ( messageBubble ) and ( messageBubble.text ) ) then
            transition.fadeOut( messageBubble.text, { time = 400 } )
            transition.fadeOut( messageBubble, { time = 400 } )
            messageBubble.text:removeSelf()
            messageBubble.text = nil
            transition.cancel( messageBubble.blinkingDart )
            messageBubble.blinkingDart.alpha = 0
            messageBubble.blinkingDart = nil
          end
          executeTutorial()
        end,

      on_showFeedback = 
        function( self, event, from, to ) 
            local from, wait, _ = self.from:match( "([^,]+)_([^,]+)_([^,]+)" )

            gamePanel.stopExecutionListeners()
            if ( ( from == "transitionState" ) and ( wait ) ) then 
              timer.performWithDelay( wait, executeTutorial )
            else
              executeTutorial()
            end
          end,

      on_nextTutorial = 
        function( self, event, from, to ) 
          bikeTutorial()
        end,

      on_saveGame = 
        function( self, event, from, to ) 
          miniGameData.controlsTutorial = "complete"
          --gameState:save( miniGameData )
          executeTutorial()
        end,
    }
  })

  mom = house:findObject( "mom" )
  mom.originalX = mom.x 
  mom.originalY = mom.y
  
  tutorialFSM.showAnimation()
  --timer.performWithDelay( animation[tutorialFSM.current](), executeTutorial )
  

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
    elseif ( ( obj1.myName == "puzzle" ) and ( obj2.myName == "character" ) ) then
      if ( collectedPieces[obj1.puzzleNumber] == nil ) then 
        puzzle.bigPieces[obj1.puzzleNumber].alpha = 1
        puzzle.littlePieces[ obj1.puzzleNumber ].alpha = 0
        collectedPieces[ obj1.puzzleNumber ] = puzzle.littlePieces[ obj1.puzzleNumber ]
        local remainingPieces = puzzle.littlePieces.count - (collectedPieces.count + 1)

        collectedPieces.last = obj1.puzzleNumber
        if ( ( collectedPieces.count ~= 0 ) and ( remainingPieces > 0 ) ) then
          executeTutorial()
        elseif ( remainingPieces <= 0 ) then 
          executeTutorial( _, "transitionEvent" )
        end
        collectedPieces.count = collectedPieces.count + 1

      end 
    elseif ( ( obj1.myName == "character" ) and ( obj2.myName == "puzzle" ) ) then 
      if ( collectedPieces[obj2.puzzleNumber] == nil ) then
        puzzle.bigPieces[obj2.puzzleNumber].alpha = 1
        puzzle.littlePieces[ obj2.puzzleNumber ]. alpha = 0
        collectedPieces[ obj2.puzzleNumber ] = puzzle.littlePieces[ obj2.puzzleNumber ]
        local remainingPieces = puzzle.littlePieces.count - (collectedPieces.count + 1)

        collectedPieces.last = obj2.puzzleNumber
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

  house:removeSelf()
  house = nil 

  if ( ( messageBubble ) and ( messageBubble.text ) ) then
    messageBubble.text:removeSelf()
    messageBubble.text = nil 
  end

  tutorialFSM = nil 
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

  --miniGameData.controlsTutorial = "complete"
  --miniGameData.bikeTutorial = "incomplete"
  --miniGameData.isComplete = false

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
