local composer = require( "composer" )

local perspective = require("com.perspective.perspective")

local scene = composer.newScene()

local tiled = require "com.ponywolf.ponytiled"

local physics = require "physics"

local json = require "json"

local persistence = require "persistence"

local scenesTransitions = require "scenesTransitions"

local gamePanel = require "gamePanel"

local instructions = require "instructions"

local gameState = require "gameState"

local path = require "path"

physics.start()

--------------
-- Declaração das variáveis
--------------
local gameFile 

local camera = perspective.createView()

local map

local character

-- delay e tempo dos movimentos
local quickStep = 80

-- tamanho dos tiles usados no tiled
local tilesSize = 32

-- -----------------------------------------------------------------------------------
-- Funções de criação
-- -----------------------------------------------------------------------------------
local function setMap( )
  -- Cria mapa a partir do arquivo JSON exportado pelo tiled
  display.setDefault("magTextureFilter", "nearest")
  display.setDefault("minTextureFilter", "nearest")
  local maptiledData = json.decodeFile(system.pathForFile("tiled/newmap.json", system.ResourceDirectory))

  map = tiled.new(maptiledData, "tiled")

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
  layer:setCameraOffset( -60, -tilesSize/2 )

  layer = camera:layer(2)
  layer:setCameraOffset( -60, -tilesSize/2 )

  camera:setBounds( 170, 320, 150, 345 )
  camera:setFocus(character)
  camera:track()
  camera:toBack( )
end

-- -----------------------------------------------------------------------------------
-- Listeners
-- -----------------------------------------------------------------------------------


-- Trata dos tipos de colisão
local function onCollision( event )
  phase = event.phase
  local obj1 = event.object1
  local obj2 = event.object2

  if ( event.phase == "began" ) then
    if ( ( ( obj1.myName == "house" ) and ( obj2.myName == "character" ) ) or ( ( obj1.myName == "character" ) and ( obj2.myName == "house" ) ) ) then 
      transition.cancel( )
      scenesTransitions.gotoHouse( )
    -- Colisão entre o personagem e os sensores dos tiles do caminho
    elseif ( ( obj1.myName == "character" ) and ( obj2.myName ~= "collision" ) ) then 
      character.steppingX = obj1.x 
      character.steppingY = obj1.y 
      path:showTile( obj2.myName )
      --table.insert( markedPath, path[obj2.myName] )
    elseif ( ( obj2.myName == "character" ) and ( obj1.myName ~= "collision" ) ) then 
      character.steppingX = obj1.x 
      character.steppingY = obj1.y 
      path:showTile( obj1.myName )
      --table.insert( markedPath, path[obj1.myName] )
    -- Colisão com os demais objetos e o personagem (rope nesse caso)
    elseif ( ( ( obj1.myName == "collision" ) and ( obj2.myName == "rope" ) ) or ( ( obj1.myName == "rope" ) and ( obj2.myName == "collision" ) ) ) then 
      transition.cancel( )
    end
  end
  return true 
end

-- -----------------------------------------------------------------------------------
-- Remoções para limpar a tela
-- -----------------------------------------------------------------------------------
local function destroyMap( )
  map:removeSelf( )
  camera:destroy( )

  map = nil 
  character = nil 

  path:destroy( )
end

local function cleanScene( )
  instructions:destroyInstructionsTable( )
  destroyMap( )
  gamePanel:destroy( )

  Runtime:removeEventListener( "collision", onCollision )
end

local function finishedLoading( )
  -- Retira imagem de carregamento (uma vez que a transição para o último ponto salvo se finalizou)
  transition.fadeOut( loading, { time = 800, onComplete = function( ) loading:removeSelf( ) loading = nil end } )
  
  -- Adiciona o listener das colisões, já que o personagem já está no ponto certo do mapa
  Runtime:addEventListener( "collision", onCollision )
  gameState:save( "map", character.steppingX, character.steppingY )
end

local function loadGameFile( )
  -- Mostra uma imagem de carregamento
  local loadingData = json.decodeFile(system.pathForFile("tiled/loading.json", system.ResourceDirectory))  -- load from json export
  loading = tiled.new(loadingData, "tiled")

  gameFile = persistence.loadGameFile( )
  if ( gameFile ~= nil ) then 
    local startingPointX, startingPointY = persistence.startingPoint( gameFile.miniGame )
    local stepsX = math.ceil( ( gameFile.character.steppingX - startingPointX ) / tilesSize )
    local stepsY = math.ceil( ( gameFile.character.steppingY - startingPointY ) / tilesSize )
    local time
    if ( math.abs(stepsX) > math.abs(stepsY) ) then 
      time = math.abs(stepsX) * quickStep
    else 
      time = math.abs(stepsY) * quickStep
    end  

    transition.to( character, {time = time, x = character.x + stepsX * tilesSize, y =  character.y + stepsY * tilesSize, onComplete = finishedLoading } )
    character.steppingX = gameFile.character.steppingX
    character.steppingY = gameFile.character.steppingY
  else 
    print("Arquivo do jogo vazio")
    finishedLoading( )
  end  
end

-- -----------------------------------------------------------------------------------
-- Cenas
-- -----------------------------------------------------------------------------------
-- create()
function scene:create( event )
  sceneGroup = self.view
  local markedPath

  setMap( )
  setCharacter( ) 

  persistence.setCurrentFileName("ana")

  loadGameFile( )
  markedPath = path.new( map )
  path:setSensors( )

  instructionsTable = instructions.new( tilesSize, character, markedPath )

  sceneGroup:insert( map )
  sceneGroup:insert( gamePanel.new( instructions.executeInstructions ) )
end

-- show()
function scene:show( event )
  local sceneGroup = self.view
  local phase = event.phase

  if ( phase == "will" ) then
    setCamera()
    gamePanel:addDirectionListeners( )

  elseif ( phase == "did" ) then
    
    --Runtime:addEventListener( "collision", onCollision )
    gamePanel:addButtonsListeners( )
    gamePanel:addInstructionPanelListeners( )

    --instructionsTable.direction = {"right","down","right","down","right","right","up","left","right","down","left","down","left","down","left","up","right","up","left","up","right"}
    --instructionsTable.steps = {5,6,6,2,3,6,6,5,5,6,2,9,7,3,13,6,3,8,4,6,3}
    --instructionsTable.last = 21

    --instructionsTable.direction = {"right","down","right","down","left","down","right","up","right","down","left","down","left","up","left","up","left","up","left","up","right"}
    --instructionsTable.steps = {2,2,2,2,2,2,6,3,3,6,3,3,3,1,3,2,3,2,1,7,4}
    --instructionsTable.last = 21
  end
end

-- hide()
function scene:hide( event )
  local sceneGroup = self.view
  local phase = event.phase

  if ( phase == "will" ) then
    transition.cancel()
  elseif ( phase == "did" ) then
    --gameState:save( "map", character.steppingX, character.steppingY )
    cleanScene()
    composer.removeScene( "map" )
  end
end

-- destroy()
function scene:destroy( event )

  local sceneGroup = self.view
  gamePanel:removeGoBackButton( )
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