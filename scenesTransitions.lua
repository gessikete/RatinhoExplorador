module(..., package.seeall)

local composer = require( "composer" )

local M = { }

function M.gotoMenu( )
	composer.gotoScene( "menu", { time = 800, effect = "crossFade" } )
end

function M.gotoMap( )
	composer.gotoScene( "map", { time = 4000 } )
end

function M.gotoNewGame( )
	composer.gotoScene( "newGame", { time = 800, effect = "crossFade" } )
end

function M.gotoChooseGameFile( )
	composer.gotoScene( "chooseGameFile", { time = 800, effect = "crossFade" } )
end



return M