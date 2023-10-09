_G["Default.Aggro.Param"] = function( self, param ) if type(param) == type("") then param = { param } end param.player = sm.player.getAllPlayers()[1]; return param; end

_G["Default.Give.Param"] = function( self, param ) if type(param) == type("") then param = { param } end param.player = sm.player.getAllPlayers()[1]; return param; end

