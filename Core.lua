local ADDON, SRH = ...

SRH.TITLE = "SimpleRogueHelper - Forever"
local PREFIX = "|cfffff569SimpleRogueHelper|r: "

---------------------------------------------------------------------------
-- Localisation: English is the base (Locales/enUS.lua), each client
-- language overrides it (Locales/<locale>.lua, loaded before this file);
-- the other languages are then let go
---------------------------------------------------------------------------
-- Updated while the game was running: a /reload doesn't load the files the
-- game didn't know when it started (these). The keys' own names meanwhile,
-- and a word in the chat once in the world
if not SRH.L then
    SRH.L = setmetatable({}, { __index = function(_, key) return key end })
    local warn = CreateFrame("Frame")
    warn:RegisterEvent("PLAYER_ENTERING_WORLD")
    warn:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. "|cffff4040updated while the game was running|r: quit and restart the game (/reload is not enough for new files).")
    end)
end
local L = SRH.L

for key, value in pairs(SRH.LOCALES and SRH.LOCALES[GetLocale()] or {}) do
    L[key] = value
end
SRH.LOCALES = nil

-- Escape > Options > Key Bindings > AddOns (Bindings.xml)
BINDING_HEADER_SIMPLEROGUEHELPER = SRH.TITLE
BINDING_NAME_SIMPLEROGUEHELPER_TOGGLE = L.BINDING_TOGGLE

---------------------------------------------------------------------------
-- Saved variables: this character's (SavedVariablesPerCharacter), there
-- at ADDON_LOADED. { marks = { [spell name] = true } }; a file edited by
-- hand: what isn't a table is started again
---------------------------------------------------------------------------
function SRH:InitDB()
    if type(SimpleRogueHelperCharDB) ~= "table" then SimpleRogueHelperCharDB = {} end
    local db = SimpleRogueHelperCharDB
    if type(db.marks) ~= "table" then db.marks = {} end
    db.version = 1
    self.db = db
end

function SRH:Print(msg, ...)
    if select("#", ...) > 0 then msg = format(msg, ...) end
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(msg))
end

-- In combat: refused, a red message in the middle of the screen like the
-- game's own errors
function SRH:BlockedByCombat()
    if not InCombatLockdown() then return false end
    if UIErrorsFrame then
        UIErrorsFrame:AddMessage(L.COMBAT_UNAVAILABLE, 1, 0.1, 0.1, 1)
    else
        self:Print(L.COMBAT_UNAVAILABLE)
    end
    return true
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
    if name ~= ADDON then return end
    self:UnregisterEvent("ADDON_LOADED")
    SRH:InitDB()
    SRH.Window:Init()
end)
