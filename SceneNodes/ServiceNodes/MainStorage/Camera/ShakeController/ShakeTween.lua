local Tween = {}

--补间动画列表
Tween.tweens = {}
Tween.tempTweens = {}

--补间类型
Tween.Easing = {
    Linear = "Linear",
    EaseInQuad = "EaseInQuad",
    EaseOutQuad = "EaseOutQuad",
    EaseInOutQuad = "EaseInOutQuad",
    EaseInCubic = "EaseInCubic",
    EaseOutCubic = "EaseOutCubic",
    EaseInOutCubic = "EaseInOutCubic",
    EaseInQuart = "EaseInQuart",
    EaseOutQuart = "EaseOutQuart",
    EaseInOutQuart = "EaseInOutQuart"
}
--生成TweenId
function Tween:GenerateTweenId()
    self.tweenId = self.tweenId or 0
    self.tweenId = self.tweenId + 1
    return self.tweenId
end
--注册补间动画
function Tween:AddTween(callback, duration, easing)
    local tweenId = self:GenerateTweenId()
    if self.updating then
        table.insert(
            Tween.tempTweens,
            {
                tweenId = tweenId,
                callback = callback,
                duration = duration,
                easing = easing or Tween.Easing.Linear,
                time = 0
            }
        )
    else
        table.insert(
            Tween.tweens,
            {
                tweenId = tweenId,
                callback = callback,
                duration = duration,
                easing = easing or Tween.Easing.Linear,
                time = 0
            }
        )
    end
    return tweenId
end

--移除补间动画
function Tween:RemoveTween(tweenId)
    for i, tween in ipairs(Tween.tweens) do
        if tween.tweenId == tweenId then
            table.remove(Tween.tweens, i)
            break
        end
    end
end

--补间添加完成回调
function Tween:AddTweenComplete(tweenId, complete)
    for i, tween in ipairs(Tween.tempTweens) do
        if tween.tweenId == tweenId then
            tween.complete = complete
            return
        end
    end
    for i, tween in ipairs(Tween.tweens) do
        if tween.tweenId == tweenId then
            tween.complete = complete
            return
        end
    end
end

function Tween:SetComplete(tweenId, complete)
    self:AddTweenComplete(tweenId, complete)
end

--取消补间动画
function Tween:Cancel(tweenId)
    self:RemoveTween(tweenId)
end

--MoveTo补间动画
function Tween:MoveTo(callback, from, to, duration, easing)
    return Tween:AddTween(
        function(progress)
            callback(from:Lerp(to, progress), progress)
        end,
        duration,
        easing
    )
end

--ScaleTo补间动画
function Tween:ScaleTo(callback, from, to, duration, easing)
    return Tween:AddTween(
        function(progress)
            callback(from:Lerp(to, progress), progress)
        end,
        duration,
        easing
    )
end

--RotateTo补间动画
function Tween:RotateTo(callback, from, to, duration, easing)
    return Tween:AddTween(
        function(progress)
            callback(from:Lerp(to, progress), progress)
        end,
        duration,
        easing
    )
end

--ColorTo补间动画
function Tween:ColorTo(callback, from, to, duration, easing)
    return Tween:AddTween(
        function(progress)
            callback(from:Lerp(to, progress), progress)
        end,
        duration,
        easing
    )
end

--AlphaTo补间动画
function Tween:AlphaTo(callback, from, to, duration, easing)
    return Tween:AddTween(
        function(progress)
            callback(from + (to - from) * progress, progress)
        end,
        duration,
        easing
    )
end

--SizeTo补间动画
function Tween:SizeTo(callback, from, to, duration, easing)
    return Tween:AddTween(
        function(progress)
            callback(from:Lerp(to, progress), progress)
        end,
        duration,
        easing
    )
end

--MoveBy补间动画
function Tween:MoveBy(callback, from, by, duration, easing)
    return Tween:AddTween(
        function(progress)
            callback(from + by * progress, progress)
        end,
        duration,
        easing
    )
end

--ScaleBy补间动画
function Tween:ScaleBy(callback, from, by, duration, easing)
    return Tween:AddTween(
        function(progress)
            callback(from + by * progress, progress)
        end,
        duration,
        easing
    )
end

