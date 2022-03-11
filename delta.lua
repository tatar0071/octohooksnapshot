-- // nice code liam u code like a FUCKING MONKEY

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- // Load Library
local init = false;
local library = library; -- fix vscode being silly

-- // Variables
local function gs(a)
    return game:GetService(a);
end

local players, http, runservice, teleportservice, inputservice, lighting, network, repstorage = gs('Players'), gs('HttpService'), gs('RunService'), gs('TeleportService'), gs('UserInputService'), gs('Lighting'), gs('NetworkClient'), gs('ReplicatedStorage');
local localplayer, mouse = players.LocalPlayer, players.LocalPlayer:GetMouse();

local floor, ceil, huge, clamp, pi, tau = math.floor, math.ceil, math.huge, math.clamp, math.pi, math.pi*2
local fromrgb, fromhsv, c3new = Color3.fromRGB, Color3.fromHSV, Color3.new

local connections = {};
local espDrawings = {};

local invDrawings = {};
local cachedPlayers = {};

local droppedItems = workspace.DroppedItems;
local itemClasses = {'Guns', 'Clothes', 'Throwables', 'Attachments'}

local VFXModule = require(repstorage.Modules.VFX)

local bodyparts = {
    ['Head'] = {'Head'};
    ['Left Arm'] = {'LeftUpperArm', 'LeftLowerArm', 'LeftHand'};
    ['Right Arm'] = {'RightUpperArm', 'RightLowerArm', 'RightHand'};
    ['Left Leg'] = {'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot'};
    ['Right Leg'] = {'RightUpperLeg', 'RightLowerLeg', 'RightFoot'};
    ['Torso'] = {'UpperTorso', 'LowerTorso'};
}

local r6Parts = {'Head', 'Left Arm', 'Right Arm', 'Left Arm', 'Left Leg', 'Right Leg', 'Torso'};
local r15Parts = {'Head', 'LeftUpperArm', 'LeftLowerArm', 'LeftHand', 'RightUpperArm', 'RightLowerArm', 'RightHand', 'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot', 'RightUpperLeg', 'RightLowerLeg', 'RightFoot', 'UpperTorso', 'LowerTorso'};
local allBodyParts = {'Head', 'Left Arm', 'Right Arm', 'Left Arm', 'Left Leg', 'Right Leg', 'Torso','LeftUpperArm', 'LeftLowerArm', 'LeftHand', 'RightUpperArm', 'RightLowerArm', 'RightHand', 'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot', 'RightUpperLeg', 'RightLowerLeg', 'RightFoot', 'UpperTorso', 'LowerTorso'}

local chamsMaterials = {
    'SmoothPlastic';
    'ForceField';
    'Neon';
    'Glass';
}

-- // Functions

local function newDrawing(type, props)
    local d = Drawing.new(type);
    for i,v in next, props or {} do
        local s,e = pcall(function()
            d[i] = v;
        end)
        if not s then
            warn(e);
        end
    end
    return d;
end

local function Connection(signal,callback,...)
    local connection = signal:Connect(callback,...)
    table.insert(connections,connection)
    return connection
end

local function ConvertNumberRange(val,oldmin,oldmax,newmin,newmax)
    return (((val - oldmin) * (newmax - newmin)) / (oldmax - oldmin)) + newmin;
end

local function hasCharacter(player, minhealth)
    local pass = false;
    if player.Character and player.Character:FindFirstChild('HumanoidRootPart') and player.Character:FindFirstChild('Head') and player.Character:FindFirstChild('Humanoid') and player.Character.Humanoid.Health > (minhealth or 0) then
        pass = true;
    end
    return pass and player.Character or false;
end

local function modelOnScreen(model)
    for i,v in next, model:GetChildren() do
        if v:IsA('Part') or v:IsA('BasePart') or v:IsA('MeshPart') then
            local _, vis = workspace.CurrentCamera:WorldToViewportPoint(v.CFrame.p);
            if vis then
                return true
            end
        end
    end
end

local function getClosestPlayerToVector2(vector2, teamcheck, part)
    part = part == nil and 'HumanoidRootPart' or part
    local target, dist = nil, math.huge;
    for i,v in next, players:GetPlayers() do
        local char = hasCharacter(v);
        if v ~= localplayer and (teamcheck and (v.Team ~= localplayer.Team) or true) and char and char:FindFirstChild(part) then
            local pos, vis = workspace.CurrentCamera:WorldToViewportPoint(char[part].CFrame.p);
            if vis then
                local mag = (Vector2.new(pos.X, pos.Y) - vector2).magnitude;
                if mag < dist then
                    dist = mag;
                    target = v;
                end
            end
        end
    end
    return target, dist;
end

local function rotateVector2(v2, r)
    local c = math.cos(r);
    local s = math.sin(r);
    return Vector2.new(c * v2.X - s*v2.Y, s*v2.X + c*v2.Y)
end

local function hookfunc(a,b)
    local old
    old = hookfunction(a,function(...)
        return old(b({...}))
    end)
end

local function combineTable(...)
    local t3 = {}
    for _,v in next, {...} do
        for i,v2 in next, v do
            t3[i] = v2;
        end
    end
    return t3
end

local selectedPlayerDrawing = newDrawing('Text', {Text = 'PLAYERS INVENTORY:', Position = Vector2.new(10,350), Color = Color3.new(1,1,1), Outline = true, Size = 13, Font = 2})
local function updateInvDrawings()
    selectedPlayerDrawing.Visible = library.flags.aimbot_viewinventory
    if init then
        local pos = 350
        for i,v in next, invDrawings do
            v[1].Visible = library.flags.aimbot_viewinventory;
            v[1].Position = Vector2.new(10, pos + 18);
            v[1].Text = v[2] == 1 and i or i..' x'..tostring(v[2]);
            pos = v[1].Position.Y;
        end
    end
end

local invc1, invc2
local selectedInventoryTarget;
local function viewInventory(plr)
    if plr ~= selectedInventoryTarget then
        selectedInventoryTarget = plr
        
        if invc1 then
            invc1:Disconnect();
            invc2:Disconnect();
        end
        
        for i,v in next, invDrawings do
            v[1]:Remove();
            invDrawings[i] = nil;
        end
    
        if cachedPlayers[plr.Name] then
            local function a(inst)
                if invDrawings[inst.Name] then
                    invDrawings[inst.Name][2] += 1
                else
                    invDrawings[inst.Name] = {newDrawing('Text', {Text = inst.Name, Color = Color3.new(.85,.85,.85), Outline = true, Size = 13, Font = 2}), 1};
                end
                updateInvDrawings();
            end
            for _,inst in next, cachedPlayers[plr.Name]:GetChildren() do
                a(inst)
            end
            invc1 = Connection(cachedPlayers[plr.Name].ChildAdded, a)
            invc2 = Connection(cachedPlayers[plr.Name].ChildRemoved, function(inst)
                local data = invDrawings[inst.Name]
                if data then
                    data[2] -= 1
                    if data[2] == 0 then
                        data[1]:Remove();
                        invDrawings[inst.Name] = nil;
                    end
                end
                updateInvDrawings();
            end)
            selectedPlayerDrawing.Text = plr.Name.."'s Inventory ["..#cachedPlayers[plr.Name]:GetChildren().." Items]:";
        end
    end
end

local staffDetectionDrawings = {}
local staffDetectionDrawing = newDrawing('Text', {Text = 'Staff In Server [0]: ', Outline = true, Color = Color3.new(1,1,1), Size = 13, Font = 2})
local function updateStaffDetectionDrawings()
    staffDetectionDrawing.Visible = library.flags.staffdetection;
    staffDetectionDrawing.Text = 'Staff In Server ['..#staffDetectionDrawings..']:'
    staffDetectionDrawing.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X - staffDetectionDrawing.TextBounds.X - 10, 350);
    local pos = 350
    for i,v in next, staffDetectionDrawings do
        v.Visible = library.flags.staffdetection;
        v.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X - v.TextBounds.X - 10, pos + 18);
        pos = v.Position.Y;
    end
