fx_version "adamant"
game 'rdr3'
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."
lua54 'yes'
name "moro_race"
startup_message "moro_race loaded successfully!"
author "Morojgovany"
description "Race"

shared_script {
    "config.lua",
}
client_script {
    'client.lua',
}
server_script {
    'server.lua',
}

files {
    'ui/index.html',
    'ui/app.js',
    'ui/style.css',
    'ui/vendor/*',
    'ui/fonts/*',
}

ui_page 'ui/index.html'
