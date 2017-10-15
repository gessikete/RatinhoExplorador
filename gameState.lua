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

local stepDuration = 80

-- -----------------------------------------------------------------------------------
-- Funções
-- -----------------------------------------------------------------------------------
function M.new(  currentMiniGame, character, onCollision )
	local loadingScreen = nil 

	-- Salva o estado atual do jogo
	function M:save( steppingX, steppingY )
	  	local gameState = persistence.loadGameFile( )

	  	if ( gameState ) then
	  		print( "SALVANDO ESTADO DO JOGO" )
	  		gameState.currentMiniGame = currentMiniGame
	  		gameState.character.steppingX = steppingX
	  		gameState.character.steppingY = steppingY 

	  		persistence.saveGameFile( gameState )
		end
	end

	-- Ações que devem ser tomadas após o fim do carregamento
	local function finishedLoading( )
	  -- Retira imagem de carregamento (uma vez que a transição para o último ponto salvo se finalizou)
	  if ( loadingScreen ) then
	    transition.fadeOut( loadingScreen, { time = 800, onComplete = function( ) loadingScreen:removeSelf( ) loadingScreen = nil end } )
	  end
	  -- Adiciona o listener das colisões, já que o personagem já está no ponto certo do mapa
	  Runtime:addEventListener( "collision", onCollision )
	  
	  -- Salva o estado atual
	  M:save( character.steppingX, character.steppingY )

	  print( "----------------------- FIM DO CARREGAMENTO -----------------------" )
	end

	-- Carrega um jogo salvo, posicionando o personagem no lugar correto
	function M:load( )
		local loadingMiniGame = currentMiniGame
		gameFile = persistence.loadGameFile( )

		print( "CARREGANDO MINIGAME: " .. currentMiniGame )

	  	if ( gameFile ~= nil ) then 
		    if ( gameFile.currentMiniGame == loadingMiniGame ) then 
		      local defaultLoadingData = json.decodeFile(system.pathForFile("tiled/loading.json", system.ResourceDirectory))  -- load from json export
		      loadingScreen = tiled.new(defaultLoadingData, "tiled")
		      fitScreen:fitBackground( loadingScreen )
		    elseif ( gameFile.currentMiniGame == "house" ) then 
		      	local loadingHouseData = json.decodeFile(system.pathForFile("tiled/loadingHouse.json", system.ResourceDirectory))
		      	loadingScreen = tiled.new(loadingHouseData, "tiled")
		      	fitScreen:fitDefault( loadingScreen )
		    elseif ( gameFile.currentMiniGame == "map" ) then
		      	local loadingMapData = json.decodeFile(system.pathForFile("tiled/loadingMap.json", system.ResourceDirectory))
	    		loadingScreen = tiled.new(loadingMapData, "tiled")
	    		fitScreen:fitMap( loadingScreen )
		    end

		    local startingPointX, startingPointY = persistence.startingPoint( loadingMiniGame )
		    local goBackPointX, goBackPointY = persistence.goBackPoint( loadingMiniGame, gameFile )
		    local stepsX = math.ceil( ( goBackPointX - startingPointX ) / tilesSize )
		    local stepsY = math.ceil( ( goBackPointY - startingPointY ) / tilesSize )
		    local time
		    if ( math.abs(stepsX) > math.abs(stepsY) ) then 
		        time = math.abs(stepsX) * stepDuration
		    else 
		        time = math.abs(stepsY) * stepDuration
		    end  

		    print( "PREPARANDO PERSONAGEM" )
		    transition.to( character, {time = time, x = character.x + stepsX * tilesSize, y =  character.y + stepsY * tilesSize, onComplete = timer.performWithDelay( time, finishedLoading ) } )
		    character.steppingX = goBackPointX
		    character.steppingY = goBackPointY
		else 
		    print("Arquivo do jogo vazio")
		    finishedLoading( nil, onCollision )
	  	end  
	end
end

return M

