local config = require 'config.server'
local sharedConfig = require 'config.shared'
local robberyBusy = false
local timeOut = false
local ITEMS =  exports.ox_inventory:Items()

--- This will convert a table's keys into an array
--- @param tbl table
--- @return array
local function tableKeysToArray(tbl)
    local array = {}
    for k in pairs(tbl) do
        array[#array+1] = k
    end
    return array
end

--- This will loop over the given table to check if the power stations in the table have been hit
--- @param toLoop table
--- @return boolean
local function tableLoopStations(toLoop)
    local hits = 0
    for _, station in pairs(toLoop) do
        if type(station) == 'table' then
            local hits2 = 0
            for _, station2 in pairs(station) do
                if sharedConfig.powerStations[station2].hit then hits2 += 1 end
                if hits2 == #station then return true end
            end
        else
            if sharedConfig.powerStations[station].hit then hits += 1 end
            if hits == #toLoop then return true end
        end
    end
    return false
end

--- This will check what stations have been hit and update them accordingly
--- @return nil
local function checkStationHits()
    local policeHits = {}
    local bankHits = {}

    for k, v in pairs(config.cameraHits) do
        local allStationsHitPolice = false
        local allStationsHitBank = false
        if type(v.type) == 'table' then
            for _, cameraType in pairs(v.type) do
                if cameraType == 'police' then
                    if type(v.stationsToHitPolice) == 'table' then
                        allStationsHitPolice = tableLoopStations(v.stationsToHitPolice)
                    else
                        allStationsHitPolice = sharedConfig.powerStations[v.stationsToHitPolice].hit
                    end
                elseif cameraType == 'bank' then
                    if type(v.stationsToHitBank) == 'table' then
                        allStationsHitBank = tableLoopStations(v.stationsToHitBank)
                    else
                        allStationsHitBank = sharedConfig.powerStations[v.stationsToHitBank].hit
                    end
                end
            end
        else
            if v.type == 'police' then
                if type(v.stationsToHitPolice) == 'table' then
                    allStationsHitPolice = tableLoopStations(v.stationsToHitPolice)
                else
                    allStationsHitPolice = sharedConfig.powerStations[v.stationsToHitPolice].hit
                end
            elseif v.type == 'bank' then
                if type(v.stationsToHitBank) == 'table' then
                    allStationsHitBank = tableLoopStations(v.stationsToHitBank)
                else
                    allStationsHitBank = sharedConfig.powerStations[v.stationsToHitBank].hit
                end
            end
        end

        if allStationsHitPolice then
            policeHits[k] = true
        end

        if allStationsHitBank then
            bankHits[k] = true
        end
    end

    policeHits = tableKeysToArray(policeHits)
    bankHits = tableKeysToArray(bankHits)

    -- table.type checks if it's empty as well, if it's empty it will return the type 'empty' instead of 'array'
    
    if table.type(policeHits) == 'array' then TriggerClientEvent('police:client:SetCamera', -1, policeHits, false) end
    if table.type(bankHits) == 'array' then TriggerClientEvent('qb-bankrobbery:client:BankSecurity', -1, bankHits, false) end
end

--- This will do a quick check to see if all stations have been hit
--- @return boolean
local function allStationsHit()
    local hit = 0
    for k in pairs(sharedConfig.powerStations) do
        if sharedConfig.powerStations[k].hit then
            hit += 1
        end
    end
    return hit >= config.hitsNeeded
end

--- This will check if the given coords are in the area of the given distance of a powerstation
--- @param coords vector3
--- @param dist number
--- @return boolean
local function isNearPowerStation(coords, dist)
    for _, v in pairs(sharedConfig.powerStations) do
        if #(coords - v.coords) < dist then
            return true
        end
    end
    return false
end

---Changes the bank state
---@param bankId string | number
---@param state boolean
local function changeBankState(bankId, state)
    local bankName = type(bankId) == 'number' and 'bankrobbery' or bankId
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', bankName, state)
    if bankName ~= 'bankrobbery' then return end
    TriggerEvent('qb-banking:server:SetBankClosed', bankId, state)
end

local function changeBlackoutState(state)
    local eventName = state and 'police:client:DisableAllCameras' or 'police:client:EnableAllCameras'
    TriggerClientEvent(eventName, -1)
end

RegisterNetEvent('qb-bankrobbery:server:setBankState', function(bankId)
    if robberyBusy then return end
    if bankId == 'paleto' then
        if sharedConfig.bigBanks.paleto.isOpened or #(GetEntityCoords(GetPlayerPed(source)) - sharedConfig.bigBanks.paleto.coords) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', {event = 'qb-bankrobbery:server:setBankState', extraInfo = ' (paleto) ', source = source}))
        end
        sharedConfig.bigBanks.paleto.isOpened = true
        TriggerEvent('qb-bankrobbery:server:setTimeout')
    elseif bankId == 'pacific' then
        if sharedConfig.bigBanks.pacific.isOpened or #(GetEntityCoords(GetPlayerPed(source)) - sharedConfig.bigBanks.pacific.coords[2]) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', {event = 'qb-bankrobbery:server:setBankState', extraInfo = ' (pacific) ', source = source}))
        end
        sharedConfig.bigBanks.pacific.isOpened = true
        TriggerEvent('qb-bankrobbery:server:setTimeout')
    else
        if sharedConfig.smallBanks[bankId].isOpened or #(GetEntityCoords(GetPlayerPed(source)) - sharedConfig.smallBanks[bankId].coords) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', {event = 'qb-bankrobbery:server:setBankState', extraInfo = ' (smallbank '..bankId..') ', source = source}))
        end
        sharedConfig.smallBanks[bankId].isOpened = true
        TriggerEvent('qb-bankrobbery:server:SetSmallBankTimeout', bankId)
    end
    TriggerClientEvent('qb-bankrobbery:client:setBankState', -1, bankId)
    robberyBusy = true

    local bankName = type(bankId) == 'number' and 'bankrobbery' or bankId
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', bankName, true)
    if bankName ~= 'bankrobbery' then return end
    TriggerEvent('qb-banking:server:SetBankClosed', bankId, true)
    changeBankState(bankId, true)
end)

RegisterNetEvent('qb-bankrobbery:server:setLockerState', function(bankId, lockerId, state, bool)
    if bankId == 'paleto' or bankId == 'pacific' then
        if #(GetEntityCoords(GetPlayerPed(source)) - sharedConfig.bigBanks[bankId].lockers[lockerId].coords) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', {event = 'qb-bankrobbery:server:setLockerState', extraInfo = ' ('..bankId..') ', source = source}))
        end
        sharedConfig.bigBanks[bankId].lockers[lockerId][state] = bool
    else
        if #(GetEntityCoords(GetPlayerPed(source)) - sharedConfig.smallBanks[bankId].lockers[lockerId].coords) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', {event = 'qb-bankrobbery:server:setLockerState', extraInfo = ' (smallbank '..bankId..') ', source = source}))
        end
        sharedConfig.smallBanks[bankId].lockers[lockerId][state] = bool
    end
    TriggerClientEvent('qb-bankrobbery:client:setLockerState', -1, bankId, lockerId, state, bool)
end)

RegisterNetEvent('qb-bankrobbery:server:recieveItem', function(type, bankId, lockerId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    if type == 'small' then
        if #(GetEntityCoords(GetPlayerPed(src)) - sharedConfig.smallBanks[bankId].lockers[lockerId].coords) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', {event = 'qb-bankrobbery:server:receiveItem', extraInfo = ' (smallbank '..bankId..') ', source = source}))
        end
        local itemType = math.random(#config.rewardTypes)
        local weaponChance = math.random(1, 50)
        local odd1 = math.random(1, 50)
        local tierChance = math.random(1, 100)
        local tier
        if tierChance < 50 then tier = 1 elseif tierChance >= 50 and tierChance < 80 then tier = 2 elseif tierChance >= 80 and tierChance < 95 then tier = 3 else tier = 4 end
        if weaponChance ~= odd1 then
            if tier ~= 4 then
                if config.rewardTypes[itemType].type == 'item' then
                    local item = config.lockerRewards['tier'..tier][math.random(#config.lockerRewards['tier'..tier])]
                    local itemAmount = math.random(item.minAmount, item.maxAmount)
                    player.Functions.AddItem(item.item, itemAmount)
                    TriggerClientEvent('inventory:client:ItemBox', src,ITEMS[item.item], 'add')
                elseif config.rewardTypes[itemType].type == 'money' then
                    local info = {
                        worth = math.random(2300, 3200)
                    }
                    player.Functions.AddItem('markedbills', math.random(2,3), false, info)
                    TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['markedbills'], 'add')
                end
            else
                player.Functions.AddItem('security_card_01', 1)
                TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['security_card_01'], 'add')
            end
        else
            player.Functions.AddItem('weapon_stungun', 1)
            TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['weapon_stungun'], 'add')
        end
    elseif type == 'paleto' then
        if #(GetEntityCoords(GetPlayerPed(source)) - sharedConfig.bigBanks.paleto.lockers[lockerId].coords) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', {event = 'qb-bankrobbery:server:receiveItem', extraInfo = ' (paleto) ', source = source}))
        end
        local itemType = math.random(#config.rewardTypes)
        local tierChance = math.random(1, 100)
        local weaponChance = math.random(1, 10)
        local odd1 = math.random(1, 10)
        local tier
        if tierChance < 25 then tier = 1 elseif tierChance >= 25 and tierChance < 70 then tier = 2 elseif tierChance >= 70 and tierChance < 95 then tier = 3 else tier = 4 end
        if weaponChance ~= odd1 then
            if tier ~= 4 then
                 if config.rewardTypes[itemType].type == 'item' then
                    local item = config.lockerRewardsPaleto['tier'..tier][math.random(#config.lockerRewardsPaleto['tier'..tier])]
                    local itemAmount = math.random(item.minAmount, item.maxAmount)
                    player.Functions.AddItem(item.item, itemAmount)
                    TriggerClientEvent('inventory:client:ItemBox', src,ITEMS[item.item], 'add')
                 elseif config.rewardTypes[itemType].type == 'money' then
                    local info = {
                        worth = math.random(4000, 6000)
                    }
                    player.Functions.AddItem('markedbills', math.random(1,4), false, info)
                    TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['markedbills'], 'add')
                 end
            else
                player.Functions.AddItem('security_card_02', 1)
                TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['security_card_02'], 'add')
            end
        else
            player.Functions.AddItem('weapon_vintagepistol', 1)
            TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['weapon_vintagepistol'], 'add')
        end
    elseif type == 'pacific' then
        if #(GetEntityCoords(GetPlayerPed(source)) - sharedConfig.bigBanks.pacific.lockers[lockerId].coords) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', {event = 'qb-bankrobbery:server:receiveItem', extraInfo = ' (pacific) ', source = source}))
        end
        local itemType = math.random(#config.rewardTypes)
        local weaponChance = math.random(1, 100)
        local odd1 = math.random(1, 100)
        local odd2 = math.random(1, 100)
        local tierChance = math.random(1, 100)
        local tier
        if tierChance < 10 then tier = 1 elseif tierChance >= 25 and tierChance < 50 then tier = 2 elseif tierChance >= 50 and tierChance < 95 then tier = 3 else tier = 4 end
        if weaponChance ~= odd1 or weaponChance ~= odd2 then
            if tier ~= 4 then
                if config.rewardTypes[itemType].type == 'item' then
                    local item = config.lockerRewardsPacific['tier'..tier][math.random(#config.lockerRewardsPacific['tier'..tier])]
                    local maxAmount
                    if tier == 3 then maxAmount = 7 elseif tier == 2 then maxAmount = 18 else maxAmount = 25 end
                    local itemAmount = math.random(maxAmount)
                    player.Functions.AddItem(item.item, itemAmount)
                    TriggerClientEvent('inventory:client:ItemBox', src,ITEMS[item.item], 'add')
                elseif config.rewardTypes[itemType].type == 'money' then
                    local info = {
                        worth = math.random(19000, 21000)
                    }
                    player.Functions.AddItem('markedbills', math.random(1,4), false, info)
                    TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['markedbills'], 'add')
                end
            else
                local info = {
                    worth = math.random(19000, 21000)
                }
                player.Functions.AddItem('markedbills', math.random(1,4), false, info)
                TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['markedbills'], 'add')
                info = {
                    crypto = math.random(1, 3)
                }
                player.Functions.AddItem('cryptostick', 1, false, info)
                TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['cryptostick'], 'add')
            end
        else
            local chance = math.random(1, 2)
            local odd = math.random(1, 2)
            if chance == odd then
                player.Functions.AddItem('weapon_microsmg', 1)
                TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['weapon_microsmg'], 'add')
            else
                player.Functions.AddItem('weapon_minismg', 1)
                TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['weapon_minismg'], 'add')
            end
        end
    end
end)

