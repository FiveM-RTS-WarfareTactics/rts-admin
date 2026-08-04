fx_version 'cerulean'
game 'gta5'

author 'EnyoScripts'
description 'Enyo RTS - Administration & Moderation Panel'
version '2.0.0'

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    'enyo-rts',
    'oxmysql',
}

lua54 'yes'