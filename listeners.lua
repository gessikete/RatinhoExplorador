local M = { }
local M_mt = { __index = M }


function M:new()
	local listeners = { }
	return setmetatable( { listeners = listeners }, M_mt )
end

--print( "list: " .. tostring(listeners) )
function M:add( target, event, func )
	local alreadyAdded = false 
	for k, v in pairs( self.listeners ) do
		if  ( ( target == v.target ) and ( event == v.event ) and ( func  == v.func ) ) then
			alreadyAdded = true 
			break
		end
	end

	if ( alreadyAdded == false ) then 
		--print( event .. ": " .. tostring(target)  )
		--print( print( "list: " .. tostring(self.listeners) ) )
		target:addEventListener( event, func )
		table.insert( self.listeners, { target =  target, event = event, func = func } )
	end
end


function M:remove( target, event, func )
	for k, v in pairs( self.listeners ) do
		if  ( ( target == v.target ) and ( event == v.event ) and ( func  == v.func ) ) then
			--print( "REMOVE: " .. "event: " .. event .. "; targ: " .. tostring(target) )
			target:removeEventListener( event, func )
			table.remove( self.listeners, k )
			break
		end
	end
end

function M:destroy()
	--print( "----" )
	for k, v in pairs( self.listeners ) do
		local target = v.target
		local event = v.event 
		local func = v.func 

		--print( k )
		if ( target.removeEventListener ) then 
			--print( tostring(target) )
			target:removeEventListener( event, func )
			self.listeners[k] = nil
		end
	end
	--print( "----" )
end

return M