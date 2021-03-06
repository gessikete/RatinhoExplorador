module(..., package.seeall)

local composer = require( "composer" )

local M = { }

-- -----------------------------------------------------------------------------------
-- Todas as funções de transição
-- -----------------------------------------------------------------------------------
function M.gotoCredits()
	composer.gotoScene( "credits", { time = 800, effect = "crossFade" } )
end

function M.gotoProgress()
	composer.gotoScene( "progress", { time = 800, effect = "crossFade" } )
end

function M.gotoMenu()
	composer.gotoScene( "menu", { time = 800, effect = "crossFade" } )
end

function M.gotoHouse()
	composer.gotoScene( "house", { time = 800, effect = "crossFade" } )
end

function M.gotoSchool()
	composer.gotoScene( "school", { time = 800, effect = "crossFade" } )
end

function M.gotoRestaurant()
	composer.gotoScene( "restaurant", { time = 800, effect = "crossFade" } )
end

function M.gotoMap()
	composer.gotoScene( "map", { time = 4000 } )
end

function M.gotoNewGame()
	composer.gotoScene( "newGame", { time = 800, effect = "crossFade" } )
end

function M.gotoChooseGameFile()
	composer.gotoScene( "chooseGameFile", { time = 800, effect = "crossFade" } )
end

function M.gotoWarning()
	composer.gotoScene( "warning", { time = 800, effect = "crossFade" } )
end

return M