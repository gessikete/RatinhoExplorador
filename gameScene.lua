local tiled = require "com.ponywolf.ponytiled"

local physics = require "physics"

local json = require "json"

local gamePanel

local persistence = require "persistence"

local instructions = require "instructions"

local gameState = require "gameState"

local path = require "path"

local fitScreen = require "fitScreen"

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local M = { }

local tilesSize = 32

local function setCharacter( tileMap, character )
	local rope, ropeJoint

    physics.addBody( character, "dynamic" )
    character.gravityScale = 0

  	-- Objeto invisível que vai colidir com os objetos de colisão
  	-- @TODO: mudar posição e tamanho do rope quando substituirmos a imagem do personagem
  	rope = display.newRect( tileMap:findLayer("character"), character.x, character.y + 4, 25, 20 )
  	physics.addBody( rope ) 
  	rope.gravityScale = 0 
  	rope.myName = "rope"
  	rope.isVisible = false
  	ropeJoint = physics.newJoint( "rope", rope, character, 0, 0 )

  	return rope, ropeJoint
end

function M:set( miniGame, onCollision, sceneGroup )
  local miniGameData
	local tileMap 
	local fileName
	local fitTiled 
	local character
	local rope 
	local ropeJoint
	local instructionsTable

	if ( miniGame == "map" ) then 
		fileName = "tiled/newmap.json"
		fit = fitScreen.fitMap
	elseif ( miniGame == "house" ) then 
		fileName = "tiled/house.json"
		fit = fitScreen.fitDefault
	end

  	-- Cria mapa a partir do arquivo JSON exportado pelo tiled
  	display.setDefault("magTextureFilter", "nearest")
  	display.setDefault("minTextureFilter", "nearest")
  	local tiledData = json.decodeFile(system.pathForFile(fileName, system.ResourceDirectory))

  	tileMap = tiled.new( tiledData, "tiled" )

  	if ( fit ) then  
  		fit( tileMap )
  	end 

    -- lembrar: o myName (para os listeners) foi definido
    -- no próprio tiled
    character = tileMap:findObject("character")

  	gameState.new( miniGame, character, onCollision )

  	miniGameData = gameState:load()
    rope, ropeJoint = setCharacter( tileMap, character )

  	markedPath = path.new( tileMap )
  	path:setSensors()

  	instructionsTable = instructions.new( tilesSize, character, markedPath )

    if ( ( miniGame == "house" ) and ( miniGameData.isComplete == false ) ) then 
      gamePanel = require "gamePanelTutorial" 
    else
      gamePanel = require "gamePanel"
    end

  	gamePanel.tiled = gamePanel.new( instructions.executeInstructions )
  	instructions:setGamePanelListeners( gamePanel.stopExecutionListeners, gamePanel.restartExecutionListeners )
  	
    Runtime:addEventListener( "collision", onCollision )
  	--@TODO: TIRAR ISSO QUANDO ACABAREM OS TESTES COM A TELA
  	--local dragable = require "com.ponywolf.plugins.dragable"
  	--map = dragable.new(map)
  	return tileMap, character, rope, ropeJoint, gamePanel, gameState, path, instructions, instructionsTable, miniGameData
end

return M