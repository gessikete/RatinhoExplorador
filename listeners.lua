local M = { }

listeners = { }


function M.add( target, event, func )
	local alreadyAdded = false 
	for k, v in pairs( listeners ) do
		if  ( ( target == v.target ) and ( event == v.event ) and ( func  == v.func ) ) then
			alreadyAdded = true 
			break
		end
	end

	if ( alreadyAdded == false ) then 
		print( "ADDED: " .. tostring(target.hmm) )
		target:addEventListener( event, func )
		table.insert( listeners, { target =  target, event = event, func = func } )
	end
end


function M.remove( target, event, func )
	print( "REMOVEEEEEE: " .. target.hmm )
	for k, v in pairs( listeners ) do
		if  ( ( target == v.target ) and ( event == v.event ) and ( func  == v.func ) ) then
			target:removeEventListener( event, func )
			table.remove( listeners, k )
			break
		end
	end
end

function M.destroy()
	print( "======" )
	for k, v in pairs( listeners ) do
		local target = v.target
		local event = v.event 
		local func = v.func 

		print( "---" )
		print( "k: " .. k )
		print( "targ: " .. tostring(target.hmm) )
		print( "ev: " .. tostring(event) )
		print( "func: " .. tostring(func) )

		if ( target.removeEventListener ) then 
			target:removeEventListener( event, func )
			listeners[k] = nil
			print( "REMOVED" )
		end
		print( "---" )
	end

	for k, v in pairs( listeners ) do
		print( "hmm" )
	end
	print( "======" )
end


return M