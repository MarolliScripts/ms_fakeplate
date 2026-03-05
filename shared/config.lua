Config = Config or {}

Config.Locale = 'pl'

Config.NPC = {
    model = `s_m_m_autoshop_02`,
    coords = vector3(467.3362, -539.3098, 27.9330),
    heading = 95.0,
    distance = 1.5
}

Config.Items = {
    EmptyPlate = 'pustatablica',
    RealPlate = 'tablica'
}

Config.Price = 1000

Config.Target = 'ox_target'

Config.Progress = {
    duration = 20000
}

function Locale(key)
    local loc = Config.Locale or 'en'
    if type(Locales) == 'table' and type(Locales[loc]) == 'table' and Locales[loc][key] then
        return Locales[loc][key]
    end
    return key
end
