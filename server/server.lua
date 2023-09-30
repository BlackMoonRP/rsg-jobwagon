local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/Rexshack-RedM/rsg-jobwagon/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

        --versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        --versionCheckPrint('success', ('Latest Version: %s'):format(text))
        
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

-----------------------------------------------------------------------

-- setup wagon
RegisterServerEvent('rsg-jobwagon:server:SetupWagon', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local isBoss = Player.PlayerData.job.isboss
    local job = Player.PlayerData.job.name
    if isBoss == true then
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM job_wagons WHERE job = ?", { job })
        if result == 0 then
            local plate = GeneratePlate()
            MySQL.insert('INSERT INTO job_wagons(job, plate, active) VALUES(@job, @plate, @active)', {
                ['@job'] = job,
                ['@plate'] = plate,
                ['@active'] = 1,
            })
            TriggerClientEvent('RSGCore:Notify', src, Lang:t('success.wagon_setup_successfully'), 'success')
        else
            TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.already_have_wagon'), 'error')
        end
    else
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.not_the_boss'), 'error')
    end
end)

-- get active wagon
RSGCore.Functions.CreateCallback('rsg-jobwagon:server:GetActiveWagon', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local job = Player.PlayerData.job.name
    local result = MySQL.query.await('SELECT * FROM job_wagons WHERE job=@job AND active=@active', {
        ['@job'] = job,
        ['@active'] = 1
    })
    if (result[1] ~= nil) then
        cb(result[1])
    else
        cb(nil)
    end
end)

-- generate wagon plate
function GeneratePlate()
    local UniqueFound = false
    local plate = nil
    while not UniqueFound do
        plate = tostring(RSGCore.Shared.RandomStr(3) .. RSGCore.Shared.RandomInt(3)):upper()
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM job_wagons WHERE plate = ?", { plate })
        if result == 0 then
            UniqueFound = true
        end
    end
    return plate
end

--------------------------------------------------------------------------------------------------
-- start version check
--------------------------------------------------------------------------------------------------
CheckVersion()
