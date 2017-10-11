module(..., package.seeall)

local GBCDataCabinet = require("plugin.GBCDataCabinet")

local M = { }

GBCDataCabinet.createCabinet( "currentFileName"  )

function M.filesNames( )
	if ( GBCDataCabinet.load( "files" ) == true ) then
		return GBCDataCabinet.get( "files", "names" )
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

	GBCDataCabinet.save( "files" )

	M.setCurrentFileName( newFileName )

	for i = 1, #files do
		print( i .. ": " .. files[i] )
	end
	--M.deleteFiles()
end

function M.saveGameFile( data )
	local fileName = M.getCurrentFileName()

	GBCDataCabinet.set( fileName, "data", data )
	GBCDataCabinet.save( fileName )
end

function M.loadGameFile( )
	local fileName = M.getCurrentFileName()
	GBCDataCabinet.load(fileName)
	return GBCDataCabinet.get( fileName, "data" )
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

return M