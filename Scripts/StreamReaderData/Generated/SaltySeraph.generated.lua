_G["SaltySeraph.Blast.Param"] = function( self, param ) if type(param) == type("") then param = { param } end param.location = sm.player.getAllPlayers()[1]:getWorldPosition(); return param; end

_G["SaltySeraph.Fast.Param"] = function( self, param ) if type(param) == type("") then param = { param } end param.player = sm.player.getAllPlayers()[1]; return param; end

_G["SaltySeraph.Kit.Param"] = function( self, param ) if type(param) == type("") then param = { param } end param.player = sm.player.getAllPlayers()[1]; return param; end

_G["SaltySeraph.Trip.Param"] = function( self, param ) if type(param) == type("") then param = { param } end param.player = sm.player.getAllPlayers()[1]; return param; end

