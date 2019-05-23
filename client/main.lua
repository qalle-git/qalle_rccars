local RCCar = {}

RegisterCommand("rc", function()
	RCCar.Start()
end)

RCCar.Start = function()
	if DoesEntityExist(RCCar.Entity) then return end

	RCCar.Spawn()

	RCCar.Tablet(true)

	while DoesEntityExist(RCCar.Entity) and DoesEntityExist(RCCar.Driver) do
		Citizen.Wait(5)

		local distanceCheck = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()),  GetEntityCoords(RCCar.Entity), true)

		RCCar.DrawInstructions(distanceCheck)
		RCCar.HandleKeys(distanceCheck)

		if distanceCheck <= Config.LoseConnectionDistance then
			if not NetworkHasControlOfEntity(RCCar.Driver) then
				NetworkRequestControlOfEntity(RCCar.Driver)
			elseif not NetworkHasControlOfEntity(RCCar.Entity) then
				NetworkRequestControlOfEntity(RCCar.Entity)
			end
		else
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 6, 2500)
		end
	end
end

RCCar.HandleKeys = function(distanceCheck)
	if IsControlJustReleased(0, 47) then
		if IsCamRendering(RCCar.Camera) then
			RCCar.ToggleCamera(false)
		else
			RCCar.ToggleCamera(true)
		end
	end

	if distanceCheck <= 1.5 then
		if IsControlJustPressed(0, 38) then
			RCCar.Attach("pick")
		end
	end

	if distanceCheck < Config.LoseConnectionDistance then
		if IsControlPressed(0, 172) and not IsControlPressed(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 9, 1)
		end
		
		if IsControlJustReleased(0, 172) or IsControlJustReleased(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 6, 2500)
		end

		if IsControlPressed(0, 173) and not IsControlPressed(0, 172) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 22, 1)
		end

		if IsControlPressed(0, 174) and IsControlPressed(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 13, 1)
		end

		if IsControlPressed(0, 175) and IsControlPressed(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 14, 1)
		end

		if IsControlPressed(0, 172) and IsControlPressed(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 30, 100)
		end

		if IsControlPressed(0, 174) and IsControlPressed(0, 172) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 7, 1)
		end

		if IsControlPressed(0, 175) and IsControlPressed(0, 172) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 8, 1)
		end

		if IsControlPressed(0, 174) and not IsControlPressed(0, 172) and not IsControlPressed(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 4, 1)
		end

		if IsControlPressed(0, 175) and not IsControlPressed(0, 172) and not IsControlPressed(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 5, 1)
		end
	end
end

