local tiled = require "com.ponywolf.ponytiled"

local physics = require "physics"

local json = require "json"

local gamePanel

local persistence = require "persistence"

local instructions = require "instructions"

local gameState = require "gameState"

local path = require "path"

local fitScreen = require "fitScreen"

physics.start()

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
    character.rope = rope 
  	ropeJoint = physics.newJoint( "rope", rope, character, 0, 0 )
    character.ropeJoint = ropeJoint
end

function M:set( miniGame )
  local miniGameData
	local tileMap 
	local fileName
	local fitTiled 
	local character
	local instructionsTable

	if ( miniGame == "map" ) then 
		fileName = "tiled/newmap.json"
		fit = fitScreen.fitMap
	elseif ( miniGame == "house" ) then 
		fileName = "tiled/house.json"
		fit = fitScreen.fitDefault
  elseif ( miniGame == "school" ) then 
    fileName = "tiled/school.json"
    fit = fitScreen.fitSchool
  elseif ( miniGame == "restaurant" ) then 
    fileName = "tiled/restaurant.json"
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
    local charName = persistence.loadGameFile().character.name 
    local charLayer = tileMap:findLayer("character")

    for i = 1, charLayer.numChildren do
      if ( charLayer[i].myName == persistence.loadGameFile().character.name ) then
        character = charLayer[i]
      end
    end

    --print( persistence.loadGameFile().character.name  )

    --character = tileMap:findObject("character")

  	gameState.new( miniGame, character, onCollision )

  	miniGameData = gameState:load()
    setCharacter( tileMap, character )

  	markedPath = path.new( tileMap )
  	path:setSensors()

  	instructionsTable = instructions.new( tilesSize, character, markedPath )

    if ( ( miniGame == "house" ) and ( ( miniGameData.isComplete == false ) or ( miniGameData.onRepeat == true ) ) ) then 
      gamePanel = require "gamePanelTutorial" 
    else
      gamePanel = require "gamePanel"
    end

  	gamePanel.tiled = gamePanel.new( instructions.executeInstructions, miniGameData )
  	instructions:setGamePanelListeners( gamePanel.stopExecutionListeners, gamePanel.restartExecutionListeners )
  	
  	return tileMap, character, gamePanel, gameState, path, instructions, instructionsTable, miniGameData
end

return M