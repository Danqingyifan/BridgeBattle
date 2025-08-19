local SkyLightAttrs = {
    {AttrName = 'Position', AttrType = 'vector3', DefaultValue = Vector3.New(0, 0, 0)},
    {AttrName = 'Euler', AttrType = 'vector3', DefaultValue = Vector3.New(0, 0, 0)},
    {AttrName = 'LocalPosition', AttrType = 'vector3', DefaultValue = Vector3.New(0, 0, 0)},
    {AttrName = 'LocalEuler', AttrType = 'vector3', DefaultValue = Vector3.New(0, 0, 0)},
    {AttrName = 'LocalScale', AttrType = 'vector3', DefaultValue = Vector3.New(1, 1, 1)},
    {AttrName = 'CubeBorderEnable', AttrType = 'bool', DefaultValue = false},
    {AttrName = 'CubeBorderColor', AttrType = 'color', DefaultValue = ColorQuad.New(135, 206, 250, 255)},
    {AttrName = 'SkyLightType', AttrType = 'enum', EnumValues = 'Skybox,Gradient'},
    {AttrName = 'Intensity', AttrType = 'double', DefaultValue = 1.1},
    {AttrName = 'Color', AttrType = 'color', DefaultValue = ColorQuad.New(226, 244, 255, 255)},
    {AttrName = 'AmbientSkyColor', AttrType = 'color', DefaultValue = ColorQuad.New(139, 156, 188, 255)},
    {AttrName = 'AmbientEquatorColor', AttrType = 'color', DefaultValue = ColorQuad.New(150, 158, 172, 255)},
    {AttrName = 'AmbientGroundColor', AttrType = 'color', DefaultValue = ColorQuad.New(75, 59, 53, 255)}
}

local AtmosphereAttrs = {
    {AttrName = 'FogType', AttrType = 'enum', EnumValues = 'Disable,Linear'},
    {AttrName = 'FogColor', AttrType = 'color', DefaultValue = ColorQuad.New(64, 77, 86, 255)},
    {AttrName = 'FogStart', AttrType = 'double', DefaultValue = 500.00},
    {AttrName = 'FogEnd', AttrType = 'double', DefaultValue = 12000.00},
    {AttrName = 'FogOffset', AttrType = 'double', DefaultValue = 0.8}
}

local SkydomeAttrs = {
    {AttrName = 'HazeColor', AttrType = 'color', DefaultValue = ColorQuad.New(10, 32, 66, 255)},
    {AttrName = 'HorizonColor', AttrType = 'color', DefaultValue = ColorQuad.New(65, 72, 84, 255)},
    {AttrName = 'ZenithColor', AttrType = 'color', DefaultValue = ColorQuad.New(90, 102, 111, 255)},
    {AttrName = 'SkyBoxType', AttrType = 'enum', EnumValues = 'Game,Custom'},
    {AttrName = 'CubeAssetID', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'AdvanceMaterialAssetID', AttrType = 'string', DefaultValue = 'sandboxSysId&filetype=8&restype=6://Materials/Studio/AdvancedSkybox.mat'},
    {AttrName = 'CloudsEnable', AttrType = 'bool', DefaultValue = true},
    {AttrName = 'ShadowColor', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'ShadowDarkColor', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'CloudsCoverage', AttrType = 'double', DefaultValue = 0.042},
    {AttrName = 'LightIntensity', AttrType = 'double', DefaultValue = 0.1},
    {AttrName = 'CloudsSpeed', AttrType = 'double', DefaultValue = 0.1},
    {AttrName = 'CloudsAlpha', AttrType = 'double', DefaultValue = 0.41},
    {AttrName = 'StarsAmount', AttrType = 'double', DefaultValue = 0.5}
}

local SunLightAttrs = {
    {AttrName = 'Intensity', AttrType = 'double', DefaultValue = 0.8},
    {AttrName = 'Color', AttrType = 'color', DefaultValue = ColorQuad.New(212, 242, 255, 255)},
    {AttrName = 'LockTimeDir', AttrType = 'bool', DefaultValue = false},
    {AttrName = 'Euler', AttrType = 'vector3', DefaultValue = Vector3.New(36, -27, -93)},
    {AttrName = 'ShadowBias', AttrType = 'double', DefaultValue = 0.35},
    {AttrName = 'ShadowSlopeBias', AttrType = 'double', DefaultValue = 0.4},
    {AttrName = 'ShadowDistance', AttrType = 'double', DefaultValue = 8000},
    {AttrName = 'ShadowCascadeCount', AttrType = 'enum', EnumValues = 'One,Two,Three,Four'},
    {AttrName = 'SunRaysActive', AttrType = 'bool', DefaultValue = true},
    {AttrName = 'SunRaysScale', AttrType = 'double', DefaultValue = 0.45},
    {AttrName = 'SunRaysThreahold', AttrType = 'double', DefaultValue = 0.5},
    {AttrName = 'SunRaysColor', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'UseCustomSunAndMoonTex', AttrType = 'bool', DefaultValue = false},
    {AttrName = 'SunTex', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'SunScale', AttrType = 'vector2', DefaultValue = Vector2.New(1, 1)},
    {AttrName = 'MoonTex', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'MoonScale', AttrType = 'vector2', DefaultValue = Vector2.New(1, 1)}
}

