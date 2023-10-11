dofile "$SURVIVAL_DATA/Scripts/game/SurvivalPlayer.lua"
dofile "$CONTENT_DATA/Scripts/Timer.lua"

CustomPlayer = class( SurvivalPlayer )

function CustomPlayer.server_onCreate( self )
    SurvivalPlayer.server_onCreate( self )
    CreateTimer(self)
	print("Player.server_onCreate")
end

function CustomPlayer.server_onFixedUpdate( self, timeStep )
    SurvivalPlayer.server_onFixedUpdate( self, timeStep )
    self.Timer:Tick()
end

function CustomPlayer.ambigous_runInstruction( self, instruction )
    StreamReader.ambigous_runInstruction( self, instruction )
end