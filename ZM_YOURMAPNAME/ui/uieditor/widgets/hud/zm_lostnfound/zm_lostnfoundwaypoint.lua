require("ui.uieditor.widgets.MPHudWidgets.WaypointArrowContainer")
require("ui.uieditor.widgets.MPHudWidgets.WaypointDistanceIndicatorContainer")
require("ui.uieditor.widgets.MPHudWidgets.Waypoint_TextBG")
require("ui.uieditor.widgets.MPHudWidgets.WaypointCenter")

require("ui.uieditor.widgets.HUD.ZM_LostNFound.ZM_LostNFoundWidget")

local f0_local0 = 0.8
local f0_local1 = 0.3
local setupWaypoint = function (f1_arg0, f1_arg1)
	if f1_arg1.objId then
		--f1_arg0:setLeftRight(false, false, 0, 0)
		--f1_arg0:setTopBottom(false, false, 0, 0)
		f1_arg0.objId = f1_arg1.objId
		f1_arg0.waypoint_label_default = f1_arg0.objective.waypoint_text
		if f1_arg0.waypoint_label_default == nil then
			f1_arg0.waypoint_label_default = ""
		end
		local objective = f1_arg0.objective
		local b_value
		if objective.waypoint_fade_when_targeted ~= "enable" and objective.waypoint_fade_when_targeted ~= true then
			b_value = false
		else
			b_value = true
		end
		f1_arg0.waypoint_fade_when_targeted = b_value
		if objective.waypoint_clamp ~= "enable" and objective.waypoint_clamp ~= true then
			b_value = false
		else
			b_value = true
		end
		f1_arg0.waypoint_container_clamp = b_value
		if objective.show_distance ~= "enable" and objective.show_distance ~= true then
			b_value = false
		else
			b_value = true
		end
		f1_arg0.show_distance = b_value
		if objective.hide_arrow ~= "enable" and objective.hide_arrow ~= true then
			b_value = false
		else
			b_value = true
		end
		f1_arg0.hide_arrow = b_value
		f1_arg0.waypoint_image_default = nil
		if f1_arg0.objective.waypoint_image ~= nil then
			f1_arg0.waypoint_image_default = f1_arg0.objective.waypoint_image
		end
		f1_arg0:setupWaypointContainer(f1_arg0.objId)
		if f1_arg0.waypoint_fade_when_targeted then
			f1_arg0:setEntityContainerFadeWhenTargeted(true)
		end
		if f1_arg0.waypoint_container_clamp then
			f1_arg0:setEntityContainerClamp(true)
		end
		if not f1_arg0.isClamped then
			f1_arg0.WaypointDistanceIndicatorContainer:setAlpha(1)
		end
		b_value = Engine.GetObjectiveEntity(f1_arg1.controller, f1_arg1.objId)
		local distanceIndicator = f1_arg0.WaypointDistanceIndicatorContainer.DistanceIndicator
		local f1_local4
		if b_value ~= 0 then
			f1_local4 = b_value
		else
			f1_local4 = f1_arg1.objId
		end
		distanceIndicator:setupDistanceIndicator(f1_local4, b_value == nil, f1_arg0.show_distance)
		f1_arg0.snapToCenterWhenContested = true
		f1_arg0.snapToCenterForObjectiveTeam = true
		f1_arg0.snapToCenterForOtherTeams = true
		f1_arg0.updateState = true
		f1_arg0.zOffset = 0
		if f1_arg0.objective.waypoint_z_offset ~= nil then
			f1_arg0.zOffset = f1_arg0.objective.waypoint_z_offset
		end
		f1_arg0.pulse = false
		if f1_arg0.objective.pulse_waypoint ~= nil then
			f1_arg0.pulse = (f1_arg0.objective.pulse_waypoint == "enable")
		end
		--f1_arg0:setState("DefaultState")
		--[[
		f1_arg0.progressMeter:setImage(RegisterMaterial("hud_objective_circle_meter"))
		if f1_arg0.objId == 0 or f1_arg0.objId == 2 then
			f1_arg0:setState("DefaultState")
			f1_arg0:subscribeToModel(Engine.GetModel(Engine.GetModelForController(f1_arg1.controller), "zmInventory.zc_change_progress_bar_color"), function (ModelRef)
				local ModelValue = Engine.GetModelValue(ModelRef)
				if ModelValue == 0 then
					f1_arg0:setState("NotCapturing")
				elseif ModelValue == 1 then
					f1_arg0:setState("DefaultState")
				end
			end)
		else
			f1_arg0:setState("NotCapturing")
		end
		]]--
	end