end

local function staffDetectionCheck(plr)
    local s,e = pcall(function()
        local role = plr:GetRoleInGroup(3765739);
        if table.find({'Tester', 'Temp Dev Team', 'Dev Team', 'Moderator', 'Head Moderator', 'Admin', 'Developer', 'Lead Developer'}, role) and not staffDetectionDrawings[plr] then
            staffDetectionDrawings[plr] = newDrawing('Text', {Text = plr.Name..' ['..role..']', Visible = true, Outline = true, Color = Color3.new(.85, .85, .85), Size = 13, Font = 2})
            updateStaffDetectionDrawings()
        end
    end)
    if not s then
        return false, e
    end
end

local function updateViewmodel()
    task.wait()
    local viewmodel = workspace.CurrentCamera:FindFirstChild('ViewModel');
    if init and viewmodel and library.flags.viewmodelchanger then
        for i,v in next, viewmodel:GetDescendants() do
            if v:IsA('Part') or v:IsA('BasePart') or v:IsA('MeshPart') then
                if v.Parent.Name == 'Item' then
                    v.Color = library.flags.viewmodel_itemcolor;
                    v.Transparency = library.options.viewmodel_itemcolor.trans;
                    v.Material = Enum.Material[library.flags.viewmodel_itemmaterial];
                else
                    v.Color = library.flags.viewmodel_armcolor;
                    v.Transparency = library.options.viewmodel_armcolor.trans;
                    v.Material = Enum.Material[library.flags.viewmodel_armmaterial];
                end
            elseif v:IsA('SurfaceAppearance') then
                v:Destroy();
            end
        end
    end
end

-- // Options

-- Tabs
local LegitTab = library:AddTab('Legit');
local RageTab = library:AddTab('Rage');
local VisualsTab = library:AddTab('Visuals');
local MiscTab = library:AddTab('Misc');
local SettingsTab = library.InitSettingsTab();

local legitColumn1 = LegitTab:AddColumn();
local legitColumn2 = LegitTab:AddColumn();
local rageColumn1 = RageTab:AddColumn();
local rageColumn2 = RageTab:AddColumn();
local visualsColumn1 = VisualsTab:AddColumn();
local visualsColumn2 = VisualsTab:AddColumn();
local miscColumn1 = MiscTab:AddColumn();
local miscColumn2 = MiscTab:AddColumn();

--[Legit]--

-- Aimbot
local aimbotTargetting, aimbotTargettingDist, aimbotClosest = false, 0, nil;
local aimbotFOVCircle = newDrawing('Circle', {Thickness = .5});
local aimbotDeadzoneFOVCircle = newDrawing('Circle', {Thickness = .5});

local function updateAimbotFOVCircle()
    if init then
        aimbotFOVCircle.Visible = library.flags.aimbot_showfov and library.flags.aimbot_enabled;
        aimbotFOVCircle.Color = library.flags.aimbot_fov_color;
        aimbotFOVCircle.Transparency = library.options.aimbot_fov_color.trans
        aimbotFOVCircle.Radius = library.flags.aimbot_fov;
        aimbotFOVCircle.Position = library.flags.aimbot_fov_position == 'Center' and workspace.CurrentCamera.ViewportSize/2 or inputservice:GetMouseLocation();

        aimbotDeadzoneFOVCircle.Visible = library.flags.aimbot_showdeadzone and library.flags.aimbot_enabled;
        aimbotDeadzoneFOVCircle.Color = library.flags.aimbot_deadzone_color;
        aimbotDeadzoneFOVCircle.Transparency = library.options.aimbot_deadzone_color.trans
        aimbotDeadzoneFOVCircle.Radius = library.flags.aimbot_deadzone;
        aimbotDeadzoneFOVCircle.Position = aimbotFOVCircle.Position
    end
end

local aimbotSection = legitColumn1:AddSection('Aimbot');
aimbotSection:AddToggle({text = 'Aimbot Enabled', flag = 'aimbot_enabled'}):AddBind({mode = 'hold', flag = 'aimbot_held'});
aimbotSection:AddToggle({text = 'Team Check', flag = 'aimbot_teamcheck'});
aimbotSection:AddToggle({text = 'Show Target Inventory', flag = 'aimbot_viewinventory'});
aimbotSection:AddToggle({text = 'Show FOV', flag = 'aimbot_showfov', callback = updateAimbotFOVCircle}):AddColor({flag = 'aimbot_fov_color', trans = 1, callback = updateAimbotFOVCircle, calltrans = updateAimbotFOVCircle});
aimbotSection:AddToggle({text = 'Show Deadzone', flag = 'aimbot_showdeadzone', callback = updateAimbotFOVCircle}):AddColor({flag = 'aimbot_deadzone_color', trans = 1, callback = updateAimbotFOVCircle, calltrans = updateAimbotFOVCircle});
aimbotSection:AddToggle({text = 'Visualize Target', flag = 'aimbot_showtarget'}):AddColor({flag = 'aimbot_target_color', trans = 1}):AddColor({flag = 'aimbot_inAimbotFOV_color', trans = 1});
aimbotSection:AddToggle({text = 'Limit Distance', flag = 'aimbot_limitdistance'}):AddSlider({min = 0, max = 1500, flag = 'aimbot_maxdistance'});
aimbotSection:AddSlider({text = 'Smoothness', flag = 'aimbot_smoothness', min = 1, max = 30, float = .5});
aimbotSection:AddSlider({text = 'FOV', flag = 'aimbot_fov', min = 0, max = 500, callback = updateAimbotFOVCircle});
aimbotSection:AddSlider({text = 'Deadzone', flag = 'aimbot_deadzone', min = 0, max = 50, callback = updateAimbotFOVCircle})
aimbotSection:AddList({text = 'FOV Position', flag = 'aimbot_fov_position', values = {'Mouse', 'Center'}, callback = updateAimbotFOVCircle});
aimbotSection:AddList({text = 'Aim Part', flag = 'aimbot_aimpart', values = {'Head', 'Torso'}});

Connection(mouse.Move, function()
    if library.flags.aimbot_fov_position == 'Mouse' then
        aimbotFOVCircle.Position = inputservice:GetMouseLocation();
    end
end)

