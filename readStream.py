from ast import parse
from socket import timeout
import pytchat # most recent thing in the core is the updated stuff
import time
import json
import os
import subprocess
import sys
import copy
#import requests
import threading
from winreg import *
import vdf
import json
from shutil import copyfile
import shutil
# import smObjects


#FAKE PAYLOADS
superChatPayload = {'id': 122, 'command':"/kill", 'author': "saltyseraph", 'sponsor': "true", 'userid': "kjdkjij90u0d", 'amount': 12.0}
regular_payload = {'id': 0, 'command': 'Hi', 'author': 'Lv Apples', 'sponsor': False, 'userid': 'UCSdVROtEFJMjUO_4f_aqPTg', 'amount': 0.0}
super2chat = {'id': 0, 'command': 'sup fuckerrrrr', 'author': 'Blackoutdrunk', 'sponsor': False, 'userid': 'UCyTAzuTRkpJaPSYdLz95u1A', 'amount': 2.0}
GAME_ID = '387990'
## This automatically finds the scrap mechanic installation (DEPREciated technically since custom games now out)
## and sets SM_Location appropriately

aReg = ConnectRegistry(None,HKEY_LOCAL_MACHINE)

aKey = OpenKey(aReg, r"SOFTWARE\WOW6432Node\Valve\Steam")

steamPathKey=str(QueryValueEx(aKey, "InstallPath"))

def formatRegKey(key):
    return key.split(',')[0].replace('\'', '').replace('\\\\', '\\').replace('(C:', 'C:').replace('(H:', 'H:') #Mine was on H: not C, possibly check for more drives?

steamPath = formatRegKey(steamPathKey)

vdfFile = os.path.join(steamPath, "steamapps", "libraryfolders.vdf")
#vdf process: Used to be one liner but debugged and it had leading parenthases 
#newVdFile = vdfFile.replace("(",'')
#openFile = open(newVdFile)
#loadFile = vdf.load(openFile)
#strFile = str(loadFile).replace('\'', '\"')
#print("Got thing",strFile)
vdfFileContent = str(vdf.load(open(vdfFile))).replace('\'', '\"')
#print("content:",vdfFileContent)
alternateSteamLibraries = json.loads(vdfFileContent)#["LibraryFolders"] ?? whats this for?

SM_Location = os.path.join(steamPath, "steamapps", "common", "Scrap Mechanic")

i = 1
while(str(i) in alternateSteamLibraries):
    path = os.path.join(alternateSteamLibraries[str(i)], "common", "Scrap Mechanic")
    if os.path.isdir(path):
        SM_Location = path
        break
    i = i + 1

###########################################################

# dir_path is the current directory
dir_path = os.path.dirname(os.path.realpath(__file__))

# commonly use sm folder locations
Local_Scripts = os.path.join(dir_path, "Scripts")
smBase = os.path.join(SM_Location, "Survival", "Scripts", "game") #Hard coding to just these scripts
dataBase = os.path.join(Local_Scripts, "StreamReaderData")
blueprintBase = os.path.join(dataBase, "blueprints") #location for stored databases
download_path = os.path.join(dir_path,"steamcmd","steamapps","workshop","content",GAME_ID)
steamcmd_path = os.path.join(dir_path,"steamcmd")

# commly used file locations
statOutput = os.path.join(dir_path, "DeathCounter.txt")
gameStats = os.path.join(dataBase, "gameStats.json")

