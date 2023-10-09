dofile "$SURVIVAL_DATA/Scripts/game/SurvivalPlayer.lua"

Player = class( SurvivalPlayer )

function Player.server_onCreate( self )
    SurvivalPlayer.server_onCreate( self )
	print("Player.server_onCreate")
end

function Player.server_runInstruction( self, instruction )
    StreamReader.ambigous_runInstruction( self, instruction )
end

function Player.client_runInstruction( self, instruction )
    StreamReader.ambigous_runInstruction( self, instruction )
end