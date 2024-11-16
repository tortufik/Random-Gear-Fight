-- module script
-- game.ReplicatedStorage.Modules.GearApi

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage

if RunService:IsServer() then
	ServerStorage = game:GetService("ServerStorage")
end

local api = {}
local classes = {}
local geartable = script.Parent.GearTable:GetChildren()
local NameToId = require(script.NameToId)

if RunService:IsServer() then
	api.OnKill = ServerScriptService.KOSHandler.OnKill.Event
	api.MapEnd = ServerScriptService.MapsHandler.End.Event
	api.OnHit = ServerScriptService.KOSHandler.OnHit.Event
	api.OnHitInternal = ServerScriptService.KOSHandler.OnHit -- do not use
elseif RunService:IsClient() then
	api.OnKill = ReplicatedStorage.ClientAPI.OnKill.OnClientEvent
	api.MapEnd = ReplicatedStorage.ClientAPI.End.OnClientEvent
	api.OnHit = ReplicatedStorage.ClientAPI.OnHit.OnClientEvent
	api.OnHitInternal = ReplicatedStorage.ClientAPI.OnHit -- do not use
end

api.ClassesTable = classes
api.GearTable = require(ReplicatedStorage.Modules.GearTable)
api.PointsTexture = "rbxassetid://72087838994989"

for _,v in pairs(geartable) do
	if v:IsA("ModuleScript") then
		classes[v.Name] = require(v)
	end
end

function api:GetGearTable()
	return api.GearTable
end

function api:GetClassesTable()
	return classes
	-- classes format
	--[[
	{
		 ["Misc"] = {ID},
		 ["Award"] = {ID}, -- child of misc class
		 ["Celebration"] = {ID}, -- child of misc class
		 ["Other"] = {ID}, -- child of misc class
		 ["Toy"] = {ID}, -- child of misc class
		 ["Music"] = {ID}, -- child of misc class
		 ["Support"] = {ID},
		 ["Defense"] = {ID}, -- child of support class
		 ["Healing"] = {ID}, -- child of support class
		 ["Movement"] = {ID}, -- child of support class
		 ["Summoning"] = {ID}, -- child of support class
		 ["Potion"] = {ID}, -- child of support class
		 ["Weapon"] = {ID},
		 ["Melee"] = {ID}, -- child of weapon class
		 ["Magic"] = {ID}, -- child of weapon class
		 ["Explosion"] = {ID}, -- child of weapon class
		 ["Ranged"] = {ID} -- child of weapon class
	}
	child of x class means that the ids inside of this class will also be in its parent
	]]
end

function api:AwardPoints(Player, Points)
	assert(typeof(Player) == "Instance", "Argument 1 expected to be instance got "..typeof(Player))
	assert(typeof(Points) == "number", "Argument 2 expected to be number got "..typeof(Points))
	assert(RunService:IsServer(), "AwardPoints can only be accessed on server")
	
	Player.leaderstats.Points.Value += Points
	ReplicatedStorage.MakeSysNotification:FireClient(Player, {Title = "Points", Text = "You got awarded "..Points.." Points", Icon = api.PointsTexture})
end

function api:SetKiller(Player1 : Player, Player2 : Player) -- overwrite hit detection (probably dont use this)
	assert(RunService:IsServer(), "SetKiller can only be accessed on server")
	
	Player1.Killer.Value = Player2
end

function api:GetKiller(Player)
	assert(typeof(Player) == "Instance", "Argument 1 expected to be instance got "..typeof(Player))
	
	return Player.Killer.Value
end

function api:EndMap()
	assert(RunService:IsServer(), "EndMap can only be accessed on server")
	ServerScriptService.MapsHandler.End:Fire()
end

function api:GetClassesFromId(Id)
	assert(typeof(Id) == "number", "Argument 1 expected to be number got "..typeof(Id))
	
	local class = {}
	
	for i,c in pairs(classes) do
		if table.find(c, Id) then
			table.insert(class, i)
		end
	end
	
	return class
end

function api:IsGear(instance)
	if instance then
		if instance:IsA("Tool") or instance:IsA("HopperBin") then
			return instance
		end

		return instance:FindFirstAncestorWhichIsA("Tool") or instance:FindFirstAncestorWhichIsA("HopperBin")
	end
	return nil
end

function api:IsProjectile(instance)
	if instance then
		if instance:IsA("BasePart") then
			return instance
		end
		return instance:FindFirstAncestorWhichIsA("BasePart")
	end
end

function api:GetProjectileOwner(obj)
	local Owner

	Owner = (obj:CanSetNetworkOwnership() and obj:GetNetworkOwner()) or nil

	if not Owner then
		for _,tags in pairs(obj:GetDescendants()) do
			if tags:IsA("ObjectValue") and tags.Value then
				Owner = tags.Value
			end
		end
	end

	return Owner