# Import settings? for now have global settings
# TODO: Money pool to allow viewers to donate to a common goal
SETTINGS = {
    'showChats': True,
    'allFree': False, # make everything freee
    'sponsorFree': True, # channel Members get free commands
    'TheGuyMode': True, # Special mode for TheGuy920 -- Leaving this on because you did a lot and deserve it
    'fixedCost': 0, # if >0 and allFree == false, all commands will cost this price
    'interval': 1, # rate in which to check for new commands, BROKEN until fixed...
    'prefix': ['!','/','$','%'],
    'filename': os.path.join(dataBase, 'streamchat.json'),
    'videoID': "bDeysRZ3PJI", #<-- Update this to your stream ID 
    'commands': { # list of commands and parameters, their prices are the values
        'spawn': {
            'totebot': 0,
            'woc': 0,
            'worm': 0,
            'haybot': 0,
            'tapebot': 0,
            'redtapebot': 0,
            'farmbot': 0,
        },
        'give':{ # give items to player (automatically gives stack if possible?)
            'shotgun': 0, # gives 10
            'gatling': 0,
            'ammo': 0
        },
        'kit': { # gives player specified kit
            'seed': 0,
            'food': 0,
            'starter': 0,
            'pipe': 0,
            'meme': 0,
            'mechanic': 0
        },
        'aggro': 0, # aggro all nearby units to player
        'kill': 1, # kill player instantly
        'trip': 0, # Make player trip
        'slap': 0,
        'shield':0, # shield player for bried ammount of time
        'rain': 0, # spawn a bunch of explosives in the air, could be random objects?
        'raid': 0, # random raid at levels
        'blast':0,
        'heal': 0,
        'fast':0,
        'slow':0
    },
    'internalCommands':
    {
        'import':0
    },
    'single': ['raid', 'fast', 'slow','heal','shield','blast','trip','slap','aggro','rain','kill'] # list of all single param commands for extra validation
}

def outputCommandQueue(commandQue):
    #print("OUT=>", commandQue)
    with open(SETTINGS['filename'], 'w') as outfile:
        #print("opened file")
        jsonMessage = json.dumps(commandQue)
        log("Writing commands: "+" - " +jsonMessage)
        outfile.write(jsonMessage)

def addToQue(commands, handleCommand):
    #print("called add to que",commands,handleCommand)
    # adds to the already existing command que

    # log(commands)
    # Check if exists first
    # log("addQWue",commands)

    if not os.path.exists(SETTINGS['filename']):
        f = open(SETTINGS['filename'], "a")
        # make blank
        f.write('[]')
        f.close()

    with open(SETTINGS['filename'], 'r') as inFile:

        currentQue = json.load(inFile)
        #print("Current Queue:",currentQue,"\n adding:",commands)

        # if empty? or check len too
        if currentQue == None: 

            # Create empty list
            currentQue = []
            currentQue.extend(commands)
        else:
            currentQue.extend(commands)

        # determines if the command should be handled or not
        # unless this is being run from/after an internal command
        # has executed, leave as default (True)
        if handleCommand == True:
            # TODO: get callback on success?
            commandHandler(currentQue)
        elif handleCommand == False:
            # print("Sending Queue=>", currentQue)
            outputCommandQueue(currentQue)

def commandHandler(commandQue):
    # command handler will take 2 copies of the queue
    commandList = copy.copy(commandQue)

    # if the command type exsists in internalCommands, it will be removed from the final execution
    # and will be executed internally instead
    for command in copy.copy(commandQue):
        if command['type'] in SETTINGS['internalCommands']:
            commandList.remove(command)
            handleInternalCommand(command)

    # if the command queue is not empty, update it
    # after command has been handled, add it to the
    # queue again, but do not handle it
    if(len(commandList) > 0):
        #print("adding que commandList ",commandList)
        addToQue(commandList, False)

def handleInternalCommand(command):
    # internal command handler

    # yea, only got import as of now...
    if command['type'] == "import":
        try:
            # init fileId
            fileId = command['params']
            # if the command parameters are a list (ie. not a string)
            if not isinstance(command['params'], str):
                fileId = command['params'][0]

            # init blueprint.json file path and description file path
            jsonFile = os.path.join(download_path,fileId,"blueprint.json").replace("\\\\", "\\")

            # init destination file paths
            jsonFileDest = os.path.join(blueprintBase, fileId+".blueprint") #destination place
           
            # checks to see if its already been downloaded
            
            if not os.path.exists(jsonFileDest):
                if not os.path.exists(jsonFile):
                    # downloads workshop item (most errors happen here)
                    downloadWorkshopItem(fileId)

                # init timeout handler (seconds * 1000 / 50)
                timeOut = 20
                errorCount = 0
                # wait for file to exist or timeout
                while (not os.path.exists(jsonFile)) and errorCount < timeOut:
                    print(errorCount,timeOut,end=" ")#display timeout counter
                    errorCount = errorCount + 1
                    time.sleep(0.5)
                if errorCount > timeOut:
                    print("Timed out downloading")
                    return
                # copy blueprint to staging (downloads) folder
                copyfile(jsonFile, jsonFileDest)
                #copyfile(descFile, descFileDest)
            # gather json state (static versus dynamic)
            state = 0.0
            if len(command['params']) > 2:
                state = getImportType(command['params'][2])
            elif len(command['params']) > 1:
                state = getImportType(command['params'][1])

            # load the json blueprint
            with open(jsonFileDest, 'r') as f:
                jsonContent = json.loads(f.read())

            # update the state #possibly fix this??
            array = jsonContent["bodies"]
            for i in range(len(array)):
                array[i]["type"] = state

            # save the json blueprint
            with open(jsonFileDest, 'w') as json_file:
                json.dump(jsonContent, json_file)
            #print("saved file",jsonFileDest)
            # create command queue
            commandQue = []
            commandQue.extend(toJson(command))

            # update command queue
            #print("Updating commandque, internal command",commandQue)
            addToQue(commandQue, False)
            #might be a blocking function... we do not want this ran rapidly (large cooldown gameside)

        except Exception as e:
            # handle any download or file errors
            logCommandError(e, command)

