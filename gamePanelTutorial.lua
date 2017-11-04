module(..., package.seeall)

local json = require "json"

local tiled = require "com.ponywolf.ponytiled"

local sceneTransition = require "sceneTransition"

local fitScreen = require "fitScreen"

local physics = require "physics"

physics.start()

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
  	local instructions = { selectedBox = {}, boxes = { }, upArrows = { }, downArrows = { }, leftArrows = { }, rightArrows = { }, shownArrow = { }, shownInstruction = { }, texts = { }, shownBox = -1 }
  	local directionButtons = { up, down, left, right }
  	local bikeWheel 

  	-- Carrega o arquivo tiled
  	gamePanelData = json.decodeFile(system.pathForFile("tiled/gamePanelTutorial.json", system.ResourceDirectory))  -- load from json export
  	gamePanel = tiled.new(gamePanelData, "tiled")

  	-- Cria referências para os quadros de instruções e suas setas
  	local instructionsLayer = gamePanel:findLayer("instructions")
  	local selectedInstructionLayer = gamePanel:findLayer("selectedInstruction")
  	local upArrowsLayer = gamePanel:findLayer("upArrows")
  	local downArrowsLayer = gamePanel:findLayer("downArrows")
  	local leftArrowsLayer = gamePanel:findLayer("leftArrows")
  	local rightArrowsLayer = gamePanel:findLayer("rightArrows")

  	for i = 1, instructionsLayer.numChildren do
    	instructions.boxes[i - 1] = instructionsLayer[i]
    	instructions.selectedBox[i - 1] = selectedInstructionLayer[i]

    	instructions.upArrows[i - 1] = upArrowsLayer[i]
    	instructions.downArrows[i - 1] = downArrowsLayer[i]
    	instructions.leftArrows[i - 1] = leftArrowsLayer[i]
    	instructions.rightArrows[i - 1] = rightArrowsLayer[i]
  	end

  	instructions.boxes[0].alpha = 1

  	-- Roda da bicicleta que aumenta o número de passos
  	bikeWheel  = gamePanel:findObject("bikeWheel")
  	bikeWheel.radius = bikeWheel.width/2
  	bikeWheel.quadrant = 1
  	bikeWheel.steps = 1
  	M.bikeWheel = bikeWheel

  	-- Setas que definem a direção
  	directionButtons.right = gamePanel:findObject("directionRight") 
  	directionButtons.right.originalX = directionButtons.right.x 
  	directionButtons.right.originalY = directionButtons.right.y 

  	directionButtons.left = gamePanel:findObject("directionLeft") 
  	directionButtons.left.originalX = directionButtons.left.x 
  	directionButtons.left.originalY = directionButtons.left.y 

  	directionButtons.down = gamePanel:findObject("directionDown") 
  	directionButtons.down.originalX = directionButtons.down.x 
  	directionButtons.down.originalY = directionButtons.down.y 

  	directionButtons.up = gamePanel:findObject("directionUp") 
  	directionButtons.up.originalX = directionButtons.up.x 
  	directionButtons.up.originalY = directionButtons.up.y 

 	instructionsPanel = gamePanel:findObject("instructionsPanel")

  	executeButton = gamePanel:findObject("executeButton")
  	M.executeButton = executeButton

  	goBackButton = gamePanel:findObject("goBackButton")

  	M.hand = gamePanel:findObject("hand")
  	M.hand.originalX = M.hand.x 
  	M.hand.originalY = M.hand.y

  	M.firstBox = instructions.boxes[0]
  	M.secondBox = instructions.boxes[1]

  	fitScreen.fitGamePanel( gamePanel, goBackButton )

  	function M:showDirectionButtons( fadeIn )
  		if ( fadeIn == true ) then 
	  		transition.fadeIn( directionButtons.right, { time = 400 } )
	  		transition.fadeIn( directionButtons.left, { time = 400 } )
	  		transition.fadeIn( directionButtons.up, { time = 400 } )
	  		transition.fadeIn( directionButtons.down, { time = 400 } )

	  		local nonDraggableLayer = gamePanel:findLayer("non-draggable")
	  		for i = 1, nonDraggableLayer.numChildren do
	  			transition.fadeIn( nonDraggableLayer[i], { time = 400 } )
	  		end
  		else 
  			directionButtons.left.alpha = 1
  			directionButtons.up.alpha = 1
  			directionButtons.down.alpha = 1

  			local nonDraggableLayer = gamePanel:findLayer("non-draggable")
	  		for i = 1, nonDraggableLayer.numChildren do
	  			nonDraggableLayer[i].alpha = 1
	  		end
  		end
  	end

  	function M:showBikewheel ( fadeIn )
  		if ( fadeIn == true ) then
  			transition.fadeIn( bikeWheel, { time = 400 } )
  		else
  			bikeWheel.alpha = 1
  		end
  	end

  	-- -----------------------------------------------------------------------------------
	-- Listeners do game panel
	-- -----------------------------------------------------------------------------------
	-- Atualiza quantidade de passos de acordo com giro da roda da bicicleta
	local function updateSteps( circle )
	  stepsCount = math.floor(circle.steps)
	  instructionsTable.steps[instructionsTable.last] = stepsCount

	  for i = 0, instructions.shownBox do 
	    if ( instructions.shownInstruction[i] == instructionsTable.last ) then 
	      instructions.texts[i].text = instructionsTable.last .. ".  " .. stepsCount
	    end
	  end  
	end

	-- Retorna quadrante do ponto onde o jogador está tocando
	local function getQuadrant( dx, dy )
	  	if ( ( dx > 0) and ( dy > 0 ) ) then
	    	return 2
	  	elseif ( ( dx > 0 ) and ( dy < 0 ) ) then
	    	return 1
	  	elseif ( ( dx < 0 ) and ( dy > 0 ) ) then
	    	return 3
	  	elseif ( ( dx < 0 ) and ( dy < 0 ) ) then
	    	return 4
	  	end
	end

	-- Gira a roda da bicicleta
	local function spinBikeWheel( event )
		local circle = event.target
		local phase = event.phase
		local centerX, centerY = circle:localToContent( 0, 0 )

		if ( "began" == phase ) then
		    display.currentStage:setFocus( circle )

		    local dx = event.x - centerX
		    local dy = event.y - centerY 
		    local radius = math.sqrt( math.pow( dx, 2 ) + math.pow( dy, 2 ) )
		    local ds, dt = ( circle.radius * dx ) / radius, ( circle.radius * dy ) / radius

		    adjustment = math.atan2( dt, ds ) * 180 / math.pi - circle.rotation

		    circle.quadrant = getQuadrant( ds, dt )
		  
		elseif ( "moved" == phase ) then
		    if ( adjustment ) then 
		    	--print( bikeWheel.maxSteps )
		    	if ( ( bikeWheel.maxSteps ) and ( bikeWheel.steps == bikeWheel.maxSteps ) ) then
						local executeTutorial = event.target.executeTutorial
						transition.cancel( M.hand ) 
						transition.fadeOut( M.hand, { time = 450, onComplete = 
      						function() 
        						executeTutorial()
        					end } )
					
				elseif ( ( not bikeWheel.maxSteps ) or ( ( bikeWheel.maxSteps ) and ( bikeWheel.steps < bikeWheel.maxSteps ) ) ) then  
			      	local dx = event.x - centerX 
			      	local dy = event.y - centerY
			      	local radius = math.sqrt( math.pow( dx, 2 ) + math.pow( dy, 2 ) )
			      	local ds, dt = ( circle.radius * dx ) / radius, ( circle.radius * dy ) / radius
			      	local quadrant = getQuadrant( dx, dy )

			      	if ( ( quadrant ) and ( circle.quadrant ) ) then 
				      	if ( quadrant ~= circle.quadrant ) then
				      	  	if ( ( circle.quadrant == 4 ) and ( quadrant == 1 ) ) then 
				      	    	circle.steps = circle.steps + 0.5
				      		elseif ( ( circle.quadrant == 1 ) and ( quadrant == 4 ) ) then 
				      	    	if ( circle.steps > 0 ) then
				      	      		circle.steps = circle.steps - 0.5
				      	    	end
				      	  	elseif ( quadrant > circle.quadrant ) then 
				      	    	circle.steps = circle.steps + 0.5
				      	  	elseif ( quadrant < circle.quadrant ) then 
				      	    	if ( circle.steps > 0 ) then
				      	      		circle.steps = circle.steps - 0.5
				      	    	end
				      	  	end 
				      	end

				      	circle.quadrant = quadrant

				      	if ( circle.steps > 0 ) then
				      	  circle.rotation = ( math.atan2( dt, ds ) * 180 / math.pi ) - adjustment 
				      	end
				 
				      	updateSteps( circle )
				      	
			      	end
		      	end
		    end 
		  
		elseif ( "ended" == phase or "cancelled" == phase ) then
			display.currentStage:setFocus( nil )
			if ( bikeWheel.executeTutorial ) then 
				bikeWheel:removeEventListener( "touch", spinBikeWheel )
				bikeWheel.executeTutorial = nil 
				bikeWheel.maxSteps = nil
			end
		end

		return true 
	end

	-- É o listener para quando o jogador aperta uma seta
	-- Também adiciona a instrução na fila
	local function createInstruction( event )
		local phase = event.phase
	 	local direction = event.target.myName
	  	local directionButton = event.target
	  	local box
	  	local selectedBox

	  	-- Descobre qual é a caixa de instrução que mostrará a nova instrução e as suas posições
	  	if ( instructions.shownBox < #instructions.boxes ) then
	  		box = instructions.boxes[ instructions.shownBox + 1 ], instructions.boxes[ instructions.shownBox + 1 ]:localToContent( 0, 0 )
	  		selectedBox = instructions.selectedBox[ instructions.shownBox + 1 ]
	  	else
	  		box = instructions.boxes[ #instructions.boxes ], instructions.boxes[ #instructions.boxes ]:localToContent( 0, 0 )
	  		selectedBox = instructions.selectedBox[ #instructions.boxes ]
	  	end

	  	if ( "began" == phase ) then
			display.currentStage:setFocus( directionButton )
			-- Seta selecionada é posicionada na frente de todos os outros objetos na tela
			directionButton:toFront()

			-- Cálculo do offset inicial
			directionButton.touchOffsetX = event.x - directionButton.x
			directionButton.touchOffsetY = event.y - directionButton.y

			-- O loop começa com 1 passo e a rotação da roda de bicicleta volta para o início 
			bikeWheel.steps = 1
			bikeWheel.rotation = 0

			-- Esconde as instruções anteriores e reseta a lista de instruções após uma execução
			if ( instructionsTable.executing ~= 1 ) then 
			   	M:hideInstructions()
			   	instructionsTable:reset() 
			end

			-- Verifica se a última caixa de instrução está mostrando alguma instrução
			-- e caso esteja, houve scroll
			if ( ( instructions.shownBox >= #instructions.boxes ) and ( instructions.shownInstruction[instructions.shownBox] ~= instructionsTable.last  ) ) then
				-- Caso tenha havido um scroll anteriormente, faz scroll para cima até a última
				-- instrução feita ser mostrada na última caixa de instrução
				while ( instructions.shownInstruction[instructions.shownBox] ~= instructionsTable.last ) do
					scrollInstruction("up")
				end 
				moveInstruction( 0,  instructions.shownBox, 1, true )
			elseif ( ( instructions.shownBox >= #instructions.boxes ) and ( instructions.texts[instructions.shownBox].text ~= " " ) ) then
				-- Se a última instrução feita estiver na última caixa de instrução, faz um
				-- scroll para cima para que a última caixa de instrução seja esvaziada
				moveInstruction( 0,  instructions.shownBox, 1, true )
			end
	
		elseif ( ( "moved" == phase ) and ( directionButton.touchOffsetX ) ) then
			-- Move a seta
			directionButton.x = event.x - directionButton.touchOffsetX
			directionButton.y = event.y - directionButton.touchOffsetY

			-- Mostra a "caixa selecionada", para reforçar que aquele é o local onde a seta deve ser
			-- colocada
			if ( ( event.x > box.contentBounds.xMin ) and ( event.x < box.contentBounds.xMax ) 
			and ( event.y > box.contentBounds.yMin ) and ( event.y < box.contentBounds.yMax ) ) then
				selectedBox.alpha = 1
			else
				selectedBox.alpha = 0
			end

		elseif ( ( "ended" == phase ) or ( "cancelled" == phase ) and ( directionButton.touchOffsetX ) ) then
			-- Verifica se o local onde o movimento de "touch" terminou está dentro
			-- da caixa de instrução atual
			if ( ( event.x > box.contentBounds.xMin ) and ( event.x < box.contentBounds.xMax ) 
			and ( event.y > box.contentBounds.yMin ) and ( event.y < box.contentBounds.yMax ) ) then
				-- Caso esteja, a seta volta para sua posição original
				directionButton.x = directionButton.originalX
				directionButton.y = directionButton.originalY

			  	-- Instrução começa com um passo para a direção escolhida
			  	local stepsCount = 1

			  	-- Instrução é adicionada à lista de instruções e mostrada na sua caixa de instrução correspondente
			  	instructionsTable:add( direction, stepsCount )
			  	showInstruction( direction, stepsCount )

			  	-- Listener da roda de bicicleta é adicionado
			  	if ( instructionsTable.last == 1 ) then 
			  		bikeWheel:addEventListener( "touch", spinBikeWheel )
				end

				-- A caixa selecionada é escondida
			  	selectedBox.alpha = 0
			else
				-- Caso o movimento de toque acabe e a seta não seja colocada na caixa correta, ela 
				-- volta para a posição original
				transition.to( directionButton, { time = 400, x = directionButton.originalX, y = directionButton.originalY } )
		  	end
	    	display.currentStage:setFocus( nil )
		end

	  	return true 
	end

	-- É o listener para quando o jogador aperta uma seta
	-- Também adiciona a instrução na fila
	local function createControlsTutorialInstruction( event )
		local phase = event.phase
	 	local direction = event.target.myName
	  	local directionButton = event.target
	  	local box
	  	local selectedBox

	  	-- Descobre qual é a caixa de instrução que mostrará a nova instrução e as suas posições
	  	if ( instructions.shownBox < #instructions.boxes ) then
	  		box = instructions.boxes[ instructions.shownBox + 1 ], instructions.boxes[ instructions.shownBox + 1 ]:localToContent( 0, 0 )
	  		selectedBox = instructions.selectedBox[ instructions.shownBox + 1 ]
	  	else
	  		box = instructions.boxes[ #instructions.boxes ], instructions.boxes[ #instructions.boxes ]:localToContent( 0, 0 )
	  		selectedBox = instructions.selectedBox[ #instructions.boxes ]
	  	end

	  	if ( "began" == phase ) then
			display.currentStage:setFocus( directionButton )
			-- Seta selecionada é posicionada na frente de todos os outros objetos na tela
			directionButton:toFront()

			-- Cálculo do offset inicial
			directionButton.touchOffsetX = event.x - directionButton.x
			directionButton.touchOffsetY = event.y - directionButton.y

			-- O loop começa com 1 passo e a rotação da roda de bicicleta volta para o início 
			bikeWheel.steps = 1
			bikeWheel.rotation = 0

			-- Esconde as instruções anteriores e reseta a lista de instruções após uma execução
			if ( instructionsTable.executing ~= 1 ) then 
			   	M:hideInstructions()
			   	instructionsTable:reset() 
			end

			-- Verifica se a última caixa de instrução está mostrando alguma instrução
			-- e caso esteja, houve scroll
			if ( ( instructions.shownBox >= #instructions.boxes ) and ( instructions.shownInstruction[instructions.shownBox] ~= instructionsTable.last  ) ) then
				-- Caso tenha havido um scroll anteriormente, faz scroll para cima até a última
				-- instrução feita ser mostrada na última caixa de instrução
				while ( instructions.shownInstruction[instructions.shownBox] ~= instructionsTable.last ) do
					scrollInstruction("up")
				end 
				moveInstruction( 0,  instructions.shownBox, 1, true )
			elseif ( ( instructions.shownBox >= #instructions.boxes ) and ( instructions.texts[instructions.shownBox].text ~= " " ) ) then
				-- Se a última instrução feita estiver na última caixa de instrução, faz um
				-- scroll para cima para que a última caixa de instrução seja esvaziada
				moveInstruction( 0,  instructions.shownBox, 1, true )
			end
	
		elseif ( ( "moved" == phase ) and ( directionButton.touchOffsetX ) ) then
			-- Move a seta
			directionButton.x = event.x - directionButton.touchOffsetX
			directionButton.y = event.y - directionButton.touchOffsetY

			-- Mostra a "caixa selecionada", para reforçar que aquele é o local onde a seta deve ser
			-- colocada
			if ( ( event.x > box.contentBounds.xMin ) and ( event.x < box.contentBounds.xMax ) 
			and ( event.y > box.contentBounds.yMin ) and ( event.y < box.contentBounds.yMax ) ) then
				selectedBox.alpha = 1
			else
				selectedBox.alpha = 0
			end

		elseif ( ( "ended" == phase ) or ( "cancelled" == phase ) and ( directionButton.touchOffsetX ) ) then
			-- Verifica se o local onde o movimento de "touch" terminou está dentro
			-- da caixa de instrução atual
			if ( ( event.x > box.contentBounds.xMin ) and ( event.x < box.contentBounds.xMax ) 
			and ( event.y > box.contentBounds.yMin ) and ( event.y < box.contentBounds.yMax ) ) then
				-- Caso esteja, a seta volta para sua posição original
				directionButton.x = directionButton.originalX
				directionButton.y = directionButton.originalY

			  	-- Instrução começa com um passo para a direção escolhida
			  	local stepsCount = 1

			  	-- Instrução é adicionada à lista de instruções e mostrada na sua caixa de instrução correspondente
			  	instructionsTable:add( direction, stepsCount )
			  	showInstruction( direction, stepsCount )

			  	-- Listener da roda de bicicleta é adicionado
			  	--[[if ( instructionsTable.last == 1 ) then 
			  		bikeWheel:addEventListener( "touch", spinBikeWheel )
				end]]

				-- A caixa selecionada é escondida
			  	selectedBox.alpha = 0

			  	directionButtons.right:removeEventListener( "touch", createControlsTutorialInstruction )
			  	directionButtons.up:removeEventListener( "touch", createControlsTutorialInstruction )

			  	transition.fadeOut( M.hand, { time = 450, onComplete = 
      				function() 
        				event.target.executeTutorial()
        			end } )

			  	
			else
				-- Caso o movimento de toque acabe e a seta não seja colocada na caixa correta, ela 
				-- volta para a posição original
				transition.to( directionButton, { time = 400, x = directionButton.originalX, y = directionButton.originalY } )
		  	end
	    	display.currentStage:setFocus( nil )
		end

	  	return true 
	end

	-- Faz o scroll das instruções
	local function scrollInstructionsPanel( event )
	  local phase = event.phase
	  local xInstructionsPanel, yInstructionsPanel = instructionsPanel:localToContent( 0, instructionsPanel.height/2 )

	  if ( phase == "began" ) then
	    instructionsPanel.touchOffsetY = event.y 
	  elseif ( phase == "moved" ) then
	  	if ( instructionsPanel.touchOffsetY ) then 
			if ( ( instructionsPanel.touchOffsetY - event.y ) < -tilesSize ) then 
				scrollInstruction( "down" )
				instructionsPanel.touchOffsetY = event.y 
			elseif ( ( instructionsPanel.touchOffsetY - event.y ) > tilesSize ) then
				scrollInstruction( "up" )
				instructionsPanel.touchOffsetY = event.y
			end
		end 
	  end
	  return true
	end

	function M:removeGoBackButton()
		goBackButton:removeEventListener( "tap", sceneTransition.gotoMenu )
  		goBackButton = nil
	end

	function M:addGoBackButtonListener( )
		goBackButton:addEventListener( "tap", sceneTransition.gotoMenu )
	end

  	function M:addDirectionListeners()
  		directionButtons.right:addEventListener( "touch", createInstruction )
	    directionButtons.left:addEventListener( "touch", createInstruction )
	    directionButtons.down:addEventListener( "touch", createInstruction )
	    directionButtons.up:addEventListener( "touch", createInstruction )
  	end

  	function M:addRightDirectionListener( executeTutorial )
  		directionButtons.right.executeTutorial = executeTutorial
  		directionButtons.right:addEventListener( "touch", createControlsTutorialInstruction )
  	end

  	function M:addUpDirectionListener( executeTutorial )
  		directionButtons.up.executeTutorial = executeTutorial
  		directionButtons.up:addEventListener( "touch", createControlsTutorialInstruction )
  	end

  	function M:addBikeTutorialListener( maxSteps, executeTutorial )
  		bikeWheel:addEventListener( "touch", spinBikeWheel )
  		bikeWheel.maxSteps = maxSteps
  		bikeWheel.executeTutorial = executeTutorial
  	end

  	local function executeTutorialInstructions( )
  		executeInstructions()
  		transition.fadeOut( M.hand, { time = 450, onComplete = 
      				function() 
        				executeButton.executeTutorial()
  						executeButton.executeTutorial = nil
        			end } )

  		executeButton:removeEventListener( "tap", executeTutorialInstructions ) 
  	end

  	function M:addExecuteButtonListener( executeTutorial )
  		executeButton.executeTutorial = executeTutorial
  		executeButton:addEventListener( "tap", executeTutorialInstructions )
  	end

  	function M:addButtonsListeners()
  		executeButton:addEventListener( "tap", executeInstructions )
    	goBackButton:addEventListener( "tap", sceneTransition.gotoMenu )
  	end

  	function M:addInstructionPanelListeners()
    	instructionsPanel:addEventListener( "touch", scrollInstructionsPanel )
  	end

  	function M.stopExecutionListeners()
  		directionButtons.right:removeEventListener( "touch", createInstruction )
		directionButtons.left:removeEventListener( "touch", createInstruction )
		directionButtons.down:removeEventListener( "touch", createInstruction )
		directionButtons.up:removeEventListener( "touch", createInstruction )

		executeButton:removeEventListener( "tap", executeInstructions )

		bikeWheel:removeEventListener( "touch", spinBikeWheel )

		goBackButton:removeEventListener( "tap", sceneTransition.gotoMenu )
  	end

  	function M:stopAllListeners( )
  		instructionsPanel:removeEventListener( "touch", scrollInstructionsPanel )
  		directionButtons.right:removeEventListener( "touch", createInstruction )
		directionButtons.left:removeEventListener( "touch", createInstruction )
		directionButtons.down:removeEventListener( "touch", createInstruction )
		directionButtons.up:removeEventListener( "touch", createInstruction )

		executeButton:removeEventListener( "tap", executeInstructions )

		bikeWheel:removeEventListener( "touch", spinBikeWheel )
  	end

  	function M.restartExecutionListeners()
  		M:addDirectionListeners()
  		M:addButtonsListeners()
  	end

  	function M:destroy() 
  		gamePanel:removeSelf()

		directionButtons.right:removeEventListener( "touch", createInstruction )
		directionButtons.left:removeEventListener( "touch", createInstruction )
		directionButtons.down:removeEventListener( "touch", createInstruction )
		directionButtons.up:removeEventListener( "touch", createInstruction )

		bikeWheel:removeEventListener( "touch", spinBikeWheel )

		executeButton:removeEventListener( "tap", executeInstructions )
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

		-- remove tabela de instruções
		for k0, v0 in pairs( instructionsTable ) do
			if ( type(v0) == "table" ) then 
				for k1, v1 in pairs(v0) do
					table.remove( v0, k1 )
				end
				instructionsTable[k0] = nil 
			end
		end
		instructionsTable = nil 

		executeButton = nil  

		bikeWheel = nil

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
	function moveInstruction( firstBox, lastBox, direction, isLastBoxEmpty )
		
	  for i = firstBox, lastBox do
	  	local instructionIndex  = instructions.shownInstruction[i] + direction

	  	if ( ( i < instructions.shownBox ) or ( isLastBoxEmpty == false ) ) then 
		    local instructionIndex  = instructions.shownInstruction[i] + direction
		    local steps = instructionsTable.steps[ instructionIndex ]
		    local arrow = findInstructionArrow( instructionIndex )
		    instructions.shownArrow[i].alpha = 0

		    instructions.shownArrow[i] = arrow[i]
		    arrow[i].alpha = 1 
		    instructions.texts[i].text = instructionIndex .. ".  " .. steps
		    instructions.shownInstruction[i] = instructions.shownInstruction[i] + direction
		else 
			instructions.shownArrow[i].alpha = 0
			instructions.texts[i].text = " "
		end
	  end
	end

	-- Verifica se as instruções podem ser movidas para baixo/cima e chama
	-- moveInstruction
	function scrollInstruction ( direction )
	  if ( instructions.shownBox ~= -1 ) then
	    local firstBox = 0

	    local lastBox = instructions.shownBox
	    
	    if ( ( direction == "down" ) and ( instructions.shownInstruction[0] > 1 ) ) then 
	        moveInstruction( firstBox, lastBox, -1, false )
	    elseif ( ( direction == "up" ) and ( instructions.shownInstruction[instructions.shownBox] < instructionsTable.last ) ) then 
	        moveInstruction( firstBox, lastBox, 1, false )
	    end 
	  end
	end

	-- Esconde as instruções após a execução
	function M:hideInstructions()
	  local boxNum = instructions.shownBox

	  	if ( instructions.shownBox ~= -1 ) then
		    for i = 0, boxNum do
		      display.remove(instructions.texts[i])
		      instructions.shownArrow[i].alpha = 0
		      instructions.boxes[i].alpha = 0
		      instructions.shownBox = -1
		    end
	  	 

		  	for i = boxNum, #instructions.boxes do
		  		instructions.boxes[i].alpha = 0
		  	end 

		  	instructions.boxes[0].alpha = 1
	  	end
	end

	-- Mostra as instruções à medida que são feitas
	function showInstruction( direction, stepsCount )
	  local arrow = findInstructionArrow ( instructionsTable.last )

	  if ( instructions.shownBox < #instructions.boxes ) then
	    local boxNum = instructions.shownBox + 1
	    local box = instructions.boxes[boxNum]

	    instructions.shownBox = boxNum
	    if ( ( boxNum + 1 ) < #instructions.boxes + 1 ) then 
	    	instructions.boxes[ boxNum + 1 ].alpha = 1
		end
		
	    arrow[ boxNum ].alpha = 1
	    instructions.shownArrow[boxNum] = arrow[boxNum]
	    instructions.texts[boxNum] = display.newText( gamePanel:findLayer("instructions"), boxNum + 1 .. ".  " .. stepsCount, box.x - 10, box.y, system.nativeFontBold, 12)
	    instructions.shownInstruction[boxNum] = instructionsTable.last 
	  else 
	    local boxNum = instructions.shownBox
	    -- Verifica se a última instrução sendo mostrada na tela foi a feita anteriormente (se não for, houve scroll)
	    if ( ( instructionsTable.last - 1 ) == instructions.shownInstruction[boxNum] ) then 
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