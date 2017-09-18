local composer = require( "composer" )

local scene = composer.newScene()

local tiled = require "com.ponywolf.ponytiled"

local physics = require "physics"

local json = require "json"

physics.start()


--------------
-- Declaração das variáveis
--------------
local map

local character

local joystick = { tiled, screen, up, down, left, right }

-- contador de passos que será mostrado na tela
local stepsCount = 0

-- texto que mostra os passos dentro do joystick
local stepsText 

-- delay e tempo dos movimentos
local delayMovement = 0
local stepDuration = 400

-- tamanho dos tiles usados no tiled
local tilesSize = 32


-- fila de instruções
instructionsQueue = { first = 0, last = -1,  direction = { }, steps = { } }

-- Botão que o jogador aperta para executar as instruções
local okButton

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
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
  self.first = 0
  self.last = -1
  self.direction = { }
  self.steps = { }
end

-- É o listener para quando o jogador aperta em uma seta
-- Também adiciona a instrução na fila
local function defineDirection( event )
  local joystickArrow = event.target
  
  instructionsQueue:add( joystickArrow.myName, math.floor(stepsCount) )
end

-- Define número de passos que o jogador dará em uma dada instrução e
-- mostra a atualização deles na tela do joystick
local function defineSteps( event )
  local phase = event.phase
  local offset

  if ( "began" == phase ) then
    display.currentStage:setFocus( joystick.screen )

    --calcula offset inicial
    joystick.screen.touchOffsetY = event.y - joystick.screen.y
  
  elseif ( "moved" == phase ) then
    if (event.y >= joystick.screen.y ) then
      -- Calcula novo offset à medida que o toque do jogador sobe ou desce na tela do joystick
      offset = (event.y - joystick.screen.y)

      -- Caso o novo offset seja maior, o número de passos aumenta
      if ( offset > joystick.screen.touchOffsetY ) then 
        
        -- o 3000 garante que o contador de passos não irá aumentar rápido demais
        stepsCount = stepsCount - offset/3000

        -- o offset deve ser atualizado para a próxima chamada do "moved"
        joystick.screen.touchOffsetY = offset
      else 
        stepsCount = stepsCount + offset/1700

      end

      -- Verifica se o número de passos não está negativo  
      if ( stepsCount >= 0) then
        stepsText.text = math.floor(stepsCount)
      else

        -- Zera os passos caso esteja
        stepsCount = 0
        stepsText.text = 0

      end 
    end
  elseif ( "ended" == phase or "cancelled" == phase ) then
      display.currentStage:setFocus( nil )
  end

  return true
end

-- Recalcula posição do personagem 
-- Cada passo é equivalente a 1 tileSize)
local function moveCharacter( direction, steps ) 
  local moveOffset = tilesSize * steps
  local newMapPosition
  local charMovementDuration = 0
  local finalCharPosX, finalCharPosY = character.x, character.y
  local finalMapPosX, finalMapPosY = map.x, map.y 
 
  if ( ( direction == "left" ) or ( direction == "up" ) ) then
    moveOffset = - moveOffset
  end

  if ( ( direction == "left" ) or ( direction == "right" ) ) then
    newMapPosition = map.x - moveOffset

    -- não deixa personagem sair da tela pelo lado esquerdo
    if ( newMapPosition > 0 ) then

      if ( (character.x + moveOffset ) > tilesSize ) then 
        finalCharPosX = character.x + moveOffset
        finalMapPosX = 0
        moveOffset = - moveOffset - tilesSize
      else
        finalCharPosX = tilesSize
        finalMapPosX = 0
        moveOffset = character.x - tilesSize
      end

    -- não deixa personagem sair pela direita
    elseif ( newMapPosition < -display.contentHeight ) then
      newMapPosition = -display.contentHeight

      if ( ( character.x + moveOffset ) < map.designedWidth ) then
        finalCharPosX = character.x + moveOffset
        finalMapPosX = newMapPosition
        moveOffset = moveOffset - tilesSize
      else
        finalCharPosX = map.designedWidth - tilesSize
        finalMapPosX = newMapPosition
        moveOffset = map.designedWidth - character.x - tilesSize 
      end

    else 
      finalCharPosX = character.x + moveOffset
      finalMapPosX = newMapPosition
      moveOffset = tilesSize * steps - tilesSize
    end 

  elseif ( (direction == "up" ) or (direction == "down") ) then
    newMapPosition = map.y - moveOffset

    -- impedir que personagem saia da tela por cima
    if ( newMapPosition > 0 ) then
      if ( (character.y + moveOffset ) >= 0 ) then
        finalCharPosY = character.y + moveOffset
        finalMapPosY = 0
        moveOffset = - moveOffset - tilesSize
     else
        finalCharPosY = tilesSize
        finalMapPosY = 0
        moveOffset = character.y - tilesSize
      end

    elseif ( newMapPosition < -display.contentWidth ) then
      if ( ( character.y + moveOffset) <= map.designedHeight ) then
        finalCharPosY = character.y + moveOffset
        finalMapPosY = -display.contentWidth
        moveOffset = moveOffset - tilesSize
     else 
        finalCharPosY = map.designedHeight - tilesSize
        finalMapPosY = -display.contentWidth
        moveOffset = character.y + moveOffset - map.designedHeight 
     end

    else 
      finalCharPosY = character.y + moveOffset
      finalMapPosY = newMapPosition
      moveOffset  = tilesSize * steps
    end

  else 
    print ( "Direcao inexistente" )
    return -1
  end

  -- Vira personagem quando a direção da esquerda/direita muda 
  if ( ( direction == "left" ) and ( character.xScale ~= -1  ) ) then character.xScale = -1
  elseif ( ( direction == "right" ) and ( character.xScale == -1 ) ) then character.xScale = 1 end

  charMovementDuration = moveOffset/tilesSize * stepDuration 
  transition.to( map, {time = charMovementDuration, delay = delayMovement, x = finalMapPosX, y = finalMapPosY } )
  transition.to( character, {time = charMovementDuration, delay = delayMovement, x = finalCharPosX, y =  finalCharPosY } )
  
