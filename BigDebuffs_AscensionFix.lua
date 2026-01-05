-- Fix BigDebuffs for WOW Ascension modified by Hannahmckay
-- Enhanced with LibGetFrame for dynamic raid frame support

local InArena = InArena or function() return (select(2, IsInInstance()) == "arena") end

-- LibGetFrame for dynamic unit frame detection (works with any raid frame addon)
local LibGetFrame = LibStub and LibStub("LibGetFrame-1.0", true)

BigDebuffs.SpellsByName = {}

function BigDebuffs:BuildSpellNameTable()
    for spellId, spellData in pairs(self.Spells) do
        if type(spellId) == "number" then
            local spellName = GetSpellInfo(spellId)
            if spellName then
                if not self.SpellsByName[spellName] then
                    self.SpellsByName[spellName] = {}
                end
                
                for k, v in pairs(spellData) do
                    self.SpellsByName[spellName][k] = v
                end
                
                self.SpellsByName[spellName].originalId = spellId
            end
        end
    end
end


local TestDebuffs = {}

function BigDebuffs:InsertTestDebuff(spellID)
    local texture = select(3, GetSpellInfo(spellID))
    table.insert(TestDebuffs, {spellID, texture})
end


function UnitDebuffTest(unit, index)
    local debuff = TestDebuffs[index]
    if not debuff then return end
    return GetSpellInfo(debuff[1]), nil, debuff[2], 0, "Magic", 30, GetTime() + 30, nil, nil, nil, debuff[1]
end


