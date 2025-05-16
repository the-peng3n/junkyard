-- Gui to Lua
-- Version: 3.2

-- Instances:

local HiddenUi = Instance.new("ScreenGui")
local activitynotifier = Instance.new("TextLabel")
local reset = Instance.new("TextButton")
local deletetion = Instance.new("ImageButton")

--Properties:

HiddenUi.Name = "HiddenUi"
HiddenUi.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
HiddenUi.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HiddenUi.ResetOnSpawn = false

activitynotifier.Name = "activitynotifier"
activitynotifier.Parent = HiddenUi
activitynotifier.Active = true
activitynotifier.AnchorPoint = Vector2.new(0, 1)
activitynotifier.BackgroundColor3 = Color3.fromRGB(176, 147, 100)
activitynotifier.BorderColor3 = Color3.fromRGB(153, 128, 87)
activitynotifier.BorderSizePixel = 5
activitynotifier.Position = UDim2.new(0.429378539, 0, 0.0432525948, 0)
activitynotifier.Size = UDim2.new(0, 200, 0, 50)
activitynotifier.Font = Enum.Font.Fantasy
activitynotifier.Text = "ACTIVE"
activitynotifier.TextColor3 = Color3.fromRGB(0, 0, 0)
activitynotifier.TextScaled = true
activitynotifier.TextSize = 14.000
activitynotifier.TextWrapped = true

reset.Name = "reset"
reset.Parent = HiddenUi
reset.BackgroundColor3 = Color3.fromRGB(176, 147, 100)
reset.BorderColor3 = Color3.fromRGB(153, 128, 87)
reset.BorderSizePixel = 5
reset.Position = UDim2.new(0.463983059, 0, 0.0484429076, 0)
reset.Size = UDim2.new(0, 101, 0, 37)
reset.Font = Enum.Font.Fantasy
reset.Text = "Reset?"
reset.TextColor3 = Color3.fromRGB(0, 0, 0)
reset.TextSize = 23.000

deletetion.Name = "deletetion"
deletetion.Parent = HiddenUi
deletetion.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
deletetion.BorderColor3 = Color3.fromRGB(153, 128, 87)
deletetion.BorderSizePixel = 5
deletetion.Position = UDim2.new(0.57062149, 0, 0, 0)
deletetion.Size = UDim2.new(0, 11, 0, 50)
deletetion.ImageColor3 = Color3.fromRGB(255, 0, 0)

-- Scripts:

local function MBEUMB_fake_script() -- HiddenUi.AddClickDetectors 
	local script = Instance.new('LocalScript', HiddenUi)

	-- Services
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local ProximityPromptService = game:GetService("ProximityPromptService") -- Ensure service is available
	
	local LocalPlayer = Players.LocalPlayer
	
	-- Button References
	local refreshButton = script.Parent:FindFirstChildOfClass("TextButton") -- This should find "reset"
	if not refreshButton then
		warn("AddClickDetectors: Refresh button (TextButton) not found as a sibling of this script.")
	end
	
	local deletionButton = script.Parent:FindFirstChild("deletetion") -- Find the ImageButton by its Name property
	if not deletionButton then
	    warn("AddClickDetectors: Deletion button (ImageButton named 'deletetion') not found as a sibling of this script.")
	end
	
	-- Unique attribute name to mark ProximityPrompts processed by this teleport logic
	local TELEPORT_LOGIC_PROCESSED_ATTRIBUTE = "AddTeleportProximityPrompts_TeleportLogicProcessed"
	
	local function addProximityPromptToPart(part)
		-- Check if the part belongs to any player's character
		local currentAncestor = part
		while currentAncestor and currentAncestor ~= Workspace do
			if currentAncestor:IsA("Model") and Players:GetPlayerFromCharacter(currentAncestor) then
				return -- This part belongs to a player character, so do not add a prompt
			end
			currentAncestor = currentAncestor.Parent
		end
	    -- If the part itself is a character model directly under Workspace (e.g. StarterCharacter loaded)
	    if part:IsA("Model") and Players:GetPlayerFromCharacter(part) and part.Parent == Workspace then
	        return
	    end
	
		if part:IsA("BasePart") then -- Check if it's a BasePart
			local proximityPrompt = part:FindFirstChildOfClass("ProximityPrompt")
			if not proximityPrompt then
				proximityPrompt = Instance.new("ProximityPrompt")
				proximityPrompt.ObjectText = part.Name or "Part"
				proximityPrompt.ActionText = "Teleport"
				proximityPrompt.RequiresLineOfSight = false -- Allow triggering without direct line of sight
				proximityPrompt.Parent = part
			end
	
			-- Check if this ProximityPrompt instance has already had the teleport logic connected
			if proximityPrompt:GetAttribute(TELEPORT_LOGIC_PROCESSED_ATTRIBUTE) then
				return -- Already processed, do nothing to avoid multiple connections
			end
	
			proximityPrompt.Triggered:Connect(function(playerWhoTriggered)
				-- Since this is a LocalScript, playerWhoTriggered will be LocalPlayer
				if playerWhoTriggered ~= LocalPlayer then return end
	
				-- Define the target CFrame directly
				-- CFrame components: x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22
				local targetCFrame = CFrame.new(-1545.5, 175.063446, 0, 0, 0, 1, 0, -1, 0, 1, 0, 0)
				
				-- Safely attempt to move the part
				local success, err = pcall(function()
					part:PivotTo(targetCFrame)
				end)
				if not success then
					warn("Failed to PivotTo part " .. part:GetFullName() .. " to " .. tostring(targetCFrame) .. ": " .. err)
				end
			end)
			
			-- Mark this ProximityPrompt as having the teleport logic connected
			proximityPrompt:SetAttribute(TELEPORT_LOGIC_PROCESSED_ATTRIBUTE, true)
		end
	end
	
	-- Function to iterate through all descendants and add ProximityPrompts/connect logic
	local function processInstance(instance)
		addProximityPromptToPart(instance) -- Check the instance itself
	
		for _, child in instance:GetChildren() do
			processInstance(child) -- Recursively process children
		end
	end
	
	-- Function to delete all ProximityPrompts managed by this script
	local function deleteAllTeleportPrompts()
		local count = 0
		for _, descendant in Workspace:GetDescendants() do
			if descendant:IsA("ProximityPrompt") and descendant:GetAttribute(TELEPORT_LOGIC_PROCESSED_ATTRIBUTE) == true then
				descendant:Destroy()
				count = count + 1
			end
		end
		print("AddClickDetectors: Deleted " .. count .. " managed ProximityPrompts.")
	end
	
	-- Function to refresh all prompts: delete existing ones and re-add to all parts
	local function refreshAllPrompts()
		print("AddClickDetectors: Refreshing all ProximityPrompts...")
		deleteAllTeleportPrompts()
		processInstance(Workspace)
		print("AddClickDetectors: Refresh complete.")
	end
	
	-- Function to handle the deletion button click
	local function onDeletionButtonClick()
	    print("AddClickDetectors: Deletion button clicked.")
	    deleteAllTeleportPrompts() -- Delete all managed proximity prompts
	
	    -- Delete the button's parent (which is the ScreenGui, also script.Parent)
	    if script.Parent then -- Check if script.Parent (the ScreenGui) still exists
	        print("AddClickDetectors: Destroying ScreenGui: " .. script.Parent:GetFullName())
	        script.Parent:Destroy()
	    else
	        warn("AddClickDetectors: ScreenGui (script.Parent) not found to destroy for deletion action.")
	    end
	end
	
	-- Connect refresh button click to the refresh function
	if refreshButton then
		refreshButton.MouseButton1Click:Connect(refreshAllPrompts)
	else
	    warn("AddClickDetectors: Refresh button not found, so click event cannot be connected.")
	end
	
	-- Connect deletion button click to its handler function
	if deletionButton then
	    deletionButton.MouseButton1Click:Connect(onDeletionButtonClick)
	else
	    warn("AddClickDetectors: Deletion button ('deletetion') not found, so click event cannot be connected.")
	end
	
	-- Process existing parts in Workspace on script start
	print("AddClickDetectors: Initial processing of Workspace for ProximityPrompts...")
	processInstance(Workspace)
	print("AddClickDetectors: Initial processing complete.")
	
	-- Connect to DescendantAdded to handle parts added later
	Workspace.DescendantAdded:Connect(function(descendant)
		-- When a new descendant is added, process it (and its children if it's a model)
	    -- This ensures that if a model with multiple parts is added, all get processed.
		processInstance(descendant)
	end)
	
	print("AddClickDetectors script loaded and running.")
	
	
end
coroutine.wrap(MBEUMB_fake_script)()
