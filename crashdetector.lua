--[[
	Crash Detector (c) 2018 Ale32bit
	
	Created for RN SCP Breach server
	
	lol this is my first gmod script
	
	wow, these lines perfectly align
	
	(this code is a mess, pardon me)
]]--

local config = {
    lagMessages = {
        {text="[WARNING] The server is not responding",color=Color(255,0,0)},
        {text="Join the external fallback chat: https://rnscp.ale32bit.me",color=Color(33, 150, 243)},
        {text="Join RN SCP Discord Server: https://discord.gg/GEktb9U",color=Color(114,137,218)},
    }, -- messages to send in chat for players {text="", color=Color(r,g,b,a)},
    url = "https://rnscp.ale32bit.me", -- external chat button url
    discord = "https://discord.gg/GEktb9U", -- discord button invite

    debug = false, -- log all pings in console
    delay = 5, -- seconds to send each ping
    timeout = 10, -- trigger the lag counter after x seconds of not receiving any ping
}

local function log(...)
    print("CRASH DETECTOR",...)
end

log("Ale32bit's crash detector loaded")
local lastPing = CurTime()
local delay = 0;
local lag = false;
local started = false;

concommand.Add("cd_debug", function()
    config.debug = not config.debug
    log("Debug:",config.debug)
end)


if SERVER then
    log("Running as server")

    AddCSLuaFile("crashdetector.lua");


    util.AddNetworkString( "CrashDetectPing" )

    local receive = function( len, ply )
        local ping = net.ReadString()
        if ping == "ping" then
            if(config.debug) then
                log(ply,ping)
            end
            net.Start("CrashDetectPing")
            net.WriteString("ping")
            net.Send( ply )
        end
    end

    net.Receive( "CrashDetectPing", receive )
elseif CLIENT then
    log("Running as client")

    chat.AddText("Running Crash Detector by Ale32bit! https://ale32bit.me");

    -- frame

    local sw,sh = 500,250

    local Frame = vgui.Create( "DFrame" )
    Frame:SetPos( math.floor((ScrW()/2)-(sw/2)), math.floor((ScrH()/2)-(sh/2)) )
    Frame:SetSize( sw, sh )
    Frame:SetTitle( "The server stopped responding" )
    Frame:SetVisible( false )
    Frame:SetDraggable( false )
    Frame:ShowCloseButton( false )
    Frame:MakePopup()

    Frame.Paint = function( self, w, h ) -- 'function Frame:Paint( w, h )' works too
        draw.RoundedBox( 0, 0, 0, w, h, Color( 68, 68, 68, 255 ) ) -- Draw a red box instead of the frame
    end

    local URLB = vgui.Create("DButton", Frame)

    URLB:SetText("Open external fallback chat")
    URLB:SetTextColor(Color(255,255,255))
    URLB:SetSize(300,50)
    URLB:SetPos(math.floor(sw/2)-150, 65)
    --URLB:Center()
    URLB.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 33, 150, 243, 255 ) ) -- Draw a blue button
    end

    URLB.DoClick = function()
        gui.OpenURL( config.url )
    end

    local Discord = vgui.Create("DButton",Frame)

    Discord:SetText("Discord Server")
    Discord:SetTextColor(Color(255,255,255))
    Discord:SetSize(300,50)
    Discord:SetPos(math.floor(sw/2)-150, 145)
    --Discord:Center()
    Discord.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 33, 150, 243, 255 ) ) -- Draw a blue button
    end

    Discord.DoClick = function()
        gui.OpenURL( config.discord )
    end

    local Close = vgui.Create( "DButton", Frame )
    Close:SetText( "Close" )
    Close:SetTextColor( Color( 255, 255, 255 ) )
    Close:SetPos( sw-105, 5 )
    Close:SetSize( 100, 30 )
    Close.Paint = function( self, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 244, 67, 54, 255 ) ) -- Draw a blue Close
    end
    Close.DoClick = function()
        Frame:SetVisible(false)
    end

    local function triggerLag()
        log("Lag detected")

        for i = 1,#config.lagMessages do
            chat.AddText(config.lagMessages[i].color,config.lagMessages[i].text)
        end

        Frame:SetVisible(true)

    end

    local function receive( len )
        local ping = net.ReadString()

        if ping == "ping" then
            if config.debug then
                log(" <-- Received server ping")
            end
            if not started then
                started = true
            end

            lastPing = CurTime()
            Frame:SetVisible(false)
            lag = false
        end
    end

    net.Receive( "CrashDetectPing", receive )


    local function sendPing()
        if config.debug then
            log(" --> Sending ping")
        end
        net.Start( "CrashDetectPing" )
        net.WriteString("ping")
        net.SendToServer()
    end

    -- 1 sec interval
    local tsec = 0;
    hook.Add( "Think", "CurTimeDelay", function()
        if CurTime() < tsec then
            return
        end
        if CurTime() > delay then
            sendPing()
            delay = CurTime() + config.delay
        end
        if CurTime() > lastPing+config.timeout and not lag then --detect lag
            if not started then
                return
        end
        lag = true
        triggerLag()
        end
        tsec = CurTime() + 1
    end)

    concommand.Add( "cd_ping", function()
        log("Sending ping to the server...")
        sendPing()
    end)

    concommand.Add("cd_triggerlag", function()
        log("Triggering crash trigger")
        triggerLag()
    end)
end
