module(..., package.seeall)

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local M = { }

local json = require "json"

local tiled = require "com.ponywolf.ponytiled"

local sceneTransition = require "sceneTransition"

local listenersModule = require "listeners"

local persistence = require "persistence"

local message

local listeners = listenersModule:new()

-- -----------------------------------------------------------------------------------
-- Listeners
-- -----------------------------------------------------------------------------------

local function accept( event )
	if ( message == "resetGame" ) then 
		persistence.resetGame()
		transition.fadeOut( warning )
		timer.performWithDelay( 200, sceneTransition.gotoHouse )
	else 
		sceneTransition.gotoMenu()
	end
	listeners:destroy()
end

local function decline( event )
	transition.fadeOut( warning )
	listeners:destroy()
end

-- -----------------------------------------------------------------------------------
-- Cenas
-- -----------------------------------------------------------------------------------
-- create()
function M.show( message_ )
	local warningData = json.decodeFile(system.pathForFile("tiled/warning.json", system.ResourceDirectory))
	local time = 1000

	warning = tiled.new(warningData, "tiled")
	warning.y = warning.y - 32

	acceptButton = warning:findObject( "acceptButton" )
	declineButton = warning:findObject( "declineButton" )

	transition.fadeIn( warning:findObject( "background" ), { time = time } )
	transition.fadeIn( warning:findObject( "blackBackground" ), { time = time } )

	message = message_
	if ( message ) then
		listeners:add( acceptButton, "tap", accept )
		listeners:add( declineButton, "tap", decline )	

		if ( message == "resetGame" ) then 
			local resetGame = warning:findObject( "resetGame" )
			resetGame.alpha = 1
		end
	else 
		transition.fadeOut( warning )
	end

	return warning
end


return M