AddEventHandler('qb-bankrobbery:server:setTimeout', function()
    if robberyBusy or timeOut then return end
    timeOut = true
    CreateThread(function()
        SetTimeout(60000 * 90, function()
            for k in pairs(sharedConfig.bigBanks.pacific.lockers) do
                sharedConfig.bigBanks.pacific.lockers[k].isBusy = false
                sharedConfig.bigBanks.pacific.lockers[k].isOpened = false
            end
            for k in pairs(sharedConfig.bigBanks.paleto.lockers) do
                sharedConfig.bigBanks.paleto.lockers[k].isBusy = false
                sharedConfig.bigBanks.paleto.lockers[k].isOpened = false
            end
            TriggerClientEvent('qb-bankrobbery:client:ClearTimeoutDoors', -1)
            sharedConfig.bigBanks.paleto.isOpened = false
            sharedConfig.bigBanks.pacific.isOpened = false
            timeOut = false
            robberyBusy = false
            changeBankState('paleto', false)
            changeBankState('pacific', false)
        end)
    end)
end)

AddEventHandler('qb-bankrobbery:server:SetSmallBankTimeout', function(bankId)
    if robberyBusy or timeOut then return end
    timeOut = true
    CreateThread(function()
        SetTimeout(60000 * 30, function()
            for k in pairs(sharedConfig.smallBanks[bankId].lockers) do
                sharedConfig.smallBanks[bankId].lockers[k].isOpened = false
                sharedConfig.smallBanks[bankId].lockers[k].isBusy = false
            end
            TriggerClientEvent('qb-bankrobbery:client:ResetFleecaLockers', -1, bankId)
            timeOut = false
            robberyBusy = false
            changeBankState(bankId, false)
        end)
    end)
end)

