local config = require 'config.client'
local sharedConfig = require 'config.shared'
local inBankCardBZone = false
local inElectronickitZone = false
local currentLocker = 0
local copsCalled = false

-- Functions

--- This will be triggered once the hack in the pacific bank is done
--- @param success boolean
--- @return nil
local function OnHackPacificDone(success)
    TriggerEvent('mhacking:hide')
    if not success then return end
    TriggerServerEvent('qb-bankrobbery:server:setBankState', 'pacific')
end

--- This will load an animation dictionary so you can play an animation in that dictionary
--- @param dict string
--- @return nil
local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

-- Events

RegisterNetEvent('qb-bankrobbery:UseBankcardB', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    if math.random(1, 100) > 85 or IsWearingGloves() then return end
    TriggerServerEvent("evidence:server:CreateFingerDrop", pos)
    if not inBankCardBZone then return end
    local isBusy = lib.callback.await('qb-bankrobbery:server:isRobberyActive', false)
    if not isBusy then
        if CurrentCops >= config.minPacificPolice then
            if not sharedConfig.bigBanks["pacific"]["isOpened"] then
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().security_card_02.name, image = exports.ox_inventory:Items().security_card_02.image}
                -- }, false)
                loadAnimDict("anim@gangops@facility@servers@")
                TaskPlayAnim(ped, 'anim@gangops@facility@servers@', 'hotwire', 3.0, 3.0, -1, 1, 0, false, false, false)
                if lib.progressBar({
                    duration = 75000,
                    label = Lang:t("general.validating_bankcard"),
                    canCancel = true,
                    useWhileDead = false,
                    disable = {
                        move = true,
                        car = true,
                        mouse = false,
                        combat = true
                    },
                    anim = {
                        dict = "anim@gangops@facility@servers@",
                        clip = "hotwire",
                        flag = 1
                    }
                }) then
                    --Config.DoorlockAction(1, false)
                    TriggerServerEvent('qb-bankrobbery:server:removeBankCard', '02')
                    if copsCalled or not sharedConfig.bigBanks["pacific"]["alarm"] then return end
                    TriggerServerEvent("qb-bankrobbery:server:callCops", "pacific", 0, pos)
                    copsCalled = true
                else
                    exports.qbx_core:Notify(Lang:t("error.cancel_message"), "error")
                end
            else
                exports.qbx_core:Notify(Lang:t("error.bank_already_open"), "error")
            end
        else
            exports.qbx_core:Notify(Lang:t("error.minimum_police_required", {police = config.minPacificPolice}), "error")
        end
    else
        exports.qbx_core:Notify(Lang:t("error.security_lock_active"), "error", 5500)
    end
end)

RegisterNetEvent('electronickit:UseElectronickit', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    if not inElectronickitZone then return end
    local isBusy = lib.callback.await('qb-bankrobbery:server:isRobberyActive', false)
    if not isBusy then
        if CurrentCops >= config.minPacificPolice then
            if not sharedConfig.bigBanks["pacific"]["isOpened"] then
                local hasItem = HasItem({"trojan_usb", "electronickit"})
                if hasItem then
                    -- Config.ShowRequiredItems(nil, false)
                    -- loadAnimDict("anim@gangops@facility@servers@")
                    -- TaskPlayAnim(ped, 'anim@gangops@facility@servers@', 'hotwire', 3.0, 3.0, -1, 1, 0, false, false, false)
                    if lib.progressBar({
                        duration = 7500,
                        label = Lang:t("general.breaking_open_safe"),
                        canCancel = true,
                        useWhileDead = false,
                        disable = {
                            move = true,
                            car = true,
                            mouse = false,
                            combat = true
                        },
                        anim = {
                            dict = "anim@gangops@facility@servers@",
                            clip = "hotwire",
                            flag = 1
                        }
                    }) then
                        StopAnimTask(ped, "anim@gangops@facility@servers@", "hotwire", 1.0)
                        TriggerEvent("mhacking:show")
                        TriggerEvent("mhacking:start", math.random(5, 9), math.random(10, 15), OnHackPacificDone)
                        if copsCalled or not sharedConfig.bigBanks["pacific"]["alarm"] then return end
                        TriggerServerEvent("qb-bankrobbery:server:callCops", "pacific", 0, pos)
                        copsCalled = true
                    else
                        exports.qbx_core:Notify(Lang:t("error.cancel_message"), "error")
                    end
                else
                    exports.qbx_core:Notify(Lang:t("error.missing_item"), "error")
                end
            else
                exports.qbx_core:Notify(Lang:t("error.bank_already_open"), "error")
            end
        else
            exports.qbx_core:Notify(Lang:t("error.minimum_police_required", {police = config.minPacificPolice}), "error")
        end
    else
        exports.qbx_core:Notify(Lang:t("error.security_lock_active"), "error", 5500)
    end
end)

