CoD.ZM_LostNFoundWidget = InheritFrom(LUI.UIElement)
CoD.ZM_LostNFoundWidget.new = function (HudRef, InstanceRef)
	local Widget = LUI.UIElement.new()
	if PreLoadFunc then
		PreLoadFunc(Widget, InstanceRef)
	end
	Widget:setUseStencil(false)
	Widget:setClass(CoD.ZM_LostNFoundWidget)
	Widget.id = "ZM_LostNFoundWidget"
	Widget.soundSet = "default"
	Widget:setLeftRight(true, false, 0, 256)
	Widget:setTopBottom(true, false, 0, 256)
	Widget.anyChildUsesUpdateState = true

	local bgGlow = LUI.UIImage.new();
    bgGlow:setLeftRight(false, false, -80, 80)
	bgGlow:setTopBottom(false, false, -126.5, 126.5)
	bgGlow:setRGB(33/255, 111/255, 255/255)
    bgGlow:setAlpha(0.4)
    bgGlow:setZRot(90)
	bgGlow:setImage(RegisterImage("uie_t7_core_hud_mapwidget_panelglow"))
	bgGlow:setMaterial(LUI.UIImage.GetCachedMaterial("ui_add"))
	Widget:addElement(bgGlow)
	Widget.bgGlow = bgGlow

	--[[local glow = LUI.UIImage.new()
	glow:setLeftRight(false, false, -70, 70)
	glow:setTopBottom(false, false, -70, 70)
	--glow:setRGB(33/255, 111/255, 255/255)
	glow:setImage(RegisterImage("uie_t7_zm_hud_revive_glow"))
	Widget:addElement(glow)
	Widget.Glow = glow]]--

	local ringGlow = LUI.UIImage.new()
	ringGlow:setLeftRight(false, false, -70, 70)
	ringGlow:setTopBottom(false, false, -70, 70)
	ringGlow:setRGB(33/255, 111/255, 255/255)
	ringGlow:setAlpha(0)
	ringGlow:setImage(RegisterImage("uie_t7_zm_hud_revive_ringblur"))
	ringGlow:setMaterial(LUI.UIImage.GetCachedMaterial("ui_add"))
	Widget:addElement(ringGlow)
	Widget.RingGlow = ringGlow

	local ringMiddle = LUI.UIImage.new()
	ringMiddle:setLeftRight(false, false, -70, 70)
	ringMiddle:setTopBottom(false, false, -70, 70)
	ringMiddle:setRGB(33/255, 137/255, 255/255)
	ringMiddle:setAlpha(0.1)
	ringMiddle:setImage(RegisterImage("uie_t7_zm_hud_revive_ringmiddle"))
	ringMiddle:setMaterial(LUI.UIImage.GetCachedMaterial("ui_add"))
	Widget:addElement(ringMiddle)
	Widget.RingMiddle = ringMiddle

	local ringPercent = LUI.UIImage.new()
	ringPercent:setLeftRight(false, false, -70, 70)
	ringPercent:setTopBottom(false, false, -70, 70)
	ringPercent:setRGB(33/255, 214/255, 255/255)
	ringPercent:setImage(RegisterImage("uie_t7_zm_hud_revive_ringtop"))
	ringPercent:setMaterial(LUI.UIImage.GetCachedMaterial("uie_clock_add"))
	ringPercent:setShaderVector(1, 0.5, 0, 0, 0)
	ringPercent:setShaderVector(2, 0.5, 0, 0, 0)
	ringPercent:setShaderVector(3, 0.05, 0, 0, 0)
	ringPercent:subscribeToGlobalModel(InstanceRef, "PerController", "zmhud.lnfPercentage", function (ModelRef)
		local ModelValue = Engine.GetModelValue(ModelRef)
		if ModelValue then
			local shaderW = CoD.GetVectorComponentFromString(ModelValue, 1)
			local shaderX = CoD.GetVectorComponentFromString(ModelValue, 2)
			local shaderY = CoD.GetVectorComponentFromString(ModelValue, 3)
			local shaderZ = CoD.GetVectorComponentFromString(ModelValue, 4)

			ringPercent:setShaderVector(0, AdjustStartEnd(0, 1, shaderW, shaderX, shaderY, shaderZ))
		end
	end)
	Widget:addElement(ringPercent)
	Widget.RingPercent = ringPercent

	local icon = LUI.UIImage.new()
	icon:setLeftRight(false, false, -70, 70)
	icon:setTopBottom(false, false, -70, 70)
	icon:setImage(RegisterImage("uie_t7_zm_hud_lostnfound_skull"))
	Widget:addElement(icon)
	Widget.Icon = icon

	local abilitySwirl = LUI.UIImage.new()
	abilitySwirl:setLeftRight(false, false, -67.86, 69)
	abilitySwirl:setTopBottom(false, false, -69, 67.86)
	abilitySwirl:setRGB(33/255, 137/255, 255/255)
	abilitySwirl:setAlpha(1)
	abilitySwirl:setScale(1)
	abilitySwirl:setImage(RegisterImage("uie_t7_core_hud_ammowidget_abilityswirl"))
	abilitySwirl:setMaterial(LUI.UIImage.GetCachedMaterial("ui_add"))
	Widget:addElement(abilitySwirl)
	Widget.AbilitySwirl = abilitySwirl

	Widget.clipsPerState = {
		DefaultState = {
			DefaultClip = function ()
				Widget:setupElementClipCounter(1)

				abilitySwirl:completeAnimation()
				Widget.AbilitySwirl:setAlpha(0)
				Widget.AbilitySwirl:setZRot(0)
				Widget.AbilitySwirl:setScale(1)
				local f5_local5 = function (Element, Event)
					local f22_local0 = function (Element, Event)
						local f31_local0 = function (Element, Event)
							local f32_local0 = function (Element, Event)
								if not Event.interrupted then
									Element:beginAnimation("keyframe", 50, false, false, CoD.TweenType.Linear)
								end
								Element:setAlpha(0)
								Element:setZRot(360)
								Element:setScale(1.4)
								if Event.interrupted then
									Widget.clipFinished(Element, Event)
								else
									Element:registerEventHandler("transition_complete_keyframe", Widget.clipFinished)
								end
							end

							if Event.interrupted then
								f32_local0(Element, Event)
								return 
							else
								Element:beginAnimation("keyframe", 40, false, false, CoD.TweenType.Linear)
								Element:setAlpha(0)
								Element:setZRot(360)
								Element:setScale(1.33)
								Element:registerEventHandler("transition_complete_keyframe", f32_local0)
							end
						end

						if Event.interrupted then
							f31_local0(Element, Event)
							return 
						else
							Element:beginAnimation("keyframe", 199, false, false, CoD.TweenType.Linear)
							Element:setAlpha(1)
							Element:setZRot(300)
							Element:setScale(1.28)
							Element:registerEventHandler("transition_complete_keyframe", f31_local0)
						end
					end

					if Event.interrupted then
						f22_local0(Element, Event)
						return 
					else
						Element:beginAnimation("keyframe", 389, false, false, CoD.TweenType.Linear)
						Element:registerEventHandler("transition_complete_keyframe", f22_local0)
					end
				end

				f5_local5(abilitySwirl, {})
			end
		}
	}

	LUI.OverrideFunction_CallOriginalSecond(Widget, "close", function (Sender)
		Sender.RingPercent:close()
	end)

	if PostLoadFunc then
		PostLoadFunc(Widget, InstanceRef, HudRef)
	end

	return Widget
end