local inAimbotFOV = {};
task.spawn(function() -- this is disgusting
    Connection(runservice.RenderStepped, function()
        local aimpart = library.flags.aimbot_aimpart == 'Torso' and 'HumanoidRootPart' or library.flags.aimbot_aimpart;
        for plr,obj in next, inAimbotFOV do
            local char = hasCharacter(plr);
            local pos, vis

            if char then
                pos, vis = workspace.CurrentCamera:WorldToViewportPoint(char[aimpart].CFrame.p);
                pos = Vector2.new(pos.X, pos.Y)
            end

            if vis and (pos - aimbotFOVCircle.Position).magnitude <= aimbotFOVCircle.Radius and (pos - aimbotFOVCircle.Position).magnitude >= aimbotDeadzoneFOVCircle.Radius and library.flags.aimbot_enabled and library.flags.aimbot_showtarget then
                local mousepos = inputservice:GetMouseLocation();
                obj.From = mousepos
                obj.To = pos
                obj.Color = plr == aimbotClosest and library.flags.aimbot_target_color or library.flags.aimbot_inAimbotFOV_color
            else
                obj:Remove()
                inAimbotFOV[plr] = nil
            end
        end
    end)

    while runservice.Heartbeat:Wait() do
        if library.flags.aimbot_enabled then
            local aimpart = library.flags.aimbot_aimpart == 'Torso' and 'HumanoidRootPart' or library.flags.aimbot_aimpart;
            local closest, dist = nil, aimbotFOVCircle.Radius
            for i,plr in next, players:GetPlayers() do
                local char = hasCharacter(plr)
                if plr ~= localplayer and (library.flags.aimbot_teamcheck and (plr.Team ~= localplayer.Team) or true) and char then
                    local pos, vis = workspace.CurrentCamera:WorldToViewportPoint(char[aimpart].CFrame.p);
                    local mag = (Vector2.new(pos.X, pos.Y) - aimbotFOVCircle.Position).magnitude;
                    if vis then
                        if mag <= aimbotFOVCircle.Radius and not inAimbotFOV[plr] and (char[aimpart].CFrame.p - workspace.CurrentCamera.CFrame.p).magnitude <= library.flags.esp_maxdistance then
                            inAimbotFOV[plr] = newDrawing('Line',{Visible = true, Thickness = .1})
                        end
                        if mag <= dist then
                            closest = plr;
                            dist = mag;
                            aimbotClosest = plr;
                        end
                    elseif inAimbotFOV[plr] then
                        inAimbotFOV[plr]:Remove();
                        inAimbotFOV[plr] = nil;
                    end
                end
            end

            if closest and not aimbotTargetting then
                aimbotTargetting = closest
                if library.flags.aimbot_viewinventory then
                    viewInventory(closest)
                elseif selectedInventoryTarget then
                    selectedInventoryTarget = nil;
                end
            end

            if aimbotTargetting then
                local char = hasCharacter(aimbotTargetting)
                local screenPos
                if char then
                    screenPos = workspace.CurrentCamera:WorldToViewportPoint(char[aimpart].CFrame.p);
                    screenPos = Vector2.new(screenPos.X, screenPos.Y)
                end

                local mag = (screenPos - aimbotFOVCircle.Position).magnitude
                if library.flags.aimbot_held and modelOnScreen(char) and mag <= aimbotFOVCircle.Radius and mag >= aimbotDeadzoneFOVCircle.Radius then
                    local mousePos = inputservice:GetMouseLocation();
                    local pos = (screenPos - mousePos) / library.flags.aimbot_smoothness
                    for i = 1, library.flags.aimbot_smoothness do
                        mousemoverel(pos.X, pos.Y);
                        runservice.RenderStepped:Wait()
                    end
                else
                    aimbotTargetting, aimbotTargettingDist = false, 0;
                end
            end
        elseif aimbotTargetting then
            aimbotTargetting, aimbotTargettingDist = false, 0;
        end
    end

end)

--[Rage]--

-- Gun Mods
local gunmodsSection = rageColumn2:AddSection('Gun Mods');
gunmodsSection:AddToggle({text = 'No Recoil', flag = 'norecoil_enabled'});

--[Visuals]--

-- ESP

local espSection = visualsColumn1:AddSection('ESP');
espSection:AddToggle({text = 'Enabled', flag = 'esp_enabled'});
espSection:AddToggle({text = 'Outline', flag = 'esp_outline'});
espSection:AddToggle({text = 'Use Display Name', flag = 'esp_displayname'});
espSection:AddToggle({text = 'Health Text', flag = 'esp_healthtext'});
espSection:AddToggle({text = 'Chams', flag = 'esp_chams'}):AddColor({flag = 'esp_chamscolor1', trans = 0}):AddColor({flag = 'esp_chamscolor2', trans = 0});
espSection:AddToggle({text = 'Box', flag = 'esp_box'}):AddColor({flag = 'esp_boxcolor', trans = 0});
espSection:AddToggle({text = 'Name', flag = 'esp_name'}):AddColor({flag = 'esp_namecolor', trans = 0});
espSection:AddToggle({text = 'Distance', flag = 'esp_distance'}):AddColor({flag = 'esp_distancecolor', trans = 0});
espSection:AddToggle({text = 'Weapon', flag = 'esp_weapon'}):AddColor({flag = 'esp_weaponcolor', trans = 0});
espSection:AddToggle({text = 'Tracer', flag = 'esp_tracer'}):AddColor({flag = 'esp_tracercolor', trans = 0});
espSection:AddToggle({text = 'View Angle', flag = 'esp_viewangle'}):AddColor({flag = 'esp_viewanglecolor', trans = 0});
espSection:AddToggle({text = 'Health', flag = 'esp_health'}):AddColor({flag = 'esp_healthcolor1', trans = 0}):AddColor({flag = 'esp_healthcolor2', trans = 0});
espSection:AddToggle({text = 'Off Screen Arrows', flag = 'esp_arrows'}):AddColor({flag = 'esp_arrowscolor', trans = 0});
espSection:AddToggle({text = 'Skeleton', flag = 'esp_skeleton'}):AddColor({flag = 'esp_skeletoncolor', trans = 0});
espSection:AddList({text = 'Team Check', flag = 'esp_teamcheck', values = {'Show', 'Colors', 'Hide'}});
espSection:AddSlider({text = 'Skeleton Thickness', flag = 'esp_skeletonthickness', min = 1, max = 5, float = .1})
espSection:AddSlider({text = 'Arrow Radius', flag = 'esp_arrowradius', min = 100, max = 1000})
espSection:AddToggle({text = 'Limit Distance', flag = 'esp_distancelimit'}):AddSlider({flag = 'esp_maxdistance', min = 0, max = 8000});
espSection:AddSlider({text = 'Text Font', flag = 'esp_font', min = 0, max = 3});
espSection:AddSlider({text = 'Text Size', flag = 'esp_size', min = 5, max = 35});



-- Local Player
local selfSection = visualsColumn2:AddSection('Local Player');

selfSection:AddDivider('Self Chams');
local selfChamsToggle = selfSection:AddToggle({text = 'Chams', flag = 'selfchams_enabled'});
local fakelagChamsToggle = selfSection:AddToggle({text = 'Fake Lag Chams', flag = 'fakelagchams_enabled'});
selfChamsToggle:AddColor({flag = 'selfchams_color', trans = 0});
selfChamsToggle:AddList({text = 'Material', flag = 'selfchams_material', values = chamsMaterials}):SetValue('ForceField')
fakelagChamsToggle:AddColor({flag = 'fakelagchams_color', trans = 0});
fakelagChamsToggle:AddList({text = 'Material', flag = 'fakelag_material', values = chamsMaterials}):SetValue('ForceField')

selfSection:AddButton({text = 'Remove Clothing', callback = function()
    if localplayer.Character ~= nil then
        for i,v in next, localplayer.Character:GetChildren() do
            if v:IsA('Clothing') then
                v:Destroy()
            end
        end
    end
end})


-- China Hat
local chinahatDrawings = {};
for i = 1,30 do
    chinahatDrawings[i] = {newDrawing('Line'),newDrawing('Triangle')}
    chinahatDrawings[i][1].ZIndex = 2;
    chinahatDrawings[i][1].Thickness = 2;
    chinahatDrawings[i][2].ZIndex = 1;
    chinahatDrawings[i][2].Filled = true;
end

selfSection:AddDivider('China Hat');
selfSection:AddToggle({text = 'Enabled', flag = 'chinahat_enabled', callback = function(bool)
    for i = 1,30 do
        chinahatDrawings[i][1].Visible = bool;
        chinahatDrawings[i][2].Visible = bool;
    end
end}):AddColor({flag = 'chinahat_color'});
selfSection:AddToggle({text = 'Rainbow', flag = 'chinahat_rainbow'});
selfSection:AddSlider({text = 'Hat Transparency', flag = 'chinahat_hattransparency', min = 0, max = 1, float = .05});
selfSection:AddSlider({text = 'Circle Transparency', flag = 'chinahat_circletransparency', min = 0, max = 1, float = .05});
selfSection:AddSlider({text = 'Radius', flag = 'chinahat_radius', min = 0, max = 3, float = .05});
selfSection:AddSlider({text = 'Height', flag = 'chinahat_height', min = 0, max = 3, float = .05});
selfSection:AddSlider({text = 'Offset', flag = 'chinahat_offset', min = 0, max = 5, float = .05});


