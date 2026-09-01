-- Broadcast em runtime quando a convar `mri:color` muda (admin via painel
-- mri_Qadmin ou `setr mri:color` no console). Mesmo padrao do
-- mri_Qmultichar/mri_Qspawn/mri_Qadmin/mri_Qchat — toda a suite MRI
-- compartilha a mesma cor de destaque.
AddConvarChangeListener('mri:color', function(name)
    if name ~= 'mri:color' then return end
    local color = GetConvar('mri:color', '#00E699')
    if not color:match('^#%x%x%x%x%x%x$') then return end
    TriggerClientEvent('ox_lib:accentColorChanged', -1, color)
end)

-- Idem pra cor de fundo. Diferente do accent, '' e valido: significa "sem cor
-- custom", os tokens do index.css voltam a valer.
AddConvarChangeListener('mri:backgroundColor', function(name)
    if name ~= 'mri:backgroundColor' then return end
    local color = GetConvar('mri:backgroundColor', '')
    if color ~= '' and not color:match('^#%x%x%x%x%x%x$') then return end
    TriggerClientEvent('ox_lib:backgroundColorChanged', -1, color)
end)

local locales, localesN = lib.getFilesInDirectory('locales', '%.json')

for i = 1, localesN do
    local key = locales[i]
    local value = key:gsub('%.json', '')
    local label = (json.decode(LoadResourceFile(lib.name, ('locales/%s'):format(key)) or '') or '').language or value
    locales[i] = { label = label, value = value }
end

table.sort(locales, function(a, b)
    return a.label < b.label
end)

GlobalState['ox_lib:locales'] = locales

local ignoreSecurityAdvisory = lib.array.reduce(json.decode(GetConvar('ox:ignoreSecurityAdvisory', "")) or {}, function(acc, value)
    acc[value] = true
    return acc
end, {})

if GetResourceState('qb-core') ~= 'missing' then
    ignoreSecurityAdvisory.stateBagStrictMode = true
end

if not ignoreSecurityAdvisory.stateBagStrictMode then
    SetTimeout(2000, function()
        local stateBagStrictMode = GetConvarBool('sv_stateBagStrictMode', false)

        if stateBagStrictMode then return end

            print([[
^3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  SECURITY WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━^0
sv_stateBagStrictMode is currently ^1DISABLED.^0

State bags are used to replicate entity/player data between server and clients.
When strict mode is OFF, clients are able to freely modify state bag values.

Enabling strict mode improves security by rejecting replicated state bag modifications from clients.

^2Enable with:^0 setr sv_stateBagStrictMode true

^1CAUTION:^0 Some scripts may break or stop syncing when strict mode is enabled.
If you experience issues, update resource logic to comply with strict replication rules.

Disable this warning using ^4set ox:ignoreSecurityAdvisory ["stateBagStrictMode"]^0
^3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━^0]])
    end)
end