local PostProcessingAttrs = {
    {AttrName = 'BloomActive', AttrType = 'bool', DefaultValue = true},
    {AttrName = 'BloomIntensity', AttrType = 'double', DefaultValue = 2},
    {AttrName = 'BloomThreshold', AttrType = 'double', DefaultValue = 1},
    {AttrName = 'BloomLuminanceScale', AttrType = 'double', DefaultValue = 1},
    {AttrName = 'BloomIterator', AttrType = 'double', DefaultValue = 4},
    {AttrName = 'DofActive', AttrType = 'bool', DefaultValue = false},
    {AttrName = 'DofFocalRegion', AttrType = 'double', DefaultValue = 0},
    {AttrName = 'DofNearTransitionRegion', AttrType = 'double', DefaultValue = 300},
    {AttrName = 'DofFarTransitionRegion', AttrType = 'double', DefaultValue = 500},
    {AttrName = 'DofFocalDistance', AttrType = 'double', DefaultValue = 100},
    {AttrName = 'DofScale', AttrType = 'double', DefaultValue = 1},
    {AttrName = 'AntialiasingEnable', AttrType = 'bool', DefaultValue = true},
    {AttrName = 'AntialiasingMethod', AttrType = 'enum', EnumValues = 'AntialiasingMethodFXAA,AntialiasingMethodSMAA'},
    {AttrName = 'AntialiasingQuality', AttrType = 'enum', EnumValues = 'AntialiasingQualityLow,AntialiasingQualityMedium,AntialiasingQualityHigh'},
    {AttrName = 'LUTsActive', AttrType = 'bool', DefaultValue = true},
    {AttrName = 'LUTsTemperatureType', AttrType = 'enum', EnumValues = 'WhiteBalance,Color'},
    {AttrName = 'LUTsWhiteTemp', AttrType = 'double', DefaultValue = 6000},
    {AttrName = 'LUTsWhiteTint', AttrType = 'double', DefaultValue = 0},
    {AttrName = 'LUTsColorCorrectionShadowsMax', AttrType = 'double', DefaultValue = 0.8},
    {AttrName = 'LUTsColorCorrectionHighlightsMin', AttrType = 'double', DefaultValue = 0.5},
    {AttrName = 'LUTsBlueCorrection', AttrType = 'double', DefaultValue = 0.6},
    {AttrName = 'LUTsExpandGamut', AttrType = 'double', DefaultValue = 1},
    {AttrName = 'LUTsToneCurveAmout', AttrType = 'double', DefaultValue = 1},
    {AttrName = 'LUTsFilmicToneMapSlope', AttrType = 'double', DefaultValue = 0.88},
    {AttrName = 'LUTsFilmicToneMapToe', AttrType = 'double', DefaultValue = 0.55},
    {AttrName = 'LUTsFilmicToneMapShoulder', AttrType = 'double', DefaultValue = 0.26},
    {AttrName = 'LUTsFilmicToneMapBlackClip', AttrType = 'double', DefaultValue = 0},
    {AttrName = 'LUTsFilmicToneMapWhiteClip', AttrType = 'double', DefaultValue = 0.04},
    {AttrName = 'LUTsBaseSaturation', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsBaseContrast', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsBaseGamma', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsBaseGain', AttrType = 'color', DefaultValue = ColorQuad.New(225, 225, 225, 255)},
    {AttrName = 'LUTsBaseOffset', AttrType = 'color', DefaultValue = ColorQuad.New(0, 0, 0, 0)},
    {AttrName = 'LUTsShadowSaturation', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsShadowContrast', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsShadowGamma', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsShadowGain', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsShadowOffset', AttrType = 'color', DefaultValue = ColorQuad.New(0, 0, 0, 0)},
    {AttrName = 'LUTsMidtoneSaturation', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsMidtoneContrast', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsMidtoneGamma', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsMidtoneGain', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsMidtoneOffset', AttrType = 'color', DefaultValue = ColorQuad.New(0, 0, 0, 0)},
    {AttrName = 'LUTsHighlightSaturation', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsHighlightContrast', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsHighlightGamma', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsHighlightGain', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'LUTsHighlightOffset', AttrType = 'color', DefaultValue = ColorQuad.New(0, 0, 0, 0)},
    {AttrName = 'LUTsColorGradingLUTPath', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'GTAOActive', AttrType = 'bool', DefaultValue = false},
    {AttrName = 'GTAOThicknessblend', AttrType = 'double', DefaultValue = 0.75},
    {AttrName = 'GTAOFalloffStartRatio', AttrType = 'double', DefaultValue = 0.5},
    {AttrName = 'GTAOFalloffEnd', AttrType = 'double', DefaultValue = 70},
    {AttrName = 'GTAOFadeoutDistance', AttrType = 'double', DefaultValue = 7000},
    {AttrName = 'GTAOFadeoutRadius', AttrType = 'double', DefaultValue = 3000},
    {AttrName = 'GTAOIntensity', AttrType = 'double', DefaultValue = 0.5},
    {AttrName = 'GTAOPower', AttrType = 'double', DefaultValue = 3.5},
    {AttrName = 'ChromaticAberrationActive', AttrType = 'bool', DefaultValue = true},
    {AttrName = 'ChromaticAberrationIntensity', AttrType = 'double', DefaultValue = 1},
    {AttrName = 'ChromaticAberrationStartOffset', AttrType = 'double', DefaultValue = 0.4},
    {AttrName = 'ChromaticAberrationIterationStep', AttrType = 'double', DefaultValue = 0.01},
    {AttrName = 'ChromaticAberrationIterationSamples', AttrType = 'double', DefaultValue = 1},
    {AttrName = 'VignetteActive', AttrType = 'bool', DefaultValue = true},
    {AttrName = 'VignetteIntensity', AttrType = 'double', DefaultValue = 0.4},
    {AttrName = 'VignetteRounded', AttrType = 'bool', DefaultValue = false},
    {AttrName = 'VignetteSmoothness', AttrType = 'double', DefaultValue = 0.2},
    {AttrName = 'VignetteCenter', AttrType = 'vector2', DefaultValue = Vector2.New(0.5, 0.5)},
    {AttrName = 'VignetteColor', AttrType = 'color', DefaultValue = ColorQuad.New(75, 75, 75, 255)},
    {AttrName = 'VignetteMode', AttrType = 'enum', EnumValues = 'Classic,Masked'},
    {AttrName = 'VignetteRoundness', AttrType = 'double', DefaultValue = 1},
    {AttrName = 'VignetteMaskTexturePath', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'VignetteMaskOpacity', AttrType = 'double', DefaultValue = 1},
    {AttrName = 'RadialFlashActive', AttrType = 'bool', DefaultValue = false},
    {AttrName = 'RadialFlashLuminance', AttrType = 'double', DefaultValue = 0.65},
    {AttrName = 'RadialFlashRadius', AttrType = 'double', DefaultValue = 0.001},
    {AttrName = 'RadialFlashContrast', AttrType = 'double', DefaultValue = 3},
    {AttrName = 'RadialFlashThreshold', AttrType = 'double', DefaultValue = 0.06},
    {AttrName = 'RadialFlashColor', AttrType = 'color', DefaultValue = ColorQuad.New(255, 255, 255, 255)},
    {AttrName = 'RadialFlashPivot', AttrType = 'vector2', DefaultValue = Vector2.New(0.5, 0.5)},
    {AttrName = 'RadialFlashScale', AttrType = 'vector2', DefaultValue = Vector2.New(27.36, 0.2)},
    {AttrName = 'RadialFlashSpeed', AttrType = 'vector2', DefaultValue = Vector2.New(0, -5.5)},
    {AttrName = 'RadialFlashNoiseTexturePath', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'MaterialListActive', AttrType = 'bool', DefaultValue = false},
    {AttrName = 'MaterialList', AttrType = 'table', DefaultValue = {}}
}

local CameraConfig = {
    {AttrName = 'Position', AttrType = 'vector3', DefaultValue = Vector3.New(0, 0, 0)},
    {AttrName = 'Euler', AttrType = 'vector3', DefaultValue = Vector3.New(0, 0, 0)}
}

local LevelConfig = {
    {AttrName = 'LevelChineseName', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'LevelDesc', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'LevelCoverAssetID', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'LevelRecommendPlant', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'LevelZombie', AttrType = 'string', DefaultValue = ''}
}

local configDesc = {
    {
        AttrName = 'SkyLight',
        AttrType = 'table',
        SubAttrs = SkyLightAttrs,
        SubAttrsClass = 'SkyLightAttrs'
    },
    {
        AttrName = 'Atmosphere',
        AttrType = 'table',
        SubAttrs = AtmosphereAttrs,
        SubAttrsClass = 'AtmosphereAttrs'
    },
    {
        AttrName = 'Skydome',
        AttrType = 'table',
        SubAttrs = SkydomeAttrs,
        SubAttrsClass = 'SkydomeAttrs'
    },
    {
        AttrName = 'SunLight',
        AttrType = 'table',
        SubAttrs = SunLightAttrs,
        SubAttrsClass = 'SunLightAttrs'
    },
    {
        AttrName = 'PostProcessing',
        AttrType = 'table',
        SubAttrs = PostProcessingAttrs,
        SubAttrsClass = 'PostProcessingAttrs'
    },
    {
        AttrName = 'AreaCameraConfig',
        AttrType = 'table array',
        SubAttrs = CameraConfig,
        SubAttrsClass = 'CameraConfig'
    },
    {
        AttrName = 'LevelConfig',
        AttrType = 'table',
        SubAttrs = LevelConfig,
        SubAttrsClass = 'LevelConfig'
    }
}
return configDesc
