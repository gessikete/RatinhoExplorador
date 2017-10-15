module(..., package.seeall)

local GBCDataCabinet = require("plugin.GBCDataCabinet")

local M = { }

GBCDataCabinet.createCabinet( "currentFileName"  )

function M.filesNames( )
	if ( GBCDataCabinet.load( "files" ) == true ) then
		return GBCDataCabinet.get( "files", "names" )
	end
end

function defaultFile( )
	local default = { character = { steppingX, steppingY } }
	
	default.character.steppingX = 144
	default.character.steppingY = 96
	default.currentMiniGame = "map" 

	return default
end

function M.startingPoint( currentMiniGame )
	if ( currentMiniGame == "map" ) then 
		return 144, 96
	elseif ( currentMiniGame == "house" ) then 
		return 368, 144
	end
end

-- Informa onde o character irá se posicionar dependendo de onde ele saiu/entrou no último minigame
function M.goBackPoint( currentMiniGame, previousMiniGameFile )
	local houseExitX, houseExitY = 368, 144
	local houseMapExitX, houseMapExitY = 144, 96 
	local houseEntranceX, houseEntranceY = 16, 304  
	local houseMapEntranceX, houseMapEntranceY = 80, 160

	if ( currentMiniGame == previousMiniGameFile.currentMiniGame ) then
		return previousMiniGameFile.character.steppingX, previousMiniGameFile.character.steppingY
	elseif ( currentMiniGame == "map" ) then 
		if ( previousMiniGameFile.currentMiniGame == "house" ) then 
			if ( previousMiniGameFile.character.steppingX == houseExitX ) then 
				return houseMapExitX, houseMapExitY
			else 
				return houseMapEntranceX, houseMapEntranceY
			end 
		end
	elseif ( currentMiniGame == "house" ) then
		if ( previousMiniGameFile.character.steppingX == houseMapExitX ) then
			return houseExitX, houseExitY
		else
			return houseEntranceX, houseEntranceY
		end 
	end 
end

function M.newGameFile( newFileName )
	local files = { }

	if ( GBCDataCabinet.load( "files" ) == false ) then
		GBCDataCabinet.createCabinet( "files" )
		GBCDataCabinet.set( "files", "names", files )
	end

	files = GBCDataCabinet.get( "files", "names" )
	table.insert( files,  newFileName )

	GBCDataCabinet.createCabinet( newFileName )
	GBCDataCabinet.set( newFileName, "gameStatus", defaultFile( ) )

	GBCDataCabinet.save( "files" )
	GBCDataCabinet.save( newFileName )

	M.setCurrentFileName( newFileName )

	for i = 1, #files do
		print( i .. ": " .. files[i] )
	end
	--M.deleteFiles()
end

function M.saveGameFile( gameStatus )
	local fileName = M.getCurrentFileName()

	GBCDataCabinet.set( fileName, "gameStatus", gameStatus )
	GBCDataCabinet.save( fileName )
end

function M.loadGameFile( )
	local fileName = M.getCurrentFileName()
	GBCDataCabinet.load(fileName)
	return GBCDataCabinet.get( fileName, "gameStatus" )
end

function M.setCurrentFileName( fileName )
	GBCDataCabinet.set( "currentFileName", "name", fileName )
	GBCDataCabinet.save( "currentFileName" )
end

function M.getCurrentFileName( )
	return GBCDataCabinet.get( "currentFileName", "name" )
end

function M.deleteFiles( )
	local files
	GBCDataCabinet.load( "files" )

	files = GBCDataCabinet.get( "files", "names" )
	for i = #files, 1, -1 do
		GBCDataCabinet.deleteCabinet(files[i], true)
		table.remove( files )
	end

	GBCDataCabinet.save( "files" )
end

function M.addInstructionsTable( direction, steps )

end

return M