end

local isOwnedByMyTeam = function (f2_arg0, f2_arg1)
	if Engine.GetTeamID(f2_arg1, Engine.GetPredictedClientNum(f2_arg1)) ~= Engine.GetObjectiveTeam(f2_arg1, f2_arg0.objId) then
		return false
	else
		return true
	end
end

local getTeam = function (f3_arg0, f3_arg1)
	return Engine.GetObjectiveTeam(f3_arg1, f3_arg0.objId)
end

local isPlayerUsing = function (f4_arg0, f4_arg1, f4_arg2, f4_arg3)
	if Engine.IsPlayerInVehicle(f4_arg1) == true then
		return false
	elseif Engine.IsPlayerRemoteControlling(f4_arg1) == true then
		return false
	elseif Engine.IsPlayerWeaponViewOnlyLinked(f4_arg1) == true then
		return false
	else
		return Engine.ObjectiveIsPlayerUsing(f4_arg1, f4_arg0.objId, Engine.GetPredictedClientNum(f4_arg1))
	end
end

local Clamped = function (Sender, Event)
	Sender.isClamped = true
	Sender.WaypointArrowContainer:setupEdgePointer(90)
	--Sender.WaypointArrowContainer.WaypointArrowWidget:setState("DefaultState")
	Sender.WaypointArrowContainer:setAlpha(1)
	local waypointText = Sender.WaypointText
	if Sender.snapped then
		waypointText:setAlpha(0)
		Sender.WaypointDistanceIndicatorContainer:setAlpha(0)
	end
end

local Unclamped = function (Sender, Event)
	Sender.isClamped = false
	Sender.WaypointArrowContainer:setupUIElement()
	Sender.WaypointArrowContainer:setZRot(0)
	--Sender.WaypointArrowContainer.WaypointArrowWidget:setState("DefaultState")
	Sender.WaypointArrowContainer:setAlpha(0)
	Sender.WaypointText:setAlpha(1)
	Sender.WaypointDistanceIndicatorContainer:setAlpha(1)
end

local setCompassObjectiveIcon = function (f7_arg0, f7_arg1, f7_arg2, f7_arg3, f7_arg4)
	if f7_arg3 then
		if f7_arg4 then
			Engine.SetObjectiveIcon(f7_arg1, f7_arg2, f7_arg0.mapIconType, f7_arg3, f7_arg4.r, f7_arg4.g, f7_arg4.b)
			Engine.SetObjectiveIcon(f7_arg1, f7_arg2, CoD.GametypeBase.shoutcasterMapIconType, f7_arg3, f7_arg4.r, f7_arg4.g, f7_arg4.b)
		else
			Engine.SetObjectiveIcon(f7_arg1, f7_arg2, f7_arg0.mapIconType, f7_arg3)
			Engine.SetObjectiveIcon(f7_arg1, f7_arg2, CoD.GametypeBase.shoutcasterMapIconType, f7_arg3)
		end
		Engine.SetObjectiveIconPulse(f7_arg1, f7_arg2, f7_arg0.mapIconType, f7_arg0.pulse)
	else
		Engine.ClearObjectiveIcon(f7_arg1, f7_arg2, f7_arg0.mapIconType)
		Engine.ClearObjectiveIcon(f7_arg1, f7_arg2, CoD.GametypeBase.shoutcasterMapIconType)
		Engine.SetObjectiveIconPulse(f7_arg1, f7_arg2, f7_arg0.mapIconType, false)
	end
end

local clearCompassObjectiveIcon = function (f8_arg0, f8_arg1, f8_arg2)
	Engine.ClearObjectiveIcon(f8_arg1, f8_arg2, f8_arg0.mapIconType)
	Engine.ClearObjectiveIcon(f8_arg1, f8_arg2, CoD.GametypeBase.shoutcasterMapIconType)
end

local updateProgress = function (f9_arg0, f9_arg1, f9_arg2, f9_arg3)
--	f9_arg0.progressMeter:setShaderVector(0, Engine.GetObjectiveProgress(f9_arg1, f9_arg0.objId), 0, 0, 0)
end