RegisterNetEvent('qb-bankrobbery:server:callCops', function(type, bank, coords)
    if type == 'small' then
        if not sharedConfig.smallBanks[bank].alarm then
            return error(Lang:t('error.event_trigger_wrong', {event = 'qb-bankrobbery:server:callCops', extraInfo = ' (smallbank '..bank..') ', source = source}))
        end
    elseif type == 'paleto' then
        if not sharedConfig.bigBanks.paleto.alarm then
            return error(Lang:t('error.event_trigger_wrong', {event = 'qb-bankrobbery:server:callCops', extraInfo = ' (paleto) ', source = source}))
        end
    elseif type == 'pacific' then
        if not sharedConfig.bigBanks.pacific.alarm then
            return error(Lang:t('error.event_trigger_wrong', {event = 'qb-bankrobbery:server:callCops', extraInfo = ' (pacific) ', source = source}))
        end
    end
    TriggerClientEvent('qb-bankrobbery:client:robberyCall', -1, type, coords)
end)

RegisterNetEvent('qb-bankrobbery:server:SetStationStatus', function(key, isHit)
    sharedConfig.powerStations[key].hit = isHit
    TriggerClientEvent('qb-bankrobbery:client:SetStationStatus', -1, key, isHit)
    if allStationsHit() then
        exports['qb-weathersync']:setBlackout(true)
        TriggerClientEvent('qb-bankrobbery:client:disableAllBankSecurity', -1)
        changeBlackoutState(true)
        CreateThread(function()
            SetTimeout(60000 * config.blackoutTimer, function()
                exports['qb-weathersync']:setBlackout(false)
                TriggerClientEvent('qb-bankrobbery:client:enableAllBankSecurity', -1)
                changeBlackoutState(false)
            end)
        end)
    else
        checkStationHits()
    end
end)

