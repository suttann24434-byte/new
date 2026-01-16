-- =========================================================
-- UNIVERSAL AIMLOCK CONTROLLER (FINAL + FIX 1 SAFU)
-- UI FULL | STICKY LOCK | SMART VEHICLE PRIORITY | NO ESP
-- AUTO UNLOCK JIKA KAMERA DITARIK
-- =========================================================

-- ================= SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- ================= REFS =================
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================= CONFIG =================
local AIM_RADIUS = 400
local AIM_SPEED  = 0.45
local LOCK_PART  = "Head"

local USE_CAM_HEIGHT = true
local CAM_HEIGHT = 2
local SCREEN_TILT = -4

local USE_FRIEND_FILTER = true
local USE_FACE_TARGET = false
local USE_STEALTH_MODE = false

local TOGGLE_KEY = Enum.KeyCode.V

-- ================= FINAL LOCK CONFIG =================
local STICKY_LOCK  = true
local STICKY_BONUS = 0.06
local SWITCH_DELAY = 0.04
local MIN_DOT_FOV  = 0.6

-- VEHICLE PRIORITY (AKTIF CUMA SAAT LU PENUMPANG)
local VEHICLE_BONUS_PASSENGER = 0.35
local VEHICLE_BONUS_DRIVER    = 0.2

-- ================= FIX 1 CONFIG =================
-- AUTO UNLOCK JIKA KAMERA DITARIK
local MANUAL_BREAK_DOT = 0.50

-- ================= STATE =================
local aiming = false
local targetPart = nil
local holdTime = 0

local function clearTarget()
	targetPart = nil
	holdTime = 0
end

-- ================= GUI PROTECTION =================
local ProtectedFolder = Instance.new("Folder")
ProtectedFolder.Name = "RobloxGui"
ProtectedFolder.Parent = CoreGui

local function Protect(inst)
	if not inst then return end
	local HiddenUI = gethui or gethiddenui or get_hidden_ui or get_hui or get_h_ui
	inst.Parent = (HiddenUI and HiddenUI()) or cloneref(ProtectedFolder)
	inst.Name = HttpService:GenerateGUID(false)
end

-- ================= GUI ROOT =================
local gui = Instance.new("ScreenGui")
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
pcall(function()
	gui.Parent = gethui and gethui() or CoreGui
end)
if not gui.Parent then
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
Protect(gui)

-- ================= SAFE FRAME =================
local SafeFrame = Instance.new("Frame", gui)
SafeFrame.Size = UDim2.fromScale(1,1)
SafeFrame.BackgroundTransparency = 1
Instance.new("UIPadding",SafeFrame).PaddingTop = UDim.new(0,90)

-- ================= MAIN PANEL =================
local main = Instance.new("Frame", SafeFrame)
main.Size = UDim2.new(0,300,0,95)
main.Position = UDim2.new(0.5,0,0,20)
main.AnchorPoint = Vector2.new(0.5,0)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.Active = true
main.Draggable = true
Instance.new("UICorner",main).CornerRadius = UDim.new(0,14)

local title = Instance.new("TextLabel", main)
title.Text = "Pengontrol Aimlock"
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Position = UDim2.new(0,12,0,6)
title.Size = UDim2.new(1,-50,0,26)
title.TextXAlignment = Enum.TextXAlignment.Left

local setBtn = Instance.new("TextButton", main)
setBtn.Text = "⚙"
setBtn.Font = Enum.Font.GothamBold
setBtn.TextSize = 18
setBtn.Size = UDim2.new(0,34,0,34)
setBtn.Position = UDim2.new(1,-42,0,6)
setBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
Instance.new("UICorner",setBtn).CornerRadius = UDim.new(1,0)

local aimBtn = Instance.new("TextButton", main)
aimBtn.Size = UDim2.new(0.7,0,0,36)
aimBtn.Position = UDim2.new(0,12,0,46)
aimBtn.Text = "AIMBOT: NONAKTIF"
aimBtn.Font = Enum.Font.GothamBold
aimBtn.TextSize = 16
aimBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
aimBtn.TextColor3 = Color3.fromRGB(180,180,180)
Instance.new("UICorner",aimBtn).CornerRadius = UDim.new(0,10)

local dot = Instance.new("Frame", main)
dot.Size = UDim2.new(0,16,0,16)
dot.Position = UDim2.new(1,-38,0,52)
dot.BackgroundColor3 = Color3.fromRGB(150,0,0)
Instance.new("UICorner",dot).CornerRadius = UDim.new(1,0)