-- Other
local visualOtherSection = visualsColumn1:AddSection('Other');
visualOtherSection:AddToggle({text = 'Exit ESP', flag = 'exitesp_enabled'}):AddColor({flag = 'exitesp_color'});
visualOtherSection:AddToggle({text = 'Health Bar', flag = 'healthbar_enabled'});

local toggle = visualOtherSection:AddToggle({text = 'Corpse ESP', flag = 'corpseesp_enabled'})
toggle:AddColor({flag = 'corpseesp_color'})
toggle:AddSlider({flag = 'corpseesp_maxdistance', min = 0, max = 3500});

visualOtherSection:AddToggle({text = 'Viewmodel Changer', flag = 'viewmodelchanger', callback = updateViewmodel})
visualOtherSection:AddList({text = 'Arm', flag = 'viewmodel_armmaterial', values = chamsMaterials, callback = updateViewmodel}):AddColor({flag = 'viewmodel_armcolor', trans = 1, callback = updateViewmodel});
visualOtherSection:AddList({text = 'Item', flag = 'viewmodel_itemmaterial', values = chamsMaterials, callback = updateViewmodel}):AddColor({flag = 'viewmodel_itemcolor', trans = 1, callback = updateViewmodel});

Connection(workspace.CurrentCamera.ChildAdded, function()
    updateViewmodel();
end)

-- World
local colorCorrectionEffect = Instance.new('ColorCorrectionEffect', lighting)
colorCorrectionEffect.TintColor = lighting:FindFirstChildWhichIsA('ColorCorrectionEffect') == nil and colorCorrectionEffect.TintColor or lighting:FindFirstChildWhichIsA('ColorCorrectionEffect').TintColor;

local function updateLighting()
    if init then
        colorCorrectionEffect.TintColor = library.flags.correction_color;
        colorCorrectionEffect.Contrast = library.flags.world_contrast;
        colorCorrectionEffect.Saturation = library.flags.world_saturation;
    
        lighting.Ambient = library.flags.ambientcolor;
        lighting.OutdoorAmbient = library.flags.outdoorambient;
        lighting.ColorShift_Top = library.flags.colorshift_top;
        lighting.ColorShift_Bottom = library.flags.colorshift_bottom;
    end
end

local worldSection = visualsColumn2:AddSection('World');
worldSection:AddToggle({text = 'Remove Foliage', flag = 'removefoliage', callback = function(bool)
    for _,v in next, workspace.SpawnerZones.Trees:GetDescendants() do
        if v.Name == 'Leaf' then
            v.Transparency = bool and 1 or 0
        end
    end
end})
worldSection:AddToggle({text = 'Remove Grass', flag = 'removegrass', callback = function(bool)
    sethiddenproperty(workspace.Terrain, 'Decoration', not bool)
end})
worldSection:AddColor({text = 'Color Correction', flag = 'correction_color', callback = updateLighting}):SetColor(colorCorrectionEffect.TintColor);
worldSection:AddColor({text = 'Ambient', flag = 'ambientcolor', callback = updateLighting}):SetColor(lighting.Ambient);
worldSection:AddColor({text = 'Outdoor Ambient', flag = 'outdoorambient', callback = updateLighting}):SetColor(lighting.OutdoorAmbient);
worldSection:AddColor({text = 'Color Shift Top', flag = 'colorshift_top', callback = updateLighting}):SetColor(lighting.ColorShift_Top);
worldSection:AddColor({text = 'Color Shift Bottom', flag = 'colorshift_bottom', callback = updateLighting}):SetColor(lighting.ColorShift_Bottom);
worldSection:AddSlider({text = 'Contrast', flag = 'world_contrast', min = 0, max = 1, float = .05, callback = updateLighting}):SetValue(colorCorrectionEffect.Contrast);
worldSection:AddSlider({text = 'Saturation', flag = 'world_saturation', min = -1, max = 1, float = .05, callback = updateLighting}):SetValue(colorCorrectionEffect.Saturation);

-- Camera
local lastfov = workspace.CurrentCamera.FieldOfView;
local cameraSection = visualsColumn2:AddSection('Camera');
local thirdpersonToggle = cameraSection:AddToggle({text = 'Third Person', flag = 'thirdperson_toggled'})
thirdpersonToggle:AddBind({flag = 'thirdperson_enabled'})
cameraSection:AddToggle({text = 'Hide Viewmodel', flag = 'thirdperson_hideviewmodel'})
cameraSection:AddSlider({text = 'Distance', flag = 'thirdperson_distance', min = 0, max = 30});
cameraSection:AddToggle({text = 'FOV', flag = 'camera_fov_enabled', function(bool)
    if bool then
        lastfov = workspace.CurrentCamera.FieldOfView;
        workspace.CurrentCamera.FieldOfView = library.flags.camera_fov;
    else
        workspace.CurrentCamera.FieldOfView = lastfov;
    end
end}):AddSlider({flag = 'camera_fov', min = 0, max = 120, callback = function(val)
    workspace.CurrentCamera.FieldOfView = val;
end}):SetValue(workspace.CurrentCamera.FieldOfView);

--[Misc]--


-- Main Misc
local mainMiscSection = miscColumn1:AddSection('Main');
mainMiscSection:AddToggle({text = 'Staff Detection', flag = 'staffdetection', callback = updateStaffDetectionDrawings});

-- Fake Lag
local fakelagSection = miscColumn1:AddSection('Fake Lag');
fakelagSection:AddToggle({text = 'Enabled', flag = 'fakelag_enabled'});
fakelagSection:AddToggle({text = 'Randomize', flag = 'fakelag_randomize'});
fakelagSection:AddSlider({text = 'Delay', flag = 'fakelag_delay', suffix = 'ms', min = 100, max = 3000})

-- Crosshair
local c = {newDrawing('Line', {Color = Color3.new(1,1,1), ZIndex = 999}), newDrawing('Line', {Color = Color3.new(1,1,1), ZIndex = 999}), newDrawing('Line', {Color = Color3.new(1,1,1), ZIndex = 999}), newDrawing('Line', {Color = Color3.new(1,1,1), ZIndex = 999});}
local function updateCrosshair()
    local x,y = workspace.CurrentCamera.ViewportSize.X,workspace.CurrentCamera.ViewportSize.Y
    local gap = library.flags.crosshair_gap
    local len = library.flags.crosshair_length
    c[1].From = Vector2.new((x/2)-gap,y/2)
    c[1].To = Vector2.new((x/2)-gap-len,(y/2))

    c[2].From = Vector2.new((x/2)+gap,y/2)
    c[2].To = Vector2.new((x/2)+gap+len,(y/2))

    c[3].From = Vector2.new(x/2,(y/2)-gap)
    c[3].To = Vector2.new(x/2,(y/2)-gap-len)

    c[4].From = Vector2.new(x/2,(y/2)+gap)
    c[4].To = Vector2.new(x/2,(y/2)+gap+len)

    for i,v in next, c do
        v.Thickness = library.flags.crosshair_width
        v.Visible = library.flags.crosshair_enabled
        v.Color = library.flags.crosshair_color
        v.ZIndex = library.flags.crosshair_overesp and 999 or -999
    end
end

local crosshairSection = miscColumn2:AddSection('Crosshair')
crosshairSection:AddToggle({text = 'Crosshair Enabled', flag = 'crosshair_enabled', callback = updateCrosshair}):AddColor({text = 'crosshair_color', trans = 1, callback = updateCrosshair})
crosshairSection:AddToggle({text = 'Over ESP', flag = 'crosshair_overesp'})
crosshairSection:AddSlider({text = 'Gap', flag = 'crosshair_gap', min = 0, max = 50, float = .1, callback = updateCrosshair});
crosshairSection:AddSlider({text = 'Width', flag = 'crosshair_width', min = 0, max = 5, float = .5, callback = updateCrosshair});
crosshairSection:AddSlider({text = 'Length', flag = 'crosshair_length', min = 0, max = 50, float = .5, callback = updateCrosshair});




