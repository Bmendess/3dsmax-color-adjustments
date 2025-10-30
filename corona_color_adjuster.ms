-- Corona Material Color Adjuster v1.0
-- Adjusts material colors and adds tonal correction to textures

(
    try (
        fn createColorCorrectWithCurve = (
            local ccMap = CoronaColorCorrect()
            ccMap.name = "ColorCorrect_Auto"
            ccMap.curveEnabled = true
            ccMap.curveMasterInterpol = 0
            ccMap.curveMasterNodes = #([0,0,0], [0.503,0.503,0], [1,0.718,0])
            ccMap.curveMasterLeftPoints = #([0,0,0], [0.403,0.403,0], [1,0.718,0])
            ccMap.curveMasterRightPoints = #([0,0,0], [0.603,0.603,0], [1,0.718,0])
            return ccMap
        )
        
        fn uiValueToCodeValue uiVal = (
            return (uiVal * 184.0 / 220.0) as integer
        )
        
        fn limitColorValue col maxValue:220 = (
            local maxVal = amax #(col.r, col.g, col.b)
            if maxVal > maxValue then (
                local scale = (maxValue as float) / maxVal
                return color (col.r * scale) (col.g * scale) (col.b * scale)
            )
            return col
        )
        
        fn isColorNode node = (
            return (classOf node == CoronaColor or classOf node == RGB_Color)
        )
        
        fn getColorValue col = (
            return amax #(col.r, col.g, col.b)
        )
        
        rollout materialSelectorDialog "Color Adjustment - Corona Materials" width:480 height:720
        (
            group "Materials with Solid Colors" (
                spinner spn_maxValue "Value Limit (0-255):" range:[0,255,220] type:#integer fieldwidth:50 align:#left
                
                label lbl_separator "" height:5
                
                multilistbox mlb_colorMaterials "" height:7 width:450
                checkbox chk_selectAllColors "Select All" checked:false align:#left
            )
            
            group "Materials with Textures" (
                multilistbox mlb_textureMaterials "" height:7 width:450
                checkbox chk_selectAllTextures "Select All" checked:false align:#left
            )
            
            label lbl_spacer1 "" height:15
            
            group "Method: Color Clamp" (
                label lbl_clamp1 "Materials with solid colors will have their RGB values" align:#left
                label lbl_clamp2 "adjusted proportionally to not exceed the limit." align:#left
                label lbl_clamp3 "Maintains hue and saturation, reducing only brightness." align:#left
            )
            
            label lbl_spacer2 "" height:15
            
            group "Method: Tonal Correction" (
                label lbl_cc1 "Materials with textures will receive a CoronaColorCorrect node" align:#left
                label lbl_cc2 "with custom tonal curve applied before the material." align:#left
                label lbl_cc3 "Preserves details while controlling high values." align:#left
            )
            
            label lbl_spacer3 "" height:10
            
            button btn_process "Process Materials" width:450 height:40 align:#center
            
            local colorMaterials = #()
            local textureMaterials = #()
            
            on materialSelectorDialog open do (
                local threshold = uiValueToCodeValue 220
                
                for mat in sceneMaterials where classOf mat == CoronaPhysicalMtl do (
                    if mat.baseTexmap != undefined then (
                        if isColorNode mat.baseTexmap then (
                            if hasProperty mat.baseTexmap "color" then (
                                local matColor = mat.baseTexmap.color
                                if getColorValue matColor > threshold then (
                                    append colorMaterials mat
                                )
                            )
                        ) else (
                            append textureMaterials mat
                        )
                    ) else (
                        local matColor = mat.baseColor
                        if getColorValue matColor > threshold then (
                            append colorMaterials mat
                        )
                    )
                )
                
                mlb_colorMaterials.items = for mat in colorMaterials collect mat.name
                mlb_textureMaterials.items = for mat in textureMaterials collect mat.name
            )
            
            on chk_selectAllColors changed state do (
                if state then
                    mlb_colorMaterials.selection = #{1..colorMaterials.count}
                else
                    mlb_colorMaterials.selection = #{}
            )
            
            on chk_selectAllTextures changed state do (
                if state then
                    mlb_textureMaterials.selection = #{1..textureMaterials.count}
                else
                    mlb_textureMaterials.selection = #{}
            )
            
            on btn_process pressed do (
                local colorIndices = mlb_colorMaterials.selection as array
                local textureIndices = mlb_textureMaterials.selection as array
                local maxValueUI = spn_maxValue.value
                local maxValueCode = uiValueToCodeValue maxValueUI
                
                if colorIndices.count == 0 and textureIndices.count == 0 then (
                    messageBox "Select at least one material." title:"Warning"
                    return false
                )
                
                format "\n=== PROCESSING (UI: % / Code: %) ===\n\n" maxValueUI maxValueCode
                
                for idx in colorIndices do (
                    local mat = colorMaterials[idx]
                    format "% [Clamp]\n" mat.name
                    
                    if mat.baseTexmap != undefined and hasProperty mat.baseTexmap "color" then (
                        local originalColor = mat.baseTexmap.color
                        local maxVal = getColorValue originalColor
                        mat.baseTexmap.color = limitColorValue originalColor maxValue:maxValueCode
                        format "  Adjusted: % -> %\n" (maxVal as integer) maxValueCode
                    ) else (
                        local originalColor = mat.baseColor
                        local maxVal = getColorValue originalColor
                        mat.baseColor = limitColorValue originalColor maxValue:maxValueCode
                        format "  Adjusted: % -> %\n" (maxVal as integer) maxValueCode
                    )
                )
                
                for idx in textureIndices do (
                    local mat = textureMaterials[idx]
                    format "% [ColorCorrect]\n" mat.name
                    
                    local existingMap = mat.baseTexmap
                    local ccMap = createColorCorrectWithCurve()
                    ccMap.inputTexmap = existingMap
                    mat.baseTexmap = ccMap
                    format "  CoronaColorCorrect inserted\n"
                )
                
                format "\n=== COMPLETED ===\n"
                format "Colors: % | Textures: %\n" colorIndices.count textureIndices.count
                
                messageBox ("Processing completed.\n\n" + \
                           "Colors adjusted: " + (colorIndices.count as string) + "\n" + \
                           "ColorCorrect inserted: " + (textureIndices.count as string)) \
                           title:"Completed"
                
                destroyDialog materialSelectorDialog
            )
        )
        
        createDialog materialSelectorDialog
        
    ) catch (ex) (
        format "ERROR: %\n" ex
    )
)
