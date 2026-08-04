local ActiveBans = {}
local ActiveMutes = {}
local AdminPlayers = {}

function GetPermissionLevel(src)
    if IsPlayerAceAllowed(tostring(src), "command.rtsadmin") then return "admin"
    elseif IsPlayerAceAllowed(tostring(src), "command.rtsmod") then return "mod"
    elseif IsPlayerAceAllowed(tostring(src), "command.rtssupport") then return "support"
    end
end

function HasPerm(src, required)
    local level = GetPermissionLevel(src)
    if level == "admin" then return true end
    if required == "mod" and level == "mod" then return true end
    if required == "support" and (level == "support" or level == "mod") then return true end
    return false
end

RegisterNetEvent('rts-admin:requestPanelData', function()
    local src = source
    local level = GetPermissionLevel(src)
    if not level then
        TriggerClientEvent('rts-admin:panelData', src, { permission = nil, online = 0, matchCount = 0, players = {}, matches = {} })
        return
    end

    local players = {}
    for _, pid in ipairs(GetPlayers()) do
        local p = tonumber(pid)
        if p then
            table.insert(players, {
                id = p, name = GetPlayerName(p) or "Player " .. p,
                ping = GetPlayerPing(p), bucket = GetPlayerRoutingBucket(p),
                isMuted = ActiveMutes[p] ~= nil, permission = GetPermissionLevel(p) or "player"
            })
        end
    end

    local matches = {}
    if GetResourceState('enyo-rts') == 'started' then
        local data = exports['enyo-rts']:GetActiveMatchDetails()
        print("^5[ADMIN-SRV] GetActiveMatchDetails returned: " .. tostring(data) .. " type=" .. type(data) .. "^7")
        if data then
            print("^5[ADMIN-SRV] Match count: " .. #data .. "^7")
            for _, m in ipairs(data) do
                print("^5[ADMIN-SRV] Match: id=" .. tostring(m.matchId) .. " map=" .. tostring(m.mapName) .. " bucket=" .. tostring(m.bucketId) .. "^7")
                local mapData = exports['enyo-rts']:GetMapData(m.mapName)
                print("^5[ADMIN-SRV] GetMapData('" .. tostring(m.mapName) .. "') = " .. tostring(mapData) .. "^7")
                if mapData then
                    print("^5[ADMIN-SRV] mapData.center = " .. tostring(mapData.center) .. "^7")
                    if mapData.center then
                        m.cx = mapData.center.x
                        m.cy = mapData.center.y
                        m.cz = mapData.center.z
                        print("^5[ADMIN-SRV] Set coords: cx=" .. m.cx .. " cy=" .. m.cy .. " cz=" .. m.cz .. "^7")
                    end
                end
                table.insert(matches, m)
            end
        end
    end

    local mapNames = {}
    if GetResourceState('enyo-rts') == 'started' then
        local ok, maps = pcall(function() return exports['enyo-rts']:GetMaps() end)
        if ok and maps then for k in pairs(maps) do table.insert(mapNames, k) end end
    end

    TriggerClientEvent('rts-admin:panelData', src, {
        permission = level, online = #players, matchCount = #matches,
        players = players, matches = matches, maps = mapNames,
        adminActive = AdminPlayers[src] or false
    })
end)

RegisterNetEvent('rts-admin:kick', function(target, reason)
    if target == 'all' then
        local all = GetPlayers()
        local count = 0
        for _, pid in ipairs(all) do
            local pnum = tonumber(pid)
            if pnum and pnum ~= source then
                DropPlayer(pnum, "Server shutdown: " .. (reason or "Staff"))
                count = count + 1
            end
        end
        print("^3[ADMIN] Kick all by " .. tostring(source) .. ": kicked " .. count .. " of " .. #all .. " players^7")
    elseif tonumber(target) then
        local t = tonumber(target)
        if GetPlayerName(t) then DropPlayer(t, "Kicked: " .. (reason or "Staff")) end
    end
end)

RegisterNetEvent('rts-admin:ban', function(target, duration, reason)
    if not HasPerm(source, "admin") then return end
    local t = tonumber(target)
    if not GetPlayerName(t) then return end
    local lic = GetPlayerIdentifierByType(t, 'license') or ""
    ActiveBans[lic] = { name = GetPlayerName(t), expires = os.time() + (duration or 0), reason = reason }
    DropPlayer(t, "Banned: " .. (reason or "Rule violation"))
end)

RegisterNetEvent('rts-admin:mute', function(target, duration)
    if not HasPerm(source, "support") then return end
    ActiveMutes[tonumber(target)] = os.time() + (duration or 600)
    TriggerClientEvent('rts-admin:muted', tonumber(target), duration)
end)

RegisterNetEvent('rts-admin:unmute', function(target)
    if not HasPerm(source, "support") then return end
    ActiveMutes[tonumber(target)] = nil
end)

RegisterNetEvent('rts-admin:gotoBucket', function(bucket)
    if not HasPerm(source, "mod") then return end
    SetPlayerRoutingBucket(source, tonumber(bucket) or 0)
end)

RegisterNetEvent('rts-admin:gotoPlayer', function(target)
    if not HasPerm(source, "mod") then return end
    local t = tonumber(target)
    SetPlayerRoutingBucket(source, GetPlayerRoutingBucket(t))
end)

RegisterNetEvent('rts-admin:toggleAdminMode', function()
    if not HasPerm(source, "mod") then return end
    local src = source
    AdminPlayers[src] = not AdminPlayers[src]
    TriggerClientEvent('rts-admin:adminModeToggled', src, AdminPlayers[src])
    if AdminPlayers[src] then
        SetPlayerRoutingBucket(src, 0)
    end
end)

RegisterNetEvent('rts-admin:terminateMatch', function(matchId)
    if not HasPerm(source, "admin") then return end
    if matchId == 'all' then
        TriggerEvent('enyo-rts:server:adminForceEnd', 'all')
    else
        TriggerEvent('enyo-rts:server:adminForceEnd', matchId)
    end
end)

RegisterNetEvent('rts-admin:clearMutes', function()
    ActiveMutes = {}
    print("^3[ADMIN] All mutes cleared by " .. tostring(source) .. "^7")
end)

RegisterNetEvent('rts-admin:announce', function(data)
    if not HasPerm(source, "mod") then return end
    local msg = data.message or ""
    for _, pid in ipairs(GetPlayers()) do
        TriggerClientEvent('rts:client:receiveChatMessage', tonumber(pid), 'SERVER', msg, 'global')
    end
end)

-- Ban check on connect
AddEventHandler('playerConnecting', function(name, setKick, deferrals)
    deferrals.defer()
    local lic
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if string.match(id, '^license:') then lic = id end
    end
    if lic and ActiveBans[lic] and (ActiveBans[lic].expires == 0 or ActiveBans[lic].expires > os.time()) then
        deferrals.done("Banned: " .. (ActiveBans[lic].reason or "Rule violation"))
        CancelEvent()
        return
    end
    deferrals.done()
end)

RegisterNetEvent('rts-admin:togglePanel', function()
    local src = source
    if not GetPermissionLevel(src) then
        TriggerClientEvent('rts:nuiNotify', src, { message = "You do not have permission to access the admin panel.", type = "error" })
        return
    end
    TriggerClientEvent('rts-admin:openPanel', src)
end)

CreateThread(function()
    while true do
        Wait(10000)
        local now = os.time()
        for pid, expires in pairs(ActiveMutes) do
            if expires < now then ActiveMutes[pid] = nil end
        end
    end
end)

RegisterCommand('admin', function(source)
    if source > 0 and not GetPermissionLevel(source) then return end
    TriggerClientEvent('rts-admin:openPanel', source)
end, true)

exports('GetPermissionLevel', GetPermissionLevel)
exports('HasPerm', HasPerm)
exports('IsPlayerMuted', function(pid) return ActiveMutes[pid] and ActiveMutes[pid] > os.time() end)