local updatePlayerUsing = function (f10_arg0, f10_arg1, isTeamUsing, isOtherTeamUsing)
	local playerUsing = isPlayerUsing(f10_arg0, f10_arg1.controller, isTeamUsing, isOtherTeamUsing)
	if f10_arg0.playerUsing == playerUsing then
		return 
	elseif playerUsing == true then
		if f10_arg0.playerUsing ~= nil then
			f10_arg0:beginAnimation("snap_in", 250, true, true)
		end
		f10_arg0.snapped = true
		f10_arg0.WaypointText:setAlpha(1)
		f10_arg0:setEntityContainerStopUpdating(true)
		f10_arg0:setLeftRight(false, false, -75, 75)
		f10_arg0:setTopBottom(false, false, 99, 249)
		f10_arg0.WaypointArrowContainer:setAlpha(0)
	else
		if f10_arg0.playerUsing ~= nil then
			f10_arg0:beginAnimation("snap_out", 250, true, true)
		end
		f10_arg0.snapped = false
		f10_arg0:setEntityContainerStopUpdating(false)
		f10_arg0:setLeftRight(false, false, -32, 32)
		f10_arg0:setTopBottom(false, false, -32, 32)
		f10_arg0.WaypointArrowContainer:setAlpha(1)
	end
	f10_arg0.playerUsing = playerUsing
end

local update = function (f11_arg0, f11_arg1)
	local f11_local0 = f11_arg1.controller
	local objId = f11_arg0.objId
	if Engine.GetObjectiveEntity(f11_local0, objId) then
		f11_arg0:setupWaypointContainer(objId, 0, 0, f11_arg0.zOffset)
	else
		local f11_local2, f11_local3, f11_local4 = Engine.GetObjectivePosition(f11_local0, objId)
		f11_arg0:setupWaypointContainer(objId, f11_local2, f11_local3, f11_local4 + f11_arg0.zOffset)
	end
	local scale3d
	if not f11_arg0.objective.scale3d or f11_arg0.objective.scale3d == 0 then
		scale3d = false
	else
		scale3d = true
	end
	f11_arg0:setEntityContainerScale(scale3d)
	if f11_arg0.objective.show3dDirectionArrow and f11_arg0.objective.show3dDirectionArrow ~= 0 then
		f11_arg0.WaypointArrowContainer:setup3dPointer(objId)
	end
	local teamId = Engine.GetTeamID(f11_local0, Engine.GetPredictedClientNum(f11_local0))
	local isTeamUsing = Engine.ObjectiveIsTeamUsing(f11_local0, objId, teamId)
	local isOtherTeamUsing = Engine.ObjectiveIsAnyOtherTeamUsing(f11_local0, objId, teamId)
	--f11_arg0:updatePlayerUsing(f11_arg1, isTeamUsing, isOtherTeamUsing)
	--f11_arg0:updateProgress(f11_local0, isTeamUsing, isOtherTeamUsing)
end

local SetWaypointState = function (f12_arg0, f12_arg1)
	if f12_arg0.animationState == f12_arg1 then
		return 
	elseif f12_arg1 == "waypoint_line_of_sight" then
		f12_arg0:setAlpha(1)
		f12_arg0.WaypointArrowContainer.WaypointArrowWidget:setState("SolidArrowState")
		local waypointText = f12_arg0.WaypointText
		if f12_arg0.snapped or f12_arg0.isClamped then
			waypointText:setAlpha(0)
		end
	elseif f12_arg1 == "waypoint_out_of_line_of_sight" then
		f12_arg0:setAlpha(0.7)
		f12_arg0.WaypointArrowContainer.WaypointArrowWidget:setState("DefaultState")
		local waypointText = f12_arg0.WaypointText
		if f12_arg0.snapped or f12_arg0.isClamped then
			waypointText:setAlpha(1)
		end
	elseif f12_arg1 == "waypoint_distance_culled" then
		f12_arg0:setAlpha(0)
	end
end

