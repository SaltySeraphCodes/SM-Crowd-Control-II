dofile "$SURVIVAL_DATA/Scripts/game/SurvivalGame.lua"
dofile "$CONTENT_DATA/Scripts/World.lua"
dofile "$CONTENT_DATA/Scripts/Streamreader.lua"
dofile "$CONTENT_DATA/Scripts/Timer.lua"

MOD_FOLDER = "$CONTENT_DATA/Scripts/StreamReaderData"
download_folder = "$CONTENT_DATA/tmp-download"
CustomGame = class( SurvivalGame )

function CustomGame.server_onCreate( self )
    SurvivalGame.server_onCreate( self )
	CreateTimer(self)
	print("CustomGame.server_onCreate")
    
	StreamReader.sv_onCreate(self)
    print("Loaded stream Reader", self.initialized)
end

function CustomGame.server_onRefresh( self )
	SurvivalGame.server_onRefresh(self)
	StreamReader.sv_onRefresh(self)
    print("Reloaded StreamReader")
end

function CustomGame.server_runInstruction(self, instruction)
	StreamReader.server_runInstruction(self, instruction)
end

function CustomGame.server_runInstructionPlayer(self, instruction)
	StreamReader.server_runInstructionPlayer(self, instruction)
end

function CustomGame.client_onRefresh( self )
	--StreamReader.sv_onRefresh(self)
    print("Reloaded StreamReader")
end

function CustomGame.server_onFixedUpdate( self, timeStep )
	if StreamReader then
		if self.initialized then
			StreamReader.sv_onFixedUpdate( self, timeStep )
		end
	end
	self.Timer:Tick()
end

function CustomGame.client_onFixedUpdate( self, timeStep )
	if StreamReader then
		StreamReader.cl_onFixedUpdate( self, timeStep )
	end
end