end



local function executeInstructions ( )
  if ( instructionsQueue.last < instructionsQueue.first)  then
    instructionsQueue:reset( )
    return 0
  end
  local movementDuration = instructionsQueue.steps[instructionsQueue.first] * stepDuration

  moveCharacter ( instructionsQueue.direction[instructionsQueue.first], instructionsQueue.steps[instructionsQueue.first] )
  instructionsQueue:remove( )
  timer.performWithDelay( movementDuration, executeInstructions )
  print(movementDuration)

end

-- -----------------------------------------------------------------------------------
-- Cenas
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

  local sceneGroup = self.view

  -- Cria mapa a partir do arquivo JSON exportado pelo tiled
  display.setDefault("magTextureFilter", "nearest")
  display.setDefault("minTextureFilter", "nearest")
  local mapData = json.decodeFile(system.pathForFile("imgs/tiles/tilemap.json", system.ResourceDirectory))  -- load from json export
  map = tiled.new(mapData, "imgs/tiles")

  -- Posiciona tela no meio do mapa (eixo y)
  map.y = display.viewableContentHeight - map.designedHeight/2

  -- Cria joystick a partir de outro arquivo JSON 
  -- Não está no mesmo JSON do mapa porque assim é possível
  -- garantir que o joystick não irá se mover quando o mapa
  -- sair de lugar
  local joystickData = json.decodeFile(system.pathForFile("imgs/tiles/joystick.json", system.ResourceDirectory))  -- load from json export
  joystick.tiled = tiled.new(joystickData, "imgs/tiles")

  -- posiciona joystick no canto direito da tela
  joystick.tiled.x, joystick.tiled.y = display.contentHeight, display.contentCenterY
  
  --@TODO: TIRAR ISSO QUANDO ACABAREM OS TESTES COM A TELA
  local dragable = require "com.ponywolf.plugins.dragable"
  map = dragable.new(map)


  -- Atribuição das referências para os objetos
  -- lembrar: o myName (para os listeners) de cada objeto foi definido
  -- no próprio tiled
  character = map:findObject("character")

  joystick.right = joystick.tiled:findObject("right") 

  joystick.left = joystick.tiled:findObject("left") 

  joystick.down = joystick.tiled:findObject("down") 

  joystick.up = joystick.tiled:findObject("up") 

  joystick.screen = joystick.tiled:findObject("screen")

  stepsText = display.newText( joystick.tiled, stepsCount, joystick.screen.x, joystick.screen.y, "DS-DIGIT.ttf", 50 )
  stepsText:setFillColor( 0, 0, 0 )

  okButton = display.newRect( joystick.tiled, joystick.screen.x + 55, joystick.screen.y + 55, 60, 30 )
  local okText = display.newText( joystick.tiled, "OK", joystick.screen.x + 55, joystick.screen.y + 55, system.nativeFont, 30 )
  okButton:setFillColor( 0, 0, 0 )
end


-- show()
function scene:show( event )

  local sceneGroup = self.view
  local phase = event.phase

  if ( phase == "will" ) then
    -- criar os listeners para mover o character por meio do joystick
    joystick.right:addEventListener( "tap", defineDirection )
    joystick.left:addEventListener( "tap", defineDirection )
    joystick.down:addEventListener( "tap", defineDirection )
    joystick.up:addEventListener( "tap", defineDirection )

    joystick.screen:addEventListener( "touch", defineSteps )
  elseif ( phase == "did" ) then
    okButton:addEventListener( "tap", executeInstructions )
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
