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
	function M:save( miniGameData )
	  	local gameState = persistence.loadGameFile()

	  	if ( gameState ) then
	  		print( "SALVANDO ESTADO DO JOGO" )
	  		gameState.currentMiniGame = currentMiniGame
	  		gameState.character.stepping = character.stepping
	  		gameState.character.flipped = character.flipped 
 
	  		if ( miniGameData ) then
	  			if ( currentMiniGame == "house" ) then
	  				gameState.house = miniGameData
	  			elseif ( currentMiniGame == "school" ) then
	  				gameState.school = miniGameData
	  			elseif ( currentMiniGame == "restaurant" ) then
	  				gameState.restaurant = miniGameData
	  			elseif ( currentMiniGame == "map" ) then 
	  				gameState = miniGameData
	  				gameState.character.stepping = character.stepping
	  				gameState.character.flipped = character.flipped  
	  			end

	  		end

	  		persistence.saveGameFile( gameState )

		end
	end

	-- Carrega um jogo salvo, posicionando o personagem no lugar correto
	function M:load()
		local loadingMiniGame = currentMiniGame
		local miniGameData
		gameFile = persistence.loadGameFile()

		print( "CARREGANDO ARQUIVO: " .. persistence.getCurrentFileName() )
		print( "CARREGANDO MINIGAME: " .. currentMiniGame )

	  	if ( gameFile ~= nil ) then 
	  		--if ( ( currentMiniGame ~= "house" ) or ( gameFile.house.controlsTutorial == "complete" ) ) then 
		  		local startingPointX, startingPointY = persistence.startingPoint( loadingMiniGame )
		  		local goBackPointX, goBackPointY, flipped, point 

		  		if ( ( gameFile.house.onRepeat == true )  or ( gameFile.restaurant.onRepeat == true ) or ( gameFile.school.onRepeat == true ) ) then
		  		 	goBackPointX, goBackPointY, point, flipped = persistence.goBackPoint( loadingMiniGame, gameFile, true ) 
		  		else
		  			goBackPointX, goBackPointY, point, flipped = persistence.goBackPoint( loadingMiniGame, gameFile, false )
		  		end
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
				character.stepping = { }
		  		character.stepping.x = goBackPointX
		  		character.stepping.y = goBackPointY
				character.stepping.point = point 
				physics.addBody( character, "dynamic" )

		  		if ( character.flipped == true ) then
    				character.xScale = -1
  				end 

		  		gameFile.currentMiniGame = currentMiniGame
		  	--end

	  		if ( currentMiniGame == "house" ) then
	  			miniGameData = gameFile.house 
	  		elseif ( currentMiniGame == "school" ) then
	  			miniGameData = gameFile.school
	  		elseif ( currentMiniGame == "restaurant" ) then
	  			miniGameData = gameFile.restaurant
	  		elseif ( currentMiniGame == "map" ) then
	  			miniGameData = gameFile
	  		end
	  	end  

	  	 -- Retira imagem de carregamento (uma vez que a transição para o último ponto salvo se finalizou)
	  	if ( loadingScreen ) then
	    	transition.fadeOut( loadingScreen, { time = 800, onComplete = function() loadingScreen:removeSelf() loadingScreen = nil end } )
	  	end

	  	-- Salva o estado atual
	  	M:save( miniGameData ) 	

	  	print( "----------------------- FIM DO CARREGAMENTO -----------------------" )

	  	return miniGameData
	end
end

return M