def getImportType(string):
    if (string == "static"):
        return 1
    else:
        return 0

def logCommandError(e, command):
    # print error
    print(e)
    # generate new log command
    command['type'] = "log"
    command['params'] = str(e)
    commandQue = []
    commandQue.extend(toJson(command))
    # add log to queue (to send error msg to SM)
    #print("logging command error")
    addToQue(commandQue, False)

def downloadWorkshopItem(fileID):
    # if start params is not a string (ie. its an array) configure it
    if not isinstance(fileID, str):
        #print("Not instance???",fileID)
        fileID = str(fileID)

    # configure node run command
    startArgs = "steamcmd +login {username} {password} +workshop_download_item  387990 "+fileID+" +quit" #NOTICE: I removed my secondary account's username and password. Anonymous login/download does not work unfortunately
    wd = os.getcwd() # change wd so we can run steamcmd inside a different directory
    os.chdir(steamcmd_path)
    output = subprocess.check_call(startArgs, shell=True) # need to async this so that it can still run commands in background
    #output =subprocess.Popen(startArgs, cwd=steamcmd_path)
    os.chdir(wd)

    #print("Post output subprocess",output)
    # if app exits with error (69) alert of download failure
    if output == 69:
        raise Exception("Failed To Download Workshop Item: {0}".format(str(fileID)))
    
    
def generateCommand(command,parameter,cmdData): #Generates command dictionary
    command =  {'id': cmdData['id'], 'type':command, 'params':parameter, 'username': cmdData['author'], 
                'sponsor': cmdData['sponsor'], 'userid': cmdData['userid'], 'amount': cmdData['amount']}
    # print("Generated command:",command)
    return command

def validatePayment(command,price,message):
    # Validate payment data for the specified command
    # not necessary, just need price and message
    if command != None: 
        if SETTINGS['allFree'] or (SETTINGS['sponsorFree'] and message['sponsor']) or ((SETTINGS['fixedCost'] >0 and message['amount'] >= SETTINGS['fixedCost']) or message['amount'] >= price) :
           return True
        elif message['amount'] < price:
            print("Insuficcient payment",message['amount'],price)
            return False
        else:
            log("Payment Failed")
            return False
         
