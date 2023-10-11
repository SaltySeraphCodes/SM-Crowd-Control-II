dofile "$SURVIVAL_DATA/Scripts/game/worlds/Overworld.lua"
dofile "$CONTENT_DATA/Scripts/Streamreader.lua"
dofile "$CONTENT_DATA/Scripts/Timer.lua"

CustomWorld = class( Overworld )

function CustomWorld.ambigous_runInstruction( self, instruction )
    StreamReader.ambigous_runInstruction( self, instruction )
end