RCCar.DrawInstructions = function(distanceCheck)
	local steeringButtons = {
		{
			["label"] = "Right",
			["button"] = "~INPUT_CELLPHONE_RIGHT~"
		},
		{
			["label"] = "Forward",
			["button"] = "~INPUT_CELLPHONE_UP~"
		},
		{
			["label"] = "Reverse",
			["button"] = "~INPUT_CELLPHONE_DOWN~"
		},
		{
			["label"] = "Left",
			["button"] = "~INPUT_CELLPHONE_LEFT~"
		}
	}

	local pickupButton = {
		["label"] = "Pick Up",
		["button"] = "~INPUT_CONTEXT~"
	}

	local buttonsToDraw = {
		{
			["label"] = "Toggle Camera",
			["button"] = "~INPUT_DETONATE~"
		}
	}

	if distanceCheck <= Config.LoseConnectionDistance then
		for buttonIndex = 1, #steeringButtons do
			local steeringButton = steeringButtons[buttonIndex]

			table.insert(buttonsToDraw, steeringButton)
		end

		if distanceCheck <= 1.5 then
			table.insert(buttonsToDraw, pickupButton)
		end
	end

    Citizen.CreateThread(function()
        local instructionScaleform = RequestScaleformMovie("instructional_buttons")

        while not HasScaleformMovieLoaded(instructionScaleform) do
            Wait(0)
        end

        PushScaleformMovieFunction(instructionScaleform, "CLEAR_ALL")
        PushScaleformMovieFunction(instructionScaleform, "TOGGLE_MOUSE_BUTTONS")
        PushScaleformMovieFunctionParameterBool(0)
        PopScaleformMovieFunctionVoid()

        for buttonIndex, buttonValues in ipairs(buttonsToDraw) do
            PushScaleformMovieFunction(instructionScaleform, "SET_DATA_SLOT")
            PushScaleformMovieFunctionParameterInt(buttonIndex - 1)

            PushScaleformMovieMethodParameterButtonName(buttonValues["button"])
            PushScaleformMovieFunctionParameterString(buttonValues["label"])
            PopScaleformMovieFunctionVoid()
        end

        PushScaleformMovieFunction(instructionScaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
        PushScaleformMovieFunctionParameterInt(-1)
        PopScaleformMovieFunctionVoid()
        DrawScaleformMovieFullscreen(instructionScaleform, 255, 255, 255, 255)
    end)
end

RCCar.Spawn = function()
	RCCar.LoadModels({ GetHashKey("rcbandito"), 68070371 })

	local spawnCoords, spawnHeading = GetEntityCoords(PlayerPedId()) + GetEntityForwardVector(PlayerPedId()) * 2.0, GetEntityHeading(PlayerPedId())

	RCCar.Entity = CreateVehicle(GetHashKey("rcbandito"), spawnCoords, spawnHeading, true)

	while not DoesEntityExist(RCCar.Entity) do
		Citizen.Wait(5)
	end

	RCCar.Driver = CreatePed(5, 68070371, spawnCoords, spawnHeading, true)

	SetEntityInvincible(RCCar.Driver, true)
	SetEntityVisible(RCCar.Driver, false)
	FreezeEntityPosition(RCCar.Driver, true)
	SetPedAlertness(RCCar.Driver, 0.0)

	TaskWarpPedIntoVehicle(RCCar.Driver, RCCar.Entity, -1)

	while not IsPedInVehicle(RCCar.Driver, RCCar.Entity) do
		Citizen.Wait(0)
	end

	RCCar.Attach("place")
end

RCCar.Attach = function(param)
	if not DoesEntityExist(RCCar.Entity) then
		return
	end
	
	RCCar.LoadModels({ "pickup_object" })

	if param == "place" then
		AttachEntityToEntity(RCCar.Entity, PlayerPedId(), GetPedBoneIndex(PlayerPedId(),  28422), -0.1, 0.0, -0.2, 70.0, 0.0, 270.0, 1, 1, 0, 0, 2, 1)

		TaskPlayAnim(PlayerPedId(), "pickup_object", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)

		Citizen.Wait(800)

		DetachEntity(RCCar.Entity, false, true)

		PlaceObjectOnGroundProperly(RCCar.Entity)
	elseif param == "pick" then
		if DoesCamExist(RCCar.Camera) then
			RCCar.ToggleCamera(false)
		end

		RCCar.Tablet(false)

		Citizen.Wait(100)

		TaskPlayAnim(PlayerPedId(), "pickup_object", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)

		Citizen.Wait(600)
	
		AttachEntityToEntity(RCCar.Entity, PlayerPedId(), GetPedBoneIndex(PlayerPedId(),  28422), -0.1, 0.0, -0.2, 70.0, 0.0, 270.0, 1, 1, 0, 0, 2, 1)

		Citizen.Wait(900)
	
		DetachEntity(RCCar.Entity)

		DeleteVehicle(RCCar.Entity)
		DeleteEntity(RCCar.Driver)

		RCCar.UnloadModels()
	end
end

RCCar.Tablet = function(boolean)
	if boolean then
		RCCar.LoadModels({ GetHashKey("prop_cs_tablet") })

		RCCar.TabletEntity = CreateObject(GetHashKey("prop_cs_tablet"), GetEntityCoords(PlayerPedId()), true)

		AttachEntityToEntity(RCCar.TabletEntity, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), -0.03, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
	
		RCCar.LoadModels({ "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a" })
	
		TaskPlayAnim(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 3.0, -8, -1, 63, 0, 0, 0, 0 )
	
		Citizen.CreateThread(function()
			while DoesEntityExist(RCCar.TabletEntity) do
				Citizen.Wait(5)
	
				if not IsEntityPlayingAnim(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 3) then
					TaskPlayAnim(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 3.0, -8, -1, 63, 0, 0, 0, 0 )
				end
			end

			ClearPedTasks(PlayerPedId())
		end)
	else
		DeleteEntity(RCCar.TabletEntity)
	end
end

RCCar.ToggleCamera = function(boolean)
	if not Config.Camera then return end

	if boolean then
		if not DoesEntityExist(RCCar.Entity) then return end 
		if DoesCamExist(RCCar.Camera) then DestroyCam(RCCar.Camera) end

		RCCar.Camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

		AttachCamToEntity(RCCar.Camera, RCCar.Entity, 0.0, 0.0, 0.4, true)

		Citizen.CreateThread(function()
			while DoesCamExist(RCCar.Camera) do
				Citizen.Wait(5)

				SetCamRot(RCCar.Camera, GetEntityRotation(RCCar.Entity))
			end
		end)

		local easeTime = 500 * math.ceil(GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(RCCar.Entity), true) / 10)

		RenderScriptCams(1, 1, easeTime, 1, 1)

		Citizen.Wait(easeTime)

		SetTimecycleModifier("scanline_cam_cheap")
		SetTimecycleModifierStrength(2.0)
	else
		local easeTime = 500 * math.ceil(GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(RCCar.Entity), true) / 10)

		RenderScriptCams(0, 1, easeTime, 1, 0)

		Citizen.Wait(easeTime)

		ClearTimecycleModifier()

		DestroyCam(RCCar.Camera)
	end
end

RCCar.LoadModels = function(models)
	for modelIndex = 1, #models do
		local model = models[modelIndex]

		if not RCCar.CachedModels then
			RCCar.CachedModels = {}
		end

		table.insert(RCCar.CachedModels, model)

		if IsModelValid(model) then
			while not HasModelLoaded(model) do
				RequestModel(model)
	
				Citizen.Wait(10)
			end
		else
			while not HasAnimDictLoaded(model) do
				RequestAnimDict(model)
	
				Citizen.Wait(10)
			end    
		end
	end
end

RCCar.UnloadModels = function()
	for modelIndex = 1, #RCCar.CachedModels do
		local model = RCCar.CachedModels[modelIndex]

		if IsModelValid(model) then
			SetModelAsNoLongerNeeded(model)
		else
			RemoveAnimDict(model)   
		end
	end
end