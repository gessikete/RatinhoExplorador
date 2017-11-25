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
--composer.gotoScene( "house" )
--composer.gotoScene( "school" )
composer.gotoScene( "menu" )
--composer.gotoScene( "restaurant" )
--composer.gotoScene( "map" )
--composer.gotoScene( "progress" )
--composer.gotoScene("newGame")
--composer.gotoScene( "chooseGameFile" )