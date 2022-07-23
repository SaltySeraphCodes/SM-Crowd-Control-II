dofile "$SURVIVAL_DATA/Scripts/game/SurvivalGame.lua"

dofile "$CONTENT_DATA/Scripts/World.lua"
dofile( "$CONTENT_DATA/Scripts/survival_streamreader.lua") 

MOD_FOLDER = "$CONTENT_DATA/Scripts/StreamReaderData"
BLUEPRINT_FOLDER = MOD_FOLDER .. "/blueprints"
Game = class( SurvivalGame )

function Game.server_onCreate( self )
    SurvivalGame.server_onCreate( self )
	print("Game.server_onCreate")
    
    g_streamReader = StreamReader() -- Generate stream reader
	g_streamReader:sv_onCreate(self)
    print("Loaded stream Reader",g_streamReader.initialized)
    --self:initScript()
end

function Game.cl_initScript(self) -- runs on create and refresh
	print("Init script game")
end

function Game.server_onRefresh( self )
	SurvivalGame.server_onRefresh(self)
	g_streamReader = StreamReader()
	g_streamReader:sv_onRefresh(self)
  
    print("refreshedStreamReader")
end


function Game.client_onRefresh( self )
	g_streamReader = StreamReader()
	g_streamReader:sv_onRefresh(self)
    --self:cl_initScript()
    print("refreshedStreamReader")
end

function Game.server_onFixedUpdate( self, timeStep )
	if g_streamReader then
		if g_streamReader.initialized then
			g_streamReader:sv_onFixedUpdate()
		end
	end
end


function Game.client_onFixedUpdate(self,dt)
	if g_streamReader then
		g_streamReader:cl_onFixedUpdate()
	end
end

function Game.cl_shield(self,params) -- Shield character Depreciated because Effects only work in survivalPlayer...
	self.shieldFX = sm.effect.createEffect("Loot - GlowItem",params.character)
	local effectName = "Loot - GlowItem"
	sm.effect.playEffect( effectName, params.position, sm.vec3.zero(), sm.quat.identity(), sm.vec3.one(), { ["Color"] = sm.color.new(225,55,225) } )
	self.effect:setPosition(params.position)
	self.shieldFX:start()
end

function Game.cl_importCreation( self, params )
	print("client import")
	objName = params
	playerDir = ( sm.vec3.new( 1, 1, 0 ) * sm.camera.getDirection() ) + sm.vec3.new( 0, 0, 2.5 )
	direction = playerDir * 5

	if(type(params)=="table") then
        objName = params[1]
		if params[2] ~= nil then
			-- front is default and already set
			if params[2] == "above" then
				direction = sm.vec3.new( 0, 0, 6 )
			elseif params[2] == "right" then
				direction = ( sm.camera.getRight() * 5 ) + sm.vec3.new( 0, 0, 2.5 )
			elseif params[2] == "left" then
				direction = ( sm.camera.getRight() * -5 ) + sm.vec3.new( 0, 0, 2.5 )
			elseif params[2] == "behind" then
				direction = ( playerDir * -5 ) + sm.vec3.new( 0, 0, 2.5 )
			elseif params[2] == "on" then
				direction = sm.vec3.new( 0, 0, -1 )
			end
		end
    end

	local pos = sm.localPlayer.getPlayer().character:getWorldPosition() + direction
	local importParams = {
		world = sm.localPlayer.getPlayer().character:getWorld(),
		name = objName,
		position = pos,
		location = BLUEPRINT_FOLDER -- should probably organize this
	}

	self.network:sendToServer( "sv_importCreation", importParams )
end

function Game.sv_importCreation( self, params )
	print("starting import")
    -- TODO add pcall for importing modded creations (it will fail to import)
    --[[
	local modPartsLoaded, err = pcall(sm.item.getShapeSize, sm.uuid.new('cf73bdd4-caab-440d-b631-2cac12c17904'))
	if not modPartsLoaded then
		error('sm.interop is not enabled for this world')
	end
    ]]

	if params.location == nil then
		sm.creation.importFromFile( params.world, "$SURVIVAL_DATA/LocalBlueprints/"..params.name..".blueprint", params.position ) -- will error... dont need this?? use default thing instead
	else
		--print("importing",params.location.."/"..params.name..".blueprint", params.position)
		sm.creation.importFromFile( params.world, params.location.."/"..params.name..".blueprint", params.position,nil,true )
	end
end