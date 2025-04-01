local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")
local UIEffects = require(game:GetService("ReplicatedStorage").Modules.UI.UIEffects)

local PickupRemote = game:GetService("ReplicatedStorage").Remotes.Pickup

-- PARAMETERS
local DROP_LIFETIME = 20
local DROPS_AMOUNT = 10

-- LOCAL VARIABLES
local toPlayerTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local posUpTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local posDownTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
local trailTransSequence = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0)
}
local trailColorSequence = ColorSequence.new(Color3.fromHex("#7d7d7d"))

local DropsHandler = {}

DropsHandler.Drops = {
	Yen = {
		Name = "Yen",
		Icon = "" -- asset id
	}
}

function DropsHandler.Drop(entity: Model, dropType, amount, uuid)
	local loc = entity.PrimaryPart.Position
	local rayDirection = Vector3.new(0, -25, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {entity}
	
	local raycastResult = workspace:Raycast(loc, rayDirection, raycastParams)
	if not raycastResult then 
		warn("No raycast for drop found?")
		raycastResult = -1
	else
		raycastResult = raycastResult.Distance
	end
	
	local att0 = Instance.new("Attachment")
	local att1 = Instance.new("Attachment")
	att1.Position = Vector3.new(0, 0, 0.22)
	
	local Trail = Instance.new("Trail")
	Trail.Color = trailColorSequence
	Trail.Transparency = trailTransSequence
	Trail.Lifetime = 0.1
	
	local dropPart = Instance.new("Part")
	dropPart.Name = "Drop"
	dropPart.Size = Vector3.new(3, 1, 3)
	dropPart.CanCollide = false
	dropPart.Transparency = 1
	dropPart.Anchored = true
	dropPart.Position = loc
	dropPart:SetAttribute("UUID", uuid)
	dropPart:SetAttribute("Amount", amount/DROPS_AMOUNT)
	
	local dropBillboard = Instance.new("BillboardGui")
	dropBillboard.Name = "DropGUI"
	dropBillboard.Size = UDim2.fromScale(0.7, 0.7)
	dropBillboard.AlwaysOnTop = false
	dropBillboard.MaxDistance = 60
	
	local dropImage = Instance.new("ImageLabel")
	dropImage.Name = "Icon"
	dropImage.BackgroundTransparency = 1
	dropImage.Size = UDim2.fromScale(1, 1)
	dropImage.ScaleType = Enum.ScaleType.Fit
	dropImage.Image = dropType.Icon
	
	local dropFrame = Instance.new("Frame")
	dropFrame.Name = dropPart.Name
	dropFrame.BackgroundTransparency = 1
	dropFrame.Position = UDim2.fromScale(math.random(0, 10)/10, math.random(-1, 5)/10)
	dropFrame.Size = UDim2.new(0.02, 0, 0.05, 0)
	dropFrame.Visible = false
	
	local dropFrameImg = Instance.new("ImageLabel")
	dropFrameImg.Name = "Icon"
	dropFrameImg.Size = UDim2.fromScale(1, 1)
	dropFrameImg.BackgroundTransparency = 1
	dropFrameImg.ScaleType = Enum.ScaleType.Fit
	dropFrameImg.Image = dropType.Icon
	dropFrameImg.Position = UDim2.new(0, 0, -0.11, 0)
	
	local dropFrameText = Instance.new("TextLabel")
	dropFrameText.BackgroundTransparency = 1
	dropFrameText.Size = UDim2.fromScale(0.7, 0.4)
	dropFrameText.Position = UDim2.fromScale(0.15, 0.7)
	dropFrameText.TextScaled = true
	dropFrameText.TextColor3 = Color3.fromHex("#ffffff")
	dropFrameText.Font = Enum.Font.FredokaOne
	dropFrameText.TextStrokeTransparency = 0
	dropFrameText.Text = string.format("+%.1f", amount/DROPS_AMOUNT)
	
	for i=1, DROPS_AMOUNT, 1 do
		local xOffset = math.random(-5, 5)
		local zOffset = math.random(-5, 5)
		
		local c_att0 = att0:Clone()
		local c_att1 = att1:Clone()
		local c_trail = Trail:Clone()
		local c_dropPart = dropPart:Clone()
		local c_dropBillboard = dropBillboard:Clone()
		local c_dropImage = dropImage:Clone()
		
		local posUpTween = TweenService:Create(c_dropPart, posUpTweenInfo, {Position = c_dropPart.Position + Vector3.new(xOffset/3, 1, zOffset/3)})
		local posDownTween = TweenService:Create(c_dropPart, posDownTweenInfo, {Position = c_dropPart.Position + Vector3.new(xOffset, -raycastResult, zOffset)})
		
		c_dropPart.Parent = workspace.Map.Drops
		c_att0.Parent = c_dropPart
		c_att1.Parent = c_dropPart
		c_trail.Attachment0 = c_att0
		c_trail.Attachment1 = c_att1
		c_trail.Parent = c_dropPart
		c_dropBillboard.Parent = c_dropPart
		c_dropImage.Parent = c_dropBillboard
		
		posUpTween:Play()
		posUpTween.Completed:Connect(function(playbackState: Enum.PlaybackState)
			posDownTween:Play()
		end)
		
		task.delay(0.3, function()
			local connection
			local plr = game.Players.LocalPlayer
			
			connection = c_dropPart.Touched:Connect(function(touchedPart: BasePart)
				if touchedPart:IsDescendantOf(plr.Character) then
					connection:Disconnect()
					
					task.spawn(function()
						local toPlayerTween = TweenService:Create(c_dropPart, toPlayerTweenInfo, {Position = plr.Character.PrimaryPart.Position})

						toPlayerTween:Play()
					end)
					
					local c_dropFrame = dropFrame:Clone()
					local c_dropFrameImg = dropFrameImg:Clone()
					local c_dropFrameText = dropFrameText:Clone()
					
					task.delay(0.2, function()
						c_dropPart:Destroy()
					end)
					
					c_dropFrame.Parent = plr.PlayerGui.Drops.Zone
					c_dropFrameImg.Parent = dropFrame
					c_dropFrameText.Parent = dropFrame
					
					UIEffects.ShowGUI(dropFrame, UDim2.fromScale(0.02, 0.05), UDim2.fromScale(0.04, 0.1))
					PickupRemote:FireServer(c_dropPart:GetAttribute("UUID"))
					DebrisService:AddItem(dropFrame, 2)
				end
			end)
		end)
		
		DebrisService:AddItem(c_dropPart, DROP_LIFETIME)
	end
end

return DropsHandler
