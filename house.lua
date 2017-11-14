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

local houseFSM = require "fsm.miniGames.houseFSM"

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

local puzzle = { bigPieces = { }, littlePieces = { count }, puzzleSensors = { }, collectedPieces = { count = 0 } }

local collision = false 

local miniGameData

local originalMiniGameData

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
      if ( puzzle.collectedPieces[obj1.puzzleNumber] == nil ) then 
        puzzle.bigPieces[obj1.puzzleNumber].alpha = 1
        puzzle.littlePieces[ obj1.puzzleNumber ].alpha = 0
        puzzle.collectedPieces[ obj1.puzzleNumber ] = puzzle.littlePieces[ obj1.puzzleNumber ]
        local remainingPieces = puzzle.littlePieces.count - (puzzle.collectedPieces.count + 1)

        puzzle.collectedPieces.last = obj1.puzzleNumber
        if ( ( puzzle.collectedPieces.count ~= 0 ) and ( remainingPieces > 0 ) ) then
          houseFSM.update()
        elseif ( remainingPieces <= 0 ) then 
          houseFSM.update( _, "transitionEvent" )
        end
        puzzle.collectedPieces.count = puzzle.collectedPieces.count + 1

      end 
    elseif ( ( obj1.myName == "character" ) and ( obj2.myName == "puzzle" ) ) then 
      if ( puzzle.collectedPieces[obj2.puzzleNumber] == nil ) then
        puzzle.bigPieces[obj2.puzzleNumber].alpha = 1
        puzzle.littlePieces[ obj2.puzzleNumber ]. alpha = 0
        puzzle.collectedPieces[ obj2.puzzleNumber ] = puzzle.littlePieces[ obj2.puzzleNumber ]
        local remainingPieces = puzzle.littlePieces.count - (puzzle.collectedPieces.count + 1)

        puzzle.collectedPieces.last = obj2.puzzleNumber
        if ( ( puzzle.collectedPieces.count ~= 0 ) and ( remainingPieces > 0 ) ) then
          houseFSM.update()
        elseif ( remainingPieces <= 0 ) then 
          houseFSM.update( _, "transitionEvent" )
        end
        puzzle.collectedPieces.count = puzzle.collectedPieces.count + 1
      end

    -- Volta para o mapa quando o personagem chega na saída/entrada da casa
    elseif ( ( ( obj1.myName == "exit" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "exit" ) ) ) then 
      print( houseFSM.tutorialFSM )
      if ( miniGameData.isComplete == true ) then
        transition.cancel()
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 800, sceneTransition.gotoMap )

      elseif ( ( miniGameData.controlsTutorial == "complete" ) and ( houseFSM.tutorialFSM ) )then
        local _, animationName = houseFSM.tutorialFSM.current:match( "([^,]+)_([^,]+)" ) 

        if ( animationName == "handExitAnimation" ) then
          transition.fadeOut( gamePanel.exitHand, { time = 450 } )
          houseFSM.update()
        end
      end

    elseif ( ( ( obj1.myName == "entrance" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "entrance" ) ) ) then 
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

  houseFSM.tutorialFSM = nil 
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
   
  --miniGameData.controlsTutorial = "incomplete"
  --miniGameData.bikeTutorial = "incomplete"
  --miniGameData.isComplete = false

  sceneGroup:insert( house )
  sceneGroup:insert( gamePanel.tiled )

  if ( miniGameData.onRepeat == true ) then
    miniGameData.controlsTutorial = "incomplete"
    miniGameData.bikeTutorial = "incomplete"
    miniGameData.isComplete = false 
    originalMiniGameData = miniGameData
  end

  if ( miniGameData.controlsTutorial == "incomplete" )  then 
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
        houseFSM.new( house, puzzle, miniGameData, gameState, gamePanel, path, puzzle )
        houseFSM.bikeTutorial()
      end

    else
      if ( miniGameData.controlsTutorial == "incomplete" )  then
        houseFSM.new( house, puzzle, miniGameData, gameState, gamePanel, path )
        houseFSM.controlsTutorial()
      end
    end
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		physics.stop( )
    if ( miniGameData.onRepeat == true ) then
      miniGameData.onRepeat = false

      if ( miniGameData.isComplete == false ) then 
        miniGameData = originalMiniGameData
      end
    end
  
		gameState:save( miniGameData )
		destroyScene()
	elseif ( phase == "did" ) then
    composer.removeScene( "house" )
	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	--gamePanel:removegotoMenuButton()
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
