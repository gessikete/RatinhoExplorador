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
	local character = { steppingX, steppingY, flipped } 
	local house = { isComplete, controlsTutorial, collectedPieces, bikeTutorial }
	local school = { isComplete }
	local restaurant = { isComplete }
	local default = { character = character, house = house, restaurant = restaurant, school = school }

	default.character.flipped = false
	default.character.steppingX, default.character.steppingY = M.startingPoint( "house" )
	default.currentMiniGame = "house" 

	default.house.isComplete = false
	default.house.controlsTutorial = "incomplete"
	default.house.bikeTutorial = "incomplete"

	default.school.isComplete = false

	default.restaurant.isComplete = false

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
	GBCDataCabinet.load(fileName)
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
		GBCDataCabinet.deleteCabinet(files[i], true)
		table.remove( files )
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
	end
end

-- Informa onde o character irá se posicionar dependendo de onde ele entrou/saiu ou pausou
-- o jogo anteriormente
function M.goBackPoint( currentMiniGame, previousMiniGameFile )
	local houseExitX, houseExitY = 336, 208
	local houseEntranceX, houseEntranceY = 80, 304
	local houseMapExitX, houseMapExitY = 144, 96   
	local houseMapEntranceX, houseMapEntranceY = 80, 160

	local schoolExitX, schoolExitY = 336, 208
	local schoolEntranceX, schoolEntranceY = 80, 272
	local schoolMapExitX, schoolMapExitY = 144, 96   
	local schoolMapEntranceX, schoolMapEntranceY = 80, 160

	local flipped = false 

	if ( currentMiniGame == previousMiniGameFile.currentMiniGame ) then
		return previousMiniGameFile.character.steppingX, previousMiniGameFile.character.steppingY, previousMiniGameFile.character.flipped
	elseif ( ( previousMiniGameFile.currentMiniGame == "house" ) and ( currentMiniGame ~= "map" ) ) then
		return M.startingPoint( currentMiniGame )
	elseif ( currentMiniGame == "map" ) then 
		if ( previousMiniGameFile.currentMiniGame == "house" ) then
			if ( previousMiniGameFile.character.steppingX == houseExitX  ) then 
				return houseMapExitX, houseMapExitY, flipped
			else 
				return houseMapEntranceX, houseMapEntranceY, flipped
			end 
		end
	elseif ( currentMiniGame == "house" ) then
		if ( previousMiniGameFile.character.steppingX == houseMapExitX ) then
			flipped = true 
			return houseExitX, houseExitY, flipped
		else
			return houseEntranceX, houseEntranceY, flipped
		end 
	elseif ( currentMiniGame == "school" ) then
		if ( previousMiniGameFile.character.steppingX == schoolMapExitX ) then
			flipped = true 
			return schoolExitX, schoolExitY, flipped
		else
			return schoolEntranceX, schoolEntranceY, flipped
		end 
	end 
end

function M.addInstructionsTable( direction, steps )

end

return M