RegisterNetEvent('qb-bankrobbery:server:removeElectronicKit', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    player.Functions.RemoveItem('electronickit', 1)
    TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['electronickit'], 'remove')
    player.Functions.RemoveItem('trojan_usb', 1)
    TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['trojan_usb'], 'remove')
end)

RegisterNetEvent('qb-bankrobbery:server:removeBankCard', function(number)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    player.Functions.RemoveItem('security_card_'..number, 1)
    TriggerClientEvent('inventory:client:ItemBox', src,ITEMS['security_card_'..number], 'remove')
end)

RegisterNetEvent('thermite:StartServerFire', function(coords, maxChildren, isGasFire)
    local src = source
    local ped = GetPlayerPed(src)
    local coords2 = GetEntityCoords(ped)
    local thermiteCoords = sharedConfig.bigBanks.pacific.thermite[1].coords
    local thermite2Coords = sharedConfig.bigBanks.pacific.thermite[2].coords
    local thermite3Coords = sharedConfig.bigBanks.paleto.thermite[1].coords
    if #(coords2 - thermiteCoords) < 10 or #(coords2 - thermite2Coords) < 10 or #(coords2 - thermite3Coords) < 10 or isNearPowerStation(coords2, 10) then
        TriggerClientEvent('thermite:StartFire', -1, coords, maxChildren, isGasFire)
    end
end)

