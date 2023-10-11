
-- TODO: Make my own timer class that returns count and limit as well...

--IDEAS: Fake Fire effects (gives damage and flame particles until water)
-- Safe zones?
-- Inverted controls
-- Chanel members/donators bypass cooldowns
-- Nuke
-- give full water bucket
-- DAY NIGht
-- Custom buliing block giviung and gamemodes
-- more money, higher block limit
-- Eject seat command
-- random teleport
-- noaggro -- temporary timed event
-- Make sure to validate that the type of download is a blueprint and not a mod
-- increase shield duration to 30
-- /clear
-- clearcache also clears out workshop content fodler
dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_survivalobjects.lua")

StreamReader = class( nil )
local ReadClock = os.clock 

local MOD_FOLDER = "$CONTENT_DATA/Scripts/StreamReaderData"
local DownloadFolder = "$CONTENT_DATA/tmp-download" -- location of downloads and hopefully descriptions
local GameStatsPath = MOD_FOLDER.."/gameStats.json"
local StreamChatPath = MOD_FOLDER.."/streamchat.json"

function StreamReader.sv_onCreate( self, GameData )
	if sm.isHost then
		StreamReader.server_onCreate(self, GameData)
        print("hosting stream reader")
	end
end

-- TODO: Stop reading commands while player is dead
function StreamReader.server_onCreate( self, GameData )
    self.readRate = 1
    self.started = ReadClock()  
    self.localClock = 0
    self.gotTick = false
    self.lastInstruction = {['id']= -1}
    self.instructionQue = {}
    self.initialized = false
    self.deathCounter = 0
    self.loadedFiles = {}
    local loadedGameStats = sm.json.open( GameStatsPath )
    local deathStats = loadedGameStats.deaths
    deaths = 0
    if(deathStats ~= nil and type(deathStats) == "number") then
        deaths = deathStats
    end
    self.gameStats = {
        deaths = deaths,
        bonks = 0,
        robotKills = 0
    }
    -- states
    self.playerDead = false
    self.dataChange = false
end

function StreamReader.server_onDestroy( self )
    --print("streamreader destroy")
end

function StreamReader.server_onRefresh( self )
	--print("Refresh")
end

function StreamReader.sv_onRefresh( self, GameData )
    --self:server_onDestroy()
end

function StreamReader.init(self)
    --print("Streamreader init hehe")
end

function StreamReader.sv_readJson( self, fileName )
    local success, instructions = pcall(sm.json.open, fileName )
    if success then
        if instructions ~= nil then
            return instructions
        else
            return nil
        end
        return instructions
    end
    return nil
end

function StreamReader.runInstructions(self,instructionQue)
    for k=1, #instructionQue do local instruction=instructionQue[k]
        StreamReader.runInstruction(self, instruction)
        self.lastInstruction = instruction
    end
end

function StreamReader.FindFunctionFromString( self, param )
    local idxr
    local current = ""
    for i = 1, #param + 1 do
        local v = param:sub(i,i)
        if v == "." or v == ":" or i == #param + 1 then
            if idxr then
                idxr = idxr[current]
            else
                idxr = _G[current]
            end
            current = ""
        else
            current = current .. v
        end        
    end
    return idxr
end

function StreamReader.runInstruction( self, instruction )
    local altmessage = nil
    local usernameColor = "#ff0000"
    local textColor = "#ffffff"
    local moneyColor = "#3fe30e"
    
    local alertmessage = ""
    if instruction == nil then
        return
    end

    if self.loadedFiles[instruction.file] == nil then
        dofile(MOD_FOLDER.."/LuaCommands/"..instruction.file)
        self.loadedFiles[instruction.file] = true
    end

    if not sm.host then
        sm.host = sm.player.getAllPlayers()[1]
    end

    if instruction.network == "Server" then
        self.network:sendToServer("server_runInstruction", instruction)
    else
        if instruction.class == "Player" then
            sm.event.sendToPlayer(sm.host, "ambigous_runInstruction", instruction)
        elseif instruction.class == "World" then
            sm.event.sendToWorld(sm.host:getCharacter():getWorld(), "ambigous_runInstruction", instruction)
        else
            StreamReader.ambigous_runInstruction( self, instruction )
        end
    end