-- Threads

CreateThread(function()
    local bankCardBZone = BoxZone:Create(sharedConfig.bigBanks["pacific"]["coords"][1], 1.0, 1.0, {
        name = 'pacific_coords_bankcardb',
        heading = sharedConfig.bigBanks["pacific"]["heading"].closed,
        minZ = sharedConfig.bigBanks["pacific"]["coords"][1].z - 1,
        maxZ = sharedConfig.bigBanks["pacific"]["coords"][1].z + 1,
        debugPoly = false
    })
    bankCardBZone:onPlayerInOut(function(inside)
        inBankCardBZone = inside
        if inside and not sharedConfig.bigBanks["pacific"]["isOpened"] then
            -- Config.ShowRequiredItems({
            --     [1] = {name = exports.ox_inventory:Items().security_card_02.name, image = exports.ox_inventory:Items().security_card_02.image}
            -- }, true)
        else
            -- Config.ShowRequiredItems({
            --     [1] = {name = exports.ox_inventory:Items().security_card_02.name, image = exports.ox_inventory:Items().security_card_02.image}
            -- }, false)
        end
    end)
    local electronickitZone = BoxZone:Create(sharedConfig.bigBanks["pacific"]["coords"][2], 1.0, 1.0, {
        name = 'pacific_coords_electronickit',
        heading = sharedConfig.bigBanks["pacific"]["heading"].closed,
        minZ = sharedConfig.bigBanks["pacific"]["coords"][2].z - 1,
        maxZ = sharedConfig.bigBanks["pacific"]["coords"][2].z + 1,
        debugPoly = false
    })
    electronickitZone:onPlayerInOut(function(inside)
        inElectronickitZone = inside
        if inside and not sharedConfig.bigBanks["pacific"]["isOpened"] then
            -- Config.ShowRequiredItems({
            --     [1] = {name = exports.ox_inventory:Items().electronickit.name, image = exports.ox_inventory:Items().electronickit.image},
            --     [2] = {name = exports.ox_inventory:Items().trojan_usb.name, image = exports.ox_inventory:Items().trojan_usb.image}
            -- }, true)
        else
            -- Config.ShowRequiredItems({
            --     [1] = {name = exports.ox_inventory:Items().electronickit.name, image = exports.ox_inventory:Items().electronickit.image},
            --     [2] = {name = exports.ox_inventory:Items().trojan_usb.name, image = exports.ox_inventory:Items().trojan_usb.image}
            -- }, false)
        end
    end)
    local thermite1Zone = BoxZone:Create(sharedConfig.bigBanks["pacific"]["thermite"][1]["coords"], 1.0, 1.0, {
        name = 'pacific_coords_thermite_1',
        heading = sharedConfig.bigBanks["pacific"]["heading"].closed,
        minZ = sharedConfig.bigBanks["pacific"]["thermite"][1]["coords"].z - 1,
        maxZ = sharedConfig.bigBanks["pacific"]["thermite"][1]["coords"].z + 1,
        debugPoly = false
    })
    thermite1Zone:onPlayerInOut(function(inside)
        if inside and not sharedConfig.bigBanks["pacific"]["thermite"][1]["isOpened"] then
            currentThermiteGate = sharedConfig.bigBanks["pacific"]["thermite"][1]["doorId"]
            -- Config.ShowRequiredItems({
            --     [1] = {name = exports.ox_inventory:Items().thermite.name, image = exports.ox_inventory:Items().thermite.image},
            -- }, true)
        else
            if currentThermiteGate == sharedConfig.bigBanks["pacific"]["thermite"][1]["doorId"] then
                currentThermiteGate = 0
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().thermite.name, image = exports.ox_inventory:Items().thermite.image},
                -- }, false)
            end
        end
    end)
    local thermite2Zone = BoxZone:Create(sharedConfig.bigBanks["pacific"]["thermite"][2]["coords"], 1.0, 1.0, {
        name = 'pacific_coords_thermite_2',
        heading = sharedConfig.bigBanks["pacific"]["heading"].closed,
        minZ = sharedConfig.bigBanks["pacific"]["thermite"][2]["coords"].z - 1,
        maxZ = sharedConfig.bigBanks["pacific"]["thermite"][2]["coords"].z + 1,
        debugPoly = false
    })
    thermite2Zone:onPlayerInOut(function(inside)
        if inside and not sharedConfig.bigBanks["pacific"]["thermite"][2]["isOpened"] then
            currentThermiteGate = sharedConfig.bigBanks["pacific"]["thermite"][2]["doorId"]
            -- Config.ShowRequiredItems({
            --     [1] = {name = exports.ox_inventory:Items().thermite.name, image = exports.ox_inventory:Items().thermite.image},
            -- }, true)
        else
            if currentThermiteGate == sharedConfig.bigBanks["pacific"]["thermite"][2]["doorId"] then
                currentThermiteGate = 0
                -- Config.ShowRequiredItems({
                --     [1] = {name = exports.ox_inventory:Items().thermite.name, image = exports.ox_inventory:Items().thermite.image},
                -- }, false)
            end
        end
    end)
    for k in pairs(sharedConfig.bigBanks["pacific"]["lockers"]) do
        if config.useTarget then
            exports['qb-target']:AddBoxZone('pacific_coords_locker_'..k, sharedConfig.bigBanks["pacific"]["lockers"][k]["coords"], 1.0, 1.0, {
                name = 'pacific_coords_locker_'..k,
                heading = sharedConfig.bigBanks["pacific"]["heading"].closed,
                minZ = sharedConfig.bigBanks["pacific"]["lockers"][k]["coords"].z - 1,
                maxZ = sharedConfig.bigBanks["pacific"]["lockers"][k]["coords"].z + 1,
                debugPoly = false
            }, {
                options = {
                    {
                        action = function()
                            openLocker("pacific", k)
                        end,
                        canInteract = function()
                            return not IsDrilling and sharedConfig.bigBanks["pacific"]["isOpened"] and not sharedConfig.bigBanks["pacific"]["lockers"][k]["isBusy"] and not sharedConfig.bigBanks["pacific"]["lockers"][k]["isOpened"]
                        end,
                        icon = 'fa-solid fa-vault',
                        label = Lang:t("general.break_safe_open_option_target"),
                    },
                },
                distance = 1.5
            })
        else
            local lockerZone = BoxZone:Create(sharedConfig.bigBanks["pacific"]["lockers"][k]["coords"], 1.0, 1.0, {
                name = 'pacific_coords_locker_'..k,
                heading = sharedConfig.bigBanks["pacific"]["heading"].closed,
                minZ = sharedConfig.bigBanks["pacific"]["lockers"][k]["coords"].z - 1,
                maxZ = sharedConfig.bigBanks["pacific"]["lockers"][k]["coords"].z + 1,
                debugPoly = false
            })
            lockerZone:onPlayerInOut(function(inside)
                if inside and not IsDrilling and sharedConfig.bigBanks["pacific"]["isOpened"] and not sharedConfig.bigBanks["pacific"]["lockers"][k]["isBusy"] and not sharedConfig.bigBanks["pacific"]["lockers"][k]["isOpened"] then
                    exports['qbx-core']:DrawText(Lang:t("general.break_safe_open_option_drawtext"), 'right')
                    currentLocker = k
                else
                    if currentLocker == k then
                        currentLocker = 0
                        exports['qbx-core']:HideText()
                    end
                end
            end)
        end
    end
    if not config.useTarget then
        while true do
            local sleep = 1000
            if isLoggedIn then
                if currentLocker ~= 0 and not IsDrilling and sharedConfig.bigBanks["pacific"]["isOpened"] and not sharedConfig.bigBanks["pacific"]["lockers"][currentLocker]["isBusy"] and not sharedConfig.bigBanks["pacific"]["lockers"][currentLocker]["isOpened"] then
                    sleep = 0
                    if IsControlJustPressed(0, 38) then
                        exports['qbx-core']:KeyPressed()
                        Wait(500)
                        exports['qbx-core']:HideText()
                        if CurrentCops >= config.minPacificPolice then
                            openLocker("pacific", currentLocker)
                        else
                            exports.qbx_core:Notify(Lang:t("error.minimum_police_required", {police = config.minPacificPolice}), "error")
                        end
                        sleep = 1000
                    end
                end
            end
            Wait(sleep)
        end
    end
end)