end

function api:GetDamageMultiplier(Player)
	assert(typeof(Player) == "Instance", "Argument 1 expected to be instance got "..typeof(Player))
	
	if not Player:GetAttribute("DamageMultiplier") then
		Player:SetAttribute("DamageMultiplier", 1)
	end
	
	return Player:GetAttribute("DamageMultiplier")
end

function api:SetDamageMultiplier(Player, Multiplier)
	assert(typeof(Player) == "Instance", "Argument 1 expected to be instance got "..typeof(Player))
	assert(typeof(Multiplier) == "number", "Argument 2 expected to be number got "..typeof(Multiplier))
	
	Player:SetAttribute("DamageMultiplier", Multiplier)
end

function api:TakeDamage(humanoid : Humanoid, deal : number, Parent : Instance, setdamage : boolean) -- used for hit detection use this instead of humanoid:TakeDamage()
	assert(typeof(humanoid) == "Instance",  "Argument 1 expected to be instance got "..typeof(humanoid))
	assert(typeof(deal) == "number", "Argument 2 expected to be number got "..typeof(deal))
	assert(typeof(Parent) == "Instance", "Argument 3 expected to be instance got "..typeof(Parent))
	
	local gear = api:IsGear(Parent) :: Tool
	local proj = api:IsProjectile(Parent) :: BasePart
	local Hitter
	if gear then
		Hitter = (Players:GetPlayerFromCharacter(gear:FindFirstAncestorWhichIsA("Model")) or gear:FindFirstAncestorWhichIsA("Player"))
	elseif proj then
		Hitter = api:GetProjectileOwner(proj)
	end
	local Hit = Players:GetPlayerFromCharacter(humanoid.Parent)
	if not setdamage then
		if Hit then
			humanoid:TakeDamage(deal * api:GetDamageMultiplier(Hit))
		else
			humanoid:TakeDamage(deal)
		end
	else
		if Hit then
			if not humanoid.Parent:FindFirstChildWhichIsA("ForceField") then
				humanoid.Health = deal / api:GetDamageMultiplier(Hit)
			end
		else
			if not humanoid.Parent:FindFirstChildWhichIsA("ForceField") then
				humanoid.Health = deal
			end
		end
	end
	if RunService:IsServer() then
		api.OnHitInternal:Fire(humanoid, deal, Parent)
	else
		ReplicatedStorage:WaitForChild("SetClientHealth"):FireServer(-1, humanoid.Parent, humanoid.Health - deal, Parent)
		api.OnHitInternal:FireServer(humanoid, deal, Parent)
	end
	
	if Hit and Hitter and Hitter ~= Hit and RunService:IsServer() then
		api:SetKiller(Hit, Hitter)
	end
end

function api:GetNameFromId(Id)
	if typeof(Id) == "string" then
		return Id
	end
	if RunService:IsClient() then
		for i,v in pairs(NameToId) do
			if v == Id then
				return i
			end
		end

		return nil
	else
		for _,v in pairs(ServerStorage.Fixed:GetChildren()) do
			local id = api:GetIdFromGearModel(v)
			if id == Id then
				return v.Name
			end
		end
	end
end

function api:GetIdFromName(Name)
	if RunService:IsClient() then
		return NameToId[Name] or Name
	else
		for _,v in pairs(ServerStorage.Fixed:GetChildren()) do
			if v.Name == Name then
				return api:GetIdFromGearModel(v)
			end
		end
	end
	return Name
end

function api:GetIdFromGearModel(Gear)
	assert(typeof(Gear) == "Instance", "Argument 1 expected to be instance got "..typeof(Gear))
	
	if Gear:IsA("Tool") or Gear:IsA("HopperBin") then
		if Gear:FindFirstChild("Id") and Gear:FindFirstChild("Id"):IsA("NumberValue") then
			return Gear:FindFirstChild("Id").Value
		elseif Gear:FindFirstChild("ID") and Gear:FindFirstChild("ID"):IsA("NumberValue") then
			return Gear:FindFirstChild("ID").Value
		else
			return Gear.Name
		end
	end
	
	return 0
end

function api:GetFixedGearFromId(Id)
	assert(RunService:IsServer(), "GetFixedGearFromId can only be accessed on server")
	
	ServerStorage:WaitForChild("Fixed")
	
	for _,v in pairs(ServerStorage.Fixed:GetChildren()) do
		if api:GetIdFromGearModel(v) == Id then
			return v:Clone()
		end
	end
	
	for _,v in pairs(ServerStorage.Gears:GetChildren()) do
		if api:GetIdFromGearModel(v) == Id then
			return v:Clone()
		end
	end
	
	return nil
end

function api:IsSandbox()
	return game.PlaceId ~= 78594287058078
end

return api