end

function StreamReader.server_runInstruction( self, instruction )
    if not sm.host then
        sm.host = sm.player.getAllPlayers()[1]
    end

    if instruction.class == "Player" then
        sm.event.sendToPlayer(sm.host, "ambigous_runInstruction", instruction)
    elseif instruction.class == "World" then
        sm.event.sendToWorld(sm.host:getCharacter():getWorld(), "ambigous_runInstruction", instruction)
    else
        StreamReader.ambigous_runInstruction( self, instruction )
    end
end

function StreamReader.ambigous_runInstruction( self, instruction )
    if instruction.required then
        instruction.params = _G[instruction.command .. ".Param"](self, instruction.params)
    end
    local func = StreamReader.FindFunctionFromString(self, instruction.command)
    func( self, instruction.params )
end

--- Reads specified file at interval (sever?)
function StreamReader.ReadFileAtInterval( self, interval )
    if self.localClock % interval == 0 then
        local jsonData = StreamReader.sv_readJson(self, StreamChatPath)
        if jsonData == nil or jsonData == {} or not jsonData or #jsonData == 0 or jsonData == "{}" then
            return
        end
        local lastInstructionID = jsonData[#jsonData].id
        if self.lastInstruction == nil or lastInstructionID ~= self.lastInstruction.id then
            self.recievedInstruction = true
            -- Only append instructions that are > than lastInstruction
            for i,j in pairs(jsonData) do
                if self.lastInstruction == nil or j.id ~= self.lastInstruction.id then
                    table.insert(self.instructionQue, j)
                end
            end
            self.lastInstruction = self.instructionQue[#self.instructionQue]
        end
    end
end

function StreamReader.clearInstructions( self )
    local lastInstructions =  StreamReader.sv_readJson(self, StreamChatPath)
    if lastInstructions == nil or self.lastInstruction == nil then
        return
    end
    self.instructionQue = {}
	sm.json.save(nil, StreamChatPath)
end

function StreamReader.sv_onFixedUpdate( self, timeStep )  
    -- Server awaiting
    if self.initialized then
        StreamReader.ReadFileAtInterval( self, self.readRate )
    end
    if self.dataChange then
        StreamReader.outputData( self, self.gameStats )
        self.dataChange = false
    end
end

function StreamReader.cl_onFixedUpdate( self, timeStep )
    if self.initialized then
        local dead = self.player:getCharacter():isDowned()
        self.deathCounter = sm.json.open( GameStatsPath ).deaths
        if dead and not self.playerDead then
            self.deathCounter = self.deathCounter + 1
            self.gameStats.deaths = self.deathCounter -- probably unecessary, could consolidate
            self.playerDead = true
            sm.gui.chatMessage("#ffff00You have died #ff0000" .. self.deathCounter .. " #ffff00times")
            self.dataChange = true
        elseif not dead and self.playerDead then
            self.playerDead = false 
        end
    else
        local player = sm.localPlayer.getPlayer()
        if self.player == nil then self.player = player end
        if player ~= nil then
            local char = player.character
            if char ~= nil then
                local pos = char:getWorldPosition()
                local dir = char:getDirection()
                local tel = pos + dir * 5
                local cellX, cellY = math.floor( tel.x/64 ), math.floor( tel.y/64 )
                local telParams = {cellX,cellY,player,tel}
                if pos ~= nil then
                    self.playerLocation = pos
                    if not self.initialized then
                        self.initialized = true
                        print("StreamReader Initialized")
                    end
                end
            end
        end
    end
    if self.recievedInstruction then
        StreamReader.runInstructions( self, self.instructionQue )
        StreamReader.clearInstructions( self )
        self.recievedInstruction = false   
    end
end

function StreamReader.outputData( self, data ) -- writes data to json file
    sm.json.save(data,GameStatsPath)
end