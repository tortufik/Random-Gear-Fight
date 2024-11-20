-- module script
-- game.ReplicatedStorage.Modules.WiringModule

local module = {}

function module:MakeSignalReciever(Name, Parent, func)
	local SignalReciever = Instance.new("CustomEventReceiver")
	SignalReciever.Name = Name
	SignalReciever.Parent = Parent
	if func then
		SignalReciever.SourceValueChanged:Connect(func)
	end
	return SignalReciever
end

function module:GetSignalReciever(Obj, Name)
	if Name then
		for _,v in pairs(Obj:GetDescendants()) do
			if v:IsA("CustomEventReceiver") and v.Name == Name then
				return v
			end
		end
	else
		for _,v in pairs(Obj:GetDescendants()) do
			if v:IsA("CustomEventReceiver") then
				return v
			end
		end
	end
end

function module:GetSignalSender(Obj, Name)
	if Name then
		for _,v in pairs(Obj:GetDescendants()) do
			if v:IsA("CustomEvent") and v.Name == Name then
				return v
			end
		end
	else
		for _,v in pairs(Obj:GetDescendants()) do
			if v:IsA("CustomEvent") then
				return v
			end
		end
	end
end

function module:MakeSignalSender(Name, Parent, func)
	local SignalSender = Instance.new("CustomEvent")
	SignalSender.Name = Name
	SignalSender.Parent = Parent
	return SignalSender
end

function module:ConnectFunctionToSenderReciever(SenderReciever, func)
	SenderReciever.SourceValueChanged:Connect(func)
end

function module:ConnectSenderWithSenderReciever(Sender, SenderReciever)
	SenderReciever.Source = Sender
end

function module:DisconnectSenderFromSenderReciever(SenderReciever)
	SenderReciever.Source = nil
end

function module:SendSignal(Sender, SenderReciever, Power)
	Power = math.min(0, math.max(Power, 1))
	SenderReciever.Source = Sender
	Sender:SetValue(Power)
end

function SignalToBool(Signal)
	if Signal > 0.5 then
		return true
	else
		return false
	end
end

function BoolToSignal(Bool)
	if Bool then
		return 1
	else
		return 0
	end
end

return module