local PostLoadFunc = function (Widget, InstanceRef)
	Widget.setupWaypoint = setupWaypoint
	Widget.update = update
	Widget.updateProgress = updateProgress
	Widget.updatePlayerUsing = updatePlayerUsing
	Widget.isOwnedByMyTeam = isOwnedByMyTeam
	Widget.getTeam = getTeam
	Widget.SetWaypointState = SetWaypointState
	--Widget.setCompassObjectiveIcon = setCompassObjectiveIcon
	--Widget.clearCompassObjectiveIcon = clearCompassObjectiveIcon
	Widget:registerEventHandler("entity_container_clamped", Clamped)
	Widget:registerEventHandler("entity_container_unclamped", Unclamped)
	--Widget.mapIconType = CoD.GametypeBase.mapIconType
	--Widget.neutralTeamID = 8
end

CoD.ZM_LostNFoundWaypoint = InheritFrom(LUI.UIElement)
CoD.ZM_LostNFoundWaypoint.new = function (HudRef, InstanceRef)
	local Widget = LUI.UIElement.new()
	if PreLoadFunc then
		PreLoadFunc(Widget, InstanceRef)
	end
	Widget:setUseStencil(false)
	Widget:setClass(CoD.ZM_LostNFoundWaypoint)
	Widget.id = "ZM_LostNFoundWaypoint"
	Widget.soundSet = "default"
	Widget:setLeftRight(true, false, 0, 256)
	Widget:setTopBottom(true, false, 0, 256)
	Widget.anyChildUsesUpdateState = true

	local lostNFoundWidget = CoD.ZM_LostNFoundWidget.new(HudRef, InstanceRef)
	lostNFoundWidget:setLeftRight(false, false, 0, 0)
	lostNFoundWidget:setTopBottom(false, false, 0, 0)
	lostNFoundWidget:linkToElementModel(Widget, nil, false, function (ModelRef)
		lostNFoundWidget:setModel(ModelRef, InstanceRef)
	end)
	lostNFoundWidget:setScale(0.5)
	Widget:addElement(lostNFoundWidget)
	Widget.ZM_LostNFoundWidget = lostNFoundWidget
	
	local waypointArrowContainer = CoD.WaypointArrowContainer.new(HudRef, InstanceRef)
	waypointArrowContainer:setLeftRight(false, false, -128, 128)
	waypointArrowContainer:setTopBottom(false, false, -128, 128)
	waypointArrowContainer:setAlpha(0)
	waypointArrowContainer.WaypointArrowWidget:setTopBottom(false, true, -20, -52)
	waypointArrowContainer.WaypointArrowWidget.outlineArrow:setImage(RegisterImage("uie_t7_zm_hud_generic_arrow"))
	waypointArrowContainer.WaypointArrowWidget.outlineArrow:setLeftRight(false, false, -20, 20)
	waypointArrowContainer.WaypointArrowWidget.outlineArrow:setTopBottom(false, true, -52, 0)
	waypointArrowContainer.WaypointArrowWidget.solidArrow:setImage(RegisterImage("uie_t7_zm_hud_generic_arrow"))
	waypointArrowContainer.WaypointArrowWidget.solidArrow:setLeftRight(false, false, -13.85, 13.85)
	waypointArrowContainer.WaypointArrowWidget.solidArrow:setTopBottom(false, true, -36, 0)
	waypointArrowContainer.WaypointArrowWidget.solidArrow:setRGB(60/255, 200/255, 255/255)
	Widget:addElement(waypointArrowContainer)
	Widget.WaypointArrowContainer = waypointArrowContainer
	
	--[[
	local progressMeter = LUI.UIImage.new()
	progressMeter:setLeftRight(true, true, 0, 0)
	progressMeter:setTopBottom(true, true, 0, 0)
	progressMeter:setAlpha(0.9)
	progressMeter:setScale(0.46)
	progressMeter:setImage(RegisterImage("uie_t7_zm_hud_revive_arrow"))
	progressMeter:setMaterial(LUI.UIImage.GetCachedMaterial("uie_clock_normal"))
	progressMeter:setShaderVector(0, 1.03, 0, 0, 0)
	progressMeter:setShaderVector(1, 0.5, 0, 0, 0)
	progressMeter:setShaderVector(2, 0.5, 0, 0, 0)
	progressMeter:setShaderVector(3, 0, 0, 0, 0)
	progressMeter:setAlpha(0)  -- We don't need this
	Widget:addElement(progressMeter)
	Widget.progressMeter = progressMeter
	]]--
	
	local waypointDistanceIndicatorContainer = CoD.WaypointDistanceIndicatorContainer.new(HudRef, InstanceRef)
	waypointDistanceIndicatorContainer:setLeftRight(true, true, -1, -1)
	waypointDistanceIndicatorContainer:setTopBottom(false, false, -62, -45)
	Widget:addElement(waypointDistanceIndicatorContainer)
	Widget.WaypointDistanceIndicatorContainer = waypointDistanceIndicatorContainer
	
	local waypointText = CoD.Waypoint_TextBG.new(HudRef, InstanceRef)
	waypointText:setLeftRight(false, false, -41, 39)
	waypointText:setTopBottom(false, false, -45, -24)
	Widget:addElement(waypointText)
	Widget.WaypointText = waypointText
	
	local waypointCenter = CoD.WaypointCenter.new(HudRef, InstanceRef)
	waypointCenter:setLeftRight(false, false, -40, 40)
	waypointCenter:setTopBottom(false, false, -40, 40)
	waypointCenter:setAlpha(0.95)
	Widget:addElement(waypointCenter)
	Widget.WaypointCenter = waypointCenter
	
	Widget.clipsPerState = {
		DefaultState = {
			DefaultClip = function ()
				Widget:setupElementClipCounter(0)
				--[[Widget:setupElementClipCounter(2)
				bgGlow:completeAnimation()
				Widget.bgGlow:setRGB(0.68, 0.86, 1)
				Widget.bgGlow:setAlpha(1)
				local f16_local0 = function (Element, Event)
					local f19_local0 = function (Element, Event)
						if not Event.interrupted then
							Element:beginAnimation("keyframe", 699, false, false, CoD.TweenType.Linear)
						end
						Element:setRGB(0.68, 0.86, 1)
						Element:setAlpha(1)
						if Event.interrupted then
							Widget.clipFinished(Element, Event)
						else
							Element:registerEventHandler("transition_complete_keyframe", Widget.clipFinished)
						end
					end

					if Event.interrupted then
						f19_local0(Element, Event)
						return 
					else
						Element:beginAnimation("keyframe", 699, false, false, CoD.TweenType.Linear)
						Element:setAlpha(0.35)
						Element:registerEventHandler("transition_complete_keyframe", f19_local0)
					end
				end

				f16_local0(bgGlow, {})
				progressMeter:completeAnimation()
				Widget.progressMeter:setRGB(0.68, 0.86, 1)
				Widget.clipFinished(progressMeter, {})
				Widget.nextClip = "DefaultClip"]]--
			end
		},
		NotCapturing = {
			DefaultClip = function ()
				Widget:setupElementClipCounter(0)
				--[[Widget:setupElementClipCounter(2)
				bgGlow:completeAnimation()
				Widget.bgGlow:setRGB(1, 0.19, 0.19)
				Widget.bgGlow:setAlpha(1)
				local f17_local0 = function (Element, Event)
					local f21_local0 = function (Element, Event)
						if not Event.interrupted then
							Element:beginAnimation("keyframe", 699, false, false, CoD.TweenType.Linear)
						end
						Element:setRGB(1, 0.19, 0.19)
						Element:setAlpha(1)
						if Event.interrupted then
							Widget.clipFinished(Element, Event)
						else
							Element:registerEventHandler("transition_complete_keyframe", Widget.clipFinished)
						end
					end

					if Event.interrupted then
						f21_local0(Element, Event)
						return 
					else
						Element:beginAnimation("keyframe", 699, false, false, CoD.TweenType.Linear)
						Element:setAlpha(0.35)
						Element:registerEventHandler("transition_complete_keyframe", f21_local0)
					end
				end

				f17_local0(bgGlow, {})
				progressMeter:completeAnimation()
				Widget.progressMeter:setRGB(1, 0.19, 0.19)
				Widget.clipFinished(progressMeter, {})
				Widget.nextClip = "DefaultClip"]]--
			end
		}
	}

	LUI.OverrideFunction_CallOriginalSecond(Widget, "close", function (Sender)
		Sender.WaypointArrowContainer:close()
		Sender.WaypointDistanceIndicatorContainer:close()
		Sender.WaypointText:close()
		Sender.WaypointCenter:close()
		Sender.ZM_LostNFoundWidget:close()
	end)

	if PostLoadFunc then
		PostLoadFunc(Widget, InstanceRef, HudRef)
	end

	return Widget
end