--RotateBy补间动画
function Tween:RotateBy(callback, from, by, duration, easing)
    return Tween:AddTween(
        function(progress)
            callback(from + by * progress, progress)
        end,
        duration,
        easing
    )
end

--ColorBy补间动画
function Tween:ColorBy(callback, from, by, duration, easing)
    return Tween:AddTween(
        function(progress)
            callback(from + by * progress, progress)
        end,
        duration,
        easing
    )
end

--AlphaBy补间动画
function Tween:AlphaBy(callback, from, by, duration, easing)
    return Tween:AddTween(
        function(progress)
            callback(from + by * progress, progress)
        end,
        duration,
        easing
    )
end

--SizeBy补间动画
function Tween:SizeBy(callback, from, by, duration, easing)
    return Tween:AddTween(
        function(progress)
            callback(from + by * progress, progress)
        end,
        duration,
        easing
    )
end

--Linear
function Tween.Linear(progress)
    return progress
end

--EaseInQuad
function Tween.EaseInQuad(progress)
    return progress * progress
end

--EaseOutQuad
function Tween.EaseOutQuad(progress)
    return -progress * (progress - 2)
end

--EaseInOutQuad
function Tween.EaseInOutQuad(progress)
    if progress < 0.5 then
        return 2 * progress * progress
    else
        return -2 * progress * (progress - 2) - 1
    end
end

--EaseInCubic
function Tween.EaseInCubic(progress)
    return progress * progress * progress
end

--EaseOutCubic
function Tween.EaseOutCubic(progress)
    return (progress - 1) * (progress - 1) * (progress - 1) + 1
end

--EaseInOutCubic
function Tween.EaseInOutCubic(progress)
    if progress < 0.5 then
        return 4 * progress * progress * progress
    else
        return (progress - 1) * (2 * progress - 2) * (2 * progress - 2) + 1
    end
end

--EaseInQuart
function Tween.EaseInQuart(progress)
    return progress * progress * progress * progress
end

--EaseOutQuart
function Tween.EaseOutQuart(progress)
    return 1 - (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1)
end

--EaseInOutQuart
function Tween.EaseInOutQuart(progress)
    if progress < 0.5 then
        return 8 * progress * progress * progress * progress
    else
        return 1 - 8 * (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1)
    end
end

--更新
function Tween:Update(dt)
    self.updating = true
    --遍历补间动画，从后往前
    for i = #Tween.tweens, 1, -1 do
        local tween = Tween.tweens[i]
        if tween.time < tween.duration then
            tween.time = tween.time + dt
            local progress = tween.time / tween.duration
            if progress > 1 then
                progress = 1
            end
            if tween.easing == Tween.Easing.Linear then
                tween.callback(progress)
            elseif tween.easing == Tween.Easing.EaseInQuad then
                tween.callback(Tween.EaseInQuad(progress))
            elseif tween.easing == Tween.Easing.EaseOutQuad then
                tween.callback(Tween.EaseOutQuad(progress))
            elseif tween.easing == Tween.Easing.EaseInOutQuad then
                tween.callback(Tween.EaseInOutQuad(progress))
            elseif tween.easing == Tween.Easing.EaseInCubic then
                tween.callback(Tween.EaseInCubic(progress))
            elseif tween.easing == Tween.Easing.EaseOutCubic then
                tween.callback(Tween.EaseOutCubic(progress))
            elseif tween.easing == Tween.Easing.EaseInOutCubic then
                tween.callback(Tween.EaseInOutCubic(progress))
            elseif tween.easing == Tween.Easing.EaseInQuart then
                tween.callback(Tween.EaseInQuart(progress))
            elseif tween.easing == Tween.Easing.EaseOutQuart then
                tween.callback(Tween.EaseOutQuart(progress))
            elseif tween.easing == Tween.Easing.EaseInOutQuart then
                tween.callback(Tween.EaseInOutQuart(progress))
            end
        else
            tween.callback(1)
            if tween.complete ~= nil then
                tween.complete()
            end
            table.remove(Tween.tweens, i)
        end
    end
    self.updating = false
    for _, v in ipairs(Tween.tempTweens) do
        table.insert(Tween.tweens, v)
    end
    Tween.tempTweens = {}
end

return Tween
