module(..., package.seeall)

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local M = { updateFSM }

local slowStep = 400

-- -----------------------------------------------------------------------------------
-- Funções referentes às instruções
-- -----------------------------------------------------------------------------------

-- Retorna a lista das instruções
function M.new( tilesSize, character, markedPath, miniGame )
  local instructionsTable = { executing = 1, last = 0,  direction = { }, steps = { }, stop = false }
  local stopExecutionListeners
  local restartExecutionListeners

  -- Adiciona uma instrução à lista
  function instructionsTable:add ( direction, steps )
    self.last = self.last + 1
    self.direction[self.last] = direction
    self.steps[self.last] = steps
  end

  -- Reseta a lista para o estado inicial
  function instructionsTable:reset ()
    for i = self.executing, self.last do
      table.remove( self.direction, i )
      table.remove( self.steps, i )
    end

    self.executing = 1
    self.last = 0
    self.direction = { }
    self.steps = { }
  end

  function instructionsTable:remove( pos )
    for i = pos, self.last - 1 do
      self.steps[i] = self.steps[ i + 1 ]
      self.direction[i] = self.direction[ i + 1 ]
    end

    instructionsTable.steps[ self.last ] = nil  
    instructionsTable.direction[ self.last ] = nil 
    self.last = self.last - 1
  end

  function instructionsTable:isEmpty( )
    if ( ( self.executing == 1 ) and ( self.last == 0 ) ) then return true
    else return false  
    end 
  end

  -- Recebe os listeners dos botões (para evitar que o jogador adicione instruções ou volte para o menu durante a execução)
  function M:setGamePanelListeners( stop, restart )
    stopExecutionListeners = stop
    restartExecutionListeners = restart
  end

  -- -----------------------------------------------------------------------------------
  -- Funções relacionadas ao movimento do personagem (i.e., execução de instruções)
  -- -----------------------------------------------------------------------------------
  -- Move o personagem de acordo com a instrução atual
  local function moveCharacter( direction, steps, stepDuration ) 
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
 function M:unmarkPath ( markedPath )
    if ( markedPath ~= nil ) then 
      for i = #markedPath, 1, -1 do
        markedPath[i].alpha = 0
        table.remove( markedPath, i )
      end
      markedPath = { }
    end
  end

  -- Executa uma instrução
  local function executeSingleInstruction()
    if ( instructionsTable ~= nil ) then
      -- Condição de parada (fila de instruções vazia)
      if ( ( instructionsTable.last < instructionsTable.executing ) or ( instructionsTable.stop == true ) )  then
        -- Reestabelece os listeners do painel de instruções
        if ( restartExecutionListeners ) then 
          restartExecutionListeners()
          if ( M.updateFSM ) then
            timer.performWithDelay( slowStep, M.updateFSM )
          end
        else print( "Listener nulo (instructions.lua)" )
        end
        return 0
      end
      local movementDuration = instructionsTable.steps[instructionsTable.executing] * slowStep
      
      moveCharacter( instructionsTable.direction[instructionsTable.executing], instructionsTable.steps[instructionsTable.executing], slowStep )
      instructionsTable.executing = instructionsTable.executing + 1
      -- Executa próxima instrução com um delay
      timer.performWithDelay( movementDuration, executeSingleInstruction )
    end 
  end

  -- Executa todas as instruções na lista
  function M.executeInstructions()
    -- Pausa os listeners do painel de instruções, para impedir adição de instruções
    if ( stopExecutionListeners ) then 
      stopExecutionListeners()
      instructionsTable.stop = false 
    else print( "Listener nulo (instructions.lua)" )
    end
    -- Desmarca caminho anterior
    M:unmarkPath( markedPath )

    -- Executa as instruções uma a uma
    executeSingleInstruction()
  end

  -- -----------------------------------------------------------------------------------
-- Liberação de memória
-- -------------------------------------------------------------------------------------
  function M:destroyInstructionsTable()
    if ( instructionsTable ) then
      for k0, v0 in pairs( instructionsTable ) do
        if ( type(v0) == "table" ) then 
          for k1, v1 in pairs(v0) do
            table.remove( v0, k1 )
          end
        end
        instructionsTable[k0] = nil 
      end
      instructionsTable = nil 
    end

    M.updateFSM = nil 
  end

  return instructionsTable
end 

return M