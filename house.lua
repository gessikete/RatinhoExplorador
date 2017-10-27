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

local widget = require "widget"

local fsm = require "com.fsm.src.fsm"

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

local miniGameData

local activeState

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
      timer.performWithDelay( 800, sceneTransition.gotoMap )

	  elseif ( ( ( obj1.myName == "entrace" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "entrance" ) ) ) then 
      transition.cancel()
      instructions:destroyInstructionsTable()
      gamePanel:stopAllListeners()
      timer.performWithDelay( 800, sceneTransition.gotoMap )

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
    puzzle.littlePieces[ littlePiecesLayer[i].myName ] = littlePiecesLayer[i]
  end
end

local controlsTutorialFSM
local scrollView
local animation = {}
local message = {}
local helpMessage = {}

local function executeControlsTutorial( event, alternativeEvent )
    if ( scrollView ) then 
      scrollView:removeSelf()
      scrollView = nil
    end

    if ( alternativeEvent ) then
      if ( alternativeEvent == "showHelpMessage" ) then
        controlsTutorialFSM.showHelpMessage()
        executeControlsTutorial()

      elseif ( alternativeEvent == "showMessage" ) then
        controlsTutorialFSM.showMessage()
      
      end

    else
      if ( controlsTutorialFSM.nextEvent == "showAnimation" ) then 
        controlsTutorialFSM.showAnimation()
        timer.performWithDelay( animation[controlsTutorialFSM.current](), executeControlsTutorial )

      elseif ( controlsTutorialFSM.nextEvent == "showMessage" ) then 
        controlsTutorialFSM.showMessage()
      
      elseif ( controlsTutorialFSM.nextEvent == "showMessageAndAnimation" ) then 
        controlsTutorialFSM.showMessageAndAnimation()
        local _, animationName = controlsTutorialFSM.current:match( "([^,]+)_([^,]+)" )
        local from, wait, n = controlsTutorialFSM.from:match( "([^,]+)_([^,]+)_([^,]+)" )
        
        if ( ( from == "transitionState" ) and ( wait ) ) then 
          timer.performWithDelay( wait, animation[animationName] )
        else
          animation[animationName]()
        end
      
      elseif ( controlsTutorialFSM.nextEvent == "transitionEvent" ) then 
        controlsTutorialFSM.transitionEvent()
        executeControlsTutorial()
      elseif ( controlsTutorialFSM.nextEvent == "showFeedback" ) then
      end
    end
end


local function scrollSpeechBubble( event )
  local phase = event.phase 



  if ( phase == "began" ) then
    event.target.touchOffset = event.y

  elseif ( phase == "moved" ) then 
    if ( ( event.y - event.target.touchOffset >= 15 ) and ( event.target.text.y ~= event.target.text.initialY ) ) then
      event.target.text.y = event.target.text.y + 15
      event.target.touchOffset = event.y
    end
  elseif ( phase == "ended" ) then
    --[[if ( ( event.target.text.height - (event.target.text.initialY - event.target.text.y) ) < ( event.target.height + 15 ) ) then
      -- Vai para o próximo estado
      if ( controlsTutorialFSM.event == "showMessage" ) then
      --transition.fadeOut( event.target.messageBubble, { time = 400, onComplete = executeControlsTutorial } )
      end
    elseif( event.y - event.target.touchOffset == 0 ) then 
      event.target.text.y = event.target.text.y - 15

    end]]
    if ( controlsTutorialFSM.event == "showMessage" ) then 
      event.target.messageBubble.alpha = 0
      executeControlsTutorial()
    end

  end

  return true 
end

local function showScrollView( messageBubble, text )
  local options = {
    text = text,
    x = 0, 
    y = 0,
    fontSize = 13,
    width = messageBubble.width - 27,
    height = 0,
    align = "left" 
  }

  if ( messageBubble.alpha == 0 ) then
    transition.fadeIn( messageBubble, { time = 400 } )
  end 

  local newText = display.newText( options ) 

  newText.x = newText.x + newText.width/2
  newText.y = newText.y + newText.height/2

  scrollView = widget.newScrollView( 
    {
      top = messageBubble.contentBounds.yMin + 10, 
      left = messageBubble.contentBounds.xMin + 15,
      width = messageBubble.width - 27,
      height = messageBubble.height/2 + 2,
      horizontalScrollDisabled = true,
      verticalScrollDisabled = true,
      hideBackground = true,
      listener = scrollSpeechBubble
    }
  )

  scrollView:insert( newText )
  scrollView.scrollPosition = 0
  newText.initialY = newText.y 
  scrollView.text =  newText
  scrollView.messageBubble = messageBubble
end 

local function momAnimation( )
  local time = 20
  transition.to( house:findObject("mom"), { time = time, x = character.x, y = character.y - tilesSize } )

  return time
end

local function handDirectionAnimation( i, time, hand, x, y )
  if ( ( i == 0 ) or ( hand.stopAnimation == true ) ) then
    transition.fadeOut( hand, { time = 400, onComplete = function() hand.x = hand.originalX hand.y = hand.originalY hand.stopAnimation = false end } )
    return 
  else 
    hand.x = hand.originalX
    hand.y = hand.originalY
    transition.to( hand, { time = time, x = x, y = y } )
    local closure = function ( ) return handDirectionAnimation( i - 1, time, hand, x, y ) end
    timer.performWithDelay(time + 400, closure)
  end
end

