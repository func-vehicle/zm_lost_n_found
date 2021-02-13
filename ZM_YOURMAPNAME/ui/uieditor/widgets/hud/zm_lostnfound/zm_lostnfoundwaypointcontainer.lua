require("ui.uieditor.widgets.HUD.ZM_LostNFound.ZM_LostNFoundWaypoint")

local setupWaypointContainer = function (f1_arg0, f1_arg1)
	if f1_arg1.objId then
		f1_arg0.objId = f1_arg1.objId
		local waypoint = f1_arg0.Waypoint
		waypoint.objective = f1_arg0.objective
		waypoint:setupWaypoint(f1_arg1)
		waypoint.WaypointCenter.waypointCenterImage:setImage(RegisterImage(waypoint.waypoint_image_default))
		--[[if waypoint.waypoint_image_default == nil then
			waypoint:setState("NoIcon")
		else
			waypoint:setState("Default")
			waypoint.WaypointCenter.waypointCenterImage:setImage(RegisterImage(waypoint.waypoint_image_default))
		end]]--
		local f1_local1 = f1_arg1.controller
		local objId = f1_arg0.objId
		if waypoint.objective.minimapMaterial ~= nil then
			Engine.SetObjectiveIcon(f1_local1, objId, CoD.GametypeBase.mapIconType, waypoint.objective.minimapMaterial)
		else
			Engine.ClearObjectiveIcon(f1_local1, objId, CoD.GametypeBase.mapIconType)
		end
		if waypoint.waypoint_label_default == "" then
			waypoint.WaypointText:setState("NoText")
		else
			waypoint.WaypointText:setState("DefaultState")
		end
		if waypoint.objective.hide_arrow then
			waypoint.WaypointArrowContainer:setState("Invisible")
		end
		waypoint.WaypointText.text:setText(Engine.Localize(waypoint.waypoint_label_default))
	end
end

local update = function (f2_arg0, f2_arg1)
	f2_arg0.Waypoint:update(f2_arg1)
	if f2_arg1.objState ~= nil then
		if f2_arg1.objState == CoD.OBJECTIVESTATE_DONE then
			f2_arg0:setState("Done")
		else
			f2_arg0:setState("DefaultState")
			f2_arg0.Waypoint.ZM_LostNFoundWidget:setState("DefaultState")
		end
		if f2_arg0.visible == true then
			f2_arg0:show()
		else
			f2_arg0:hide()
		end
	end
end

local shouldShow = function (f3_arg0, f3_arg1)
	local f3_local0 = f3_arg1.controller
	local waypoint = f3_arg0.Waypoint
	local f3_local2 = Engine.GetObjectiveTeam(f3_local0, f3_arg0.objId)
	if f3_local2 == Enum.team_t.TEAM_FREE or f3_local2 == Enum.team_t.TEAM_NEUTRAL then
		return true
	else
		return waypoint:isOwnedByMyTeam(f3_local0)
	end
end

local PostLoadFunc = function (Widget)
	Widget.update = update
	Widget.shouldShow = shouldShow
	Widget.setupWaypointContainer = setupWaypointContainer
end

CoD.ZM_LostNFoundWaypointContainer = InheritFrom(LUI.UIElement)
CoD.ZM_LostNFoundWaypointContainer.new = function (HudRef, InstanceRef)
	local Widget = LUI.UIElement.new()
	if PreLoadFunc then
		PreLoadFunc(Widget, InstanceRef)
	end
	Widget:setUseStencil(false)
	Widget:setClass(CoD.ZM_LostNFoundWaypointContainer)
	Widget.id = "ZM_LostNFoundWaypointContainer"
	Widget.soundSet = "default"
	Widget:setLeftRight(true, false, 0, 1280)
	Widget:setTopBottom(true, false, 0, 720)
	Widget.anyChildUsesUpdateState = true
	
	local waypoint = CoD.ZM_LostNFoundWaypoint.new(HudRef, InstanceRef)
	waypoint:setLeftRight(true, true, 100, -100)
	waypoint:setTopBottom(true, true, 80, -80)
	Widget:addElement(waypoint)
	Widget.Waypoint = waypoint

	local prompt = LUI.UITightText.new()
	prompt:setLeftRight(true, true, 44, -44)
	prompt:setTopBottom(false, true, -150, -120)
	prompt:setTTF("fonts/RefrigeratorDeluxe-Regular.ttf")
	prompt:setLetterSpacing(1)
	prompt:setText(Engine.Localize("LOSTNFOUND_WEAPONS_AVAILABLE"))
	prompt:setAlpha(0)
	Widget:addElement(prompt)
	Widget.prompt = prompt
	
	Widget.clipsPerState = {
		DefaultState = {
			DefaultClip = function()
				Widget:setupElementClipCounter(3)

				waypoint:completeAnimation()
				-- Show waypoint
				waypoint:setAlpha(1)
				Widget.clipFinished(waypoint, {})
				
				prompt:completeAnimation()
				-- Show prompt
				prompt:setAlpha(1)
				Widget.clipFinished(prompt, {})

				prompt:beginAnimation("keyframe", 4000, false, false, CoD.TweenType.Linear)
				-- Wait 4 seconds
				prompt:registerEventHandler("transition_complete_keyframe", function (Element, Event)
					if not Event.interrupted then
						Element:beginAnimation("keyframe", 1000, false, false, CoD.TweenType.Linear)
					end
					-- Fade prompt over 1 second
					Element:setAlpha(0)
					if Event.interrupted then
						Widget.clipFinished(Element, {})
					else
						Element:registerEventHandler("transition_complete_keyframe", Widget.clipFinished)
					end
				end)
			end
		},
		Done = {
			DefaultClip = function ()
				Widget:setupElementClipCounter(1)
				waypoint:completeAnimation()
				Widget.Waypoint:setAlpha(1)
				local f7_local0 = function (Element, Event)
					if not Event.interrupted then
						Element:beginAnimation("keyframe", 1000, false, false, CoD.TweenType.Linear)
					end
					Element:setAlpha(0)
					if Event.interrupted then
						Widget.clipFinished(Element, Event)
					else
						Element:registerEventHandler("transition_complete_keyframe", Widget.clipFinished)
					end
				end

				f7_local0(waypoint, {})
			end
		}
	}

	LUI.OverrideFunction_CallOriginalSecond(Widget, "close", function (Sender)
		Sender.Waypoint:close()
	end)

	if PostLoadFunc then
		PostLoadFunc(Widget, InstanceRef, HudRef)
	end

	return Widget
end