-- ================= MINI AIM =================
local mini = Instance.new("TextButton", SafeFrame)
mini.Size = UDim2.new(0,52,0,52)
mini.Position = UDim2.new(0.88,0,0.55,0)
mini.Text = "AIM"
mini.Font = Enum.Font.GothamBold
mini.TextSize = 16
mini.TextColor3 = Color3.new(1,1,1)
mini.BackgroundColor3 = Color3.fromRGB(150,0,0)
mini.Active = true
mini.Draggable = true
mini.ZIndex = 999
Instance.new("UICorner",mini).CornerRadius = UDim.new(1,0)

-- ================= SETTINGS PANEL =================
local settings = Instance.new("Frame", SafeFrame)
settings.Size = UDim2.new(0,300,0,0)
settings.Position = UDim2.new(0.5,0,0,125)
settings.AnchorPoint = Vector2.new(0.5,0)
settings.BackgroundColor3 = Color3.fromRGB(25,25,25)
settings.Visible = false
settings.ClipsDescendants = true
settings.Active = true
settings.Draggable = true
Instance.new("UICorner",settings).CornerRadius = UDim.new(0,14)

local pad = Instance.new("UIPadding",settings)
pad.PaddingTop = UDim.new(0,10)
pad.PaddingLeft = UDim.new(0,10)
pad.PaddingRight = UDim.new(0,10)

local list = Instance.new("UIListLayout",settings)
list.Padding = UDim.new(0,8)

-- ================= UI BUILDERS =================
local function makeToggle(text, state, callback)
	local btn = Instance.new("TextButton",settings)
	btn.Size = UDim2.new(1,0,0,32)
	btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner",btn).CornerRadius = UDim.new(0,8)

	local value = state
	btn.Text = text..": "..(value and "AKTIF" or "NONAKTIF")

	btn.MouseButton1Click:Connect(function()
		value = not value
		btn.Text = text..": "..(value and "AKTIF" or "NONAKTIF")
		callback(value)
	end)
end