RegisterNetEvent('thermite:StopFires', function()
    TriggerClientEvent('thermite:StopFires', -1)
end)

-- Callbacks
lib.callback.register('qb-bankrobbery:server:isRobberyActive', function()
    return robberyBusy
end)

lib.callback.register('qb-bankrobbery:server:GetConfig', function()
    return sharedConfig.powerStations, sharedConfig.bigBanks, sharedConfig.smallBanks
end)

lib.callback.register('thermite:server:check', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    if player.Functions.RemoveItem('thermite', 1) then
        TriggerClientEvent('inventory:client:ItemBox', source,ITEMS['thermite'], 'remove')
        return true
    else
        return false
    end
end)

-- Items

exports.qbx_core:CreateUseableItem('thermite', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or not player.Functions.GetItemByName('thermite') then return end
	if player.Functions.GetItemByName('lighter') then
        TriggerClientEvent('thermite:UseThermite', source)
    else
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.missing_ignition_source'), 'error')
    end
end)

exports.qbx_core:CreateUseableItem('security_card_01', function(source)
    local player = exports.qbx_core:GetPlayer(source)
	if not player or not player.Functions.GetItemByName('security_card_01') then return end
    TriggerClientEvent('qb-bankrobbery:UseBankcardA', source)
end)

exports.qbx_core:CreateUseableItem('security_card_02', function(source)
    local player = exports.qbx_core:GetPlayer(source)
	if not player or not player.Functions.GetItemByName('security_card_02') then return end
    TriggerClientEvent('qb-bankrobbery:UseBankcardB', source)
end)

exports.qbx_core:CreateUseableItem('electronickit', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or not player.Functions.GetItemByName('electronickit') then return end
    TriggerClientEvent('electronickit:UseElectronickit', source)
end)
