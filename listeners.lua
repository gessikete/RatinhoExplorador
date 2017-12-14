local M = { }
local M_mt = { __index = M }


function M:new()
	local listeners = { }
	return setmetatable( { listeners = listeners }, M_mt )
end

function M:add( target, event, func )
	local alreadyAdded = false 
	for k, v in pairs( self.listeners ) do
		if  ( ( target == v.target ) and ( event == v.event ) and ( func  == v.func ) ) then
			alreadyAdded = true 
			break
		end
	end

	if ( alreadyAdded == false ) then 
		target:addEventListener( event, func )
		table.insert( self.listeners, { target =  target, event = event, func = func } )
	end
end


function M:remove( target, event, func )
	for k, v in pairs( self.listeners ) do
		if  ( ( target == v.target ) and ( event == v.event ) and ( func  == v.func ) ) then
			target:removeEventListener( event, func )
			table.remove( self.listeners, k )
			break
		end
	end
end

function M:destroy()
	for k, v in pairs( self.listeners ) do
		local target = v.target
		local event = v.event 
		local func = v.func 

		if ( target.removeEventListener ) then 
			target:removeEventListener( event, func )
			self.listeners[k] = nil
		end
	end
end

return M