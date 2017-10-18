module(..., package.seeall)


local M = { }

-- -----------------------------------------------------------------------------------
-- Ajustes das imagens dependendo do tamanho da tela 
-- -----------------------------------------------------------------------------------
function M.fitDefault( screen )
	if (  display.actualContentWidth > 512 ) then 
  		screen.x = screen.x - 44
  	elseif (  display.actualContentWidth == 512 ) then
  		screen.x = screen.x - 16
  	end
  	screen.y = screen.y - 32
end

function M.fitGamePanel( gamePanel, goBackButton )
	if ( display.actualContentWidth > 512 ) then
	  	gamePanel.x = gamePanel.x + ( display.actualContentWidth - gamePanel.designedWidth ) - 32
	  	goBackButton.x = goBackButton.x - 64
  	end
  		gamePanel.y = gamePanel.y - 5
end

function M.fitBackground( background )
	if (  display.actualContentWidth > 512 ) then 
  		background.x = background.x - 45
  	elseif (  display.actualContentWidth == 512 ) then
  		background.x = background.x - 32
  	end
  	--background.y = background.y - 32
end

function M.fitMenu( background, newGameButton, playButton, title )
	if (  display.actualContentWidth > 512 ) then 
  		background.x = background.x - 45
  	elseif (  display.actualContentWidth == 512 ) then
  		background.x = background.x - 32
  		title.x = title.x - 20 
  		playButton.x = playButton.x - 35
  	else 
  		title.x = title.x - 50
  		newGameButton.x = newGameButton.x - 40
  		playButton.x = playButton.x - 50
  	end
end

function M.fitMap( map )
	map.x = -28
	map.y =  -40
end

return M