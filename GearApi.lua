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
local typeToValueType = {
	["boolean"] = "BoolValue",
	["string"] = "StringValue",
	["BrickColor"] = "BrickColorValue",
	["CFrame"] = "CFrameValue",
	["Color3"] = "Color3Value",
	["number"] = "NumberValue",
	["Instance"] = "ObjectValue",
	["Ray"] = "RayValue",
	["Vector3"] = "Vector3Value",
	["RBXScriptConnection"] = "ObjectValue",
}

local getfenv, setfenv = getfenv, setfenv -- to avoid pointless warnings

local geartable = script.Parent.GearTable:GetChildren()
local NameToId = require(script.NameToId)
local WaitFix = 0

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
			if WaitFix < 2000 then
				WaitFix += 1
			else
				task.wait()
				WaitFix = 0
			end
			local id = api:GetIdFromGearModel(v)
			if id == Id then
				WaitFix = 0
				return v.Name
			end
		end
		WaitFix = 0
	end
end

function api:GetIdFromName(Name)
	if RunService:IsClient() then
		return NameToId[Name] or Name
	else
		for _,v in pairs(ServerStorage.Fixed:GetChildren()) do
			if WaitFix < 2000 then
				WaitFix += 1
			else
				task.wait()
				WaitFix = 0
			end
			if v.Name == Name then
				WaitFix = 0
				return api:GetIdFromGearModel(v)
			end
		end
	end
	WaitFix = 0
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

