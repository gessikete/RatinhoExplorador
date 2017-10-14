module(..., package.seeall)

local M = { }

local slowStep = 70

function M.new( tilesSize, character, markedPath )
  local instructionsTable = { executing = 1, last = 0,  direction = { }, steps = { } }

  function instructionsTable:add ( direction, steps )
    self.last = self.last + 1
    self.direction[self.last] = direction
    self.steps[self.last] = steps
  end

  function instructionsTable:reset ( )
    for i = self.executing, self.last do
      table.remove( self.direction, i )
      table.remove( self.steps, i )
    end

    self.executing = 1
    self.last = 0
    self.direction = { }
    self.steps = { }
  end


  -- -----------------------------------------------------------------------------------
  -- Funções relacionadas ao movimento do personagem
  -- -----------------------------------------------------------------------------------
  -- Cada passo é equivalente a 1 tileSize
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
  local function unmarkPath ( markedPath )
    if ( markedPath ~= nil ) then 
      for i = #markedPath, 1, -1 do
        markedPath[i].alpha = 0
        table.remove( markedPath, i )
      end
      markedPath = { }
    end
  end

  local function executeSingleInstruction ( )
    if ( instructionsTable ~= nil ) then
      -- Condição de parada (fila de instruções vazia)
      if ( instructionsTable.last < instructionsTable.executing)  then
        return 0
      end
      local movementDuration = instructionsTable.steps[instructionsTable.executing] * slowStep
      
      moveCharacter( instructionsTable.direction[instructionsTable.executing], instructionsTable.steps[instructionsTable.executing], slowStep )
      instructionsTable.executing = instructionsTable.executing + 1
      -- Executa próxima instrução com um delay
      timer.performWithDelay( movementDuration, executeSingleInstruction )
    end 
  end

  function M.executeInstructions ( )
    -- Desmarca caminho anterior
    unmarkPath( markedPath )

    -- Executa as instruções uma a uma
    executeSingleInstruction( )
  end

  function M:destroyInstructionsTable( )
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

  return instructionsTable
end 

return M