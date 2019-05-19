local RCCar = {}

RegisterCommand("rc", function()
	RCCar.Start()
end)

RCCar.Start = function()
	RCCar.Spawn()

	RCCar.Tablet(true)

	while DoesEntityExist(RCCar.Entity) and DoesEntityExist(RCCar.Driver) do
		Citizen.Wait(5)

		local rcCarPos = GetEntityCoords(RCCar.Entity)

		local distanceCheck = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), rcCarPos, true)

		TaskPause(RCCar.Driver, 1000)

		if distanceCheck <= 100.0 then
			if not NetworkHasControlOfEntity(RCCar.Driver) then
				NetworkRequestControlOfEntity(RCCar.Driver)
			elseif not NetworkHasControlOfEntity(RCCar.Entity) then
				NetworkRequestControlOfEntity(RCCar.Entity)
			end

			RCCar.HandleKeys()

			DrawScreenText("Pick up your ~g~RC~s~ to ~r~cancel~s~ the driving!")
		else
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 6, 2500)

			DrawScreenText("You're losing the ~r~contact~s~ with your RC!")
		end

		if distanceCheck <= 1.5 then
			Draw3DText(rcCarPos, "[~g~E~s~] Pick", 0.4)

			if IsControlJustPressed(0, 38) then
				RCCar.Attach("pick")
			end
		else
			Draw3DText(rcCarPos, "~b~RC", 0.4)
		end
	end
end

RCCar.HandleKeys = function()
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

DrawScreenText = function(text)
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(0.4, 0.4)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()

    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.82 - 1.0/2, 0.604 - 1.0/2 + 0.005)
end

Draw3DText = function(coords, text, size)
	local onScreen, _x, _y=World3dToScreen2d(coords["x"], coords["y"], coords["z"])
	
	SetTextScale(0.35, 0.35)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x, _y)

	local factor = (string.len(text)) / 370
	DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end