-- Finish
library:selectTab(LegitTab)
init = true


-- // Script


-- Player Cache
local function cachePlayer(plr)
    if not cachedPlayers[plr] then
        plr:WaitForChild('Inventory');
        cachedPlayers[plr.Name] = plr.Inventory;
    end
end

Connection(repstorage.Players.ChildAdded, cachePlayer)
Connection(repstorage.Players.ChildRemoved, function(plr)
    if cachedPlayers[plr.Name] then
        cachedPlayers[plr.Name] = nil;
        if selectedInventoryTarget == plr then
            for i,v in next, invDrawings do
                v[1]:Remove();
                invDrawings[i] = nil;
            end
        end
    end
end)

for i,v in next, repstorage.Players:GetChildren() do
    cachePlayer(v);
end


-- Players

Connection(players.PlayerAdded, function(plr)
    staffDetectionCheck(plr)
end)
Connection(players.PlayerRemoving, function(plr)
    if staffDetectionDrawings[plr] then
        staffDetectionDrawings[plr]:Remove();
        staffDetectionDrawings[plr] = nil;
        updateStaffDetectionDrawings()
    end
end)


for i,plr in next, players:GetPlayers() do
    staffDetectionCheck(plr)
end


-- hooks
local oldindex;
local oldnewindex;
local oldcallback;

oldindex = hookmetamethod(game, '__index', function(inst, prop, value)
    
    return oldindex(inst, prop, value);
end)

oldnewindex = hookmetamethod(game, '__newindex', function(inst, prop, value)
    if init then

        if inst == workspace.CurrentCamera and prop == 'CFrame' and library.flags.thirdperson_toggled and library.flags.thirdperson_enabled then
            value = value + (value.lookVector * -library.flags.thirdperson_distance);
        end

        if inst == workspace.CurrentCamera and prop == 'FieldOfView' and library.flags.camera_fov_enabled then
            print(value)
            value = library.flags.camera_fov;
        end

        if not checkcaller() and inst.Name == 'Leaf' and prop == 'Transparency' and library.flags.removefoliage then
            value = 1
        end
        
    end

    return oldnewindex(inst, prop, value);
end)


do
    function a(...)
        if library.flags.norecoil_enabled then
            return 0
        end
        return unpack({...})
    end
    
    local old
    old = hookfunction(VFXModule.RecoilCamera, function(...)
        return old(a(...));
    end)
end





-- Fake Lag
task.spawn(function()
    local parts = Instance.new('Folder', workspace);
    local lastTick = 0;
    while task.wait() do
        if library.flags.fakelag_enabled and localplayer.Character ~= nil and localplayer.Character:FindFirstChild('Humanoid') and localplayer.Character.Humanoid.Health > 0 then
            if (tick() - lastTick) * 1000 > library.flags.fakelag_delay then
                lastTick = tick();
                network:SetOutgoingKBPSLimit(9e9);
                parts:ClearAllChildren();
                if library.flags.fakelagchams_enabled then
                    for i,v in next, localplayer.Character:GetChildren() do
                        if (v:IsA('BasePart') or v:IsA('Part')) and v.Name ~= 'HumanoidRootPart' then
                            local p = Instance.new('Part');
                            p.CFrame = v.CFrame;
                            p.Size = v.Size;
                            p.Color = library.flags.fakelagchams_color;
                            p.Transparency = library.options.fakelagchams_color.transparency;
                            p.Material = Enum.Material[library.flags.fakelag_material];
                            p.Anchored = true;
                            p.CanCollide = false;
                            p.Parent = parts;
                        end
                    end
                end
            else
                network:SetOutgoingKBPSLimit(1);
            end
        else
            network:SetOutgoingKBPSLimit(9e9);
            parts:ClearAllChildren();
        end
    end
end)


-- Player ESP
local espTextScale = newDrawing('Text', {Visible = false, Text = 'M'});

local function newESP(plr)
    if plr ~= localplayer then
        espDrawings[plr] = {
            box = newDrawing('Square', {Thickness = 1});
            boxoutline = newDrawing('Square', {Thickness = 2.75});
            healthtext = newDrawing('Text', {Size = 13, Font = 2});
            arrow = newDrawing('Triangle');
            health = newDrawing('Square', {Thickness = 1, Filled = true});
            healthoutline = newDrawing('Square', {Thickness = 1, Filled = true});
            healthbackground = newDrawing('Square', {Thickness = 1, Filled = true});
            viewangle = newDrawing('Line');
            tracer = newDrawing('Line', {Thickness = 1});
            skeleton = {};

            textItems = {
                ['name'] = {plr.Name, 'top'};
                ['weapon'] = {'None', 'bottom'};
                ['distance'] = {'0 studs', 'bottom'};
            };

        };
        for i = 1, 14 do
            espDrawings[plr].skeleton[i] = newDrawing('Line');
        end
        for i,v in next, espDrawings[plr].textItems do
            v[3] = newDrawing('Text', {Size = library.flags.esp_size, Font = library.flags.esp_font});
        end
    end
end

for i,v in next, players:GetPlayers() do
    newESP(v)
end

players.PlayerAdded:Connect(newESP)
players.PlayerRemoving:Connect(function(plr)
    if espDrawings[plr] then
        for i,v in next, espDrawings[plr] do
            if i == 'skeleton' then
                table.foreach(v, function(_,obj)
                    obj:Remove();
                end)
            elseif i == 'textItems' then
                table.foreach(v,function(_,v2)
                    v2[3]:Remove();
                end)
            else
                v:Remove();
            end
        end
        espDrawings[plr] = nil;
    end
end)

local function ESPCheck(player)
    local pass, visible = true, false

    if not hasCharacter(player) then
        pass = false;
    else
        if library.flags.esp_distancelimit then
            local dist = (player.Character.HumanoidRootPart.Position - workspace.CurrentCamera.CFrame.p).magnitude;
            if dist > library.flags.esp_maxdistance then
                pass = false;
            end
        end
    end

    if library.flags.esp_teamcheck == 'Hide' and player.Team == localplayer.Team then
        pass = false;
    end

    return pass, visible
end

-- Exit ESP
local exitEspDrawings = {}
do
    local function a(b)
        if not exitEspDrawings[b] then
            exitEspDrawings[b] = newDrawing('Text', {Size = 13, Font = 2, Center = true});
        end
    end
    for i,v in next, workspace.NoCollision.ExitLocations:GetChildren() do
        a(v)
    end
    Connection(workspace.NoCollision.ExitLocations.ChildAdded, a)
end

-- Container ESP
local containerESPDrawings = {}
local attachments, weapons, throwables, clothing = repstorage.Attachments:GetChildren(), repstorage.RangedWeapons:GetChildren(), repstorage.Throwable:GetChildren(), repstorage.RealClothing:GetChildren();

local function a(b)
    local c = {};
    for i,v in next, b do
        table.insert(c,v.Name);
    end
    return c
end

attachments = a(attachments);
weapons = a(weapons);
throwables = a(throwables);
clothing = a(clothing);

do
    local toggle = visualOtherSection:AddToggle({text = 'Container ESP', flag = 'containeresp_enabled'});
    toggle:AddColor({flag = 'containeresp_color'});
    toggle:AddList({flag = 'containeresp_selected', multiselect = true, values = {'SmallShippingCrate', 'Toolbox', 'SmallMilitaryBox', 'MilitaryCrate', 'LargeMilitaryBox', 'FilingCabinet', 'MedBag', 'CashRegister', 'LargeShippingCrate', 'SportBag'}});
    

    local toggle = visualOtherSection:AddToggle({text = 'Show Contents', flag = 'containeresp_showcontents'});
    toggle:AddList({flags = 'containeresp_types', multiselect = true, values = itemClasses})

    visualOtherSection:AddSlider({text = 'Container Max Dist', flag = 'containeresp_maxdistance', min = 0, max = 3500});

    for i,v in next, workspace.Containers:GetChildren() do
        containerESPDrawings[v] = newDrawing('Text', {Size = 13, Font = 2, Outline = true})
    end

