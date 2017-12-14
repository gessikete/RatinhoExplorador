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

local listenersModule = require "listeners"

local listeners = listenersModule:new()
physics.start()
physics.setGravity( 0, 0 )

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local house 

local character

local mom 

local tilesSize = 32

local stepDuration = 50

local puzzle = { bigPieces = { }, littlePieces = { count }, puzzleSensors = { }, collectedPieces = { count = 0 } }

local collision = false 

local miniGameData

local originalMiniGameData

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
    if ( ( ( obj1.myName == "puzzle" ) and ( obj2.isCharacter ) ) or ( ( obj1.isCharacter ) and ( obj2.myName == "puzzle" ) ) ) then
      if ( obj1.myName == "puzzle" ) then obj = obj1 else obj = obj2 end 

      if ( puzzle.collectedPieces[obj.puzzleNumber] == nil ) then 
        puzzle.bigPieces[obj.puzzleNumber].alpha = 1
        puzzle.littlePieces[ obj.puzzleNumber ].alpha = 0
        puzzle.collectedPieces[ obj.puzzleNumber ] = puzzle.littlePieces[ obj.puzzleNumber ]
        local remainingPieces = puzzle.littlePieces.count - (puzzle.collectedPieces.count + 1)

        puzzle.collectedPieces.last = obj.puzzleNumber
        if ( ( puzzle.collectedPieces.count ~= 0 ) and ( remainingPieces > 0 ) ) then
          houseFSM.update()
        elseif ( remainingPieces <= 0 ) then 
          houseFSM.update( _, "transitionEvent" )
        end
        puzzle.collectedPieces.count = puzzle.collectedPieces.count + 1

      end 

    -- Volta para o mapa quando o personagem chega na saída/entrada da casa
    elseif ( ( ( obj1.myName == "exit" ) and ( obj2.isCharacter ) ) or ( ( obj1.isCharacter ) and ( obj2.myName == "exit" ) ) ) then 
      if ( miniGameData.isComplete == true ) then
        transition.cancel( character )
        character.stepping.point = "exit"
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 1000, sceneTransition.gotoMap )

      elseif ( ( miniGameData.controlsTutorial == "complete" ) and ( houseFSM.fsm ) ) then
        local _, animationName = houseFSM.fsm.current:match( "([^,]+)_([^,]+)" ) 

        if ( animationName == "handExitAnimation" ) then
          transition.fadeOut( gamePanel.exitHand, { time = 450 } )
          houseFSM.update()
        end
      end

    elseif ( ( ( obj1.myName == "entrance" ) and ( obj2.isCharacter ) ) or ( ( obj1.isCharacter ) and ( obj2.myName == "entrance" ) ) ) then 
      if ( miniGameData.isGameComplete == true ) then
        transition.cancel( character )
        character.stepping.point = "entrance"
        instructions:destroyInstructionsTable()
        gamePanel:stopAllListeners()
        timer.performWithDelay( 1000, sceneTransition.gotoMap )
      end
    -- Colisão entre o personagem e os sensores dos tiles do caminho
    elseif ( ( ( obj1.isCharacter ) and ( obj2.isPath ) ) or ( ( obj2.isCharacter ) and ( obj1.isPath ) ) ) then
      local obj 
      if ( obj1.isPath ) then obj = obj1 else obj = obj2 end
      character.stepping = obj
      character.stepping.point = "point"
      path:showTile( obj.myName )

    -- Colisão com os demais objetos e o personagem (rope nesse caso)
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

      if ( ( miniGameData.isComplete == false ) and ( houseFSM.fsm.current ~= "feedbackAnimation" ) ) then 
        if ( obj.isWall ) then 
          local message = { "Ei, você não pode andar por aí!", "Cuidado com as paredes." }
          houseFSM.showText( house:findObject( "momBubble" ), message, house:findObject( "mom" ) ) 

        elseif ( obj.isFloor ) then 
          local message = { "Ei, você não pode andar por aí!", "Ande apenas nos quadrados", "azuis." }
          houseFSM.showText( house:findObject( "momBubble" ), message, house:findObject( "mom" ) ) 
        end
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

  house:removeSelf()
  house = nil 

  if ( ( messageBubble ) and ( messageBubble.text ) ) then
    messageBubble.text:removeSelf()
    messageBubble.text = nil 
  end

  if ( ( houseFSM ) and ( houseFSM.destroy ) ) then 
    houseFSM.destroy()
  end
end

-- -----------------------------------------------------------------------------------
-- Cenas
-- -----------------------------------------------------------------------------------
-- create()
function scene:create( event )
	local sceneGroup = self.view

	house, character, gamePanel, gameState, path, instructions, instructionsTable, miniGameData = gameScene:set( "house" )

  sceneGroup:insert( house )
  sceneGroup:insert( gamePanel.tiled )

  if ( miniGameData.onRepeat == true ) then
    if ( ( miniGameData.isGameComplete == false ) or ( ( miniGameData.isGameComplete == true ) and ( miniGameData.shownCompletion == true ) ) )  then 
      miniGameData.controlsTutorial = "incomplete"
      miniGameData.bikeTutorial = "incomplete"
      miniGameData.isComplete = false 
      originalMiniGameData = miniGameData
    end
  end

  if ( miniGameData.controlsTutorial == "incomplete" )  then 
    setPuzzle()
  end

end

-- show()
function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase


  mom = house:findObject( "mom" )
	if ( phase == "will" ) then
    if ( miniGameData.isComplete == true ) then
      if ( ( miniGameData.isGameComplete  == true ) and ( miniGameData.shownCompletion == false ) ) then 
        local brother, brotherPosition
        path:hidePath()
        if ( character == house:findObject( "ada") ) then 
          brother = house:findObject( "turing" )
        else
          brother = house:findObject( "ada") 
        end

        brotherPosition = house:findObject( "brotherEnding" )
        if ( miniGameData.wonSurprise == false )  then 
          brother.x, brother.y = brotherPosition.x, brotherPosition.y
          brother.xScale = -1
          brother.alpha = 1
        end
      else 
        mom.alpha = 1
        character.alpha = 1
        gamePanel:addDirectionListeners()
      end
    elseif ( miniGameData.controlsTutorial == "complete" ) then
		  gamePanel:addDirectionListeners()
    else 
      gamePanel.bikeWheel.alpha = 0
      mom.alpha = 1
      character.alpha = 1
    end
    listeners:add( Runtime, "collision", onCollision )

	elseif ( phase == "did" ) then
    if ( ( miniGameData.isGameComplete  == true ) and ( miniGameData.shownCompletion == false ) ) then 
      houseFSM.new( house, character, listeners, _, miniGameData, gameState, gamePanel, path )
      houseFSM.completeGame()
    elseif ( miniGameData.controlsTutorial == "complete" ) then
		  gamePanel:addButtonsListeners()
      gamePanel:addInstructionPanelListeners()

      if ( miniGameData.bikeTutorial == "incomplete" ) then
        mom.alpha = 1
        character.alpha = 1
        gamePanel:showBikewheel ( false )
        houseFSM.new( house, character, listeners, puzzle, miniGameData, gameState, gamePanel, path )
        houseFSM.bikeTutorial()
      end

    else
      if ( miniGameData.controlsTutorial == "incomplete" )  then
        houseFSM.new( house, character, listeners, puzzle, miniGameData, gameState, gamePanel, path )
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
    composer.removeScene( "house" )
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
