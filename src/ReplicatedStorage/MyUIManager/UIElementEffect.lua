local TweenService = game:GetService("TweenService")

local UIElementEffect = {}

UITypeAndPriorityToSequence = {
	Text = {
		[0] = {
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
			}),
			size = 3,
		},
		--白
		[1] = {
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
			}),
			size = 3,
		},
		--蓝
		[2] = {
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
				ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 170, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 170, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 170, 255)),
			}),
			size = 3,
		},
		-- 紫
		[3] = {
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255)),
			}),
			size = 3,
		},
		--橙
		[4] = {
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 85, 0)),
				ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 85, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 85, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 85, 0)),
			}),
			size = 3,
		},
		--彩
		[5] = {
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
				ColorSequenceKeypoint.new(0.1510416716337204, Color3.new(0.615686297416687, 0, 1)),
				ColorSequenceKeypoint.new(0.3072916567325592, Color3.new(0.06666667014360428, 0, 1)),
				ColorSequenceKeypoint.new(0.4965277910232544, Color3.new(0, 1, 1)),
				ColorSequenceKeypoint.new(0.6649305820465088, Color3.new(0.01568627543747425, 1, 0)),
				ColorSequenceKeypoint.new(0.8385416865348816, Color3.new(1, 1, 0)),
				ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0)),
			}),
			size = 3,
		},
		--星空
		[6] = {
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 255, 255)),
				ColorSequenceKeypoint.new(0.25, Color3.fromRGB(85, 0, 127)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.75, Color3.fromRGB(85, 0, 127)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 255, 255)),
			}),
			size = 3,
		},
		transparencySequence = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.2),
			NumberSequenceKeypoint.new(0.8, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
	},
	Image = {
		[0] = {
			--白
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
			}),
			size = 3,
		},
		[1] = {
			--白
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
			}),
			size = 3,
		},
		[2] = {
			--蓝
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 170, 255)),
			}),
			size = 3,
		},
		[3] = {
			--紫
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255)),
			}),
			size = 3,
		},
		[4] = {
			--橙
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 85, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 85, 0)),
			}),
			size = 3,
		},
		[5] = {
			--彩
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
				ColorSequenceKeypoint.new(0.1510416716337204, Color3.new(0.615686297416687, 0, 1)),
				ColorSequenceKeypoint.new(0.3072916567325592, Color3.new(0.06666667014360428, 0, 1)),
				ColorSequenceKeypoint.new(0.4965277910232544, Color3.new(0, 1, 1)),
				ColorSequenceKeypoint.new(0.6649305820465088, Color3.new(0.01568627543747425, 1, 0)),
				ColorSequenceKeypoint.new(0.8385416865348816, Color3.new(1, 1, 0)),
				ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0)),
			}),
			size = 3,
		},
		[6] = {
			--星空
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 255, 255)),
				ColorSequenceKeypoint.new(0.25, Color3.fromRGB(85, 0, 127)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.75, Color3.fromRGB(85, 0, 127)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 255, 255)),
			}),
			size = 3,
		},
		transparencySequence = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0),
		}),
	},
	Frame = {
		[0] = {
			--白
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
			}),
			size = 3,
		},
		[1] = {
			--白
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
			}),
			size = 3,
		},
		[2] = {
			--蓝
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 170, 255)),
			}),
			size = 3,
		},
		[3] = {
			--紫
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255)),
			}),
			size = 3,
		},
		[4] = {
			--橙
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 85, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 85, 0)),
			}),
			size = 3,
		},
		[5] = {
			--彩
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
				ColorSequenceKeypoint.new(0.1510416716337204, Color3.new(0.615686297416687, 0, 1)),
				ColorSequenceKeypoint.new(0.3072916567325592, Color3.new(0.06666667014360428, 0, 1)),
				ColorSequenceKeypoint.new(0.4965277910232544, Color3.new(0, 1, 1)),
				ColorSequenceKeypoint.new(0.6649305820465088, Color3.new(0.01568627543747425, 1, 0)),
				ColorSequenceKeypoint.new(0.8385416865348816, Color3.new(1, 1, 0)),
				ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0)),
			}),
			size = 3,
		},
		[6] = {
			--星空
			colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 255, 255)),
				ColorSequenceKeypoint.new(0.25, Color3.fromRGB(85, 0, 127)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.75, Color3.fromRGB(85, 0, 127)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 255, 255)),
			}),
			size = 3,
		},
		transparencySequence = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0),
		}),
	},
}