def validateCommand(parameters): 

    # {command is a array of parameters}
    comType = str(parameters[0])
    index = None
    price = None
    errorType = None

    # if comType == None or index error then wth??
    # Check if command valid first
    #print("Validating",comType,SETTINGS['commands'][comType]) #price
    if comType in SETTINGS['commands'] or comType in SETTINGS['internalCommands']: 

         # a single line commnand with no extra params ex: kill, trip...
        if len(parameters) == 1 or comType in SETTINGS['single']:
            if comType == "import":
                return False,index,errorType
                
            price = SETTINGS['commands'][comType]
            #if an actual price
            if type(price) is int: 
                return comType,index,price

            # the command is supposed to have a parameter
            else: 
                errorType = "Invalid parameter count"
                return False,index,errorType

        # command = with X parameters (max params is infinite for now)
        elif len(parameters) > 1: 

            # grab the next index
            index = str(parameters[1]) 
        ## do not uncomment these logs, you will get an error if you do

            # log(SETTINGS['commands'][comType])
            # log(index)
            
            # Check for command type, or failure 
            if comType in SETTINGS['commands']:

                # If valid item within that command
                if index in SETTINGS['commands'][comType]:
                    # should be the maximum layer needed
                    price =  SETTINGS['commands'][comType][index] 
                    return comType,index,price

            # added section for internally handled commands like the import command
            elif comType in SETTINGS['internalCommands']:
                return comType,parameters[1:],int(SETTINGS['internalCommands'][comType])
            else:
                errorType = "Index Invalid"
                print("Unrecognized Index:",index)
        else:
            errorType = "Param Invalid"
            print("Too many or not enought parameters",parameters)
    else:
        errorType = "Command Invalid"
        print("unrecognized command",comType)
    #  Eventually have output error message
    return False,index,errorType

def parseMessage(chat,mesID):
    # parse any messages
    comType = None
    parameter = None
    parsed = {'id': mesID, 'command': chat.message, 'author': chat.author.name, 'sponsor': chat.author.isChatSponsor, 'userid': chat.author.channelId, 'amount': chat.amountValue}
    #print("Parsed Message",parsed)
    message = parsed['command'].lower()

    # is actually a command # Possibly separate out to parsing function
    if message[0] in SETTINGS['prefix']: 
        #print("Found parametyer,",message)
        rawCommand = message.strip(message[0])
        parameters = rawCommand.split() #TODO: More validation to fix any potential mistakes
        #print("raw stuff",rawCommand)
        # custom section for TheGuy920 and exclusive chat command ability
        if chat.author.channelId == "UCbBBHW3dQkyw7-b1eBurnuQ" and parameters[0] == "chat" and SETTINGS['TheGuyMode'] == True: # special mode for TheGuy920 (leaving this here because why not)
            return generateCommand("chat",str(chat.message)[6:],parsed)

        if len(parameters) == 0:
            log("Only Recieved Prefix")
            return None

        comType,parameter,price = validateCommand(parameters)

        if comType == False:
            # possibly use index for details?
            print("Received Error for",rawCommand+": ",price) 
        else:
            # Now validate any payments
            validPayment = validatePayment(comType,price,parsed)
            if validPayment:
                command = generateCommand(comType,parameter,parsed)
                return command
            else:
                log("Invalid Payment")
    # super chat section (no prefix but payed monies)
    elif chat.amountValue > 0 or SETTINGS['showChats']:
        return generateCommand("chat",str(chat.message),parsed)

    return None
    
def readChat():

    commandQue = []
    cID = 0
   
    while chat.is_alive():
        # Also do stats reading/outputting
        with open(gameStats, 'r') as inFile:
            gameInfo = json.load(inFile)
            #log("Got GameStats")

        with open(statOutput, 'w') as outfile:
            deaths = gameInfo['deaths']
            output = "Deaths: {:.0f}".format(deaths)
            outfile.write(output)
            #log("outputing")

        for c in chat.get().sync_items():
            #print("chat get",commandQue)
            log(c.datetime+" - " +c.author.name+" - " +c.message)
            command = parseMessage(c,cID)
            if command != None:
                #print("adding to ccq",command)
                commandQue.append(command)
                cID +=1
            if len(commandQue) >0:
                #print("adding to q >0",commandQue)
                addToQue(commandQue, True)
                if chat.is_replay():
                    commandQue = []
                    #print("Replay resetting que",commandQue)
            time.sleep(1)

        commandQue = []
        #print("reset que2",commandQue)

        try:
            chat.raise_for_status()
        except Exception as e:
            print(type(e), str(e))

commandList = '''
List of available commands:

1. clear-cache
   > clears cached imports
2. reset-deaths
   > resets the death counter
3. help
   > displays this wonderful help message
'''
# 3. remove-mod
#   > restores the original game files, clears the cache, and removes the deathcounter and other files

