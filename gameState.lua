module(..., package.seeall)

local persistence = require "persistence"

local M = { }

function M:save( miniGame, steppingX, steppingY )
  local gameState = persistence.loadGameFile( )

  gameState.miniGame = miniGame
  gameState.character.steppingX = steppingX
  gameState.character.steppingY = steppingY 

  persistence.saveGameFile( gameState )
end


function M:loadGame( )
	-- body
end


return M

