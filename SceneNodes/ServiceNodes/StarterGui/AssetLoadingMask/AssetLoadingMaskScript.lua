
local AssetLoadingUI = {}

_G.AssetLoadingUI = AssetLoadingUI

script.Parent.Visible = false


function AssetLoadingUI.hide(...)
    print("AssetLoadingUI hide")
    script.Parent.Visible = false
    AssetLoadingUI.Mask.Size = Vector2.new(0, AssetLoadingUI.Mask.Size.Y)
    AssetLoadingUI.Priovt.Position = Vector2.new(0, 0)
end

function AssetLoadingUI.show(...)
    print("AssetLoadingUI show")
    if AssetLoadingUI.Mask == nil then
        AssetLoadingUI.Mask = script.Parent.UIImage.LoadingBG_1.LoadingBG.MaskUIImage.MaskUIImage
    end
    if AssetLoadingUI.Priovt == nil then
        AssetLoadingUI.Priovt = script.Parent.UIImage.LoadingBG_1.Priovt
    end
    if AssetLoadingUI.SizeWidget== nil then
        AssetLoadingUI.SizeWidget = script.Parent.UIImage.LoadingBG_1
    end

    script.Parent.Visible = true
end

function AssetLoadingUI.progress(value)
    local ProgressLen = AssetLoadingUI.SizeWidget.Size.X * value
    AssetLoadingUI.Priovt.Position = Vector2.new(ProgressLen, 0)
    AssetLoadingUI.Mask.Size = Vector2.new(ProgressLen, AssetLoadingUI.Mask.Size.Y)
end
