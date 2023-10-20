--///////////////////////////////////////////////////////////////////
--//                                                               //
--//  MADE BY WARLOCK2010 FOR HIDDENDEVS APPLICATION FOR SCRIPTER  //
--//  10/20/2023                                                   //
--//                                                               //
--///////////////////////////////////////////////////////////////////

----------------------------------------------------------------------

--SET UP ALL SERVICES

local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local repStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--Assign local player and mouse 
local player  = Players.LocalPlayer
local char = player.Character
local playerHRP = char.HumanoidRootPart
local Mouse = player:GetMouse()

--Setup main animation
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://7242495276"
local animtrack = char.Humanoid:LoadAnimation(anim)

--Setup main sound FX
local audio = Instance.new("Sound", game.Workspace)
audio.SoundId = "rbxassetid://7242453016"

--Declare debounce and conn for disconnect of RunService
local conn
local db = true

--Array for all local effects that need to be destroyed after
local allEffects = {}

--Set up player cam
player.CameraMaxZoomDistance = 14
player.CameraMinZoomDistance = 12


-------------------------------------------------------------------------------------



-- Set player orientation to face where mouse click
local function setCharOrientation()
	
	-- dedclare Player HRP position and Mouse position
	local RootPos, MousePos = playerHRP.Position, Mouse.Hit.Position
	playerHRP.CFrame = CFrame.new(RootPos, Vector3.new(MousePos.X, RootPos.Y, MousePos.Z))
	
	local MouseHit = Mouse.Hit.Position
	
	-- Fire remote event to server for camera tween and fx
	repStorage.SwordEvents.Slash:FireServer(playerHRP, MouseHit)
	
	
end

-- copy and weld sword from RepStorage to player hand
local function swordWeld()
	
	local sword = repStorage.Katana:Clone()
	sword.Parent = char

	local newWeld = Instance.new("Weld", sword.Handle)
	newWeld.Part0 = sword.Handle
	newWeld.Part1 = player.Character.RightHand
	
	
	-- insert to array as effect to be destroyed
	table.insert(allEffects, sword)
	
end

-- Tween player movement to mouse.hit direction
local function playerMovement()
	
	local ray = Ray.new(playerHRP.Position, playerHRP.CFrame.LookVector * 40)
	local _, pos = workspace:FindPartOnRay(ray, char)

	local tween = tweenService:Create(playerHRP, TweenInfo.new(.05, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos) * CFrame.Angles(0,math.rad(playerHRP.Orientation.Y),0)})
	tween:Play()

end

-- Create wind FX when slash
local function airEffects(airPos, Y, Z)
	
	-- sets the goal position of the FX to tween to
	local function setGoal(air, pos)
		
		local goal = {
			Size = air.Size * 2,
			CFrame = CFrame.new(pos) * CFrame.Angles(90,math.pi/15,0)
		}
		
		return goal
	end
	
	-- Set starting orientation of Air FX
	local function setOrientation(orientationY,orientationZ)
		local air = repStorage.MeshPart:Clone()
		air.Parent = workspace
		air.CFrame = CFrame.new(playerHRP.Position) * CFrame.Angles(0,math.rad(playerHRP.Orientation.Y * orientationY),orientationZ)
		
		return air
	end
	
	
	local air1 = setOrientation(Y,Z)

	local airTween1 = tweenService:Create(air1, TweenInfo.new(2, Enum.EasingStyle.Linear), setGoal(air1, airPos))
	airTween1:Play()
	
	-- insert to array as effect to be destroyed
	table.insert(allEffects, air1)

end

-- Create slash fx that fluctuates transparency
local function slashFx()
	
	local slash = repStorage.Slash:Clone()
	slash.Parent = workspace
	slash.Slash.CFrame = CFrame.new(playerHRP.Position) * CFrame.Angles(0,math.rad(playerHRP.Orientation.Y),0)
	
	-- sets random transparency to the slash FX to simulate shine
	conn = RunService.Heartbeat:Connect(function()
		slash.Slash.Transparency = math.random(0.1, 1)
		wait(.1)
	end)
	
	-- insert to array as effect to be destroyed
	table.insert(allEffects, slash)

end

-- Handles the sequencing of the animation, FX, and movement
local function slashSequence(input, gpe)
	
	-- check if is GPE and not in cooldown
	if input.UserInputType == Enum.UserInputType.MouseButton1 and not gpe and db == true then
		db = false
		
		-- Play main audio
		if not audio.IsLoaded then
			audio.Loaded:wait()
		end

		audio:Play()
		
		-- Set Player Character to stationary
		char.Humanoid.WalkSpeed = 0
		char.HumanoidRootPart.Anchored = true
		
		local playerscripts = player.PlayerScripts
		local playermodule = require(playerscripts:WaitForChild("PlayerModule"))
		local controls = playermodule:GetControls()
		controls:Disable()
		
		-- Set player orientation to mouse click
		setCharOrientation()
		
		-- Play Animation
		animtrack:Play()
		animtrack:AdjustSpeed(0.5)

		wait(1.3)
		
		-- Adjust speed for emphasis on sword weld
		animtrack:AdjustSpeed(2)
		-- Weld sword to player
		swordWeld()

		
		wait(1.2)
		
		-- Create air FX
		local airRay1 = Ray.new(playerHRP.Position, playerHRP.CFrame.LookVector * -40)
		local _, airPos1 = workspace:FindPartOnRay(airRay1, char)
		airEffects(airPos1, 45, 45)
		
		-- Create air FX
		local airRay2 = Ray.new(playerHRP.Position, playerHRP.CFrame.LookVector * -40)
		local _, airPos2 = workspace:FindPartOnRay(airRay2, char)
		airEffects(airPos2, 1, 0)	
		
		-- Move Player to mouse.hit direction
		playerMovement()
		
		-- Create Slash Fx
		slashFx()

		wait(.05)
		
		-- Pause animation for effect
		animtrack:AdjustSpeed(0)
		
		-- Create air FX
		local airRay = Ray.new(playerHRP.Position, playerHRP.CFrame.LookVector * -40)
		local _, airPos = workspace:FindPartOnRay(airRay1, char)
		airEffects(airPos, 45, 45)

		wait(2.5)

		animtrack:Stop()
		
		-- Search for katana in allEffects array and destroy
		for i, v in ipairs(allEffects) do
			
			print(i,". ", v)
			
			if v.Name == "Katana" then
				
				table.remove(allEffects, i)
				v:Destroy()
				
			end
		end
		
		print("---------------------")
		
		char.HumanoidRootPart.Anchored = false
		char.Humanoid.WalkSpeed = 16
		
		local playerscripts = player.PlayerScripts
		local playermodule = require(playerscripts:WaitForChild("PlayerModule"))
		local controls = playermodule:GetControls()
		controls:Enable()


		wait(2.5)
		
		-- Cooldown for the skill. Set debounce and conn to initial state
		db = true
		conn:Disconnect()
		
		-- Loop through allEffects array and destroy all
		
		for i, v in ipairs(allEffects) do
			
			print(i,". ", v)
			v:Destroy()
			
		end
		
		table.clear(allEffects)
		
		
	end
	
end

-- On User Input
UserInput.InputBegan:Connect(function(InputObject, gpe)
	
	slashSequence(InputObject, gpe)
	
end)
