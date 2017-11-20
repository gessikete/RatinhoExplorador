module(..., package.seeall)

local GBCDataCabinet = require("plugin.GBCDataCabinet")

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local M = { }

GBCDataCabinet.createCabinet( "currentFileName"  )

-- -----------------------------------------------------------------------------------
-- Funções referentes à persistência dos arquivos
-- -----------------------------------------------------------------------------------
-- Retorna uma lista com os nomes dos arquivos de jogo salvos
function M.filesNames()
	if ( GBCDataCabinet.load( "files" ) == true ) then
		return GBCDataCabinet.get( "files", "names" )
	end
end

-- Retorna um arquivo de jogo com os valores "default" de um jogo novo
function defaultFile()
	local character = { stepping = { x, y, point }, flipped } 
	local house = { isComplete, controlsTutorial, collectedPieces, bikeTutorial, stars }
	local school = { isComplete, stars }
	local restaurant = { isComplete }
	local default = { character = character, house = house, restaurant = restaurant, school = school }

	default.character.flipped = false
	default.character.stepping.x, default.character.stepping.y = M.startingPoint( "house" )
	default.character.stepping.point = "exit"
	default.currentMiniGame = "house" 

	default.house.isComplete = false
	default.house.controlsTutorial = "incomplete"
	default.house.bikeTutorial = "incomplete"
	default.house.stars = 0
	default.house.previousStars = 0 

	default.school.isComplete = false
	default.school.stars = 0
	default.school.previousStars = 0

	default.restaurant.isComplete = false
	default.restaurant.stars = 0
	default.restaurant.previousStars = 0 

	return default
end

-- Cria um jogo novo
function M.newGameFile( newFileName )
	local files = { }

	-- Verifica se a lista de jogos salvos existe. Caso não exista, ela é criada 
	if ( GBCDataCabinet.load( "files" ) == false ) then
		GBCDataCabinet.createCabinet( "files" )
		GBCDataCabinet.set( "files", "names", files )
	end

	files = GBCDataCabinet.get( "files", "names" )

	-- Insere um novo nome da lista de jogos salvos
	table.insert( files,  newFileName )

	-- Cria um cabinet para o novo jogo e já adiciona um estado de jogo default
	GBCDataCabinet.createCabinet( newFileName )
	GBCDataCabinet.set( newFileName, "gameState", defaultFile() )

	-- Salva a lista com os nomes dos arquivos e o novo cabinet do jogo
	GBCDataCabinet.save( "files" )
	GBCDataCabinet.save( newFileName )

	-- Define o nome do jogo atual para ser acessado pelas cenas
	M.setCurrentFileName( newFileName )


	--M.deleteFiles()
end

-- Salva o estado atual do jogo
function M.saveGameFile( gameState )
	local fileName = M.getCurrentFileName()

	GBCDataCabinet.set( fileName, "gameState", gameState )
	GBCDataCabinet.save( fileName )
end

-- Retorna um arquivo salvo
function M.loadGameFile()
	local fileName = M.getCurrentFileName()
	GBCDataCabinet.load( fileName )
	return GBCDataCabinet.get( fileName, "gameState" )
end

-- Define nome do arquivo atual que será acessado pelas cenas
function M.setCurrentFileName( fileName )
	GBCDataCabinet.set( "currentFileName", "name", fileName )
	GBCDataCabinet.save( "currentFileName" )
end

-- Retorna arquivo atual
function M.getCurrentFileName()
	return GBCDataCabinet.get( "currentFileName", "name" )
end

-- Deleta os arquivos de jogo
function M.deleteFiles()
	local files
	GBCDataCabinet.load( "files" )

	files = GBCDataCabinet.get( "files", "names" )
	for i = #files, 1, -1 do
		GBCDataCabinet.load( files[i] )
		GBCDataCabinet.deleteCabinet(files[i], true)
		table.remove( files )
	end

	GBCDataCabinet.save( "files" )
end

-- Deleta arquivo único
function M.deleteFile( fileName )
	local files
	GBCDataCabinet.load( "files" )

	files = GBCDataCabinet.get( "files", "names" )
	
	GBCDataCabinet.load( fileName )
	GBCDataCabinet.deleteCabinet( fileName, true )
	for i = 1, #files do
		if ( files[i] == fileName ) then 
			table.remove( files, i )
			break
		end
	end

	GBCDataCabinet.save( "files" )
end 

