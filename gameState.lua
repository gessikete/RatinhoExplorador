module(..., package.seeall)

local persistence = require "persistence"

local tiled = require "com.ponywolf.ponytiled"

local json = require "json"

local fitScreen = require "fitScreen"

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local M = { }

local tilesSize = 32

local stepDuration = 150

-- -----------------------------------------------------------------------------------
-- Funções
-- -----------------------------------------------------------------------------------
function M.new(  currentMiniGame, character, onCollision )
	local loadingScreen = nil 

	-- Salva o estado atual do jogo
	function M:save()
	  	local gameState = persistence.loadGameFile()

	  	if ( gameState ) then
	  		print( "SALVANDO ESTADO DO JOGO" )
	  		gameState.currentMiniGame = currentMiniGame
	  		gameState.character.steppingX = character.steppingX 
	  		gameState.character.steppingY = character.steppingY
	  		gameState.character.flipped = character.flipped 

	  		persistence.saveGameFile( gameState )
		end
	end

	-- Carrega um jogo salvo, posicionando o personagem no lugar correto
	function M:load()
		local loadingMiniGame = currentMiniGame
		gameFile = persistence.loadGameFile()

		print( "CARREGANDO MINIGAME: " .. currentMiniGame )

	  	if ( gameFile ~= nil ) then 
	  		local startingPointX, startingPointY = persistence.startingPoint( loadingMiniGame )
	  		local goBackPointX, goBackPointY, flipped = persistence.goBackPoint( loadingMiniGame, gameFile )
	  		-- Apresenta uma imagem de carregamento enquanto o personagem é posicionado
		    --[[if ( gameFile.currentMiniGame == loadingMiniGame ) then 
		      local defaultLoadingData = json.decodeFile(system.pathForFile("tiled/loading.json", system.ResourceDirectory))  -- load from json export
		      loadingScreen = tiled.new(defaultLoadingData, "tiled")
		      fitScreen.fitBackground( loadingScreen )
		    elseif ( gameFile.currentMiniGame == "house" ) then 
		      	local loadingHouseData = json.decodeFile(system.pathForFile("tiled/loadingHouse.json", system.ResourceDirectory))
		      	loadingScreen = tiled.new(loadingHouseData, "tiled")
		      	fitScreen.fitDefault( loadingScreen )
		    elseif ( gameFile.currentMiniGame == "map" ) then
		      	local loadingMapData = json.decodeFile(system.pathForFile("tiled/loadingMap.json", system.ResourceDirectory))
	    		loadingScreen = tiled.new(loadingMapData, "tiled")
	    		fitScreen.fitMap( loadingScreen )
		    end]]

		    print( "PREPARANDO PERSONAGEM" )
			character.x = character.x + ( goBackPointX - startingPointX )
			character.y = character.y + (goBackPointY - startingPointY )
			character.flipped = flipped
	  		character.steppingX = goBackPointX
	  		character.steppingY = goBackPointY

	  		gameFile.currentMiniGame = currentMiniGame
	  	end  

	  	 -- Retira imagem de carregamento (uma vez que a transição para o último ponto salvo se finalizou)
	  	if ( loadingScreen ) then
	    	transition.fadeOut( loadingScreen, { time = 800, onComplete = function() loadingScreen:removeSelf() loadingScreen = nil end } )
	  	end

	  	-- Salva o estado atual
	  	M:save()
	  	
	  	-- Adiciona o listener das colisões, já que o personagem já está no ponto certo do mapa
	  	--Runtime:addEventListener( "collision", onCollision )

	  	print( "----------------------- FIM DO CARREGAMENTO -----------------------" )
	end
end

return M