-- Function for handling npcs only call at the start of the script
function api:SetupEnv()
	local customenv = getfenv(2)
	local function Instanceify(obj : Instance, tbl : table)
		-- Properties

		tbl["ClassName"] = obj.ClassName
		tbl["Name"] = obj.Name
		tbl["Archivable"] = obj.Name

		-- Functions

		function tbl:FindFirstChild(...)
			return obj:FindFirstChild(...)
		end

		function tbl:WaitForChild(...)
			return obj:WaitForChild(...)
		end

		function tbl:FindFirstChildOfClass(...)
			return obj:FindFirstChildOfClass(...)
		end

		function tbl:GetChildren(...)
			return obj:GetChildren(...)
		end

		function tbl:FindFirstChildWhichIsA(...)
			return obj:FindFirstChildWhichIsA(...)
		end

		function tbl:Clone(...)
			return obj:Clone(...)
		end

		function tbl:Destroy(...)
			return obj:Destroy(...)
		end

		function tbl:GetDescendants(...)
			return obj:GetDescendants(...)
		end

		function tbl:HasTag(...)
			return obj:HasTag(...)
		end

		function tbl:GetAttribute(...)
			return obj:GetAttribute(...)
		end

		function tbl:Remove(...)
			return obj:Remove(...)
		end

		function tbl:FindFirstAncestorWhichIsA(...)
			return obj:FindFirstAncestorWhichIsA(...)
		end

		function tbl:GetFullName(...)
			return obj:GetFullName(...)
		end

		function tbl:SetAttribute(...)
			return obj:SetAttribute(...)
		end

		function tbl:GetPropertyChangedSignal(...)
			return obj:GetPropertyChangedSignal(...)
		end

		function tbl:AddTag(...)
			return obj:AddTag(...)
		end

		function tbl:IsAncestorOf(...)
			return obj:IsAncestorOf(...)
		end

		function tbl:GetTags(...)
			return obj:GetTags(...)
		end

		function tbl:FindFirstAncestor(...)
			return obj:FindFirstAncestor(...)
		end

		function tbl:ClearAllChildren(...)
			return obj:ClearAllChildren(...)
		end

		function tbl:GetAttributeChangedSignal(...)
			return obj:GetAttributeChangedSignal(...)
		end

		function tbl:FindFirstDescendant(...)
			return obj:FindFirstDescendant(...)
		end

		function tbl:GetAttributes(...)
			return obj:GetAttributes(...)
		end

		function tbl:IsPropertyModified(...)
			return obj:IsPropertyModified(...)
		end

		function tbl:ResetPropertyToDefault(...)
			return obj:ResetPropertyToDefault(...)
		end

		function tbl:GetActor(...)
			return obj:GetActor(...)
		end

		function tbl:GetStyled(...)
			return obj:GetStyled(...)
		end

		function tbl:RemoveTag(...)
			return obj:RemoveTag(...)
		end

		function tbl:IsDescendantOf(...)
			return obj:IsDescendantOf(...)
		end

		function tbl:FindFirstAncestorOfClass(...)
			return obj:FindFirstAncestorOfClass(...)
		end

		-- Child events

		obj.ChildAdded:Connect(function(child)
			tbl[child.Name] = child
		end)

		obj.ChildRemoved:Connect(function(child)
			tbl[child.Name] = nil
		end)

		obj.Changed:Connect(function(property)
			tbl[property] = obj[property]
		end)

		-- Events

		tbl.ChildAdded = obj.ChildAdded
		tbl.ChildRemoved = obj.ChildRemoved
		tbl.Changed = obj.Changed
		tbl.DescendantAdded = obj.DescendantAdded
		tbl.DescendantRemoving = obj.DescendantRemoving
		tbl.AncestryChanged = obj.AncestryChanged
		tbl.AttributeChanged = obj.AttributeChanged
		tbl.Destroying = obj.Destroying
		tbl.StyledPropertiesChanged = obj.StyledPropertiesChanged

		for _,v in pairs(obj:GetChildren()) do
			tbl[v.Name] = v
		end

		return tbl
	end

	local fakegame = {}

	local Players = game:GetService("Players")

	-- Properties
	fakegame.CreatorId = game.CreatorId
	fakegame.CreatorType = game.CreatorType
	fakegame.GameId = game.GameId
	fakegame.Genre = game.Genre
	fakegame.JobId = game.JobId
	fakegame.PlaceId = game.PlaceId
	fakegame.PlaceVersion = game.PlaceVersion
	if RunService:IsServer() then
		fakegame.PrivateServerId = game.PrivateServerId
		fakegame.PrivateServerOwnerId = game.PrivateServerOwnerId
	end
	fakegame.workspace = game.Workspace

	-- Functions
	function fakegame:BindToClose(...)
		return game:BindToClose(...)
	end

	function fakegame:GetJobsInfo()
		return game:GetJobsInfo()
	end

	function fakegame:GetObjects(...)
		return game:GetObjects(...)
	end

	function fakegame:IsLoaded()
		return game:IsLoaded()
	end

	function fakegame:SetPlaceId(...)
		return game:SetPlaceId(...)
	end

	function fakegame:SetUniverseId(...)
		return game:SetUniverseId(...)
	end

	function fakegame:FindService(...)
		return game:FindService(...)
	end

	-- Events
	fakegame.GraphicsQualityChangeRequest = game.GraphicsQualityChangeRequest
	fakegame.Loaded = game.Loaded
	fakegame.Close = game.Close
	fakegame.ServiceAdded = game.ServiceAdded
	fakegame.ServiceRemoving = game.ServiceRemoving

	local fakeplayers = {}

	Players.PlayerRemoving:Connect(function(v)
		fakeplayers[v.Name] = nil
	end)

	Players.PlayerAdded:Connect(function(v)
		fakeplayers[v.Name] = v
	end)

	for _, v in pairs(Players:GetPlayers()) do
		fakeplayers[v.Name] = v
	end

	-- Properties
	fakeplayers.BubbleChat = Players.BubbleChat
	fakeplayers.CharacterAutoLoads = Players.CharacterAutoLoads
	fakeplayers.ClassicChat = Players.ClassicChat
	fakeplayers.LocalPlayer = Players.LocalPlayer
	fakeplayers.MaxPlayers = Players.MaxPlayers
	fakeplayers.PreferredPlayers = Players.PreferredPlayers
	fakeplayers.RespawnTime = Players.RespawnTime
	fakeplayers.ClassName = Players.ClassName
	fakeplayers.Parent = fakegame

	-- Events
	fakeplayers.PlayerAdded = Players.PlayerAdded
	fakeplayers.PlayerRemoving = Players.PlayerRemoving
	fakeplayers.PlayerMembershipChanged = Players.PlayerMembershipChanged
	fakeplayers.UserSubscriptionStatusChanged = Players.UserSubscriptionStatusChanged

	-- Functions
	function fakeplayers:Chat(message)
		return Players:Chat(message)
	end

	function fakeplayers:GetPlayerByUserId(userId)
		return Players:GetPlayerByUserId(userId)
	end

	function fakeplayers:GetPlayerFromCharacter(Character)
		local Player = game:GetService("Players"):GetPlayerFromCharacter(Character)
		if Player then
			return Player
		elseif Character and typeof(Character) == "Instance" and Character:IsA("Model") and Character:FindFirstChildWhichIsA("Humanoid") then
			local FakePlayer = {}
			FakePlayer = Instanceify(Players, FakePlayer)
			FakePlayer.ClassName = "Player"
			FakePlayer.Name = Character.Name
			FakePlayer.UserId = -1
			FakePlayer.AccountAge = 0
			FakePlayer.Character = Character
			FakePlayer.Backpack = Instance.new("Folder")
			FakePlayer.PlayerGui = Instance.new("Folder")
			FakePlayer.PlayerScripts = Instance.new("Folder")
			FakePlayer.Team = nil
			FakePlayer.TeamColor = BrickColor.new("White")
			FakePlayer.MembershipType = Enum.MembershipType.None
			FakePlayer.Neutral = true
			FakePlayer.Parent = fakeplayers
			FakePlayer.Attributes = {}
			FakePlayer.Archivable = true
			FakePlayer.CharacterAppearanceId = -1
			FakePlayer.FollowUserId = 0
			FakePlayer.CanLoadCharacterAppearance = false
			FakePlayer.GameplayPaused = false
			FakePlayer.DevComputerMovementMode = Enum.DevComputerMovementMode.UserChoice
			FakePlayer.DevTouchMovementMode = Enum.DevTouchMovementMode.UserChoice
			FakePlayer.CameraMaxZoomDistance = 400
			FakePlayer.CameraMinZoomDistance = 0.5
			FakePlayer.CameraMode = Enum.CameraMode.Classic
			FakePlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
			FakePlayer.DevComputerCameraMode = Enum.DevComputerCameraMovementMode.UserChoice
			FakePlayer.DevEnableMouseLock = true
			FakePlayer.DevTouchCameraMode = Enum.DevTouchCameraMovementMode.UserChoice
			FakePlayer.HealthDisplayDistance = 100
			FakePlayer.NameDisplayDistance = 100
			FakePlayer.AutoJumpEnabled = true

			-- Events
			FakePlayer.Chatted = Instance.new("BindableEvent").Event
			FakePlayer.CharacterAdded = Instance.new("BindableEvent").Event
			FakePlayer.CharacterRemoving = Instance.new("BindableEvent").Event
			FakePlayer.Idled = Instance.new("BindableEvent").Event
			FakePlayer.OnTeleport = Instance.new("BindableEvent").Event

			-- Functions

			function FakePlayer:IsA(className)
				return className == "Player"
			end

			function FakePlayer:IsDescendantOf(instance)
				return instance == fakeplayers
			end

			function FakePlayer:IsAncestorOf(instance)
				local currentInstance = self
				while true do
					if currentInstance == instance then
						return true
					end
					currentInstance = currentInstance.Parent
					if currentInstance == nil then
						return false
					end
				end
			end

			function FakePlayer:LoadCharacter()
				-- uhhhhh
			end

			function FakePlayer:Kick(reason)
				warn("NPC " .. self.Name .. " was kicked. Reason: " .. (reason or "No reason provided."))
				self.Character:Destroy()
			end

			function FakePlayer:SetAttribute(attribute, value)
				if not self.Attributes then self.Attributes = {} end
				self.Attributes[attribute] = value
			end

			function FakePlayer:GetAttribute(attribute)
				return self.Attributes and self.Attributes[attribute] or nil
			end

			function FakePlayer:HasAppearanceLoaded()
				return true
			end

			function FakePlayer:RequestStreamAroundAsync()
				return true
			end

			function FakePlayer:GetNetworkPing()
				return math.random(50, 150)
			end

			function FakePlayer:GetFriendsOnline()
				return {} -- womp womp
			end

			function FakePlayer:CanLoadCharacterAppearance()
				return false
			end

			function FakePlayer:SetSuperSafeChat(value)
				self.SuperSafeChat = value
			end

			function FakePlayer:GetSuperSafeChat()
				return self.SuperSafeChat or false
			end

			function FakePlayer:Move()
			end

			function FakePlayer:LoadData()
				return {}
			end

			function FakePlayer:SaveData()
				return true
			end

			function FakePlayer:GetChildren(...)
				return {self.Backpack, self.PlayerGui, self.PlayerScripts}
			end

			return FakePlayer
		end
	end

	function fakeplayers:GetPlayers()
		return Players:GetPlayers()
	end

	function fakeplayers:SetChatStyle(...)
		return Players:SetChatStyle(...)
	end

	function fakeplayers:TeamChat(...)
		return Players:TeamChat(...)
	end

	function fakeplayers:BanAsync(...)
		return Players:BanAsync(...)
	end

	function fakeplayers:CreateHumanoidModelFromDescription(...)
		return Players:CreateHumanoidModelFromDescription(...)
	end

	function fakeplayers:CreateHumanoidModelFromUserId(...)
		return Players:CreateHumanoidModelFromUserId(...)
	end

	function fakeplayers:GetBanHistoryAsync(...)
		return Players:GetBanHistoryAsync(...)
	end

	function fakeplayers:GetCharacterAppearanceInfoAsync(...)
		return Players:GetCharacterAppearanceInfoAsync(...)
	end

	function fakeplayers:GetFriendsAsync(...)
		return Players:GetFriendsAsync(...)
	end

	function fakeplayers:GetHumanoidDescriptionFromOutfitId(...)
		return Players:GetHumanoidDescriptionFromOutfitId(...)
	end

	function fakeplayers:GetHumanoidDescriptionFromUserId(...)
		return Players:GetHumanoidDescriptionFromUserId(...)
	end

	function fakeplayers:GetNameFromUserIdAsync(...)
		return Players:GetNameFromUserIdAsync(...)
	end

	function fakeplayers:GetUserIdFromNameAsync(...)
		return Players:GetUserIdFromNameAsync(...)
	end

	function fakeplayers:GetUserThumbnailAsync(...)
		return Players:GetUserThumbnailAsync(...)
	end

	function fakeplayers:UnbanAsync(...)
		return Players:UnbanAsync(...)
	end

	fakeplayers = Instanceify(Players, fakeplayers)
	fakegame = Instanceify(game, fakegame)

	function fakegame:GetService(servicename)
		if servicename ~= "Players" then
			return game:GetService(servicename)
		else
			return fakeplayers
		end
	end
	
	local co = debug.info(2, "f") 

	customenv["game"] = fakegame

	setfenv(co, customenv)

	local function GetDescendants(tbl)
		local descendants = {}

		local function recurse(subTable)
			for key, value in pairs(subTable) do
				table.insert(descendants, value)
				if type(value) == "table" then
					recurse(value)
				end
			end
		end

		recurse(tbl)
		return descendants
	end
	
	local function HandleFn(v)
		local fnName, fn = debug.info(v, "nf")
		if string.find(string.lower(fnName), "tag") then
			--print("found "..fnName)
			local env = getfenv(3)

			env[fnName] = function(...)
				local tbl = {...}

				for i,v in pairs(tbl) do
					if typeof(v) == "table" then
						tbl[i] = nil
					end
				end

				return fn(unpack(tbl))
			end

			setfenv(co, env)
		end
	end

	local env = getfenv(co)
	local scr = env.script

	env["require"] = function(v1)
		if v1 ~= script then
			return require(v1)
		else
			local customapi = api
			function customapi:SetupEnv()
				-- do not run it again
			end

			return customapi
		end
	end

	setfenv(co, env)

	--coroutine.resume(co)
	Change = {}
	local Folder = Instance.new("Folder")
	Folder.Name = "_GLOBALS"
	Folder.Parent = scr
	local Functions = Instance.new("Folder")
	Functions.Name = "_FUNCTIONS"
	Functions.Parent = scr
	local bind = Instance.new("BindableFunction")
	bind.Name = "SetGlobal"
	bind.Parent = Functions
	bind.OnInvoke = function(key, value, folder)
		Change[key] = {[1] = folder, [2] = value}
	end

	local function TrackGlobals(env, Folder, traceback)
		for i,v in pairs(env) do
			if not Folder:FindFirstChild(i) then
				if typeof(v) == "function" then
					local bind = Instance.new("BindableFunction")
					bind.OnInvoke = v
					bind.Name = i
					bind.Parent = Folder
					local line, pc, a, source = debug.info(v, "las")
					local n = Instance.new("StringValue")
					n.Value = line
					n.Name = "Line"
					n.Parent = bind
					local n2 = Instance.new("StringValue")
					n2.Value = tostring(pc)
					n2.Name = "Parameters"
					n2.Parent = bind
					local n3 = Instance.new("StringValue")
					n3.Value = tostring(a)
					n3.Name = "Arity"
					n3.Parent = bind
					local n4 = Instance.new("StringValue")
					n4.Value = tostring(source)
					n4.Name = "ScriptSource"
					n4.Parent = bind
					HandleFn(v)
					continue
				elseif typeof(v) == "table" then
					local TableFolder = Instance.new("Folder")
					TableFolder.Name = i
					TableFolder.Parent = Folder
					traceback[#traceback + 1] = i
					TrackGlobals(v, TableFolder, traceback)
					continue
				elseif typeof(v) == "RBXScriptConnection" then
					local n = Instance.new("StringValue")
					n.Value = tostring(v)
					n.Name = i
					n.Parent = Folder
					continue
				elseif typeof(v) == "RBXScriptSignal" then
					local n = Instance.new("StringValue")
					n.Value = tostring(v)
					n.Name = i
					n.Parent = Folder
					continue
				elseif typeof(v) == "EnumItem" then
					local value = v
					local name = tostring(i)
					local n = Instance.new(typeToValueType[typeof(v)] or "StringValue")
					n.Name = name
					n.Value = value.Name
					n.Parent = Folder
					continue
				end
				local value = v
				local name = tostring(i)
				local n = Instance.new(typeToValueType[typeof(v)] or "StringValue")
				n.Name = name
				n.Value = value
				n.Parent = Folder
			else
				if typeof(v) ~= "function" and typeof(v) ~= "table" and typeof(v) ~= "RBXScriptConnection" then
					if Change[i] and Change[i][1] == Folder then
						if #traceback > 0 then
							local tbl = env

							for _,v in pairs(traceback) do
								tbl = tbl[v]
							end

							tbl[i] = Change[i][2]
							setfenv(co, env)
						else
							env[i] = Change[i][2]
							setfenv(co, env)
						end

						Change[i] = nil
					else
						Folder:FindFirstChild(i).Value = v
					end
				end
			end
		end
	end

	task.spawn(function()
		while task.wait() do
			TrackGlobals(getfenv(co), Folder, {})
		end
	end)
end

return api
