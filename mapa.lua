local composer = require( "composer" )

local perspective = require("com.perspective.perspective")

local scene = composer.newScene()

local tiled = require "com.ponywolf.ponytiled"

local physics = require "physics"

local json = require "json"

physics.start()

--------------
-- Declaração das variáveis
--------------
local camera = perspective.createView()

local map

local character

local gamePanel = { tiled }

local instructions = { boxes = { }, upArrows = { }, downArrows = { }, leftArrows = { }, rightArrows = { }, shownArrow = { }, shownInstruction = { }, texts = { }, shownBox = -1 }

local directionButtons = { up, down, left, right }

local stepsButton = { shownButton, listener }

local stepsCount

-- delay e tempo dos movimentos
local delayMovement = 0
local stepDuration = 400

-- tamanho dos tiles usados no tiled
local tilesSize = 32

-- fila de instruções
local instructionsQueue = { first = 1, last = 0,  direction = { }, steps = { } }

-- tiles do caminho que pode ser percorrido ( usado para mostrar caminho andado )
local path = { }

-- tiles do caminho que foi de fato percorrido
local markedPath = { }

-- Botão que o jogador aperta para executar as instruções
local okButton

local scrollView

-- -----------------------------------------------------------------------------------
-- Funções de criação
-- -----------------------------------------------------------------------------------
local function setMap( )
  -- Cria mapa a partir do arquivo JSON exportado pelo tiled
  display.setDefault("magTextureFilter", "nearest")
  display.setDefault("minTextureFilter", "nearest")
  local maptiledData = json.decodeFile(system.pathForFile("imgs/tiles/tilemap.json", system.ResourceDirectory))

  map = tiled.new(maptiledData, "imgs/tiles")

  -- Posiciona tela no meio do mapa (eixo y)
  map.y = display.viewableContentHeight - map.designedHeight/2
  map.initialY = map.y

  --@TODO: TIRAR ISSO QUANDO ACABAREM OS TESTES COM A TELA
  --local dragable = require "com.ponywolf.plugins.dragable"
  --map = dragable.new(map)
end

local function setCharacter( )
  local rope 
  local ropeJoint

  -- lembrar: o myName (para os listeners) foi definido
  -- no próprio tiled
  character = map:findObject("character")

  -- Objeto invisível que vai colidir com os objetos de colisão
  -- @TODO: mudar posição e tamanho do rope quando substituirmos a imagem do personagem
  rope = display.newRect( map:findLayer("character"), character.x, character.y + 4, 25, 20 )
  physics.addBody( rope ) 
  rope.gravityScale = 0 
  rope.myName = "rope"
  rope.isVisible = false
  ropeJoint = physics.newJoint( "rope", rope, character, 0, 0 )
end

-- Prepara a câmera para se mover de acordo com os movimentos do personagem
-- @TODO: Mudar os parâmetros de setCameraOffset e setBounds quando trocarmos o mapa 
local function setCamera( )
  local layer
  camera:add( character, 1 )
  camera:add( map, 2 )

  layer = camera:layer(1)

  local mapX, mapY = map:localToContent( 0, 0 )
  layer:setCameraOffset( -180, 0 )

  layer = camera:layer(2)
  layer:setCameraOffset( -180, - mapY )

  camera:setBounds( 32, 415, 150, 630 )
  camera:setFocus(character)
  camera:track()
end

