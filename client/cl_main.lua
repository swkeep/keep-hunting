-- ============================
--    CLIENT CONFIGS
-- ============================
local CoreName = exports['qb-core']:GetCoreObject()

-- ============================
--      FUNCTIONS
-- ============================
function SellingBlips(coord)
    for _, v in pairs(Config.SellSpots) do
        -- create Blips
        local blip = AddBlipForCoord(v.BlipsCoords.x, v.BlipsCoords.y, v.BlipsCoords.z)
        SetBlipSprite(blip, 141)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.6)
        SetBlipColour(blip, 49)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Sell Meat")
        EndTextCommandSetBlipName(blip)

        -- init qb-target for sellers
        exports['qb-target']:AddTargetModel(v.SellerNpc.model, {
            options = {{
                event = "cad-hunting:client:sellREQ",
                icon = "fas fa-sack-dollar",
                label = "Sell MMMMMMEATTTTTTTT"
            }},
            distance = 2.5
        })

        -- spwan seller npcs
        exports['qb-target']:SpawnPed({
            [_] = v.SellerNpc
        })
    end
end

function initAnimalsTargting()
    for _, v in pairs(Config.Animals) do
        exports['qb-target']:AddTargetModel(v.model, {
            options = {{
                icon = "fas fa-sack-dollar",
                label = "Buch",
                data = entity,
                canInteract = function(entity)
                    if not IsPedAPlayer(entity) then
                        local res = (entity and IsEntityDead(entity))
                        return res
                    end
                end,
                action = function(entity)
                    if IsPedAPlayer(entity) then
                        return false
                    end
                    TriggerEvent('cad-hunting:client:buchAnimal', entity)
                end
            }},
            distance = 1.5
        })
    end
end

function getAnimalMatch(hash)
    for _, v in pairs(Config.Animals) do
        if (v.hash == hash) then
            return v
        end
    end
end

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(0)
    end
end

Citizen.CreateThread(function()
    local player = PlayerPedId()
    local coord = GetEntityCoords(player)
    SellingBlips(coord)
    initAnimalsTargting()
    Wait(200)
end)

AddEventHandler('cad-hunting:client:buchAnimal', function(entity)
    local model = GetEntityModel(entity)
    local animal = getAnimalMatch(model)

    if (model and animal) then
        CoreName.Functions.TriggerCallback("QBCore:HasItem", function(hasitem)
            if hasitem then
                loadAnimDict('amb@medic@standing@kneel@base')
                loadAnimDict('anim@gangops@facility@servers@bodysearch@')
                TaskPlayAnim(GetPlayerPed(-1), "amb@medic@standing@kneel@base", "base", 8.0, -8.0, -1, 1, 0, false,
                    false, false)
                TaskPlayAnim(GetPlayerPed(-1), "anim@gangops@facility@servers@bodysearch@", "player_search", 8.0, -8.0,
                    -1, 48, 0, false, false, false)
                CoreName.Functions.Progressbar("harv_anim", "Harvesting Animal", 5000, false, false, {
                    disableMovement = true,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true
                }, {}, {}, {}, function()
                    ClearPedTasks(GetPlayerPed(-1))
                    TriggerServerEvent('cad-hunting:server:AddItem', animal)
                    Citizen.Wait(100)
                    --DeleteEntity(entity)
                end)
            else
                CoreName.Functions.Notify("You dont have knife.")
            end
        end, "weapon_knife")
    end
end)

AddEventHandler('cad-hunting:client:sellREQ', function()
    TriggerServerEvent('cad-hunting:server:sellmeat', animal)
end)

-- ============================
--      Spawning Ped
-- ============================
RegisterNetEvent('cad-hunting:client:spawnanim')
AddEventHandler('cad-hunting:client:spawnanim', function(model)
    model = (tonumber(model) ~= nil and tonumber(model) or GetHashKey(model))
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local x, y, z = table.unpack(coords + forward * 1.0)

    Citizen.CreateThread(function()
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(1)
        end
        CreatePed(5, model, x, y, z, 0.0, true, false)
    end)
end)
