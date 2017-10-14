module(..., package.seeall)

local GBCDataCabinet = require("plugin.GBCDataCabinet")

local json = require("json")

local M = { }

GBCDataCabinet.createCabinet( "currentFileName"  )

function M.filesNames( )
	if ( GBCDataCabinet.load( "files" ) == true ) then
		return GBCDataCabinet.get( "files", "names" )
	end
end

function defaultFile( )
	local default = { character = { steppingX, steppingY } }
	
	default.character.steppingX = 128
	default.character.steppingY = 80
	default.miniGame = "map" 

	return default
end

function M.startingPoint( miniGame )
	if ( miniGame == "map" ) then 
		return 128, 80
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
	--print(GBCDataCabinet.get( fileName, "gameStatus" ))
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