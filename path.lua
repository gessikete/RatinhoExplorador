module(..., package.seeall)

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local persistence = require "persistence"

local M = { }

-- -----------------------------------------------------------------------------------
-- Funções referentes ao caminho
-- -----------------------------------------------------------------------------------
-- Retorna o caminho marcado (quando o personagem anda)
function M.new( map )
	local path = { }
	local markedPath = { }
	local sensors = { x = { } }

	-- Mostra um tile quando o personagem anda sobre ele
	function M:showTile( k )
		table.insert( markedPath, path[k] )
		path[k].alpha = 1
	end

	-- Estabelece os sensores
	function M:setSensors()
		print( "PREPARANDO SENSORES" )
	  	-- Referências para os tiles do caminho
	  	local pathLayer = map:findLayer("path")
	  	local sensorsLayer = map:findLayer("sensors")

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
	    	if ( sensors.x[xCenter][yCenter] ) then 
	      		sensors.x[xCenter][yCenter].myName = i 
	    	else print (" Sensor nao encontrado em x = " .. xCenter .. " e y = " .. yCenter )
	    	end
	    	table.insert( path, pathLayer[i] )
	  	end 
	end

	function M:hidePath()
		for k, v in pairs( path ) do
			transition.fadeOut( path[k], { time = 400 } )
		end
	end

	-- -----------------------------------------------------------------------------------
	-- Liberação de memória
	-- -----------------------------------------------------------------------------------
	function M:destroy()
		for k, v in pairs( path ) do
   			path[k] = nil 
  		end
  		path = nil 

  		for k, v in pairs( markedPath ) do
    		table.remove( markedPath, k )
  		end
  		markedPath = nil


  		for k0, v0 in pairs ( sensors ) do
  			for k1, v1 in pairs ( v0 ) do
  				for k2, v2 in pairs( v1 ) do
  					v1[k2] = nil 
  				end
  				v1 = nil 
  				v0[k1] = nil
  			end
  			v0 = nil 
  			sensors[k0] = nil 
  		end
  		sensors = nil 
	end

	return markedPath 
end


return M