dofile "$SURVIVAL_DATA/Scripts/game/SurvivalGame.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_units.lua"
dofile "$CONTENT_DATA/Scripts/Streamreader.lua"
dofile "$CONTENT_DATA/Scripts/Timer.lua"

MOD_FOLDER = "$CONTENT_DATA/Scripts/StreamReaderData"
download_folder = "$CONTENT_DATA/tmp-download"
CustomGame = class( SurvivalGame )

function CustomGame.server_onCreate( self )
	self:SurvivalGame_server_onCreate()
	CreateTimer( self )
	print("CustomGame.server_onCreate")
    
	StreamReader.sv_onCreate( self )
    print("Loaded stream Reader", self.initialized)
end

function CustomGame.server_onRefresh( self )
	SurvivalGame.server_onRefresh( self )
	StreamReader.sv_onRefresh( self )
    print("Reloaded StreamReader")
end

function CustomGame.importFromFile( self, lparams )
	sm.creation.importFromFile( lparams.world, download_folder.."/blueprint.json", lparams.position, nil, true )
end

function CustomGame.server_runInstruction( self, instruction )
	StreamReader.server_runInstruction( self, instruction )
end

function CustomGame.server_onFixedUpdate( self, timeStep )
	SurvivalGame.server_onFixedUpdate( self, timeStep )
	self.Timer:Tick()
	if StreamReader then
		if self.initialized then
			StreamReader.sv_onFixedUpdate( self, timeStep )
		end
	end
end

function CustomGame.client_onFixedUpdate( self, timeStep )
	-- SurvivalGame.client_onFixedUpdate( self, timeStep )
	if StreamReader then
		StreamReader.cl_onFixedUpdate( self, timeStep )
	end
end

function CustomGame.SurvivalGame_server_onCreate( self )
	print( "SurvivalGame.server_onCreate" )
	self.sv = {}
	self.sv.saved = self.storage:load()
	print( "Saved:", self.sv.saved )
	if self.sv.saved == nil then
		self.sv.saved = {}
		self.sv.saved.data = self.data
		printf( "Seed: %.0f", self.sv.saved.data.seed )
		self.sv.saved.overworld = sm.world.createWorld( "$CONTENT_DATA/Scripts/World.lua", "CustomWorld", { dev = self.sv.saved.data.dev }, self.sv.saved.data.seed )
		self.storage:save( self.sv.saved )
	end
	self.data = nil
	print( self.sv.saved.data )
	if self.sv.saved.data and self.sv.saved.data.dev then
		g_godMode = true
		g_survivalDev = true
		sm.log.info( "Starting SurvivalGame in DEV mode" )
	end
	self:loadCraftingRecipes()
	g_enableCollisionTumble = true
	g_eventManager = EventManager()
	g_eventManager:sv_onCreate()
	g_elevatorManager = ElevatorManager()
	g_elevatorManager:sv_onCreate()
	g_respawnManager = RespawnManager()
	g_respawnManager:sv_onCreate( self.sv.saved.overworld )
	g_beaconManager = BeaconManager()
	g_beaconManager:sv_onCreate()
	g_unitManager = UnitManager()
	g_unitManager:sv_onCreate( self.sv.saved.overworld )
	self.sv.questEntityManager = sm.scriptableObject.createScriptableObject( sm.uuid.new( "c6988ecb-0fc1-4d45-afde-dc583b8b75ee" ) )
	self.sv.questManager = sm.storage.load( STORAGE_CHANNEL_QUESTMANAGER )
	if not self.sv.questManager then
		self.sv.questManager = sm.scriptableObject.createScriptableObject( sm.uuid.new( "83b0cc7e-b164-47b8-a83c-0d33ba5f72ec" ) )
		sm.storage.save( STORAGE_CHANNEL_QUESTMANAGER, self.sv.questManager )
	end
	-- Game script managed global warehouse table
	self.sv.warehouses = sm.storage.load( STORAGE_CHANNEL_WAREHOUSES )
	if self.sv.warehouses then
		print( "Loaded warehouses:" )
		print( self.sv.warehouses )
	else
		self.sv.warehouses = {}
		sm.storage.save( STORAGE_CHANNEL_WAREHOUSES, self.sv.warehouses )
	end
	self.sv.time = sm.storage.load( STORAGE_CHANNEL_TIME )
	if self.sv.time then
		print( "Loaded timeData:" )
		print( self.sv.time )
	else
		self.sv.time = {}
		self.sv.time.timeOfDay = 6 / 24 -- 06:00
		self.sv.time.timeProgress = true
		sm.storage.save( STORAGE_CHANNEL_TIME, self.sv.time )
	end
	self.network:setClientData( { dev = g_survivalDev }, 1 )
	self:sv_updateClientData()
	self.sv.syncTimer = Timer()
	self.sv.syncTimer:start( 0 )
end