end

-- Item ESP
local itemESPDrawings = {};
local corpseDrawings = {};

do
    local toggle = visualOtherSection:AddToggle({text = 'Item ESP', flag = 'itemesp_enabled'})
    toggle:AddColor({flag = 'itemesp_color'});
    toggle:AddList({flag = 'itemesp_selected', multiselect = true, values = itemClasses})

    local function a(b)
        local class = (
            table.find(attachments,b.Name) and 'Attachments' or
            table.find(weapons,b.Name) and 'Weapons' or
            table.find(throwables,b.Name) and 'Throwables' or
            table.find(clothing,b.Name) and 'Clothing' or
            players:FindFirstChild(b.Name) and 'Corpse'
        )
        if class == 'Corpse' then
            corpseDrawings[b] = newDrawing('Text', {Size = 13, Font = 2, Outline = true, Center = true});
        elseif class then
            itemESPDrawings[b] = {newDrawing('Text', {Size = 13, Font = 2, Outline = true, Center = true}), class};
        end
    end

    Connection(droppedItems.ChildAdded, a);
    Connection(droppedItems.ChildRemoved, function(inst)
        if itemESPDrawings[inst] then
            itemESPDrawings[inst][1]:Remove();
            itemESPDrawings[inst] = nil;
        elseif corpseDrawings[inst] then
            corpseDrawings[inst]:Remove();
            corpseDrawings[inst] = nil;
        end
    end)

    for _,v in next, droppedItems:GetChildren() do
        a(v);
    end
end


-- Health Bar
local healthBackground = newDrawing('Square', {Filled = true, Size = Vector2.new(450,20), Color = Color3.new(.1,.1,.1)});
local healthBar = newDrawing('Square', {Filled = true, Color = Color3.new(0,1,0)});
local healthText = newDrawing('Text', {Size = 13, Font = 2, Center = true, Outline = true, Color = Color3.new(1,1,1)})


