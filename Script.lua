warn("New Execution")
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local settings = {
    DefaultEggName = "Gingerbread Egg",
    SelectedEggName = "Gingerbread Egg",
    AutoHatchEgg = false,
    SelectedWorld = "Christmas",
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Framework = Shared:WaitForChild("Framework")
local Network = Framework:WaitForChild("Network")
local Remote = Network:WaitForChild("Remote")
local RemoteEvent = Remote:WaitForChild("RemoteEvent")
local RemoteFunction = Remote:WaitForChild("RemoteFunction")
local LocalPlayer = game:getService("Players").LocalPlayer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvent = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent
local RemoteModule = require(ReplicatedStorage.Shared.Framework.Network.Remote)
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local StatsUtil = require(ReplicatedStorage.Shared.Utils.Stats.StatsUtil)
local ItemUtil = require(ReplicatedStorage.Shared.Utils.Stats.ItemUtil)
local PetUtil = require(ReplicatedStorage.Shared.Utils.Stats.PetUtil)
local FormatSuffix = require(ReplicatedStorage.Shared.Framework.Utilities.String.FormatSuffix)
local FormatCommas = require(ReplicatedStorage.Shared.Framework.Utilities.String.FormatCommas)
local Pets = require(ReplicatedStorage.Shared.Data.Pets)
local char = LocalPlayer.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
local hum = char and char:FindFirstChildOfClass("Humanoid")
local HttpService = game:GetService('HttpService')
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Spot = PlayerGui:WaitForChild("ScreenGui"):WaitForChild("Hatching")
local leaderstats = LocalPlayer:WaitForChild("leaderstats")

local RiftFolder = workspace:WaitForChild("Rendered"):WaitForChild("Rifts")

local AllowedRifts = {
    ["yuletide-egg"] = { DisplayName = "Yuletide Egg", Emoji = "🎄" },
    ["gingerbread-egg"] = { DisplayName = "Gingerbread Egg", Emoji = "🍪" },
    ["candycane-egg"] = { DisplayName = "Candycane Egg", Emoji = "🍡" },
    ["peppermint-chest"] = { DisplayName = "Peppermint Chest", Emoji = "🍬"},
    ["aurora-egg"] = { DisplayName = "Aurora Egg", Emoji = "🎇"},
    ["northpole-egg"] = { DisplayName = "Northpole Egg", Emoji = "🎅"},
    ["giftbox-egg"] = { DisplayName = "Giftbox Egg", Emoji = "🎁"}
}

local RiftLookup = {} 
local RiftCheckboxes = {}

getgenv().AutoHatchEgg = false
getgenv().AutoHatchRunning = false
getgenv().AutoPetNotifierEnabled = false
getgenv().AutoPetNotifierRunning = false
getgenv().AutoWheelRunning = false
getgenv().AutoWheel = false
getgenv().AutoGift = false
getgenv().AutoGiftRunning = false
getgenv().AutoBlow = false
getgenv().AutoBlowRunning = false
getgenv().AutoPresent = false
getgenv().AutoPresentRunning = false
getgenv().AutoRarePet = false
getgenv().AutoRarePetRunning = false
getgenv().AutoRift = false
getgenv().AutoRiftRunning = false
getgenv().WebhookURL = getgenv().WebhookURL or ""
getgenv().WebhookRole = getgenv().WebhookRole or ""
getgenv().SelectedRarity = getgenv().SelectedRarity or "Secret"
getgenv().WebhookEnabled = false
getgenv().WebhookRunning = false
getgenv().AutoPresents = false
getgenv().AutoPresentsRunning = false
getgenv().SavedPosition = nil
getgenv().SelectedRifts = {}
getgenv().SelectedRiftType = "gingerbread-egg"
getgenv().SelectedRiftEggName = "Gingerbread Egg"

local function formatNumber(num)
    local formatted = tostring(num)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function UpdateChar(newChar)
    char = newChar
    hrp = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChildOfClass("Humanoid")
    if hrp then hrp.Anchored = false end
    if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
end

LocalPlayer.CharacterAdded:Connect(UpdateChar)
if not char then
    char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    UpdateChar(char)
end

local function GetActivations()
    local path = workspace.Worlds["Christmas World"].GiveGifts
    local activations = {}
    for _, v in ipairs(path:GetDescendants()) do
        if v:IsA("Model") and v.Name == "Activation" then
            table.insert(activations, v)
        end
    end
    return activations
end

local function SafeTP(hrp, pos)
    if hrp then
        hrp.Anchored = false
        hrp.CFrame = CFrame.new(pos) * CFrame.fromMatrix(Vector3.zero, hrp.CFrame.RightVector, hrp.CFrame.UpVector)
        task.wait()
    end
end

local DropDownWhitelist = {
    "Giftbox Egg",
    "Gingerbread Egg", 
    "Candycane Egg",
    "Yuletide Egg", 
    "Aurora Egg", 
    "Northpole Egg"
}

local Window = Fluent:CreateWindow({
    Title = "Hatcher V" .. Fluent.Version,
    SubTitle = "by Evolve",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, 
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Eggs = Window:AddTab({ Title = "Eggs", Icon = "" }),
    Rifts = Window:AddTab({ Title = "Rifts", Icon = "" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "" }),
    Farming = Window:AddTab({ Title = "Farming", Icon = "" }),
    Teleportations = Window:AddTab({ Title = "Teleports", Icon = "" }),
    AdminAbuse = Window:AddTab({ Title = "Admin Abuse", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "" })
}

local SelectedEggTextBox = Tabs.Eggs:AddInput("SelectedEgg", {
    Title = "Selected Egg",
    Default = "Default",
    Placeholder = "Input Egg",
    Numeric = false, 
    Finished = false, 
    Callback = function(SelectedEgg)
        settings.SelectedEggName = SelectedEgg
    end
})

local DropDownEgg = Tabs.Eggs:AddDropdown("DropDownEggs", {
    Title = "Selected Egg",
    Values = DropDownWhitelist,
    Multi = false,
    Default = 1,
})

local AutoHatch = Tabs.Eggs:AddToggle("Auto-Hatch", {
    Title = "Auto-Hatch",
    Default = false
})

local AutoBubble = Tabs.Farming:AddToggle("Auto-Bubble", {
    Title = "Auto-Bubble",
    Default = false
})

local AutoWheel = Tabs.Farming:AddToggle("Auto-Wheel", {
    Title = "Auto-Wheel",
    Default = false
})

local AutoGiftBox = Tabs.Farming:AddToggle("Auto-Gift", {
    Title = "Auto-Gift",
    Default = false
})

DropDownEgg:OnChanged(function(DropDown)
    settings.SelectedEggName = DropDown
end)

AutoHatch:OnChanged(function(Value)
    getgenv().AutoHatchEgg = Value

    if Value and not getgenv().AutoHatchRunning then
        getgenv().AutoHatchRunning = true

        task.spawn(function()
            while getgenv().AutoHatchEgg do
                if settings.SelectedEggName and settings.SelectedEggName ~= "" then
                    RemoteEvent:FireServer("HatchEgg", settings.SelectedEggName, 13)
                end
                task.wait(0.2)
            end
            getgenv().AutoHatchRunning = false
        end)
    end
end)

AutoBubble:OnChanged(function(AutoBubble)
    getgenv().AutoBlow = AutoBubble
    if AutoHatch and not getgenv().AutoBlowRunning then
        getgenv().AutoBlowRunning = true
        task.spawn(function()
            while getgenv().AutoBlow do
                RemoteEvent:FireServer("BlowBubble")
                task.wait()
            end
            getgenv().AutoBlowRunning = false
        end)
    end
end)

AutoGiftBox:OnChanged(function(state)
    getgenv().AutoGift = state

    if not state then
        getgenv().AutoGiftRunning = false
        if hrp then hrp.Anchored = false end
        if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
        return
    end

    if getgenv().AutoGiftRunning then return end
    getgenv().AutoGiftRunning = true

    task.spawn(function()
        while getgenv().AutoGift do
            task.wait(0.1)

            if not char or not hrp or not hum then continue end
            hum:ChangeState(Enum.HumanoidStateType.Running)
            hrp.Anchored = false

            for _, activation in ipairs(GetActivations()) do
                if not getgenv().AutoGift then break end

                local root = activation:FindFirstChild("Root")
                if not root then continue end

                SafeTP(hrp, root.Position + Vector3.new(0, 5, 0))

                local elapsed = 0
                local waitTime = 3 
                while elapsed < waitTime do
                    if not getgenv().AutoGift then break end
                    task.wait(0.05) 
                    elapsed = elapsed + 0.05
                end

                if not getgenv().AutoGift then break end
                RemoteEvent:FireServer("GiveGifts", activation.Parent.Name)
                task.wait(0.05) 
            end
        end

        if hrp then hrp.Anchored = false end
        if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
        getgenv().AutoGiftRunning = false
    end)
end)

AutoWheel:OnChanged(function(AutoWheel)
    getgenv().AutoWheel = AutoWheel
    if AutoWheel and not getgenv().AutoWheelRunning then
        getgenv().AutoWheelRunning = true
        task.spawn(function()
            while getgenv().AutoWheel do
                RemoteFunction:InvokeServer("ChristmasWheelSpin")
                RemoteEvent:FireServer("ClaimChristmasWheelSpinQueue")
                task.wait()
            end
            getgenv().AutoWheelRunning = false
        end)
    end
end)

local function FormatRiftName(name)
    local words = {}
    for word in name:gmatch("[^%-]+") do
        table.insert(words, word:sub(1,1):upper() .. word:sub(2))
    end
    return table.concat(words, " ")
end

local function BuildRiftDisplay(rift)
    local info = AllowedRifts[rift.Name] or { DisplayName = FormatRiftName(rift.Name), Emoji = "❓" }

    local emoji = tostring(info.Emoji)
    local displayName = tostring(info.DisplayName)

    local luck = "?"
    local icon = rift:FindFirstChild("Display")
        and rift.Display:FindFirstChild("SurfaceGui")
        and rift.Display.SurfaceGui:FindFirstChild("Icon")
    if icon and icon:FindFirstChild("Luck") and icon.Luck:IsA("TextLabel") then
        luck = tostring(icon.Luck.Text)
    end

    local time = "??"
    local displayPart = rift:FindFirstChild("Display")
    if displayPart then
        local gui = displayPart:FindFirstChild("SurfaceGui")
        if gui then
            local timerLabel = gui:FindFirstChild("Timer")
            if timerLabel and timerLabel:IsA("TextLabel") then
                time = tostring(timerLabel.Text)
            end
        end
    end

    return string.format("%s %s (%s • %s)", emoji, displayName, luck, time)
end

local RiftLookup = {}

local function GenerateRiftDropdown()
    local values = {}
    table.clear(RiftLookup)

    for _, rift in ipairs(RiftFolder:GetChildren()) do
        if AllowedRifts[rift.Name] then
            local text = BuildRiftDisplay(rift)
            RiftLookup[text] = rift
            table.insert(values, text)
        end
    end

    table.sort(values)
    return values
end

local SelectRift = Tabs.Rifts:AddDropdown("SelectRift", {
    Title = "Select Rift",
    Values = GenerateRiftDropdown(),
    Multi = false,
    Default = GenerateRiftDropdown()[1]
})

SelectRift:OnChanged(function(value)
    getgenv().SelectedRift = RiftLookup[value]
end)

local function RefreshRifts()
    SelectRift:SetValues(GenerateRiftDropdown())
end

RiftFolder.ChildAdded:Connect(RefreshRifts)
RiftFolder.ChildRemoved:Connect(RefreshRifts)

Tabs.Rifts:AddButton({
    Title = "Teleport To Selected Rift",
    Description = "Teleport to the currently selected rift",
    Callback = function()

        if not getgenv().SelectedRift then
            warn("No rift selected.")
            return
        end

        Window:Dialog({
            Title = "Teleport Confirmation",
            Content = "Teleport to the selected rift?",
            Buttons = {
                {
                    Title = "Confirm",
                    Callback = function()
                        local player = game.Players.LocalPlayer
                        local char = player.Character or player.CharacterAdded:Wait()
                        local hrp = char:FindFirstChild("HumanoidRootPart")

                        if not hrp then
                            warn("HumanoidRootPart missing")
                            return
                        end

                        local rift = getgenv().SelectedRift
                        local display = rift:FindFirstChild("Display")

                        if not display then
                            warn("Rift display missing")
                            return
                        end

                        local targetPos =
                            display:IsA("BasePart") and display.Position
                            or display:IsA("Model") and display:GetPivot().Position

                        if not targetPos then
                            warn("Could not determine rift position")
                            return
                        end

                        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
                        print("Teleported to:", BuildRiftDisplay(rift))
                    end
                },
                {
                    Title = "Cancel",
                    Callback = function()
                        print("Teleport cancelled.")
                    end
                }
            }
        })
    end
})

local AutoRiftEgg = Tabs.Rifts:AddDropdown("Auto-RiftEgg", {
    Title = "Auto-Rift Egg",
    Values = DropDownWhitelist,
    Multi = false,
    Default = "Gingerbread Egg"
})

local RiftMap = {
    ["Gingerbread Egg"] = {rift = "gingerbread-egg", egg = "Gingerbread Egg"},
    ["Candycane Egg"] = {rift = "candycane-egg", egg = "Candycane Egg"},
    ["Yuletide Egg"] = {rift = "yuletide-egg", egg = "Yuletide Egg"},
    ["Peppermint Chest"] = {rift = "peppermint-chest", egg = "Peppermint Chest"},
    ["Aurora Egg"] = {rift = "aurora-egg", egg = "Aurora Egg"},
    ["Northpole Egg"] = {rift = "northpole-egg", egg = "Northpole Egg"},
    ["Giftbox Egg"] = {rift = "giftbox-egg", egg = "Giftbox Egg"}
}

AutoRiftEgg:OnChanged(function(selection)
    if RiftMap[selection] then
        getgenv().SelectedRiftType = RiftMap[selection].rift
        getgenv().SelectedRiftEggName = RiftMap[selection].egg
        print("Selected Rift:", getgenv().SelectedRiftType)
        print("Selected Egg:", getgenv().SelectedRiftEggName)
    else
        warn("Invalid selection:", selection)
    end
end)

local AutoRiftToggle = Tabs.Rifts:AddToggle("Auto-Rift", {
    Title = "Auto Rift",
    Default = false
})

AutoRiftToggle:OnChanged(function(state)
    getgenv().AutoRift = state

    local char = game.Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not state then
        getgenv().AutoRiftRunning = false
        if hrp then hrp.Anchored = false end
        if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
        return
    end

    if getgenv().AutoRiftRunning then return end
    getgenv().AutoRiftRunning = true

    task.spawn(function()
        while getgenv().AutoRift do
            task.wait(0.5)

            char = game.Players.LocalPlayer.Character
            hrp = char and char:FindFirstChild("HumanoidRootPart")
            hum = char and char:FindFirstChildOfClass("Humanoid")

            if not char or not hrp or not hum then continue end

            local foundRift = nil
            for _, rift in ipairs(RiftFolder:GetChildren()) do
                if rift.Name == getgenv().SelectedRiftType and rift:FindFirstChild("Display") then
                    foundRift = rift
                    SelectedRift = rift
                    break
                end
            end

            if not foundRift then
                if getgenv().SavedPosition then
                    hrp.CFrame = getgenv().SavedPosition
                end
                RemoteEvent:FireServer("HatchEgg", settings.SelectedEggName, 13)
                task.wait(0.1)
                continue
            end

            if not getgenv().SavedPosition then
                getgenv().SavedPosition = hrp.CFrame
            end

            local targetPos = foundRift.Display.Position
            SafeTP(hrp, targetPos)
            task.wait(0.5)

            while getgenv().AutoRift and foundRift and foundRift.Parent do
                RemoteEvent:FireServer("HatchEgg", getgenv().SelectedRiftEggName, 13)
                task.wait(0.1)
            end

            if getgenv().SavedPosition then
                hrp.CFrame = getgenv().SavedPosition
                task.wait(0.5)
            end

            local waitTime = 0
            while getgenv().AutoRift and waitTime < 30 do
                local newRift = nil
                for _, rift in ipairs(RiftFolder:GetChildren()) do
                    if rift.Name == getgenv().SelectedRiftType and rift:FindFirstChild("Display") then
                        newRift = rift
                        break
                    end
                end

                if newRift then break end

                RemoteEvent:FireServer("HatchEgg", settings.SelectedEggName, 13)
                task.wait(0.1)
                waitTime = waitTime + 0.1
            end
        end

        if hrp then hrp.Anchored = false end
        if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
        getgenv().AutoRiftRunning = false
    end)
end)

local WebhookTab = Tabs.Webhook

local WebhookPasswords = {
    ["EvoBeamer"] = { Name = "Evolve", URL = "https://discord.com/api/webhooks/1450435402837004298/paOBg4KryLYQcFpPXsOMDwXMM2sm2xqynlbfgNj76Dl2KoxBLsf4vf014RmeQRMxdC6Q", Role = "1450435843654156389" },
    ["LoLpEaz"] = { Name = "Creature", URL = "https://discord.com/api/webhooks/1450436140158025950/usm4V5I6cb0dDmFBUiI8zuAsdzeVh-5kqdQ0CADBuCDC7Isk7imzNSz2PZ_d7otEGJ8R", Role = "1450435926168698881" },
    ["oMnjaR"] = { Name = "Nathan", URL = "https://discord.com/api/webhooks/1450436359993954438/65G8HcyvutHFzmlP0fJfLeIeMQ3U8iBf4hW5WCwgl-osKQicdYNVp56iTSlTzQv4cWlK", Role = "1450435969374228613" },
    ["uYRaNr"] = { Name = "Bosscrews", URL = "https://discord.com/api/webhooks/1450436281354948731/IEy_xcLnLu54oowRAKol3WaXmeghSsM7ZQtmMRM-5DwAQoWnaHGuxlJwa8AqP2X3NnL4", Role = "1450436029432725656" },
    ["KodBeamer"] = { Name = "Kody", URL = "https://discord.com/api/webhooks/1450436221011492977/0As_hvcKM_8jMhmxFl0pCN2ViGBR0_v76_ZlSiwfgJkZf_Ah10b5gpcc-TIac0CkpdIA", Role = "1450436076060540938" },
}

local PasswordInput = Tabs.Webhook:AddInput("PasswordInput", {
    Title = "Enter Password",
    Default = "",
    Placeholder = "Type password here",
    Numeric = false,
    Finished = false,
    Callback = function(Value) end
})

local UnlockButton = Tabs.Webhook:AddButton({
    Title = "Unlock Webhook Tab",
    Description = "Enter password and press to unlock webhooks",
    Callback = function()
        local enteredPassword = PasswordInput.Value
        local info = WebhookPasswords[enteredPassword]

        if not info then
            return 
        end

        getgenv().WebhookURL = info.URL
        getgenv().WebhookRole = info.Role
        getgenv().SelectedRarity = getgenv().SelectedRarity or "Secret"
        getgenv().WebhookEnabled = false
        getgenv().WebhookRunning = false

        local WebhookDropdown = WebhookTab:AddDropdown("SelectWebhook", {
            Title = "Select Webhook",
            Values = { info.Name },
            Multi = false,
            Default = info.Name
        })

        WebhookDropdown:OnChanged(function(selection)
            print("Webhook selected:", selection)
        end)

        local RarityDropdown = WebhookTab:AddDropdown("MinimumRarity", {
            Title = "Minimum Rarity",
            Values = {"Legendary", "Secret", "Infinity"},
            Multi = false,
            Default = getgenv().SelectedRarity
        })

        RarityDropdown:OnChanged(function(rarity)
            getgenv().SelectedRarity = rarity
        end)

        local WebhookToggle = WebhookTab:AddToggle("EnableWebhook", {
            Title = "Enable Webhook Notifications",
            Default = false
        })

        WebhookToggle:OnChanged(function(state)
            getgenv().WebhookEnabled = state

            if state and not getgenv().WebhookRunning then
                getgenv().WebhookRunning = true

                RemoteModule.Event("HatchEgg"):Connect(function(data)
                    if not getgenv().WebhookEnabled then return end
                    if not data then return end

                    local dataaa = LocalData:Get()
                    local embeds = {}

                    for _, v in pairs(data.Pets) do
                        local Name = ItemUtil:GetName(v.Pet)
                        local Rarity = ItemUtil:GetRarity(v.Pet)
                        local Chance = PetUtil:GetChance(v.Pet)

                        local rarityOrder = {Legendary = 1, Secret = 2, Infinity = 3}
                        local petRarityLevel = rarityOrder[Rarity] or 0
                        local minRarityLevel = rarityOrder[getgenv().SelectedRarity] or 0

                        if petRarityLevel >= minRarityLevel then
                            local Stats = {}
                            for statName, statValue in PetUtil:GetStats(v.Pet) do
                                Stats[#Stats + 1] = "> "..statName..": "..FormatCommas(math.floor(statValue))
                            end

                            local Pet = Pets[v.Pet.Name]
                            local Image = Pet.Images.Normal
                            if v.Pet.Mythic then
                                Image = Pet.Images.Mythic
                                if v.Pet.Shiny then
                                    Image = Pet.Images.MythicShiny
                                end
                            elseif v.Pet.Shiny then
                                Image = Pet.Images.Shiny
                            end

                            embeds[#embeds + 1] = {
                                title = Name.." Pet Hatched (Odds 1/"..FormatSuffix(math.ceil(100 / Chance))..")",
                                description = "Total Hatches: **"..FormatCommas(dataaa.Stats.Hatches).."**\nRarity: **"..Rarity.."**\n"..table.concat(Stats, "\n"),
                                thumbnail = {url = HttpService:JSONDecode(game:HttpGet("https://thumbnails.roblox.com/v1/assets?assetIds="..Image:match("%d+").."&size=420x420&format=Png"))["data"][1]["imageUrl"]},
                                color = tonumber(0xFF0000)
                            }
                        end
                    end

                    if #embeds > 0 and getgenv().WebhookURL ~= "" then
                        local success, err = pcall(function()
                            request({
                                Url = getgenv().WebhookURL,
                                Method = "POST",
                                Body = HttpService:JSONEncode({
                                    content = getgenv().WebhookRole and ("<@&" .. getgenv().WebhookRole .. ">") or "",
                                    embeds = embeds
                                }),
                                Headers = {["Content-Type"] = "application/json"}
                            })
                        end)

                        if success then
                            warn("Webhook sent successfully!")
                        else
                            warn("Webhook failed: " .. tostring(err))
                        end
                    end
                end)
            end
        end)
    end
})

Tabs.Teleportations:AddButton({
    Title = "Teleport to Winter Eggs",
    Callback = function()
        local targetCFrame = CFrame.new(
            -2481.11572, 36.0117455, 1226.60803,
            -0.636197329, -3.65438495e-07, 0.771526337,
            -2.59595339e-07, 1, 2.59595311e-07,
            -0.771526337, -3.51307925e-08, -0.636197329
        )

        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn("HumanoidRootPart not found")
            return
        end

        hrp.CFrame = targetCFrame
        print("Teleported to Winter Eggs!")
    end
})

Tabs.Teleportations:AddButton({
    Title = "Teleport to Enchanter",
    Callback = function()
        local targetCFrame = CFrame.new(
            -52.0119133, 10148.71, 47.0890388,
            0.512039363, 1.40908876e-20, 0.858961999,
            9.69264938e-22, 1, -1.69823459e-20,
            -0.858961999, 9.52819169e-21, 0.512039363
        )

        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn("HumanoidRootPart not found")
            return
        end

        hrp.CFrame = targetCFrame
        print("Teleported to Enchanter!")
    end
})

Tabs.Teleportations:AddButton({
    Title = "Teleport to Bubble Shrine",
    Callback = function()
        local targetCFrame = CFrame.new(
            5.203871250152588,
            15976.845703125,
            76.09961700439453
        )

        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn("HumanoidRootPart not found")
            return
        end

        hrp.CFrame = targetCFrame
        print("Teleported to Bubble Shrine!")
    end
})

Tabs.Teleportations:AddButton({
    Title = "Teleport to Dream Shrine",
    Callback = function()
        local targetCFrame = CFrame.new(
            -21799.4765625,
            7.846194267272949,
            -20440.369140625
        )

        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn("HumanoidRootPart not found")
            return
        end

        hrp.CFrame = targetCFrame
        print("Teleported to Dream Shrine!")
    end
})

Tabs.AdminAbuse:AddButton({
    Title = "Teleport to Admin Abuse Egg",
    Callback = function()
        local targetCFrame = CFrame.new(
            126.619072,
            8.59998417,
            91.6279297,
            -0.761533022,
            4.84210312e-26,
            -0.648126066,
            -3.17974163e-29,
            1,
            7.47466415e-26,
            0.648126066,
            5.69426425e-26,
            -0.761533022
        )

        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn("HumanoidRootPart not found")
            return
        end

        hrp.CFrame = targetCFrame
        print("Teleported to Admin Abuse Egg!")
    end
})

local OldPositionForTp = nil

local SavePositionKeybind = Tabs.AdminAbuse:AddKeybind("SavePositionKeybind", {
    Title = "Save Position",
    Mode = "Toggle",
    Default = "None",
    Callback = function(Value)
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            OldPositionForTp = hrp.CFrame
            print("Position saved!")
            Fluent:Notify({
                Title = "Hatcher V3",
                Content = "Saved Position!",
                Duration = 4
            })
        else
            warn("HumanoidRootPart not found!")
        end
    end,
    ChangedCallback = function(New)
        print("Save Position Keybind changed to:", New.Name)
    end
})

local TeleportKeybind = Tabs.AdminAbuse:AddKeybind("TeleportKeybind", {
    Title = "Teleport to Saved Position",
    Mode = "Toggle",
    Default = "None",
    Callback = function(Value)
        if not OldPositionForTp then
            warn("No position saved yet!")
            return
        end

        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = OldPositionForTp
            print("Teleported to saved position!")
            Fluent:Notify({
                Title = "Hatcher V3",
                Content = "Teleported to saved Position!",
                Duration = 4
            })
        else
            warn("HumanoidRootPart not found!")
        end
    end,
    ChangedCallback = function(New)
        print("Teleport Keybind changed to:", New.Name)
    end
})

-- local AutoClaimPlaytime = Tabs.Farming:AddToggle("MyToggle", {
--     Title = "Auto Claim All Playtime",
--     Default = false
-- })

-- local player = game.Players.LocalPlayer
-- local frame = player.PlayerGui.ScreenGui.Playtime.Frame

-- local claiming = false  

-- local function GetAllOpenButtons()
--     local opens = {}
--     for _, v in pairs(frame:GetDescendants()) do 
--         if v:IsA("ImageButton") and v.Name == "Button" then 
--             for _, textObj in pairs(v:GetChildren()) do 
--                 if textObj:IsA("TextLabel") and textObj.TextColor3 == Color3.fromRGB(82, 255, 51) and textObj.Text == "Open" then 
--                     table.insert(opens, v)
--                 end
--             end
--         end
--     end
--     return opens
-- end

-- AutoClaimPlaytime:OnChanged(function(value)
--     claiming = value
--     print("Toggle changed:", value)
--     if claiming then
--         task.spawn(function()
--             while claiming do
--                 local openButtons = GetAllOpenButtons()
--                 if #openButtons > 0 then
--                     RemoteEvent:FireServer("ClaimAllPlaytime")
--                 end
--                 task.wait(1)
--             end
--         end)
--     end
-- end)

local AutoClaimPlaytimeSpeed = Tabs.Farming:AddSlider("CheckSpeed", {
    Title = "Check Speed",
    Description = "How often to check for open playtime",
    Default = 2,
    Min = 2,
    Max = 14,
    Rounding = 1,
    Callback = function(Value)
        print("Slider changed:", Value)
    end
})

AutoClaimPlaytimeSpeed:OnChanged(function(Value)
    print("Slider changed:", Value)
end)

AutoClaimPlaytimeSpeed:SetValue(2)

local AutoClaimPlaytime = Tabs.Farming:AddToggle("ClaimToggle", {
    Title = "Claim All Playtime",
    Default = true
})

local player = game.Players.LocalPlayer
local frame = player.PlayerGui.ScreenGui.Playtime.Frame

local claiming = false

local function GetAllOpenButtons()
    local opens = {}
    for _, v in pairs(frame:GetDescendants()) do 
        if v:IsA("ImageButton") and v.Name == "Button" then 
            for _, textObj in pairs(v:GetChildren()) do 
                if textObj:IsA("TextLabel") and textObj.TextColor3 == Color3.fromRGB(82, 255, 51) and textObj.Text == "Open" then 
                    table.insert(opens, v)
                end
            end
        end
    end
    return opens
end

AutoClaimPlaytime:OnChanged(function(value)
    claiming = value
    print("Toggle changed:", value)

    if claiming then
        task.spawn(function()
            while claiming do
                local openButtons = GetAllOpenButtons()
                if #openButtons > 0 then
                    RemoteEvent:FireServer("ClaimAllPlaytime")
                end
                task.wait(AutoClaimPlaytimeSpeed.Value)
            end
        end)
    end
end)