local function handDirectionAnimation1( )
  local hand = gamePanel.hand
  local box = gamePanel.firstBox
  local time = 1500

  if ( ( hand.x == hand.originalX ) and ( hand.y == hand.originalY ) ) then
    hand.alpha = 1
    hand.stopAnimation = false 

    handDirectionAnimation( 3, time, hand, hand.x, box.y - 5 )
    
  end
  gamePanel:addRightDirectionListener( executeControlsTutorial )
end

local function handDirectionAnimation2( )
  local hand = gamePanel.hand
  local box = gamePanel.secondBox
  local time = 1500

  if ( ( hand.x == hand.originalX ) and ( hand.y == hand.originalY ) ) then
    hand.alpha = 1
    hand.stopAnimation = false 

    handDirectionAnimation( 3, time, hand, hand.x, box.y - 5 )
    
  end
  gamePanel:addRightDirectionListener( executeControlsTutorial )
end


animation["momAnimation"] = momAnimation
animation["handDirectionAnimation1"] = handDirectionAnimation1
animation["handDirectionAnimation2"] = handDirectionAnimation2

message["msg1"] = "Tenho um presente para você. Encontre todas as peças de quebra-cabeça que escondi pela casa para descobrir o que é."
message["msg2"] = "Arraste a seta da direita para o retângulo laranja para andar um quadradinho"
message["msg3"] = "Muito bem! Arraste mais uma seta para completar o caminho."
message["help1"] = "Opa! Tome cuidado para arrastar a seta para o retângulo."
message["help2"] = message["help1"]

local function controlsTutorial( )
  controlsTutorialFSM = fsm.create({
    initial = "start",
    events = {
      {name = "showAnimation",  from = "start",  to = "momAnimation", nextEvent = "showMessage" },
      {name = "showMessage",  from = "momAnimation",  to = "msg1", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "msg1",  to = "msg2_handDirectionAnimation1", nextEvent = "transitionEvent" },
      {name = "showHelpMessage",  from = "msg2_handDirectionAnimation1",  to = "help1", nextEvent = "showMessageAndAnimation" },
      {name = "showHelpMessage",  from = "help1_handDirectionAnimation1",  to = "help1", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "help1",  to = "help1_handDirectionAnimation1", nextEvent = "transitionEvent" },
      {name = "transitionEvent",  from = "msg2_handDirectionAnimation1",  to = "transitionState_1500_1", nextEvent = "showMessageAndAnimation" },
      {name = "transitionEvent",  from = "help1_handDirectionAnimation1",  to = "transitionState_1500_1", nextEvent = "showMessageAndAnimation" },
      {name = "transitionEvent",  from = "help1",  to = "transitionState_1500_1", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "transitionState_1500_1",  to = "msg3_handDirectionAnimation2", nextEvent = "transitionEvent" },

      {name = "showHelpMessage",  from = "msg3_handDirectionAnimation2",  to = "help2", nextEvent = "showMessageAndAnimation" },
      {name = "showHelpMessage",  from = "help2_handDirectionAnimation2",  to = "help2", nextEvent = "showMessageAndAnimation" },
      {name = "showMessageAndAnimation",  from = "help2",  to = "help2_handDirectionAnimation2", nextEvent = "transitionEvent" },
      {name = "transitionEvent",  from = "msg3_handDirectionAnimation2",  to = "transitionState_1500_2" },
      {name = "transitionEvent",  from = "help2_handDirectionAnimation2",  to = "transitionState_1500_2" },
      {name = "transitionEvent",  from = "help2",  to = "transitionState_1500_2" },
      --{name = "showAnimation", from = "msg2", to = "animation2", nextEvent = "showMessage" },
      --{name = "showMessage",  from = "animation2",  to = "end" },
    },
    callbacks = {
      on_showMessage = function( self, event, from, to ) 
          showScrollView( house:findObject("message"), message[self.current] )
      end,
      on_showHelpMessage = function( self, event, from, to ) 
          showScrollView( house:findObject("message"), message[self.current] )
      end,
      on_showMessageAndAnimation = function( self, event, from, to )
        local msg, animationName = controlsTutorialFSM.current:match( "([^,]+)_([^,]+)" ) 
        showScrollView( house:findObject("message"), message[msg] )

        return animationName
      end
    }
  })

  controlsTutorialFSM.showAnimation()


  timer.performWithDelay( animation[controlsTutorialFSM.current](), executeControlsTutorial )

end
-- -----------------------------------------------------------------------------------
-- Cenas
-- -----------------------------------------------------------------------------------
-- create()
function scene:create( event )
	local sceneGroup = self.view

  persistence.setCurrentFileName( "ana" )

	house, character, rope, ropeJoint, gamePanel, gameState, path, instructions, instructionsTable, miniGameData = gameScene:set( "house", onCollision )

  if ( character.flipped == true ) then
    character.xScale = -1
  end

  setPuzzle()

  sceneGroup:insert( house )
  sceneGroup:insert( gamePanel.tiled )

  if ( miniGameData.controlsTutorial == "incomplete" ) then 
    --gamePanel.tiled.alpha = 0
  end
end

-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
    if ( miniGameData.isComplete == true ) then
		  gamePanel:addDirectionListeners()
    end

	elseif ( phase == "did" ) then
    if ( miniGameData.isComplete == true ) then
		  gamePanel:addButtonsListeners()
      gamePanel:addInstructionPanelListeners()

    else
      controlsTutorial()
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
