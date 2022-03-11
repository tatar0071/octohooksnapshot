-- // octo loader
local delta = game:HttpGet("https://raw.githubusercontent.com/tatar0071/octohooksnapshot/main/delta.lua")
local ui = game:HttpGet("https://raw.githubusercontent.com/tatar0071/octohooksnapshot/main/ui.lua")

writefile("ui_octohook.lua", ui)

local games = {
    ['rushpoint'] = {2162282815};
    ['state of anarchy'] = {595270616};
    ['project delta'] = {2862098693};
}

if not isfolder('octohook_games') then
    makefolder('octohook_games');
    writefile("octohook_games/project delta.lua", delta)
end

repeat task.wait() until game:IsLoaded();

local filename = 'octohook_games';
local files = {};

for i,v in next, listfiles(filename) do
    files[v:gsub(filename..'\\','')] = readfile(v);
end

do
    local found, gameName, gameScript = false, nil;
    for name,ids in next, games do
        if table.find(ids, game.GameId) and files[name..'.lua'] then
            found = true;
            gameScript = files[name..'.lua'];
            gameName = name;
            break
        end
    end
    if not found then
        gameScript = files['universal.lua'];
        gameName = 'universal';
    end

    print(found, gameName)

    if gameScript ~= nil then
        if isfile('ui_octohook.lua') then
            loadstring(readfile('ui_octohook.lua'))();
            library.title = 'OCTO TAP BETA (leak by Jack Welker#0345) - '..gameName;
            library.gamename = gameName;
            library:Init();
            repeat task.wait() until library.hasInit == true
            loadstring(gameScript)()
        end
    end
end