function UIElementEffect:AddEffect(uiElement)
	uiElement:RemoveEffect()
	local colorSequence = UITypeAndPriorityToSequence[uiElement.ui_type][uiElement.Priority].colorSequence
	local transparencySequence = UITypeAndPriorityToSequence[uiElement.ui_type].transparencySequence

	if uiElement.ui_type == "Frame" then
		local stroke = uiElement:GetChild("UIStroke") or Instance.new("UIStroke", uiElement.instance)
		stroke.Color = Color3.new(255, 255, 255)
		local stokeGradient = stroke:FindFirstChild("UIGradient") or Instance.new("UIGradient", stroke)
		stokeGradient.Color = colorSequence
		stokeGradient.Transparency = transparencySequence
		stroke.Thickness = UITypeAndPriorityToSequence[uiElement.ui_type][uiElement.Priority].size
		uiElement.effect = stroke
		local Rotation = 0
		uiElement.EffectCon = task.spawn(function()
			while true do
				if not stroke or stroke.Parent == nil then
					break
				end
				Rotation = Rotation + 1
				stokeGradient.Rotation = Rotation
				task.wait()
			end
		end)
	elseif uiElement.ui_type == "Text" then
		local gradient = uiElement:GetChild("UIGradient") or Instance.new("UIGradient", uiElement.instance)
		gradient.Color = colorSequence
		gradient.Transparency = transparencySequence
		uiElement.effect = gradient
	end
end

function UIElementEffect:RemoveEffect(uiElement)
    if uiElement.effect then
        uiElement.effect:Destroy()
    end
end

function UIElementEffect:AddSelectedEffect(uiElement)
    if uiElement.ui_type == "Frame" then
        local stroke = uiElement:GetChild("UIStroke") or Instance.new("UIStroke", uiElement.instance)
		stroke.Color = Color3.new(255,255,255)
		stroke.Transparency = 0
        stroke.Thickness = UITypeAndPriorityToSequence[uiElement.ui_type][uiElement.Priority].size * 1.6
        uiElement.effect = stroke
    end
end

function UIElementEffect:AddDeleteEffect(uiElement)
    if uiElement.ui_type == "Frame" then
        local stroke = uiElement:GetChild("UIStroke") or Instance.new("UIStroke", uiElement.instance)
		stroke.Color = Color3.new(255,0,0)
		stroke.Transparency = 0
        stroke.Thickness = UITypeAndPriorityToSequence[uiElement.ui_type][uiElement.Priority].size * 1.6
        uiElement.effect = stroke
    end
end

function UIElementEffect:RemoveDeleteEffect(uiElement)
	if uiElement.effect then
        if uiElement.ui_type == "Frame" then
			uiElement.effect.Transparency = 0.4
            uiElement.effect.Color = Color3.new(218, 218, 218)
            uiElement.effect.Thickness = uiElement.effect.Thickness / 1.6
        end
    end
end

function UIElementEffect:RemoveSelectedEffect(uiElement)
    if uiElement.effect then
        if uiElement.ui_type == "Frame" then
			uiElement.effect.Transparency = 0.4
            uiElement.effect.Color = Color3.new(218, 218, 218)
            uiElement.effect.Thickness = uiElement.effect.Thickness / 1.6
        end
    end
end

function UIElementEffect:TweenSize(uiElement, endSize, duration)
    if uiElement.sizeTween then
        uiElement.sizeTween:Cancel()
    end
	endSize = UDim2.new(math.max(0, endSize.X.Scale), math.max(0, endSize.X.Offset), math.max(0, endSize.Y.Scale), math.max(0, endSize.Y.Offset))
    uiElement.sizeTween = TweenService:Create(uiElement.instance, TweenInfo.new(duration or 0.1, Enum.EasingStyle.Sine), {
        Size = endSize
    })
    uiElement.sizeTween:Play()
end

return UIElementEffect