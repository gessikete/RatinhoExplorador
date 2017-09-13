-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here

local composer = require("composer")


-- hide status bar
display.setStatusBar( display.HiddenStatusBar )

-- seed the random number generator
math.randomseed( os.time() )

-- go to the menu screen
-- composer.gotoScene( "menu" )
composer.gotoScene( "mapa" )
