dofile "$SURVIVAL_DATA/Scripts/game/worlds/BaseWorld.lua"

function BaseWorld.sv_e_onStreamChatCommand( self, params )
	if params[1] == "/memekit" then
		local chest = sm.shape.createPart( obj_container_chest, params.player.character.worldPosition + sm.vec3.new( 0, 0, 5 ), sm.quat.identity() )
		chest.color = sm.color.new( 0, 1, 1 )
		local container = chest.interactable:getContainer()

		sm.container.beginTransaction()
		sm.container.collect( container, obj_resource_glowpoop, 100 )
		sm.container.collect( container, obj_pneumatic_pipe_03, 10 )
		sm.container.collect( container, obj_resource_glowpoop, 100 )
		sm.container.endTransaction()

	elseif params[1] == "/rain" then
		print("rain?")
		local bodies = sm.body.getAllBodies()
		for _, body in ipairs( bodies ) do
			local usable = body:isUsable()
			if usable then 
				local shape = body:getShapes()[1]
				if shape:getShapeUuid() == obj_interactive_propanetank_small or  shape:getShapeUuid() == obj_interactive_propanetank_large then
					sm.physics.explode( shape:getWorldPosition() , 7, 2.0, 6.0, 25.0, "RedTapeBot - ExplosivesHit" )
				end
			end
		end
		for i = 0, 150 do
			--print("spawn bomb")
			local bomb = sm.shape.createPart( obj_interactive_propanetank_large, params.location + sm.vec3.new( sm.noise.randomRange(-80,80), sm.noise.randomRange(-80,80), sm.noise.randomRange(35,250) ), sm.quat.identity() )
		end

	elseif params[1] == "/blast" then
		local units = sm.unit.getAllUnits()
		--print("blasting",params[2]:getCharacter():getWorldPosition())
		--params['location'] = params[2]:getCharacter():getWorldPosition()
		-- TODO: bug where type of params[2] a player and not properly setup
		for i, unit in ipairs( units ) do
			if InSameWorld( self.world, unit ) then
				if unit ~= nil then
					local distance = (  unit:getCharacter().worldPosition - params.location ):length()
					if distance < 500 then
						sm.physics.explode( unit:getCharacter().worldPosition + sm.vec3.new(0,0,0.05) , 10, 5, 15, 25, "RedTapeBot - ExplosivesHit" ) -- potentialluy ignore character?
						--unit:destroy() -- Failsafe
					end
				end
			end			
		end

	end
end