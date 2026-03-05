fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'marolliscripts.pl'
description 'Simple plate replacer for ESX'
version '2.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@esx_scriptHash/hasher.lua',
    '@ox_lib/init.lua',
    'shared/config.lua',
    'locales/*.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', 
    'server/server.lua'
}