local function makeStepper(text, min, max, step, value, callback)
	local f = Instance.new("Frame",settings)
	f.Size = UDim2.new(1,0,0,34)
	f.BackgroundTransparency = 1

	local lbl = Instance.new("TextLabel",f)
	lbl.Size = UDim2.new(0.55,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextColor3 = Color3.new(1,1,1)
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local minus = Instance.new("TextButton",f)
	minus.Size = UDim2.new(0,30,0,30)
	minus.Position = UDim2.new(0.6,0,0,2)
	minus.Text = "-"
	minus.TextSize = 18
	minus.BackgroundColor3 = Color3.fromRGB(50,50,50)
	Instance.new("UICorner",minus)

	local plus = Instance.new("TextButton",f)
	plus.Size = UDim2.new(0,30,0,30)
	plus.Position = UDim2.new(0.75,0,0,2)
	plus.Text = "+"
	plus.TextSize = 18
	plus.BackgroundColor3 = Color3.fromRGB(50,50,50)
	Instance.new("UICorner",plus)

	local v = value
	local function update()
		v = math.clamp(v, min, max)
		lbl.Text = text..": "..string.format("%.2f",v)
		callback(v)
	end
	update()

	minus.MouseButton1Click:Connect(function() v -= step; update() end)
	plus.MouseButton1Click:Connect(function() v += step; update() end)
end

-- ================= SETTINGS ITEMS =================
makeStepper("Aim Speed",0.02,1.5,0.05,AIM_SPEED,function(v) AIM_SPEED=v end)
makeStepper("Aim Radius",100,1000,50,AIM_RADIUS,function(v) AIM_RADIUS=v end)
makeStepper("Camera Height",0,5,0.5,CAM_HEIGHT,function(v) CAM_HEIGHT=v end)
makeStepper("Screen Tilt",-15,15,1,SCREEN_TILT,function(v) SCREEN_TILT=v end)

makeToggle("Offset Height",USE_CAM_HEIGHT,function(v) USE_CAM_HEIGHT=v end)
makeToggle("Filter Friend",USE_FRIEND_FILTER,function(v) USE_FRIEND_FILTER=v end)
makeToggle("Face Target",USE_FACE_TARGET,function(v) USE_FACE_TARGET=v end)
makeToggle("Stealth Mode",USE_STEALTH_MODE,function(v) USE_STEALTH_MODE=v end)

-- ================= UI EVENTS =================
local function updateUI()
	aimBtn.Text = aiming and "AIMBOT: AKTIF" or "AIMBOT: NONAKTIF"
	aimBtn.TextColor3 = aiming and Color3.fromRGB(0,220,0) or Color3.fromRGB(180,180,180)
	dot.BackgroundColor3 = aiming and Color3.fromRGB(0,220,0) or Color3.fromRGB(150,0,0)
	mini.BackgroundColor3 = aiming and Color3.fromRGB(0,200,0) or Color3.fromRGB(150,0,0)
end
updateUI()

aimBtn.MouseButton1Click:Connect(function()
	aiming = not aiming
	clearTarget()
	updateUI()
end)

mini.MouseButton1Click:Connect(function()
	aiming = not aiming
	clearTarget()
	updateUI()
end)

setBtn.MouseButton1Click:Connect(function()
	settings.Visible = not settings.Visible
	TweenService:Create(settings,TweenInfo.new(0.25),{
		Size = settings.Visible and UDim2.new(0,300,0,list.AbsoluteContentSize.Y+20) or UDim2.new(0,300,0,0)
	}):Play()
end)

UserInputService.InputBegan:Connect(function(i,p)
	if not p and i.KeyCode==TOGGLE_KEY then
		aiming = not aiming
		clearTarget()
		updateUI()
	end
end)

-- ================= STATUS CHECK =================
local function isLocalPassenger()
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildWhichIsA("Humanoid")
	return hum and hum.SeatPart and hum.SeatPart:IsA("Seat")
end

local function getEnemyVehicleType(char)
	local hum = char and char:FindFirstChildWhichIsA("Humanoid")
	if not hum or not hum.SeatPart then return nil end
	if hum.SeatPart:IsA("Seat") then
		return "Passenger"
	elseif hum.SeatPart:IsA("VehicleSeat") then
		return "Driver"
	end
end

-- ================= FINAL TARGET FINDER =================
local function findTarget()
	local bestPart = nil
	local bestScore = 0
	local camCF = Camera.CFrame
	local camPos = camCF.Position

	for _,plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer
		and (not USE_FRIEND_FILTER or not LocalPlayer:IsFriendsWith(plr.UserId)) then

			local char = plr.Character
			local hum = char and char:FindFirstChildWhichIsA("Humanoid")
			local part = char and char:FindFirstChild(LOCK_PART)

			if hum and part and hum.Health > 0 then
				local dist = (part.Position - camPos).Magnitude
				if dist <= AIM_RADIUS then
					local dir = (part.Position - camPos).Unit
					local dot = camCF.LookVector:Dot(dir)
					if dot < MIN_DOT_FOV then continue end

					local score = dot
					if STICKY_LOCK and part == targetPart then
						score += STICKY_BONUS
					end

					if isLocalPassenger() then
						local vType = getEnemyVehicleType(char)
						if vType == "Passenger" then
							score += VEHICLE_BONUS_PASSENGER
						elseif vType == "Driver" then
							score += VEHICLE_BONUS_DRIVER
						end
					end

					if score > bestScore then
						bestScore = score
						bestPart = part
					end
				end
			end
		end
	end
	return bestPart
end

-- ================= AIM LOOP (FIX 1 SUDAH MASUK) =================
RunService.RenderStepped:Connect(function(dt)
	if not aiming then return end

	-- FIX 1: AUTO UNLOCK JIKA KAMERA DITARIK
	if targetPart then
		local camDir = Camera.CFrame.LookVector
		local targetDir = (targetPart.Position - Camera.CFrame.Position).Unit
		if camDir:Dot(targetDir) < MANUAL_BREAK_DOT then
			clearTarget()
			return
		end
	end

	if targetPart then
		local hum = targetPart.Parent and targetPart.Parent:FindFirstChildWhichIsA("Humanoid")
		if not hum or hum.Health <= 0 then
			clearTarget()
		end
	end

	local newTarget = findTarget()
	if newTarget ~= targetPart then
		holdTime += dt
		if holdTime >= SWITCH_DELAY then
			targetPart = newTarget
			holdTime = 0
		end
	else
		holdTime = 0
	end

	if not targetPart then return end

	local origin = Camera.CFrame.Position
	if USE_CAM_HEIGHT then
		origin += Vector3.new(0,CAM_HEIGHT,0)
	end

	local goal = targetPart.Position
	if USE_STEALTH_MODE then
		goal += Vector3.new(
			(math.random()-0.5)*0.05,
			(math.random()-0.5)*0.05,
			(math.random()-0.5)*0.05
		)
	end

	Camera.CFrame = Camera.CFrame:Lerp(
		CFrame.new(origin,goal) * CFrame.Angles(math.rad(SCREEN_TILT),0,0),
		AIM_SPEED
	)
end)

-- ================= SAFETY RESET =================
LocalPlayer.CharacterAdded:Connect(function()
	aiming = false
	clearTarget()
	updateUI()
end)
