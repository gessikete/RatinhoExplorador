module(..., package.seeall)

local json = require "json"

local tiled = require "com.ponywolf.ponytiled"

local scenesTransitions = require "scenesTransitions"

local fitScreen = require "fitScreen"

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local tilesSize = 32

local M = { }

-- -----------------------------------------------------------------------------------
-- Funções do painel de instruções
-- -----------------------------------------------------------------------------------
function M.new( executeInstructions )
  	local gamePanelData
  	local instructions = { boxes = { }, upArrows = { }, downArrows = { }, leftArrows = { }, rightArrows = { }, shownArrow = { }, shownInstruction = { }, texts = { }, shownBox = -1 }
  	local stepsButton = { shownButton, listener }
  	local directionButtons = { up, down, left, right }

  	-- Carrega o arquivo tiled
  	gamePanelData = json.decodeFile(system.pathForFile("tiled/gamePanel.json", system.ResourceDirectory))  -- load from json export
  	gamePanel = tiled.new(gamePanelData, "tiled")

  	-- Cria referências para os quadros de instruções e suas setas
  	local instructionsLayer = gamePanel:findLayer("instructions")
  	local upArrowsLayer = gamePanel:findLayer("upArrows")
  	local downArrowsLayer = gamePanel:findLayer("downArrows")
  	local leftArrowsLayer = gamePanel:findLayer("leftArrows")
  	local rightArrowsLayer = gamePanel:findLayer("rightArrows")

  	for i = 1, instructionsLayer.numChildren do
    	instructions.boxes[i - 1] = instructionsLayer[i]
    	instructions.upArrows[i - 1] = upArrowsLayer[i]
    	instructions.downArrows[i - 1] = downArrowsLayer[i]
    	instructions.leftArrows[i - 1] = leftArrowsLayer[i]
    	instructions.rightArrows[i - 1] = rightArrowsLayer[i]
  	end

  	-- Botão que aumenta o número de passos
  	stepsButton["left"] = gamePanel:findObject("leftStepsButton") 
  	stepsButton["up"] = gamePanel:findObject("upStepsButton") 
  	stepsButton["right"] = gamePanel:findObject("rightStepsButton") 
  	stepsButton["down"] = gamePanel:findObject("downStepsButton") 
  	stepsButton.listener = gamePanel:findObject("listenerStepsButton")

  	-- Setas que definem a direção
  	directionButtons.right = gamePanel:findObject("directionRight") 
  	directionButtons.left = gamePanel:findObject("directionLeft") 
  	directionButtons.down = gamePanel:findObject("directionDown") 
  	directionButtons.up = gamePanel:findObject("directionUp") 

 	instructionsPanel = gamePanel:findObject("instructionsPanel")

  	okButton = gamePanel:findObject("okButton")

  	goBackButton = gamePanel:findObject("goBackButton")

  	fitScreen:fitGamePanel( gamePanel, goBackButton )

  	-- -----------------------------------------------------------------------------------
	-- Listeners do game panel
	-- -----------------------------------------------------------------------------------
	-- É o listener para quando o jogador aperta uma seta
	-- Também adiciona a instrução na fila
	local function defineDirection( event )
	 	local direction = event.target.myName
	  
	  	if ( instructionsTable.executing ~= 1 ) then 
	    	hideInstructions( )
	    	instructionsTable:reset( ) 
	  	end

	  	if ( stepsButton.shownButton ~= nil ) then
	    	stepsButton.shownButton.alpha = 0 
	  	end
	  	stepsButton[direction].alpha = 1
	  	stepsButton.shownButton = stepsButton[direction]

	  	-- Instrução começa com um passo para a direção escolhida
	  	stepsCount = 1
	  	instructionsTable:add( direction, stepsCount )
	  	showInstruction( direction )
	end

	-- Aumenta quantidade de passos da instrução e também muda seu 
	-- valor na caixa de instrução
	local function addStep( event )
	  stepsCount = stepsCount + 1
	  instructionsTable.steps[instructionsTable.last] = stepsCount

	  for i = 0, instructions.shownBox do 
	    if ( instructions.shownInstruction[i] == instructionsTable.last ) then 
	      instructions.texts[i].text = instructionsTable.last .. ".  " .. stepsCount
	    end
	  end  
	end

	-- Faz o scroll das instruções
	local function scrollInstructionsPanel( event )
	  local phase = event.phase
	  local xInstructionsPanel, yInstructionsPanel = instructionsPanel:localToContent( 0, instructionsPanel.height/2 )

	  if ( phase == "began" ) then
	    instructionsPanel.touchOffsetY = event.y 
	  elseif ( phase == "moved" ) then
	    if ( ( instructionsPanel.touchOffsetY - event.y ) < -tilesSize ) then 
	      scrollInstruction( "down" )
	      instructionsPanel.touchOffsetY = event.y 
	    elseif ( ( instructionsPanel.touchOffsetY - event.y ) > tilesSize ) then
	      scrollInstruction( "up" )
	      instructionsPanel.touchOffsetY = event.y
	    end
	  end
	  return true
	end

	function M:removeGoBackButton( )
		goBackButton:removeEventListener( "tap", scenesTransitions.gotoMenu )
  		goBackButton = nil
	end

  	function M:addDirectionListeners( )
  		directionButtons.right:addEventListener( "tap", defineDirection )
	    directionButtons.left:addEventListener( "tap", defineDirection )
	    directionButtons.down:addEventListener( "tap", defineDirection )
	    directionButtons.up:addEventListener( "tap", defineDirection )
  	end

  	function M:addButtonsListeners( )
  		okButton:addEventListener( "tap", executeInstructions )
    	goBackButton:addEventListener( "tap", scenesTransitions.gotoMenu )
  	end

  	function M:addInstructionPanelListeners( )
  		stepsButton.listener:addEventListener( "tap", addStep )
    	instructionsPanel:addEventListener( "touch", scrollInstructionsPanel )
  	end

  	function M.stopListeners( )
  		directionButtons.right:removeEventListener( "tap", defineDirection )
		directionButtons.left:removeEventListener( "tap", defineDirection )
		directionButtons.down:removeEventListener( "tap", defineDirection )
		directionButtons.up:removeEventListener( "tap", defineDirection )

		okButton:removeEventListener( "tap", executeInstructions )
		stepsButton.listener:removeEventListener( "tap", addStep )

		goBackButton:removeEventListener( "tap", scenesTransitions.gotoMenu )
  	end

  	function M.restartListeners( )
  		M:addDirectionListeners( )
  		M:addButtonsListeners( )
  		stepsButton.listener:addEventListener( "tap", addStep )
  	end

  	function M:destroy( )
  		gamePanel:removeSelf( ) 

		directionButtons.right:removeEventListener( "tap", defineDirection )
		directionButtons.left:removeEventListener( "tap", defineDirection )
		directionButtons.down:removeEventListener( "tap", defineDirection )
		directionButtons.up:removeEventListener( "tap", defineDirection )

		okButton:removeEventListener( "tap", executeInstructions )
		stepsButton.listener:removeEventListener( "tap", addStep )
		instructionsPanel:removeEventListener( "touch", scrollInstructionsPanel )

		-- remove instruções
		for k0, v0 in pairs( instructions ) do
		    if ( type(v0) == "table" ) then 
		      for k1, v1 in pairs(v0) do
		        table.remove( v0, k1 )
		      end
		    end
		    instructions[k0] = nil 
		end
		instructions = nil 

		-- remove botões de direção
		for k, v in pairs( directionButtons ) do
			directionButtons[k] = nil 
		end
		directionButtons = nil

		-- remove listener
		stepsButton.listener:removeEventListener( "tap", addStep )

		-- remove fila de instruções
		for k0, v0 in pairs( instructionsTable ) do
		    if ( type(v0) == "table" ) then 
		      for k1, v1 in pairs(v0) do
		        table.remove( v0, k1 )
		      end
		      instructionsTable[k0] = nil 
		    end
		end
		instructionsTable = nil 

		okButton = nil  

		instructionsPanel = nil 

		gamePanel = nil
  	end

	-- -----------------------------------------------------------------------------------
	-- Funções relacionadas à amostra de instruções na tela
	-- -----------------------------------------------------------------------------------
	-- Acha qual seta deve ser mostrada nas caixas de instrução
	function findInstructionArrow ( index )
	  local direction = instructionsTable.direction[index]

	  if ( direction == "right" ) then 
	    arrow = instructions.rightArrows
	  elseif ( direction == "left" ) then
	    arrow = instructions.leftArrows
	  elseif ( direction == "down" ) then
	    arrow = instructions.downArrows
	  else
	    arrow = instructions.upArrows
	  end

	  return arrow 
	end

	-- Move as instruções mostradas na tela da caixa firstBox até lastBox
	-- Direction = 1 significa mover para cima e -1 para baixo.
	function moveInstruction( firstBox, lastBox, direction )
	  for i = firstBox, lastBox do
	    local instructionIndex  = instructions.shownInstruction[i] + direction
	    local steps = instructionsTable.steps[ instructionIndex ]
	    local arrow = findInstructionArrow( instructionIndex )
	    instructions.shownArrow[i].alpha = 0

	    instructions.shownArrow[i] = arrow[i]
	    arrow[i].alpha = 1 
	    instructions.texts[i].text = instructionIndex .. ".  " .. steps
	    instructions.shownInstruction[i] = instructions.shownInstruction[i] + direction
	  end
	end

	-- Verifica se as instruções podem ser movidas para baixo/cima e chama
	-- moveInstruction
	function scrollInstruction ( direction )
	  if ( instructions.shownBox ~= -1 ) then
	    local firstBox = 0
	    local lastBox = instructions.shownBox
	    
	    if ( ( direction == "down" ) and ( instructions.shownInstruction[0] > 1 ) ) then 
	        moveInstruction( firstBox, lastBox, -1 )
	    elseif ( ( direction == "up" ) and ( instructions.shownInstruction[instructions.shownBox] < instructionsTable.last ) ) then 
	        moveInstruction( firstBox, lastBox, 1 )
	    end 
	  end
	end

	-- Esconde as instruções após a execução
	function hideInstructions( )
	  local boxNum = instructions.shownBox

	  if ( instructions.shownBox ~= -1 ) then
	    for i = 0, boxNum do
	      display.remove(instructions.texts[i])
	      instructions.shownArrow[i].alpha = 0
	      instructions.boxes[i].alpha = 0
	      instructions.shownBox = -1
	    end
	  end 
	end

	-- Mostra as instruções à medida que são feitas
	function showInstruction( direction )
	  local arrow = findInstructionArrow ( instructionsTable.last )

	  if ( instructions.shownBox < #instructions.boxes ) then
	    local boxNum = instructions.shownBox + 1
	    local box = instructions.boxes[boxNum]

	    instructions.shownBox = boxNum
	    box.alpha = 1
	    arrow[boxNum].alpha = 1
	    instructions.shownArrow[boxNum] = arrow[boxNum]
	    instructions.texts[boxNum] = display.newText( gamePanel, boxNum + 1 .. ".  " .. stepsCount, box.x - 10, box.y, system.nativeFont, 16)
	    instructions.shownInstruction[boxNum] = instructionsTable.last 
	  else 
	    local boxNum = instructions.shownBox
	    -- Verifica se a última instrução sendo mostrada na tela foi a feita anteriormente (se não for, houve scroll)
	    if ( ( instructionsTable.last - 1 ) == instructions.shownInstruction[boxNum] ) then 
	      moveInstruction( 0,  boxNum - 1, 1 )

	      instructions.shownArrow[boxNum].alpha = 0
	      instructions.shownArrow[boxNum] = arrow[boxNum]
	      instructions.shownArrow[boxNum].alpha = 1
	      instructions.texts[boxNum].text = instructionsTable.last .. ".  " .. stepsCount
	      instructions.shownInstruction[boxNum] = instructionsTable.last 
	    end
	  end
	end

	return gamePanel
end

return M