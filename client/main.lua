local PanelOpen, AdminActive, NoclipActive = false, false, false
local architectActive, architectConfirmed = false, false
local architectPos = vector3(0,0,0)

function ExitVoidForWorld()
    TriggerEvent('rts:hideUI')
    PanelOpen = false; SetNuiFocus(false, false); SendNUIMessage({ action = 'close' })
    RenderScriptCams(false, true, 0, true, true)
    SetNuiFocusKeepInput(true)
end

function SetupPedAtCoords(x, y, z)
    local models = { "s_m_y_cop_01", "s_m_m_ciasec_01", "s_m_y_swat_01", "s_m_y_marine_01", "s_m_m_fiboffice_01" }
    local hash = GetHashKey(models[math.random(#models)])
    RequestModel(hash); while not HasModelLoaded(hash) do RequestModel(hash); Wait(10) end
    SetPlayerModel(PlayerId(), hash)
    SetPedDefaultComponentVariation(PlayerPedId())
    SetModelAsNoLongerNeeded(hash)
    local ped = PlayerPedId()
    SetEntityCoords(ped, x, y, z)
    NetworkResurrectLocalPlayer(x, y, z, 0.0, true, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, true)
    ClearPedTasksImmediately(ped)
    SetEntityVisible(ped, true)
    SetEntityAlpha(ped, 255, false)
    return ped
end

function EnterArchitectMode()
    ExitVoidForWorld()
    local ped = SetupPedAtCoords(-1040.0, -2745.0, 100.0)
    SetEntityVisible(ped, false)
    SetEntityHasGravity(ped, false)
    architectPos = vector3(-1040.0, -2745.0, 100.0)
    architectActive = true; architectConfirmed = false
end

function ExitArchitectMode()
    architectActive = false; architectConfirmed = false
    local ped = PlayerPedId()
    SetEntityCoords(ped, 0.0, 0.0, 1000.0)
    SetEntityVisible(ped, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    NetworkResurrectLocalPlayer(0.0, 0.0, 1000.0, 0.0, true, true, false)
    TriggerEvent('enyo-rts:showRTS')
end

CreateThread(function()
    while true do
        Wait(0)
        if not AdminActive and not architectActive then Wait(500) else Wait(0) end

        if architectActive then
            if IsControlPressed(0, 201) and not architectConfirmed then
                if architectPos then
                    architectConfirmed = true; architectActive = false
                    local ped = PlayerPedId()
                    SetEntityCoords(ped, architectPos.x, architectPos.y, architectPos.z + 2)
                    SetEntityVisible(ped, true); SetEntityCollision(ped, true, true); SetEntityHasGravity(ped, true)
                    ExecuteCommand(string.format('buildmap %.1f %.1f %.1f 300', architectPos.x, architectPos.y, architectPos.z))
                end
            end
            if IsControlJustPressed(0, 56) then ExitArchitectMode() end
        elseif AdminActive then
            if IsControlJustPressed(0, 56) then TriggerServerEvent('rts-admin:toggleAdminMode') end
            if IsControlJustPressed(0, 57) and IsWaypointActive() then
                local wp = GetWaypointCoords()
                local _, z = GetGroundZFor_3dCoord(wp.x, wp.y, 1000.0, 0)
                SetEntityCoords(PlayerPedId(), wp.x, wp.y, z + 1.0)
            end
            if IsControlJustPressed(0, 249) then
                NoclipActive = not NoclipActive
                if not NoclipActive then
                    local ped = PlayerPedId()
                    local c = GetEntityCoords(ped)
                    local _, z = GetGroundZFor_3dCoord(c.x, c.y, 1000.0, 0)
                    if z then SetEntityCoords(ped, c.x, c.y, z + 1.0) end
                    SetEntityVelocity(ped, 0, 0, 0)
                end
            end
        end
    end
end)

local lhSmooth, lpSmooth = 0, 0

CreateThread(function()
    while true do
        Wait(0)
        if (NoclipActive and AdminActive) or architectActive then
            local ped = PlayerPedId()
            if architectActive then
                SetEntityCollision(ped, false, false)
                SetEntityHasGravity(ped, false)
                SetEntityInvincible(ped, true)
            elseif NoclipActive and AdminActive then
                SetEntityCollision(ped, false, false)
                SetEntityHasGravity(ped, false)
                SetEntityInvincible(ped, true)
            end

            if (NoclipActive and AdminActive) or architectActive then
            local spd = IsControlPressed(0, 21) and 5.0 or 2.0
            local rot = GetGameplayCamRot(2); local h, p = rot.z, rot.x
            local x, y, z = 0, 0, 0
            if IsControlPressed(0, 32) then x = -math.sin(math.rad(h))*math.abs(math.cos(math.rad(p)))*spd; y = math.cos(math.rad(h))*math.abs(math.cos(math.rad(p)))*spd; z = math.sin(math.rad(p))*spd
            elseif IsControlPressed(0, 33) then x = math.sin(math.rad(h))*math.abs(math.cos(math.rad(p)))*spd; y = -math.cos(math.rad(h))*math.abs(math.cos(math.rad(p)))*spd; z = -math.sin(math.rad(p))*spd end
            if IsControlPressed(0, 34) then x = x-math.cos(math.rad(h))*spd; y = y-math.sin(math.rad(h))*spd
            elseif IsControlPressed(0, 35) then x = x+math.cos(math.rad(h))*spd; y = y+math.sin(math.rad(h))*spd end
            if IsControlPressed(0, 44) then z = z+spd elseif IsControlPressed(0, 38) then z = z-spd end
            if x~=0 or y~=0 or z~=0 then local c = GetEntityCoords(ped); SetEntityCoordsNoOffset(ped, c.x+x, c.y+y, c.z+z, true, true, true) end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if architectActive then
            local cp = GetGameplayCamCoord()
            local cr = GetGameplayCamRot(2)
            local cx = -math.sin(math.rad(cr.z)) * math.abs(math.cos(math.rad(cr.x)))
            local cy = math.cos(math.rad(cr.z)) * math.abs(math.cos(math.rad(cr.x)))
            local cz = math.sin(math.rad(cr.x))
            local rEnd = vector3(cp.x + cx * 800, cp.y + cy * 800, cp.z + cz * 800)
            local ray = StartShapeTestRay(cp.x, cp.y, cp.z, rEnd.x, rEnd.y, rEnd.z, -1, PlayerPedId(), 0)
            local _, hit, hPos = GetShapeTestResult(ray)
            local endPos = hit == 1 and hPos or rEnd
            local dist = #(cp - endPos)
            if dist > 150 or hit == 0 then endPos = nil end
            if endPos then
                architectPos = hit == 1 and hPos or rEnd
                DrawMarker(28, endPos.x, endPos.y, endPos.z, 0.0,0.0,0.0, 0.0,0.0,0.0, 4.0,4.0,1.5, 255,200,50,255, false,false, 2, nil, nil, false)
                DrawMarker(0, endPos.x, endPos.y, endPos.z + 2.0, 0.0,0.0,0.0, 0.0,0.0,0.0, 1.5,1.5,4.0, 255,200,50,255, false,true, 2, nil, nil, false)
                local textZ = endPos.z + math.max(3.0, dist * 0.08)
                local onScreen, sx, sy = GetScreenCoordFromWorldCoord(endPos.x, endPos.y, textZ)
                if onScreen then
                    local scale = math.max(0.30, 0.55 - dist * 0.002)
                    SetTextFont(0); SetTextScale(scale, scale); SetTextColour(255,200,50,255)
                    SetTextDropshadow(0,0,0,0,255); SetTextEdge(1,0,0,0,255); SetTextCentre(true)
                    BeginTextCommandDisplayText("STRING")
                    AddTextComponentSubstringPlayerName("~y~[ENTER]~w~ Build    ~r~[F9]~w~ Cancel")
                    EndTextCommandDisplayText(sx, sy)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if architectActive then
            SetTextFont(0); SetTextScale(0.35, 0.35); SetTextColour(232, 168, 56, 255)
            SetTextDropshadow(0,0,0,0,255); SetTextEdge(1,0,0,0,255)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName("~y~ARCHITECT MODE~w~  |  ~y~WASD~w~ Fly  |  ~y~Enter~w~ Build  |  ~y~F9~w~ Cancel")
            EndTextCommandDisplayText(0.5, 0.05)
        elseif AdminActive then
            SetTextFont(0); SetTextScale(0.33, 0.33); SetTextColour(232, 168, 56, 255)
            SetTextDropshadow(0,0,0,0,255); SetTextEdge(1,0,0,0,255)
            local ncText = NoclipActive and "~r~NOCLIP ON~w~" or "~y~N~w~ Noclip"
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName(string.format("~y~ADMIN~w~  |  %s  |  ~y~F9~w~ Exit", ncText))
            EndTextCommandDisplayText(0.5, 0.05)
        end
    end
end)

RegisterNetEvent('rts-admin:adminModeToggled', function(active)
    AdminActive = active
    if active then EnableAdminMode() else NoclipActive = false; DisableAdminMode() end
end)

RegisterNetEvent('rts-admin:openPanel', function()
    if not PanelOpen then
        PanelOpen = true; SetNuiFocus(true, true); SetNuiFocusKeepInput(false)
        SendNUIMessage({ action = 'open' }); TriggerServerEvent('rts-admin:requestPanelData')
    else
        PanelOpen = false; SetNuiFocus(false, false); SendNUIMessage({ action = 'close' })
        TriggerEvent('rts:restoreFocus')
    end
end)

RegisterCommand('rts_noclip', function()
    NoclipActive = not NoclipActive
    if not NoclipActive then
        local ped = PlayerPedId()
        SetEntityCollision(ped, true, true)
        SetEntityHasGravity(ped, true)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        local c = GetEntityCoords(ped)
        local _, z = GetGroundZFor_3dCoord(c.x, c.y, 1000.0, 0)
        if z then SetEntityCoords(ped, c.x, c.y, z + 1.0) end
        SetEntityVelocity(ped, 0, 0, 0)
    end
end, false)
RegisterKeyMapping('rts_noclip', 'TCVN(Toggle Noclip)', 'keyboard', 'n')

RegisterNUICallback('closePanel', function(_, cb)
    PanelOpen = false; SendNUIMessage({ action = 'close' }); SetNuiFocus(false, false)
    local ped = PlayerPedId()
    SetEntityCoords(ped, 0, 0, 1000); SetEntityVisible(ped, false); FreezeEntityPosition(ped, true); SetEntityInvincible(ped, true)
    NetworkResurrectLocalPlayer(0, 0, 1000, 0, true, true, false)
    TriggerEvent('enyo-rts:showRTS')
    cb({})
end)
RegisterNUICallback('refresh', function(_, cb) TriggerServerEvent('rts-admin:requestPanelData') cb({}) end)
RegisterNUICallback('kick', function(d, cb) TriggerServerEvent('rts-admin:kick', d.id, d.reason) cb({}) end)
RegisterNUICallback('ban', function(d, cb) TriggerServerEvent('rts-admin:ban', d.id, d.dur, d.reason) cb({}) end)
RegisterNUICallback('mute', function(d, cb) TriggerServerEvent('rts-admin:mute', d.id, d.dur); TriggerServerEvent('rts-admin:requestPanelData'); cb({}) end)
RegisterNUICallback('unmute', function(d, cb) TriggerServerEvent('rts-admin:unmute', d.id); TriggerServerEvent('rts-admin:requestPanelData'); cb({}) end)
RegisterNUICallback('gotoBucket', function(d, cb) TriggerServerEvent('rts-admin:gotoBucket', d.bucket) cb({}) end)
RegisterNUICallback('gotoPlayer', function(d, cb) TriggerServerEvent('rts-admin:gotoPlayer', d.id) cb({}) end)
RegisterNUICallback('toggleAdminMode', function(_, cb) TriggerServerEvent('rts-admin:toggleAdminMode') cb({}) end)
RegisterNUICallback('terminateMatch', function(d, cb) TriggerServerEvent('rts-admin:terminateMatch', d.id) cb({}) end)
RegisterNUICallback('spectate', function(d, cb)
    print("^5[ADMIN] spectate: bucket=" .. tostring(d.bucket) .. " cx=" .. tostring(d.cx) .. " cy=" .. tostring(d.cy) .. " cz=" .. tostring(d.cz) .. "^7")
    StartSpectate(d.bucket, d.cx, d.cy, d.cz) cb({})
end)
RegisterNUICallback('stopSpectate', function(_, cb) EndSpectate() cb({}) end)
RegisterNUICallback('enterArchitect', function(_, cb) if architectActive then ExitArchitectMode() else EnterArchitectMode() end cb({}) end)
RegisterNUICallback('buildAtPosition', function(_, cb) local pos = GetEntityCoords(PlayerPedId()); ExecuteCommand(string.format('buildmap %.1f %.1f %.1f 300', pos.x, pos.y, pos.z)); cb({}) end)
RegisterNUICallback('startBuilder', function(d, cb)
    if not AdminActive then ExitVoidForWorld(); SetupPedAtCoords(tonumber(d.x) or 0, tonumber(d.y) or 0, tonumber(d.z) or 0) end
    ExecuteCommand(string.format('buildmap %.1f %.1f %.1f %.0f', tonumber(d.x) or 0, tonumber(d.y) or 0, tonumber(d.z) or 0, tonumber(d.r) or 300))
    cb({})
end)
RegisterNUICallback('testMap', function(_, cb) ExecuteCommand('testmap') cb({}) end)
RegisterNUICallback('loadMap', function(d, cb)
    local Maps = exports['enyo-rts']:GetMaps()
    if d.name and Maps[d.name] then
        local map = Maps[d.name]
        ExitVoidForWorld()
        ExecuteCommand(string.format('buildmap %.1f %.1f %.1f %.0f', map.center.x, map.center.y, map.center.z, map.range))
        Citizen.CreateThread(function()
            Citizen.Wait(1500)
            TriggerEvent('rts-mapbuilder:loadMapData', map)
        end)
    end
    cb({})
end)
RegisterNUICallback('clearMap', function(_, cb) ExecuteCommand('clearmap') cb({}) end)
RegisterNUICallback('exportMap', function(_, cb) ExecuteCommand('testmap') cb({}) end)
RegisterNUICallback('clearMutes', function(_, cb) TriggerServerEvent('rts-admin:clearMutes'); TriggerServerEvent('rts-admin:requestPanelData'); cb({}) end)
RegisterNUICallback('announce', function(d, cb) TriggerServerEvent('rts-admin:announce', d); cb({}) end)

RegisterNetEvent('rts-admin:panelData', function(data) SendNUIMessage({ action = 'update', data = data }) end)

function EnableAdminMode()
    ExitVoidForWorld()
    Wait(100)
    SetupPedAtCoords(-1040.0, -2745.0, 13.0)
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_COMBATPISTOL"), 999, false, true)
    CreateVehicle(GetHashKey("police3"), -1045.0, -2745.0, 13.0, 0.0, true, true)
end

function DisableAdminMode()
    NoclipActive = false
    local ped = PlayerPedId()
    SetEntityCoords(ped, 0.0, 0.0, 1000.0)
    SetEntityVisible(ped, false); FreezeEntityPosition(ped, true); SetEntityInvincible(ped, true)
    NetworkResurrectLocalPlayer(0.0, 0.0, 1000.0, 0.0, true, true, false)
    TriggerEvent('enyo-rts:showRTS')
end

function StartSpectate(bucket, cx, cy, cz)
    ExitVoidForWorld()
    TriggerServerEvent('rts-admin:gotoBucket', bucket)
    Wait(1000)
    local ped = PlayerPedId()
    if cx then
        SetEntityCoordsNoOffset(ped, cx, cy, cz + 80, false, false, false)
    end
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, false, false)
    SetEntityHasGravity(ped, false)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false)
    NoclipActive = true
    AdminActive = true
end

function EndSpectate()
    NoclipActive = false
    AdminActive = false
    TriggerServerEvent('rts-admin:gotoBucket', 0)
    local ped = PlayerPedId()
    SetEntityCoords(ped, 0, 0, 1000); SetEntityVisible(ped, false); FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    TriggerEvent('enyo-rts:showRTS')
end