def internalConsoleCommand(command):
    if(command == "clear-cache"): #TODO: Clear out entire folders of both source and destination
        shutil.rmtree(blueprintBase)
        os.makedirs(blueprintBase)
        log("import cache cleared")
    elif(command == "reset-deaths"):
        with open(gameStats, 'w') as outfile:
            outfile.write('{ "deaths": 0, "bonks": 0, "robotKills": 0 }')
        log("deaths reset")
    elif(command == "remove-mod"):
        print(commandList)
    elif(command == "help"):
        print(commandList)
    else:
        print("Unknown command, try typing 'help'")

def toJson(obj):
    # this is basically the same as generateCommand, but I made another one for some reason

    jsonContent = jsonContent = "[ {\"id\": "+str(obj["id"])+", \"type\": \""+str(obj["type"])+"\", \"params\": \""+str(obj["params"])+"\", \"username\": \""+str(obj["username"])+"\", \"sponsor\": "+str(obj["sponsor"]).lower()+", \"userid\": \""+str(obj["userid"])+"\", \"amount\": "+str(obj["amount"])+"} ]"
    
    # specical configuration if more than one parameter
    if not isinstance(obj['params'], str):
        params =  "\""+"\",\"".join(obj["params"])+"\""
        jsonContent = "[ {\"id\": "+str(obj["id"])+", \"type\": \""+str(obj["type"])+"\", \"params\": [ "+params+" ], \"username\": \""+str(obj["username"])+"\", \"sponsor\": "+str(obj["sponsor"]).lower()+", \"userid\": \""+str(obj["userid"])+"\", \"amount\": "+str(obj["amount"])+"} ]"
    
    return json.loads(jsonContent)

# Planned commands: give speed, give slowness, lightning strike?, chop wood?
# chat = pytchat.create(video_id =  SETTINGS['videoID']) # start reading livechat #Create it here?? or store in settings and generate on main()

chat = None

debug = False

# custom logging style (kinda dumb ngl)
def log(string):
    print("["+str(string)+"]")

if __name__ == '__main__':
    if debug:
        pass
        # debug stuff here
    else:

        # verify working video url
        try:
            try:
                chat = pytchat.create(video_id=sys.argv[1])
                SETTINGS['videoID'] = sys.argv[1]
            except:
                chat = pytchat.create(SETTINGS['videoID']) #-- DEFAULT STREAM
                #chat = pytchat.create(video_id="Mk53AiDJUbM") # Genneral chat test
                #chat = pytchat.create(video_id="53SDDytPAzI") # Old stream chat test
                #chat = pytchat.create(video_id="2foo8cmrXjs") # Old stream chat test (Longer and more commands)
                #chat = pytchat.create(video_id="6s5COaPWNt8") # Most updated stream (long)
        except:
            log("Video Id Failure")
            ValidVideo = False
            userIn = ''
            while(not ValidVideo):
                if len(userIn) > 0:
                    log('Video Id \'{0}\' is not valid'.format(userIn))
                try:
                    userIn = input("YouTube Video Id => ")
                    chat = pytchat.create(video_id=userIn)
                    SETTINGS['videoID'] = userIn
                    ValidVideo = True
                except:
                    pass
        # print("Checking for backups...") maybe sum day :(

        print("Installing Pre-Requisites...")

        # create nessesary files and folders if the do not exist
        if not os.path.exists(dataBase):
            os.makedirs(dataBase)

        if not os.path.exists(blueprintBase):
            os.makedirs(blueprintBase)
            
        if not os.path.exists(statOutput):
            open(statOutput, 'a').close()

        if not os.path.exists(gameStats):
            open(gameStats, 'a').close()

        streamchatFile = open(os.path.join(dataBase, "streamchat.json"), "w")
        streamchatFile.write("[]")
        streamchatFile.close()
        
        # install modded lua files
        #copyfile(os.path.join(base,"survival_streamreader.lua"), os.path.join(dataBase, "survival_streamreader.lua"))
        #copyfile(os.path.join(base,"BaseWorld.lua"), os.path.join(smBase, "worlds", "BaseWorld.lua"))
        #copyfile(os.path.join(base,"SurvivalGame.lua"), os.path.join(smBase, "SurvivalGame.lua"))

        log("Stream Reader initialized")
        # start the reader as thread
        threading.Thread(target=readChat).start()
        # listen for user commands
        while(True):
            internalConsoleCommand(input(""))
