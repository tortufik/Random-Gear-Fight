local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Tool = script.Parent
disable = false

local gears = require(ReplicatedStorage.Modules.GearTable)
local GearAPI = require(ReplicatedStorage.Modules.GearApi)

if ServerStorage.MapAttributes:FindFirstChild("NoMovement") then
	for _,v in pairs(gears) do
		if typeof(v) == "number" then
			for _,v2 in pairs(GearAPI:GetClassesFromId(v)) do
				if v2 == "Movement" then
					table.remove(table.find(gears, v))
					break
				end
			end
		end
	end
end

function onActivated()
	if disable == false then
		disable = true
		Tool.Handle.Glow.Enabled = true
		Tool.Handle.Rays1.Enabled = true
		Tool.Handle.Rays2.Enabled = true
		task.wait(0.7)
		local plr = Players:GetPlayerFromCharacter(Tool.Parent)

		if plr then else return end
		
		magicSound = Tool.Handle:FindFirstChild("MagicSound")
		if magicSound == nil then return end
		magicSound:Play()

		local whichNum = math.random(1,#gears)
		
		ReplicatedStorage.SaveGear:Fire(plr, gears[whichNum])
		local root = ServerStorage.Gears:FindFirstChild(gears[whichNum]):Clone()
		ReplicatedStorage.MakeSysMessage:FireAllClients({Text = plr.Name.." got "..gears[whichNum], TextSize = 12, Font = Enum.Font.Ubuntu})

		Tool:Destroy()
		root.Parent = plr.Backpack
	end
end

function onEquipped()
	disable = false
	magicSound = Tool.Handle:FindFirstChild("MagicSound")
	if magicSound == nil then
		magicSound = Instance.new("Sound")
		magicSound.Parent = Tool.Handle
		magicSound.Volume = 1
		magicSound.SoundId = "http://www.roblox.com/asset/?id=35571070"
		magicSound.Name = "MagicSound"
	end
end

if Tool then
	Tool.Activated:connect(onActivated)
	Tool.Equipped:connect(onEquipped)
end