-- -----------------------------------------------------------------------------------
-- Funções referentes à persistência dos estados do jogo
-- -----------------------------------------------------------------------------------
-- Retorna o ponto inicial do minijogo atual
function M.startingPoint( currentMiniGame )
	if ( currentMiniGame == "map" ) then 
		return 144, 96
	elseif ( currentMiniGame == "house" ) then 
		return 80, 304
	elseif ( currentMiniGame == "school" ) then 
		return 80, 272
	elseif ( currentMiniGame == "restaurant" ) then 
		return 304, 336 - 64
	end
end

function M.mapProgress( position, miniGame ) 
	if ( position == "entrance" ) then 
		if ( miniGame == "house" ) then return 80, 160
		elseif ( miniGame == "school" ) then return 240, 160
		elseif ( miniGame == "restaurant" ) then return 304, 288 end
	elseif ( position == "exit" ) then 
		if ( miniGame == "house" ) then return 144, 96
		elseif ( miniGame == "school" ) then return 336, 160 
		elseif ( miniGame == "restaurant" ) then return 208, 288 end
	end
end

-- Informa onde o character irá se posicionar dependendo de onde ele entrou/saiu ou pausou
-- o jogo anteriormente
function M.goBackPoint( currentMiniGame, previousMiniGameFile, onRepeat )
	local houseExitX, houseExitY = 336, 208
	local houseEntranceX, houseEntranceY = 80, 304
	local houseMapExitX, houseMapExitY = M.mapProgress( "exit", "house" )   
	local houseMapEntranceX, houseMapEntranceY = M.mapProgress( "entrance", "house" )

	local schoolExitX, schoolExitY = 304, 336
	local schoolEntranceX, schoolEntranceY = 48, 272
	local schoolMapExitX, schoolMapExitY = M.mapProgress( "exit", "school" )   
	local schoolMapEntranceX, schoolMapEntranceY =  M.mapProgress( "entrance", "school" )

	local restaurantMapExitX, restaurantMapExitY = M.mapProgress( "exit", "restaurant" )   
	local restaurantMapEntranceX, restaurantMapEntranceY =  M.mapProgress( "entrance", "restaurant" )
	local restaurantExitX, restaurantExitY = 48, 272
	local restaurantEntranceX, restaurantEntranceY = 304, 336

	local startingPointX, startingPointY = M.startingPoint( currentMiniGame )

	local entrance, exit = "entrance", "exit"

	local flipped = false 

	if ( onRepeat == true ) then
		return startingPointX, startingPointY, entrance, flipped
	elseif ( currentMiniGame == previousMiniGameFile.currentMiniGame ) then
		--return schoolEntranceX, schoolEntranceY, flipped --TIRAR
		--return houseMapExitX, houseMapExitY, flipped --TIRAR
		return previousMiniGameFile.character.stepping.x, previousMiniGameFile.character.stepping.y, previousMiniGameFile.character.stepping.point, previousMiniGameFile.character.flipped
	elseif ( currentMiniGame == "map" ) then 
		if ( previousMiniGameFile.currentMiniGame == "house" ) then
			if ( previousMiniGameFile.character.stepping.point == exit  ) then 
				return houseMapExitX, houseMapExitY, exit, flipped
			else 
				return houseMapEntranceX, houseMapEntranceY, entrance, flipped
			end
		elseif ( previousMiniGameFile.currentMiniGame == "school" ) then 
			if ( previousMiniGameFile.character.stepping.point == exit  ) then 
				return schoolMapExitX, schoolMapExitY, exit, flipped
			else 
				flipped = true 
				return schoolMapEntranceX, schoolMapEntranceY, entrance, flipped
			end
		end
		return houseMapExitX, houseMapExitY, flipped
	elseif ( currentMiniGame == "house" ) then
		if ( previousMiniGameFile.character.stepping.point == exit ) then
			flipped = true 
			return houseExitX, houseExitY, exit, flipped
		else
			return houseEntranceX, houseEntranceY, entrance, flipped
		end 
	elseif ( currentMiniGame == "school" ) then
		if ( previousMiniGameFile.character.stepping.point == exit ) then
			flipped = true 
			return schoolExitX, schoolExitY, exit, flipped
		else
			return schoolEntranceX, schoolEntranceY, entrance, flipped
		end 
	elseif ( currentMiniGame == "restaurant" ) then
		if ( previousMiniGameFile.character.stepping.point == exit ) then
			flipped = true 
			return restaurantExitX, restaurantExitY, exit, flipped
		else
			return restaurantEntranceX, restaurantEntranceY, entrance, flipped
		end 
	end 
end

function M.addInstructionsTable( direction, steps )

end

return M