local function setGamePanel( )
  local gamePanelData = json.decodeFile(system.pathForFile("imgs/tiles/gamePanel.json", system.ResourceDirectory))  -- load from json export
  gamePanel.tiled = tiled.new(gamePanelData, "imgs/tiles")
  gamePanel.tiled.x = display.contentWidth - gamePanel.tiled.designedWidth + tilesSize/2
  gamePanel.tiled.y = 0

  -- Cria referências para os quadros de instruções e suas setas
  local instructionsLayer = gamePanel.tiled:findLayer("instructions")
  local upArrowsLayer = gamePanel.tiled:findLayer("upArrows")
  local downArrowsLayer = gamePanel.tiled:findLayer("downArrows")
  local leftArrowsLayer = gamePanel.tiled:findLayer("leftArrows")
  local rightArrowsLayer = gamePanel.tiled:findLayer("rightArrows")

  for i = 1, instructionsLayer.numChildren do
    instructions.boxes[i - 1] = instructionsLayer[i]
    instructions.upArrows[i - 1] = upArrowsLayer[i]
    instructions.downArrows[i - 1] = downArrowsLayer[i]
    instructions.leftArrows[i - 1] = leftArrowsLayer[i]
    instructions.rightArrows[i - 1] = rightArrowsLayer[i]
  end

  -- Botão que aumenta o número de passos
  stepsButton["left"] = gamePanel.tiled:findObject("leftStepsButton") 
  stepsButton["up"] = gamePanel.tiled:findObject("upStepsButton") 
  stepsButton["right"] = gamePanel.tiled:findObject("rightStepsButton") 
  stepsButton["down"] = gamePanel.tiled:findObject("downStepsButton") 
  stepsButton.listener = gamePanel.tiled:findObject("listenerStepsButton")

  -- Setas que definem a direção
  directionButtons.right = gamePanel.tiled:findObject("directionRight") 
  directionButtons.left = gamePanel.tiled:findObject("directionLeft") 
  directionButtons.down = gamePanel.tiled:findObject("directionDown") 
  directionButtons.up = gamePanel.tiled:findObject("directionUp") 

  instructionsPanel = gamePanel.tiled:findObject("instructionsPanel")
end

local function setOkButton( )
  local okText

  okButton = display.newRect( gamePanel.tiled, -50, 250, 60, 30 )
  okText = display.newText( gamePanel.tiled, "OK", okButton.x, okButton.y, system.nativeFont, 30 )
  okButton:setFillColor( 0, 0, 0 )
end

local function setSensors( )
  -- Referências para os tiles do caminho
  local pathLayer = map:findLayer("path")
  local sensorsLayer = map:findLayer("sensors")
  local sensors = { x = { } }

  -- Indexa os tiles com sensores no chão para que o "for" seguinte consiga
  -- associar os tiles com sensores com os tiles do caminho
  for i = 1, sensorsLayer.numChildren do
    local xCenter, yCenter = sensorsLayer[i]:localToContent( 0, 0 )

    if ( sensors.x[xCenter] == nil ) then
      local y = { }
      table.insert( y, yCenter, sensorsLayer[i] )
      table.insert( sensors.x, xCenter, y )
    else
      table.insert( sensors.x[xCenter], yCenter, sensorsLayer[i] )
    end
  end

  -- Dá nome aos tiles do path e sensores para que o tile correto seja 
  -- mostrado quando o personagem andar sobre um tile
  -- obs: os tiles da camada de sensores têm que estar EXATAMENTE
  -- no centro dos tiles da camada path
  for i = 1, pathLayer.numChildren do
    local xCenter, yCenter = pathLayer[i]:localToContent( 0, 0 )

    pathLayer[i].myName = i 
    if ( sensors.x[xCenter][yCenter] ) 
      then sensors.x[xCenter][yCenter].myName = i
    else print (" Sensor nao encontrado em x = " .. xCenter .. " e y = " .. yCenter )
    end
    table.insert( path, pathLayer[i] )
  end   
end

-- -----------------------------------------------------------------------------------
-- Fila de instruções
-- -----------------------------------------------------------------------------------
function instructionsQueue:add ( direction, steps )
  local queue = self

  queue.last = queue.last + 1
  queue.direction[queue.last] = direction
  queue.steps[queue.last] = steps
end

function instructionsQueue:remove ( )
  local queue = self
  local first = queue.first 
  local last = queue.last

  if ( first > last ) then
    rval = -1
    print ( "A fila ja esta vazia" )
  else 
    local rval = queue.direction[first]
    self.steps[first] = nil 
    self.direction[first] = nil 
    self.first = first + 1
  end

  return rval 
end

function instructionsQueue:reset ( )
  self.first = 1
  self.last = 0
  self.direction = { }
  self.steps = { }
end

