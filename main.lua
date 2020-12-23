PUG = LibStub("AceAddon-3.0"):NewAddon("PUG", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")

-- Add our slash commands
SLASH_PUG1 = "/pug"
function SlashCmdList.GEP(msg, editbox)
    if (msg == nil) then
        return true
    end
end

function PUG:OnInitialize()
	-- Enable add-on messages
    C_ChatInfo.RegisterAddonMessagePrefix("PUG")
end

-- Alert the player the add-on has started, and register our events.
function PUG:OnEnable()

    -- Notify that debug is enabled
    PUG:Debug('Debug is enabled.')

    -- Events
    self:RegisterEvent("LOOT_OPENED")
    self:RegisterEvent("LOOT_CLOSED")
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("CHAT_MSG_ADDON")
end

-- =====================
-- EVENT HANDLERS
-- =====================

-- Close our bid window when loot window is closed
function PUG:LOOT_CLOSED()
end

-- Handle chat messages from other copies of the add-on
function PUG:CHAT_MSG_ADDON(_, prefix, text, channel, sender)
    if (prefix == "PUG") then

    end
end

-- Add click event listeners for all items within a loot box
function PUG:LOOT_OPENED()
	
end

-- Event handler for being whispered
function PUG:CHAT_MSG_WHISPER(type, whisperText, playerName)
    
end

-- =====================
-- UTILITY FUNCTIONS
-- =====================

-- Capitalize the first letter of a word, lowercase the rest.
function PUG:UCFirst(word)
	if word then
	    word = word:sub(1,1):upper() .. word:sub(2):lower()
		return word
	end
end

-- Send an add-on message
function PUG:AddonMessage(msg, target)
    if (target ~= nil) then
        ChatThrottleLib:SendAddonMessage("NORMAL", "PUG", msg, "WHISPER", target);
    else
        ChatThrottleLib:SendAddonMessage("NORMAL", "PUG", msg, "GUILD");
    end
end

-- Send a branded whisper to player.  message = message to send, playerName = player to whisper
function PUG:SendWhisper(message, playerName)
    ChatThrottleLib:SendChatMessage("NORMAL", "PUG", "GEPGP: " .. message, "WHISPER", "COMMON", playerName)
end

-- Send a branded message to guild chat
function PUG:SendGuild(message)
    ChatThrottleLib:SendChatMessage("NORMAL", "PUG", "GEPGP: " .. message, "GUILD")
end

-- Round a number to a certain number of places
function PUG:Round(num, places)
    num = tonumber(num)
    if (num == nil) then
        return
    end
    local mult = 10^(places or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Determine which chat channel should be used to display a message
function PUG:WidestAudience(msg, rw)
    if (rw == nil) then
        rw = true
    end
    local channel = "GUILD"
    if UnitInRaid("player") then
        if ((UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and rw == true) then
            channel = "RAID_WARNING"
        else
            channel = "RAID"
        end
    elseif UnitExists("party1") then
        channel = "PARTY"
    end
    ChatThrottleLib:SendChatMessage("NORMAL", "PUG", msg, channel)
end

-- Pad a string
function PUG:PadString(originalString, length, padCharacter, direction)
    if (padCharacter == nil) then
        padCharacter = ' '
    end
    if (direction == nil) then
        direction = "right"
    end
    originalString = tostring(originalString)

    local padString = ""
    if (direction == "left") then
        padString = string.rep(padCharacter, length - #originalString) .. originalString
    else
        padString = originalString .. string.rep(padCharacter, length - #originalString)
    end

    return padString
end

-- Handle output to console / whisper
function PUG:HandleOutput(string, type, playerName)
    if (type == "whisper") then
        PUG:SendWhisper(string, playerName)
    else
        self:Print('GEPGP: ' .. string)
    end
end

-- Split a string into a table
function PUG:SplitString(string, delimiter)
    result = {};
    for match in (string..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

-- Put up a confirmation modal
function PUG:ConfirmAction(confirmString, acceptCallback, cancelCalback)
    StaticPopupDialogs["CONFIRM_ACTION"] ={
        preferredIndex = 5,
        text = confirmString,
        button1 = "Yes",
        button2 = "No",
        OnAccept = acceptCallback,
        OnCancel = cancelCalback,
        timeout = 0,
        hideOnEscape = false,
        showAlert = true
    }

    StaticPopup_Show("CONFIRM_ACTION")
end

-- Debug!
function PUG:Debug(message)
    message = tostring(message)
    if (message == nil) then
        self:Print("DEBUG: nil")
    else
        self:Print("DEBUG: " .. message)
    end
end

-- Minimap Icon
function PUG:MinimapIconToggle()
	if (PUGMiniMapPos.show == false) then
		PUG.MinimapIcon:Hide("PUGMinimap")
	else
		PUG.MinimapIcon:Show("PUGMinimap")
	end
end

-- Get Player GUID by Name
function PUG:PlayerGUID(playerName)
	player = select(1, strsplit("-", playerName))
    for i = 1, MAX_RAID_MEMBERS do
		local raidMember = select(1, GetRaidRosterInfo(i))
		if raidMember then
			if raidMember == player then
				local unitID = "raid"..i
				local playerGUID = UnitGUID(unitID)
				return playerGUID
			end
		end
    end
end

-- Secure Hookfunction
local old = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(link, ...)
	if link:find("goodbid:") then
		PUG:Debug("ItemRefTooltip - link: "..link)
		local mlGUID = select(3, strsplit(":", link))
		local bidType = select(4, strsplit(":", link))
		if link and mlGUID and bidType then
			PUG:Debug("ItemRefTooltip - link: "..link.." | mlGUID: "..mlGUID.." | bidType: "..bidType)
		end
		local masterlooter = select(6, GetPlayerInfoByGUID(mlGUID))
		if masterlooter and bidType then
			if bidType == "ms" then
				ChatThrottleLib:SendChatMessage("NORMAL", "PUG", "+", "WHISPER", nil, masterlooter)
			end
			if bidType == "os" then
				ChatThrottleLib:SendChatMessage("NORMAL", "PUG", "-", "WHISPER", nil, masterlooter)
			end
		end
	else
		return old(self, link, ...)
	end
end