Connection(runservice.RenderStepped, function(delta)

    local camera = workspace.CurrentCamera;

    -- // China Hat
    if library.flags.chinahat_enabled then
        for i = 1, #chinahatDrawings do
            local line, triangle = chinahatDrawings[i][1], chinahatDrawings[i][2];
            if localplayer.Character ~= nil and localplayer.Character:FindFirstChild('Head') and (camera.CFrame.p - camera.Focus.p) and localplayer.Character.Humanoid.health > 0 then
                local color = library.flags.chinahat_rainbow and fromhsv((tick() % 5 / 5 - (i / #chinahatDrawings)) % 1,.5,1) or library.flags.chinahat_color;
                local pos = localplayer.Character.Head.Position + Vector3.new(0, library.flags.chinahat_offset, 0);
    
                local last, next = (i / 30) * tau, ((i + 1) / 30) * tau;
                local lastScreen = camera:WorldToViewportPoint(pos + (Vector3.new(math.cos(last), 0, math.sin(last)) * library.flags.chinahat_radius));
                local nextScreen = camera:WorldToViewportPoint(pos + (Vector3.new(math.cos(next), 0, math.sin(next)) * library.flags.chinahat_radius));
                local topScreen = camera:WorldToViewportPoint(pos + Vector3.new(0, library.flags.chinahat_height, 0));
    
                line.From = Vector2.new(lastScreen.X, lastScreen.Y);
                line.To = Vector2.new(nextScreen.X, nextScreen.Y);
                line.Color = color;
                line.Transparency = library.flags.chinahat_circletransparency;
    
                triangle.PointA = Vector2.new(topScreen.X, topScreen.Y);
                triangle.PointB = line.From;
                triangle.PointC = line.To;
                triangle.Color = color;
                triangle.Transparency = library.flags.chinahat_hattransparency;
            end
        end
    end

    -- Health Bar

    healthBackground.Position = Vector2.new(20, camera.ViewportSize.Y - 40);
    healthBackground.Visible = library.flags.healthbar_enabled;
    healthBar.Visible = library.flags.healthbar_enabled;
    healthText.Visible = library.flags.healthbar_enabled;
    if library.flags.healthbar_enabled then
        local char = hasCharacter(localplayer);
        if char then
            healthBar.Color = Color3.new(1,0,0):Lerp(Color3.new(0,1,0), ConvertNumberRange(char.Humanoid.Health, 0, char.Humanoid.MaxHealth, 0, 1))
            healthBar.Size = Vector2.new(ConvertNumberRange(char.Humanoid.Health, 0, char.Humanoid.MaxHealth, 0, healthBackground.Size.X - 2), healthBackground.Size.Y - 2);
            healthBar.Position = healthBackground.Position + Vector2.new(1,1);
            healthText.Position = healthBackground.Position + (healthBackground.Size/2) - Vector2.new(0,7);
            healthText.Text = char.Humanoid.Health..'/'..char.Humanoid.MaxHealth;
        end
    end



    -- // ESP
    espTextScale.Size = library.flags.esp_size;
    espTextScale.Font = library.flags.esp_font;
    for player, items in next, espDrawings do
        local pass = ESPCheck(player);
        local char, hrp, distance, v2, onScreen = nil, nil, 0, nil, false;

        if pass then
            char = player.Character;
            hrp = char:FindFirstChild('HumanoidRootPart');
            if hrp then
                distance = floor((hrp.CFrame.p - camera.CFrame.p).magnitude);
                v2, onScreen = camera:WorldToViewportPoint(hrp.CFrame.p);
            end
        end

        items.arrow.Visible = library.flags.esp_arrows and pass and not onScreen;
        if items.arrow.Visible then
            local projected = camera.CFrame:PointToObjectSpace(hrp.Position);
            local angle = math.atan2(projected.Z, projected.X);
            local direction = Vector2.new(math.cos(angle), math.sin(angle));
            local pos = (direction * library.flags.esp_arrowradius * .5) + camera.ViewportSize / 2;
            items.arrow.PointA = pos;
            items.arrow.PointB = pos - rotateVector2(direction, math.rad(30)) * 5;
            items.arrow.PointC = pos - rotateVector2(direction, -math.rad(30)) * 5;
            items.arrow.Color = library.flags.esp_arrowscolor;
        end

        pass = pass and onScreen and library.flags.esp_enabled
        
        for i,v in next, items do
            if i == 'skeleton' then
                table.foreach(v, function(_,obj)
                    obj.Visible = pass;
                end)
            elseif i == 'textItems' then
                table.foreach(v,function(_,v2)
                    v2[3].Visible = pass;
                end)
            elseif i ~= 'arrow' then
                v.Visible = pass;
            end
        end

        if pass then
            local size = (camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0)).Y - camera:WorldToViewportPoint(hrp.Position + Vector3.new(0,2.5,0)).Y) / 2;
            local size = Vector2.new(size * 1.45, size * 2.15);
            local pos = Vector2.new(v2.X,v2.Y) - (size/2);

            local bottom = Vector2.new(pos.X+(size.X/2),pos.Y+size.Y);
            local top = Vector2.new(pos.X+(size.X/2),pos.Y);
            local right = Vector2.new(pos.X+(size.X),pos.Y);

            local textPadding = 3;
            local z = 0;
            
            local topTextPos = top + Vector2.new(0,-(espTextScale.TextBounds.Y+textPadding));
            local bottomTextPos = bottom + Vector2.new(0,textPadding);
            local rightTextPos = right + Vector2.new(textPadding,-2);

            local targetColor = (library.flags.aimbot_showtarget and player == aimbotClosest and inAimbotFOV[player] ~= nil)
            
            -- box
            items.box.Visible = library.flags.esp_box;
            items.boxoutline.Visible = library.flags.esp_box and library.flags.esp_outline;
            if library.flags.esp_box then
                items.box.Size = size;
                items.box.Position = pos;
                items.box.Color = targetColor and library.flags.aimbot_target_color or library.flags.esp_boxcolor;
                items.box.ZIndex = z;
                if library.flags.esp_outline then
                    items.boxoutline.Size = size;
                    items.boxoutline.Position = pos;
                    items.boxoutline.ZIndex = z-1;
                end
            end

            -- tracer
            items.tracer.Visible = library.flags.esp_tracer
            if library.flags.esp_tracer then
                items.tracer.To = bottom
                items.tracer.From = Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y)
                items.tracer.Color = targetColor and library.flags.aimbot_target_color or library.flags.esp_tracercolor
                items.tracer.ZIndex = z-2
            end

            -- health
            items.healthbackground.Visible = library.flags.esp_health;
            items.health.Visible = library.flags.esp_health;
            items.healthoutline.Visible = library.flags.esp_health and library.flags.esp_outline;
            if library.flags.esp_health then
                items.healthbackground.Size = Vector2.new(2,size.Y);
                items.healthbackground.Position = pos + Vector2.new(-5,0);
                items.healthbackground.ZIndex = z;
                items.health.Size = Vector2.new(2,ConvertNumberRange(char.Humanoid.Health,0,char.Humanoid.MaxHealth,0,items.healthbackground.Size.Y));
                items.health.Position = items.healthbackground.Position + Vector2.new(0,items.healthbackground.Size.Y - items.health.Size.Y);
                items.health.Color = library.flags.esp_healthcolor1:Lerp(library.flags.esp_healthcolor2, ConvertNumberRange(char.Humanoid.Health,0,char.Humanoid.MaxHealth,0,1));
                items.health.ZIndex = z+1;
                if library.flags.esp_outline then
                    items.healthoutline.Size = items.healthbackground.Size + Vector2.new(2,2);
                    items.healthoutline.Position = items.healthbackground.Position + Vector2.new(-1,-1);
                    items.healthoutline.ZIndex = z-1;
                end
            end

            -- health text
            items.healthtext.Visible = library.flags.esp_healthtext
            if library.flags.esp_healthtext then
                items.healthtext.Position = pos + Vector2.new(-(items.healthtext.TextBounds.X + (library.flags.esp_health and 8 or 2)), items.health.Visible and (items.health.Position.Y - pos.Y) - 2 or -2)
                items.healthtext.Text = tostring(floor(char.Humanoid.Health));
                items.healthtext.Color = library.flags.esp_healthcolor1:Lerp(library.flags.esp_healthcolor2, ConvertNumberRange(char.Humanoid.Health,0,char.Humanoid.MaxHealth,0,1));
                items.healthtext.Outline = library.flags.esp_outline;
                items.healthtext.Font = library.flags.esp_font;
                items.healthtext.Size = library.flags.esp_size;
            end

            -- view angle
            items.viewangle.Visible = library.flags.esp_viewangle;
            if library.flags.esp_viewangle then
                local from = camera:WorldToViewportPoint(char.Head.CFrame.p);
                local to = camera:WorldToViewportPoint((char.Head.CFrame + (char.Head.CFrame.lookVector * 20)).p);
                items.viewangle.From = Vector2.new(from.X, from.Y);
                items.viewangle.To = Vector2.new(to.X, to.Y);
                items.viewangle.Color = targetColor and library.flags.aimbot_target_color or library.flags.esp_viewanglecolor;
            end

            -- text
            if repstorage.Players[player.Name] and repstorage.Players[player.Name]:FindFirstChild('GameplayVariables') then
                local tool = repstorage.Players[player.Name].GameplayVariables.EquippedTool.Value
                items.textItems.tool[1] = tool == nil and 'None' or tool
            end
            items.textItems.distance[1] = distance..' studs';
            items.textItems.name[1] = library.flags.esp_displayname and player.DisplayName or player.Name
            for flag,data in next, items.textItems do
                local enabled, color = library.flags['esp_'..flag], library.flags['esp_'..flag..'color'];
                if enabled ~= nil and color ~= nil then
                    
                    data[3].Visible = enabled;
                    if enabled then
                        data[3].Text = data[1];
                        data[3].Size = library.flags.esp_size;
                        data[3].Font = library.flags.esp_font;
                        data[3].Color = targetColor and library.flags.aimbot_target_color or color;
                        data[3].Outline = library.flags.esp_outline;
                        data[3].Center = (data[2] == 'top' or data[2] == 'bottom') and true or false;

                        data[3].Position = (
                            data[2] == 'top' and topTextPos or
                            data[2] == 'bottom' and bottomTextPos or
                            data[2] == 'right' and rightTextPos
                        )

                        if data[2] == 'top' then topTextPos += Vector2.new(0,-(data[3].TextBounds.Y + textPadding)); end
                        if data[2] == 'bottom' then bottomTextPos += Vector2.new(0,(data[3].TextBounds.Y + textPadding)); end
                        if data[2] == 'right' then rightTextPos += Vector2.new(0,(data[3].TextBounds.Y + textPadding)) end

                    end
                end
            end

             -- skeleton [rewrite this shit later]
             table.foreach(items.skeleton, function(_,v)
                v.Visible = library.flags.esp_skeleton and char.Humanoid.RigType == Enum.HumanoidRigType.R15;
            end)
            if library.flags.esp_skeleton and char.Humanoid.RigType == Enum.HumanoidRigType.R15 then

               local objs = items.skeleton;
               local head = camera:WorldToViewportPoint(char.Head.CFrame.p)

               if char.Humanoid.RigType == Enum.HumanoidRigType.R6 then
                       
               elseif char.Humanoid.RigType == Enum.HumanoidRigType.R15 and char:FindFirstChild('UpperTorso') and char:FindFirstChild('LeftUpperArm') and char:FindFirstChild('RightUpperArm') and char:FindFirstChild('LeftUpperLeg') and char:FindFirstChild('RightUpperLeg') then
                   
                   local upperTorsoT = camera:WorldToViewportPoint((char.UpperTorso.CFrame * CFrame.new(0, char.UpperTorso.Size.Y / 2, 0)).p);
                   local upperTorsoB = camera:WorldToViewportPoint((char.UpperTorso.CFrame * CFrame.new(0, -char.UpperTorso.Size.Y / 2, 0)).p);

                   local lUpperArmT = camera:WorldToViewportPoint(char.LeftUpperArm.CFrame.p);
                   local lUpperArmB = camera:WorldToViewportPoint((char.LeftUpperArm.CFrame * CFrame.new(0, -char.LeftUpperArm.Size.Y / 2, 0)).p);
                   local lLowerArm = camera:WorldToViewportPoint((char.LeftLowerArm.CFrame * CFrame.new(0, -char.LeftLowerArm.Size.Y / 2, 0)).p);

                   local rUpperArmT = camera:WorldToViewportPoint(char.RightUpperArm.CFrame.p);
                   local rUpperArmB = camera:WorldToViewportPoint((char.RightUpperArm.CFrame * CFrame.new(0, -char.RightUpperArm.Size.Y / 2, 0)).p);
                   local rLowerArm = camera:WorldToViewportPoint((char.RightLowerArm.CFrame * CFrame.new(0, -char.RightLowerArm.Size.Y / 2, 0)).p);

                   local lUpperLegT = camera:WorldToViewportPoint((char.LeftUpperLeg.CFrame * CFrame.new(0, char.LeftUpperLeg.Size.Y / 2, 0)).p);
                   local lUpperLegB = camera:WorldToViewportPoint((char.LeftUpperLeg.CFrame * CFrame.new(0, -char.LeftUpperLeg.Size.Y / 2, 0)).p);
                   local lLowerLeg = camera:WorldToViewportPoint((char.LeftLowerLeg.CFrame * CFrame.new(0, -char.LeftLowerLeg.Size.Y / 2, 0)).p);

                   local rUpperLegT = camera:WorldToViewportPoint((char.RightUpperLeg.CFrame * CFrame.new(0, char.RightUpperLeg.Size.Y / 2, 0)).p);
                   local rUpperLegB = camera:WorldToViewportPoint((char.RightUpperLeg.CFrame * CFrame.new(0, -char.RightUpperLeg.Size.Y / 2, 0)).p);
                   local rLowerLeg = camera:WorldToViewportPoint((char.RightLowerLeg.CFrame * CFrame.new(0, -char.RightLowerLeg.Size.Y / 2, 0)).p);

                   -- Upper Torso
                   objs[1].From = Vector2.new(upperTorsoT.X, upperTorsoT.Y);
                   objs[1].To = Vector2.new(upperTorsoB.X, upperTorsoB.Y);
                   objs[1].Color = library.flags.esp_skeletoncolor;
                   objs[1].Thickness = library.flags.esp_skeletonthickness;

                   -- Head
                   objs[2].From = Vector2.new(head.X, head.Y);
                   objs[2].To = objs[1].From;
                   objs[2].Color = library.flags.esp_skeletoncolor;
                   objs[2].Thickness = library.flags.esp_skeletonthickness;

                   -- Left Arm
                   objs[3].From = Vector2.new(lUpperArmT.X, lUpperArmT.Y);
                   objs[3].To = Vector2.new(lUpperArmB.X, lUpperArmB.Y);
                   objs[3].Color = library.flags.esp_skeletoncolor;
                   objs[3].Thickness = library.flags.esp_skeletonthickness;

                   objs[4].From = Vector2.new(lLowerArm.X, lLowerArm.Y);
                   objs[4].To = objs[3].To;
                   objs[4].Color = library.flags.esp_skeletoncolor;
                   objs[4].Thickness = library.flags.esp_skeletonthickness;

                   objs[5].From = objs[1].From;
                   objs[5].To = objs[3].From;
                   objs[5].Color = library.flags.esp_skeletoncolor;
                   objs[5].Thickness = library.flags.esp_skeletonthickness;

                   -- Right Arm
                   objs[6].From = Vector2.new(rUpperArmT.X, rUpperArmT.Y);
                   objs[6].To = Vector2.new(rUpperArmB.X, rUpperArmB.Y);
                   objs[6].Color = library.flags.esp_skeletoncolor;
                   objs[6].Thickness = library.flags.esp_skeletonthickness;

                   objs[7].From = Vector2.new(rLowerArm.X, rLowerArm.Y);
                   objs[7].To = objs[6].To;
                   objs[7].Color = library.flags.esp_skeletoncolor;
                   objs[7].Thickness = library.flags.esp_skeletonthickness;

                   objs[8].From = objs[1].From;
                   objs[8].To = objs[6].From;
                   objs[8].Color = library.flags.esp_skeletoncolor;
                   objs[8].Thickness = library.flags.esp_skeletonthickness;

                   -- Left Leg
                   objs[9].From = Vector2.new(lUpperLegT.X, lUpperLegT.Y);
                   objs[9].To = Vector2.new(lUpperLegB.X, lUpperLegB.Y);
                   objs[9].Color = library.flags.esp_skeletoncolor;
                   objs[9].Thickness = library.flags.esp_skeletonthickness;

                   objs[10].From = Vector2.new(lLowerLeg.X, lLowerLeg.Y);
                   objs[10].To = objs[9].To;
                   objs[10].Color = library.flags.esp_skeletoncolor;
                   objs[10].Thickness = library.flags.esp_skeletonthickness;

                   objs[11].From = objs[1].To;
                   objs[11].To = objs[9].From;
                   objs[11].Color = library.flags.esp_skeletoncolor;
                   objs[11].Thickness = library.flags.esp_skeletonthickness;

                   -- Right Leg
                   objs[12].From = Vector2.new(rUpperLegT.X, rUpperLegT.Y);
                   objs[12].To = Vector2.new(rUpperLegB.X, rUpperLegB.Y);
                   objs[12].Color = library.flags.esp_skeletoncolor;
                   objs[12].Thickness = library.flags.esp_skeletonthickness;

                   objs[13].From = Vector2.new(rLowerLeg.X, rLowerLeg.Y);
                   objs[13].To = objs[12].To;
                   objs[13].Color = library.flags.esp_skeletoncolor;
                   objs[13].Thickness = library.flags.esp_skeletonthickness;

                   objs[14].From = objs[1].To;
                   objs[14].To = objs[12].From;
                   objs[14].Color = library.flags.esp_skeletoncolor;
                   objs[14].Thickness = library.flags.esp_skeletonthickness;

               end


            end
        end
    end


    -- // Exit ESP
    for inst, item in next, exitEspDrawings do
        local pos, vis = camera:WorldToViewportPoint(inst.CFrame.p);
        item.Visible = vis and library.flags.exitesp_enabled;
        if item.Visible then
            local mag = floor((inst.CFrame.p - camera.CFrame.p).magnitude);
            item.Position = Vector2.new(pos.X,pos.Y);
            item.Text = 'Exit\n'..mag..' studs';
            item.Color = library.flags.exitesp_color;
        end
    end


    -- // Container ESP
    -- for inst, item in next, containerESPDrawings do
    --     if inst.PrimaryPart ~= nil then
    --         local pos, vis = camera:WorldToViewportPoint(inst.PrimaryPart.CFrame.p)
    --         local mag = floor((inst.PrimaryPart.CFrame.p - camera.CFrame.p).magnitude)
    --         local items = #inst.Inventory:GetChildren()
    --         item.Visible = vis and library.flags.containeresp_enabled and table.find(library.flags.containeresp_selected, inst.Name) and (mag <= library.flags.containeresp_maxdistance) and items ~= 0;
    --         if item.Visible then
    --             local text = inst.Name..' - '..mag..' studs - '..items..' items';
    --             item.Position = Vector2.new(pos.X, pos.Y);
    --             item.Color = library.flags.containeresp_color;

    --             if library.flags.containeresp_showcontents then
    --                 for i,v in next, inst.Inventory:GetChildren() do
    --                     local types = library.flags.containeresp_types;
    --                     if (weapons[v.Name] and types['Weapons']) or (attachments[v.Name] and types['Attachments']) or (clothing[v.Name] and types['Clothing']) or (throwables[v.Name] and types['Throwables']) then
    --                         text = text..'\n'..v.Name;
    --                     end
    --                 end
    --             end

    --             item.Text = text
    --         end
    --     end
    -- end

    -- // Corpse ESP
    for inst, item in next, corpseDrawings do
        if inst.PrimaryPart and library.flags.corpseesp_enabled then
            local pos, vis = camera:WorldToViewportPoint(inst.PrimaryPart.CFrame.p);
            local mag = floor((inst.PrimaryPart.CFrame.p - camera.CFrame.p).magnitude);
            item.Visible = vis and (mag <= library.flags.corpseesp_maxdistance) and #inst.Inventory:GetChildren() ~= 0
            if item.Visible then
                item.Position = Vector2.new(pos.X,pos.Y);
                item.Color = library.flags.corpseesp_color;
                item.Text = inst.Name..' [Corpse] - '..mag..' studs - '..#inst.Inventory:GetChildren()..' items';
            end
        else
            item.Visible = false;
        end
    end
    

end)

inputservice.InputBegan:Connect(function(inp, gpe)
    if inp.KeyCode == Enum.KeyCode.P and not gpe then
        game:GetService('TeleportService'):Teleport(game.PlaceId);
    end
end)