-- -----------------------------------------------------------------------------------
-- Funções relacionadas à amostra de instruções na tela
-- -----------------------------------------------------------------------------------
-- Acha qual seta deve ser mostrada nas caixas de instrução
local function findInstructionArrow ( index )
  local direction = instructionsQueue.direction[index]

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
local function moveInstruction( firstBox, lastBox, direction )
  for i = firstBox, lastBox do
    local instructionIndex  = instructions.shownInstruction[i] + direction
    local steps = instructionsQueue.steps[ instructionIndex ]
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
local function scrollInstruction ( direction )
  if ( instructions.shownBox ~= -1 ) then
    local firstBox = 0
    local lastBox = instructions.shownBox
    
    if ( ( direction == "down" ) and ( instructions.shownInstruction[0] > 1 ) ) then 
        moveInstruction( firstBox, lastBox, -1 )
    elseif ( ( direction == "up" ) and ( instructions.shownInstruction[instructions.shownBox] < instructionsQueue.last ) ) then 
        moveInstruction( firstBox, lastBox, 1 )
    end 
  end
end

-- Esconde as instruções após a execução
local function hideInstructions( )
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
local function showInstruction( direction )
  local arrow = findInstructionArrow ( instructionsQueue.last )

  if ( instructions.shownBox < #instructions.boxes ) then
    local boxNum = instructions.shownBox + 1
    local box = instructions.boxes[boxNum]

    instructions.shownBox = boxNum
    box.alpha = 1
    arrow[boxNum].alpha = 1
    instructions.shownArrow[boxNum] = arrow[boxNum]
    instructions.texts[boxNum] = display.newText( gamePanel.tiled, boxNum + 1 .. ".  " .. stepsCount, box.x - 10, box.y, system.nativeFont, 16)
    instructions.shownInstruction[boxNum] = instructionsQueue.last 
  else 
    local boxNum = instructions.shownBox
    -- Verifica se a última instrução sendo mostrada na tela foi a feita anteriormente (se não for, houve scroll)
    if ( ( instructionsQueue.last - 1 ) == instructions.shownInstruction[boxNum] ) then 
      moveInstruction( 0,  boxNum - 1, 1 )

      instructions.shownArrow[boxNum].alpha = 0
      instructions.shownArrow[boxNum] = arrow[boxNum]
      instructions.shownArrow[boxNum].alpha = 1
      instructions.texts[boxNum].text = instructionsQueue.last .. ".  " .. stepsCount
      instructions.shownInstruction[boxNum] = instructionsQueue.last 
    end
  end
end

-- -----------------------------------------------------------------------------------
-- Funções relacionadas ao movimento do personagem
-- -----------------------------------------------------------------------------------
-- Cada passo é equivalente a 1 tileSize
local function movecharacter( direction, steps ) 
  local moveOffset = tilesSize * steps
  local finalCharPosX, finalCharPosY = character.x, character.y

  if ( direction == "left" ) then
    finalCharPosX = character.x - moveOffset
    -- vira personagem
    if ( character.xScale ~= -1  ) then character.xScale = -1 end

  elseif ( direction == "right" ) then
    finalCharPosX = character.x + moveOffset
    -- vira personagem
    if ( character.xScale == -1 ) then character.xScale = 1 end

  elseif ( direction == "up" ) then
    finalCharPosY = character.y - moveOffset

  elseif ( direction == "down" ) then
    finalCharPosY = character.y + moveOffset

  else
    print ( "Direcao inexistente" )
    return -1
  end

  transition.to( character, {time = steps * stepDuration, delay = movementDuration, x = finalCharPosX, y =  finalCharPosY } )
end

-- Desmarca caminho feito anteriormente
local function unmarkPath ( )
  if ( markedPath ~= nil ) then 
    for i = #markedPath, 1, -1 do
      markedPath[i].alpha = 0
      table.remove( markedPath, i )
    end
    markedPath = { }
  end
end

-- -----------------------------------------------------------------------------------
-- Funções relacionadas à execução das instruções
-- -----------------------------------------------------------------------------------
local function executeSingleInstruction ( )
  -- Condição de parada (fila de instruções vazia)
  if ( instructionsQueue.last < instructionsQueue.first)  then
    instructionsQueue:reset( )
    return 0
  end
  local movementDuration = instructionsQueue.steps[instructionsQueue.first] * stepDuration
  
  movecharacter ( instructionsQueue.direction[instructionsQueue.first], instructionsQueue.steps[instructionsQueue.first] )
  instructionsQueue:remove( )
  -- Executa próxima instrução com um delay
  timer.performWithDelay( movementDuration, executeSingleInstruction )
end

local function executeInstructions ( )
  -- Desmarca caminho anterior
  unmarkPath( )

  -- Executa as instruções uma a uma
  executeSingleInstruction( )
end


-- -----------------------------------------------------------------------------------
-- Listeners
-- -----------------------------------------------------------------------------------
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

-- É o listener para quando o jogador aperta uma seta
-- Também adiciona a instrução na fila
local function defineDirection( event )
  local direction = event.target.myName
  
  if ( instructionsQueue.last == 0 ) then 
    hideInstructions( )
  end

  if ( stepsButton.shownButton ~= nil ) then
    stepsButton.shownButton.alpha = 0 
  end
  stepsButton[direction].alpha = 1
  stepsButton.shownButton = stepsButton[direction]

  -- Instrução começa com um passo para a direção escolhida
  stepsCount = 1
  instructionsQueue:add( direction, stepsCount )
  showInstruction( direction )
end

-- Aumenta quantidade de passos da instrução e também muda seu 
-- valor na caixa de instrução
local function addStep( event )
  stepsCount = stepsCount + 1
  instructionsQueue.steps[instructionsQueue.last] = stepsCount

  for i = 0, instructions.shownBox do 
    if ( instructions.shownInstruction[i] == instructionsQueue.last ) then 
      instructions.texts[i].text = instructionsQueue.last .. ".  " .. stepsCount
    end
  end  
end

-- Trata dos tipos de colisão
local function onCollision( event )
  phase = event.phase
  local obj1 = event.object1
  local obj2 = event.object2

  if ( event.phase == "began" ) then
    -- Colisão entre o personagem e os sensores dos tiles do caminho
    if ( ( obj1.myName == "character" ) and ( obj2.myName ~= "collision" ) ) then 
      path[obj2.myName].alpha = 1
      table.insert( markedPath, path[obj2.myName] )
    elseif ( ( obj2.myName == "character" ) and ( obj1.myName ~= "collision" ) ) then  
      path[obj1.myName].alpha = 1
      table.insert( markedPath, path[obj1.myName] )

    -- Colisão com os demais objetos e o personagem (rope nesse caso)
    elseif ( ( ( obj1.myName == "collision" ) and ( obj2.myName == "rope" ) ) or ( ( obj2.myName == "rope" ) and ( obj2.myName == "collision" ) ) ) then 
      transition.cancel( )
     end
  end
  return true 
end

-- -----------------------------------------------------------------------------------
-- Cenas
-- -----------------------------------------------------------------------------------
-- create()
function scene:create( event )
  local sceneGroup = self.view
   
  setMap( )
  setCharacter( ) 
  setCamera( )
  setGamePanel( )
  setOkButton( )
  setSensors( )
end

-- show()
function scene:show( event )

  local sceneGroup = self.view
  local phase = event.phase

  if ( phase == "will" ) then
    -- criar os listeners para mover o character por meio do joystick
    directionButtons.right:addEventListener( "tap", defineDirection )
    directionButtons.left:addEventListener( "tap", defineDirection )
    directionButtons.down:addEventListener( "tap", defineDirection )
    directionButtons.up:addEventListener( "tap", defineDirection )

  elseif ( phase == "did" ) then
    okButton:addEventListener( "tap", executeInstructions )
    Runtime:addEventListener( "collision", onCollision )
    stepsButton.listener:addEventListener( "tap", addStep )
    instructionsPanel:addEventListener( "touch", scrollInstructionsPanel )
  end
end

-- hide()
function scene:hide( event )

  local sceneGroup = self.view
  local phase = event.phase

  if ( phase == "will" ) then
    -- Code here runs when the scene is on screen (but is about to go off screen)

  elseif ( phase == "did" ) then
    -- Code here runs immediately after the scene goes entirely off screen

  end
end

-- destroy()
function scene:destroy( event )

  local sceneGroup = self.view
  -- Code here runs prior to the removal of scene's view

end

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene