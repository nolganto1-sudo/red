
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer.Character

-- GUI parent (support executor)
local guiParent
pcall(function()
	if gethui then
		guiParent = gethui()
	elseif game:FindFirstChildOfClass("CoreGui") then
		guiParent = game:GetService("CoreGui")
	else
		guiParent = LocalPlayer:WaitForChild("PlayerGui")
	end
end)
if not guiParent then guiParent = LocalPlayer:WaitForChild("PlayerGui") end

-- hapus lama
if guiParent:FindFirstChild("TweenMenu") then guiParent.TweenMenu:Destroy() end

-- GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TweenMenu"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiParent

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 280)
Frame.Position = UDim2.new(0.05, 0, 0.25, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame)

local Title = Instance.new("TextLabel", Frame)
Title.Text = "Tween Controller"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true

local Button = Instance.new("TextButton", Frame)
Button.Size = UDim2.new(1, -20, 0, 35)
Button.Position = UDim2.new(0, 10, 0, 35)
Button.Text = "Auto Tween: OFF"
Button.Font = Enum.Font.GothamBold
Button.TextScaled = true
Button.TextColor3 = Color3.new(1,1,1)
Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Instance.new("UICorner", Button)

local ScrollingFrame = Instance.new("ScrollingFrame", Frame)
ScrollingFrame.Position = UDim2.new(0, 10, 0, 80)
ScrollingFrame.Size = UDim2.new(1, -20, 1, -90)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.ScrollBarThickness = 5
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", ScrollingFrame)

-- VAR
local on = false
local buttonHeight = 30
local currentTarget = nil
local lockedTarget = nil -- target manual (klik)
local currentTween
local following = false

-- fungsi cari player terdekat
local function getNearestPlayer()
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return nil, math.huge end
	local HRP = char.HumanoidRootPart
	local nearest, shortest = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (plr.Character.HumanoidRootPart.Position - HRP.Position).Magnitude
			if dist < shortest then
				shortest = dist
				nearest = plr
			end
		end
	end
	return nearest, shortest
end

-- tween ke target
local function followPlayer(targetPlayer)
	if following then return end
	following = true
	currentTarget = targetPlayer

	while on and currentTarget == targetPlayer do
		local char = LocalPlayer.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then break end
		if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then break end

		local HRP = char.HumanoidRootPart
		local targetHRP = targetPlayer.Character.HumanoidRootPart

		local offset = targetHRP.CFrame.LookVector * -4
		local targetPos = targetHRP.Position + offset
		local distance = (HRP.Position - targetPos).Magnitude

		local tweenTime = math.clamp(distance / 10, 0.4, 1.3)
		if currentTween then currentTween:Cancel() end

		local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		currentTween = TweenService:Create(HRP, tweenInfo, { CFrame = CFrame.new(targetPos, targetHRP.Position) })
		currentTween:Play()

		task.wait(tweenTime * 0.9)
	end

	following = false
end

-- loop utama
task.spawn(function()
	while true do
		if on then
			-- Kalau ada target lock manual, fokus ke dia
			if lockedTarget and lockedTarget.Parent and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
				if currentTarget ~= lockedTarget then
					task.spawn(function() followPlayer(lockedTarget) end)
				end
			else
				-- kalau gak ada lock, ambil nearest player
				local nearest, _ = getNearestPlayer()
				if nearest and nearest ~= currentTarget then
					task.spawn(function() followPlayer(nearest) end)
				end
			end
		end
		task.wait(0.3)
	end
end)

-- tombol ON/OFF
Button.MouseButton1Click:Connect(function()
	on = not on
	if on then
		Button.Text = "Auto Tween: ON"
		Button.BackgroundColor3 = Color3.fromRGB(0, 170, 85)
	else
		Button.Text = "Auto Tween: OFF"
		Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end
end)

-- daftar player
local function refreshPlayerList()
	for _, child in ipairs(ScrollingFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	local y = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local pButton = Instance.new("TextButton", ScrollingFrame)
			pButton.Size = UDim2.new(1, -10, 0, buttonHeight)
			pButton.Position = UDim2.new(0, 5, 0, y)
			pButton.Text = plr.Name
			pButton.Font = Enum.Font.GothamBold
			pButton.TextScaled = true
			pButton.TextColor3 = Color3.fromRGB(255,255,255)
			pButton.BackgroundColor3 = Color3.fromRGB(45,45,45)
			pButton.AutoButtonColor = true
			Instance.new("UICorner", pButton)
			
			pButton.MouseButton1Click:Connect(function()
				lockedTarget = plr
				currentTarget = plr
				task.spawn(function() followPlayer(plr) end)
				
				for _, btn in ipairs(ScrollingFrame:GetChildren()) do
					if btn:IsA("TextButton") then
						btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
					end
				end
				pButton.BackgroundColor3 = Color3.fromRGB(0,120,255)
			end)
			
			y += (buttonHeight + 5)
		end
	end
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, y)
end

refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)