local original_OnEnable = BigDebuffs.OnEnable
function BigDebuffs:OnEnable()
    self:BuildSpellNameTable()
    
    self:InsertTestDebuff(10890) -- Psychic Scream test
    
    if original_OnEnable then
        original_OnEnable(self)
    end
    
    -- Register nameplate events (Ascension has modern C_NamePlate API backported)
    if C_NamePlate then
        self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
        
        -- Schedule regular nameplate aura updates (in case UNIT_AURA doesn't fire for nameplates)
        self:ScheduleRepeatingTimer("UpdateNameplates", 0.2)
    end
    
    BigDebuffs.TestDebuffs = TestDebuffs
end

-- Update all active nameplates (called periodically)
function BigDebuffs:UpdateNameplates()
    if not C_NamePlate then return end
    if not self.db.profile.unitFrames.nameplate then return end
    if not self.db.profile.unitFrames.nameplate.enabled then return end
    
    for unit, frame in pairs(self.NamePlateFrames) do
        if frame and frame:IsShown() or UnitExists(unit) then
            self:UNIT_AURA(nil, unit)
        end
    end
end

-- Nameplate event handlers (Ascension C_NamePlate API)
function BigDebuffs:NAME_PLATE_UNIT_ADDED(event, unit)
    if not unit or not self.db.profile.unitFrames.nameplate then return end
    if not self.db.profile.unitFrames.nameplate.enabled then return end
    
    -- Create/attach frame for this nameplate unit
    self:AttachNamePlateFrame(unit)
    self:UNIT_AURA(nil, unit)
end

function BigDebuffs:NAME_PLATE_UNIT_REMOVED(event, unit)
    if not unit then return end
    
    local frame = self.NamePlateFrames and self.NamePlateFrames[unit]
    if frame then
        frame:Hide()
        frame.current = nil
        frame.currentAuraType = nil
        frame.currentSpellId = nil
    end
end

-- Initialize nameplate frames table
BigDebuffs.NamePlateFrames = {}

function BigDebuffs:AttachNamePlateFrame(unit)
    if not C_NamePlate then return end
    
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end
    
    local frame = self.NamePlateFrames[unit]
    local frameName = "BigDebuffs" .. unit .. "NamePlateFrame"
    
    if not frame then
        frame = CreateFrame("Button", frameName, nameplate, "BigDebuffsUnitFrameTemplate")
        frame.icon = _G[frameName .. "Icon"]
        
        frame.cooldownContainer = CreateFrame("Button", frameName .. "CooldownContainer", frame)
        frame.cooldownContainer:SetAllPoints()
        
        frame.CircleCooldown = CreateFrame("Frame", frameName .. "CircleCooldown", frame, "CircleCooldownFrameTemplate")
        frame.CircleCooldown:SetParent(frame.cooldownContainer)
        frame.CircleCooldown:SetFrameLevel(frame.cooldownContainer:GetFrameLevel() + 1)
        frame.CircleCooldown:SetDrawBling(false)
        frame.CircleCooldown:SetAllPoints()
        
        frame.icon:SetDrawLayer("BORDER")
        
        self.NamePlateFrames[unit] = frame
    end
    
    -- Position on nameplate
    frame:ClearAllPoints()
    frame:SetParent(nameplate)
    
    local size = self.db.profile.unitFrames.nameplate.size or 30
    frame:SetSize(size, size)
    frame:SetPoint("BOTTOM", nameplate, "TOP", 0, 2)
    frame:SetAlpha(self.db.profile.unitFrames.nameplate.alpha or 1)
    
    frame.unit = unit
    frame.isNameplate = true
end

-- Initialize raid frames table (using LibGetFrame for dynamic detection)
BigDebuffs.RaidFrames = {}

function BigDebuffs:AttachRaidFrame(unit)
    if not LibGetFrame then return end
    
    -- Use LibGetFrame to dynamically find the raid frame for this unit
    local raidFrame = LibGetFrame.GetUnitFrame(unit, {
        ignorePlayerFrame = true,
        ignoreTargetFrame = true,
        ignoreTargettargetFrame = true,
        ignorePartyFrame = true,  -- Party frames handled separately
        ignoreRaidFrame = false,
    })
    
    if not raidFrame then return end
    
    local frame = self.RaidFrames[unit]
    local frameName = "BigDebuffs" .. unit .. "RaidFrame"
    
    if not frame then
        frame = CreateFrame("Button", frameName, raidFrame, "BigDebuffsUnitFrameTemplate")
        frame.icon = _G[frameName .. "Icon"]
        
        frame.cooldownContainer = CreateFrame("Button", frameName .. "CooldownContainer", frame)
        frame.cooldownContainer:SetAllPoints()
        
        frame.CircleCooldown = CreateFrame("Frame", frameName .. "CircleCooldown", frame, "CircleCooldownFrameTemplate")
        frame.CircleCooldown:SetParent(frame.cooldownContainer)
        frame.CircleCooldown:SetFrameLevel(frame.cooldownContainer:GetFrameLevel() + 1)
        frame.CircleCooldown:SetDrawBling(false)
        frame.CircleCooldown:SetAllPoints()
        
        frame.icon:SetDrawLayer("BORDER")
        
        self.RaidFrames[unit] = frame
    end
    
    -- Position on raid frame
    frame:ClearAllPoints()
    frame:SetParent(raidFrame)
    
    local size = self.db.profile.unitFrames.raid.size or 26
    frame:SetSize(size, size)
    frame:SetPoint("CENTER", raidFrame, "CENTER", 0, 0)
    frame:SetAlpha(self.db.profile.unitFrames.raid.alpha or 1)
    
    -- Raise frame level to appear on top
    frame:SetFrameLevel(raidFrame:GetFrameLevel() + 10)
    
    frame.unit = unit
    frame.isRaidFrame = true
end

function BigDebuffs:GetAuraPriority(name, id, unit)
    local spellData = self.Spells[id]
    
    if not spellData and name then
        spellData = self.SpellsByName[name]
        if spellData and spellData.originalId then
            id = spellData.originalId
        end
    end
    
    if not spellData then return end

    if spellData.parent then
        local parentData = self.Spells[spellData.parent]
        if parentData then
            id = spellData.parent
            spellData = parentData
        else
            local parentName = GetSpellInfo(spellData.parent)
            if parentName then
                parentData = self.SpellsByName[parentName]
                if parentData and parentData.originalId then
                    id = parentData.originalId
                    spellData = parentData
                end
            end
        end
    end

    -- Determine unit type for config lookup
    local unitType = unit:gsub("%d", "")
    if unit:match("^nameplate%d+$") then
        unitType = "nameplate"
    end
    
    local unitConfig = self.db.profile.unitFrames[unitType]
    if not unitConfig or not unitConfig[spellData.type] then 
        return 
    end

    if self.db.profile.spells[id] then
        if self.db.profile.spells[id].unitFrames and self.db.profile.spells[id].unitFrames == 0 then 
            return 
        end
        if self.db.profile.spells[id].priority then 
            return self.db.profile.spells[id].priority 
        end
    end

    if spellData.nounitFrames and (not self.db.profile.spells[id] or not self.db.profile.spells[id].unitFrames) then
        return
    end

    return self.db.profile.priority[spellData.type] or 0
end

function BigDebuffs:UNIT_AURA(event, unit)
    if not self.db.profile.unitFrames.enabled or not unit then return end
    
    -- Determine unit type for config lookup
    local unitType = unit:gsub("%d", "")
    
    -- Handle nameplate units specially
    local isNameplate = unit:match("^nameplate%d+$")
    if isNameplate then
        unitType = "nameplate"
    end
    
    -- Handle raid units specially
    local isRaid = unit:match("^raid%d+$")
    if isRaid then
        unitType = "raid"
    end
    
    -- Check if unit type config exists and is enabled
    local unitConfig = self.db.profile.unitFrames[unitType]
    if not unitConfig then return end
    if not unitConfig.enabled then return end
    if not self.test and unitConfig.inArena and not InArena() then return end

    if unit == "player" then
        self:UNIT_AURA(nil, "playerFAKE")
    end

    -- Use appropriate frame table for different unit types
    local frame
    if isNameplate then
        self:AttachNamePlateFrame(unit)
        frame = self.NamePlateFrames[unit]
    elseif isRaid and LibGetFrame then
        self:AttachRaidFrame(unit)
        frame = self.RaidFrames[unit]
    else
        self:AttachUnitFrame(unit)
        frame = self.UnitFrames[unit]
    end
    if not frame then return end

    if unit == "playerFAKE" then
        unit = string.gsub(unit, "%u", "")
    end

    local UnitDebuff = self.test and UnitDebuffTest or _G.UnitDebuff

    local now = GetTime()
    local left, priority, duration, expires, icon, isAura, interrupt, auraType, spellId = 0, 0

    for i = 1, 40 do
        local n, _, ico, _, _, d, e, caster, _, _, id = UnitDebuff(unit, i)
        if not n then break end
        
        if id and (self.Spells[id] or self.SpellsByName[n]) then
            local p = self:GetAuraPriority(n, id, unit)

            if p and p > priority or p == priority and e - now > left then
                left = e - now
                duration = d
                isAura = true
                priority = p
                expires = e
                icon = ico
                
                local spellData = self.Spells[id] or self.SpellsByName[n]
                if spellData then
                    if spellData.parent then
                        local parentData = self.Spells[spellData.parent]
                        if not parentData then
                            local parentName = GetSpellInfo(spellData.parent)
                            if parentName then
                                parentData = self.SpellsByName[parentName]
                            end
                        end
                        if parentData then
                            spellData = parentData
                        end
                    end
                    auraType = spellData.type
                end
                
                spellId = id
            end
        end
    end

    for i = 1, 40 do
        local n, _, ico, _, _, d, e, _, _, _, id = UnitBuff(unit, i)
        if not n then break end
        
        if id == 605 then break end
        
        if id and (self.Spells[id] or self.SpellsByName[n]) then
            local p = self:GetAuraPriority(n, id, unit)
            if p and p >= priority then
                if p and p > priority or p == priority and e - now > left then
                    left = e - now
                    duration = d
                    isAura = true
                    priority = p
                    expires = e
                    icon = ico
                    
                    local spellData = self.Spells[id] or self.SpellsByName[n]
                    if spellData then
                        if spellData.parent then
                            local parentData = self.Spells[spellData.parent]
                            if not parentData then
                                local parentName = GetSpellInfo(spellData.parent)
                                if parentName then
                                    parentData = self.SpellsByName[parentName]
                                end
                            end
                            if parentData then
                                spellData = parentData
                            end
                        end
                        auraType = spellData.type
                    end
                    
                    spellId = id
                end
            end
        end
    end

    local n, id, ico, d, e = self:GetInterruptFor(unit)
    if n then
        local p = self:GetAuraPriority(n, id, unit)
        if p and p > priority or p == priority and e - now > left then
            left = e - now
            duration = d
            isAura = true
            priority = p
            expires = e
            icon = ico
            auraType = "interrupts"
            spellId = id
        end
    end

    local guid = UnitGUID(unit)
    if self.stances and self.stances[guid] then
        local stanceId = self.stances[guid].stance
        if stanceId then
            local stanceName = GetSpellInfo(stanceId)
            if stanceName and (self.Spells[stanceId] or self.SpellsByName[stanceName]) then
                n, _, ico = GetSpellInfo(stanceId)
                local p = self:GetAuraPriority(n, stanceId, unit)
                if p and p >= priority then
                    left = 0
                    duration = 0
                    isAura = true
                    priority = p
                    expires = 0
                    icon = ico
                    
                    local spellData = self.Spells[stanceId] or self.SpellsByName[stanceName]
                    if spellData then
                        auraType = spellData.type
                    end
                    
                    spellId = stanceId
                end
            end
        end
    end

    if isAura then
        if frame.blizzard then
            SetPortraitToTexture(frame.icon, icon)
            
            local frameName = frame:GetName()
            if frameName then
                local fixes = {
                    BigDebuffsplayerUnitFrame = {PlayerPortrait, 0.5, -0.7},
                    BigDebuffsplayerFAKEUnitFrame = {PlayerPortrait, 0.5, -0.7},
                    BigDebuffspetUnitFrame = {PetPortrait, -1.4, -0.5, 1.5},
                    BigDebuffstargetUnitFrame = {TargetFramePortrait, -0.4, -0.7},
                    BigDebuffstargettargetUnitFrame = {TargetFrameToTPortrait, -0.1, -0.5, 4.2},
                    BigDebuffsfocusUnitFrame = {FocusFramePortrait, -0.4, -0.7},
                    BigDebuffsfocustargetUnitFrame = {FocusFrameToTPortrait, -0.1, -0.5, 4.2},
                }
                
                local fix = fixes[frameName]
                if fix then
                    local portrait, x, y, sizeAdd = fix[1], fix[2], fix[3], fix[4] or 0
                    if portrait then
                        frame:ClearAllPoints()
                        frame:SetPoint("CENTER", portrait, "CENTER", x, y)
                        frame:SetSize(portrait:GetHeight() + sizeAdd, portrait:GetWidth() + sizeAdd)
                    end
                end
            end
        else
            frame.icon:SetTexture(icon)
        end

        if auraType == "interrupts" then
            if frame.interruptBorder then
                local color = self.db.profile.unitFrames.interruptBorderColor or {1, 0, 0, 1}
                if color[4] > 0 then
                    frame.interruptBorder:SetVertexColor(color[1], color[2], color[3], color[4])
                    frame.interruptBorder:ClearAllPoints()
                    
                    local isGladiusFrame = frame:GetName() and (frame:GetName():match("arena%d") ~= nil) and unit:match("arena%d") ~= nil
                    
                    if isGladiusFrame then
                        frame.interruptBorder:SetWidth(frame:GetWidth() * 1.5)
                        frame.interruptBorder:SetHeight(frame:GetHeight() * 1.5)
                    else
                        frame.interruptBorder:SetWidth(frame:GetWidth() * 1.1)
                        frame.interruptBorder:SetHeight(frame:GetHeight() * 1.1)
                    end
                    frame.interruptBorder:SetPoint("CENTER", frame, "CENTER", 0, 0)
                    frame.interruptBorder:Show()
                else
                    frame.interruptBorder:Hide()
                end
            end
        else
            if frame.interruptBorder then
                frame.interruptBorder:Hide()
            end
        end

        -- Cooldown
        if duration > 0.2 then
            if self.db.profile.unitFrames.circleCooldown and frame.blizzard then
                frame.CircleCooldown:SetCooldown(expires - duration, duration)
                frame.cooldown:Hide()
            else
                frame.cooldown:SetCooldown(expires - duration, duration)
                frame.CircleCooldown:Hide()
            end

            if self.db.profile.unitFrames.hideCDanimation then
                frame.cooldown:SetAlpha(0)
                frame.CircleCooldown:SetAlpha(0)
            else
                frame.cooldown:SetAlpha(0.85)
                frame.CircleCooldown:SetAlpha(1)
            end

            if self.db.profile.unitFrames.customTimer then
                frame.timeEnd = (expires - duration) + duration
            else
                frame.timeEnd = GetTime()
            end

            frame.cooldownContainer:Show()
        else
            frame.timeEnd = GetTime()
            frame.cooldownContainer:Hide()
        end

        frame:Show()
        frame.current = icon
        frame.currentAuraType = auraType
        frame.currentSpellId = spellId
    else
        if frame.anchor and frame.blizzard and Adapt and Adapt.portraits[frame.anchor] then
            Adapt.portraits[frame.anchor].modelLayer:SetFrameStrata("LOW")
        else
            frame:Hide()
            frame.current = nil
            frame.currentAuraType = nil
            frame.currentSpellId = nil
            if frame.interruptBorder then
                frame.interruptBorder:Hide()
            end
        end
    end
end

local original_Test = BigDebuffs.Test
function BigDebuffs:Test()
    if original_Test then
        original_Test(self)
    end
    
    if self.test then
        print("|cff00ff00BigDebuffs Test Mode:|r ENABLED")
    else
        print("|cffff0000BigDebuffs Test Mode:|r DISABLED")
    end
end