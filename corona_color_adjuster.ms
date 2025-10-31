-- Corona Material Color Adjuster v1.1
-- Adjusts material colors and adds tonal correction to textures
-- REFACTOR v1.1: Created performScan() fn to update lists after each process.

(
    try (
        try (
            if coronaAdjuster_OriginalStates == undefined then
                global coronaAdjuster_OriginalStates = #()
        ) catch (
            global coronaAdjuster_OriginalStates = #()
        )
    
        fn createColorCorrectWithCurve = (
            local ccMap = CoronaColorCorrect()
            ccMap.name = uniqueName "ColorCorrect_Auto_"
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
        
        fn isAlreadyProcessed mat = (
            for state in coronaAdjuster_OriginalStates do (
                if state[1] == mat then return true
            )
            return false
        )
        
        fn saveOriginalState mat stateType originalData createdNode:undefined = (
            append coronaAdjuster_OriginalStates #(mat, stateType, originalData, createdNode)
        )
        
        fn deleteSmeNodes refs = (
            for k=1 to sme.GetNumViews() do (
                local view = sme.getView k
                view.SetSelectedNodes refs
                view.DeleteSelection()
            )
        )
        
        rollout materialSelectorDialog "Corona Material Color Adjuster" width:480 height:780
        (
            group "Scan Configuration" (
                spinner spn_maxValue "Value Limit (0-255):" range:[0,255,220] type:#integer fieldwidth:50 align:#left
                button btn_scan "Scan Materials" width:450 height:35 align:#center
            )
            
            group "Solid Colors - Color Clamp Method" (
                label lbl_colorInfo "Clamp the brightness to the selected value limit set in the scan configuration \nno changes to hue/saturation." height:30 enabled:false align:#left
                dotNetControl lv_colorMaterials "System.Windows.Forms.ListView" height:120 width:450
                checkbox chk_selectAllColors "Select All" checked:false align:#left enabled:false
            )
            
            group "Textures - Tonal Correction Method" (
                label lbl_textureInfo "Materials with textures in the diffuse/basecolor will receive a CoronaColorCorrect node \nwith custom tonal curve to control and preserve details in the brightest areas." height:30 enabled:false align:#left
                dotNetControl lv_textureMaterials "System.Windows.Forms.ListView" height:120 width:450
                checkbox chk_selectAllTextures "Select All" checked:false align:#left enabled:false
            )
            
            button btn_process "Process Selected Materials" width:450 height:45 align:#center enabled:false
            
            group "Processed Materials" (
                dotNetControl lv_processedMaterials "System.Windows.Forms.ListView" height:120 width:450
                checkbox chk_selectAllProcessed "Select All" checked:false align:#left enabled:false
                button btn_revert "Revert Selected" width:450 height:32 align:#center enabled:false
            )
            
            local colorMaterials = #()
            local textureMaterials = #()
            
            fn initListView lv = (
                lv.View = (dotNetClass "System.Windows.Forms.View").Details
                lv.FullRowSelect = true
                lv.GridLines = false
                lv.MultiSelect = true
                lv.CheckBoxes = false
                lv.HideSelection = false
                lv.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").None
                lv.HeaderStyle = (dotNetClass "System.Windows.Forms.ColumnHeaderStyle").None
                
                lv.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 42 42 42
                lv.ForeColor = (dotNetClass "System.Drawing.Color").FromArgb 200 200 200
                
                lv.Columns.Add "" 425
            )
            
            fn getSelectedIndices lv = (
                local indices = #()
                for i = 0 to (lv.SelectedIndices.Count - 1) do (
                    append indices (lv.SelectedIndices.Item[i] + 1)
                )
                return indices
            )
            
            fn updateProcessButtonState = (
                local colorSel = getSelectedIndices lv_colorMaterials
                local textureSel = getSelectedIndices lv_textureMaterials
                btn_process.enabled = (colorSel.count > 0 or textureSel.count > 0)
            )
            
            fn updateRevertButtonState = (
                local sel = getSelectedIndices lv_processedMaterials
                btn_revert.enabled = (sel.count > 0)
            )
            
            fn updateProcessedList = (
                lv_processedMaterials.Items.Clear()
                
                for state in coronaAdjuster_OriginalStates do (
                    local item = lv_processedMaterials.Items.Add state[1].name
                )
                
                if coronaAdjuster_OriginalStates.count > 0 then (
                    chk_selectAllProcessed.enabled = true
                ) else (
                    chk_selectAllProcessed.enabled = false
                    chk_selectAllProcessed.checked = false
                    btn_revert.enabled = false
                )
            )
        
            fn performScan = (
                local threshold = uiValueToCodeValue spn_maxValue.value
                
                colorMaterials = #()
                textureMaterials = #()
                
                for mat in sceneMaterials where classOf mat == CoronaPhysicalMtl do (
                    if not isAlreadyProcessed mat then (
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
                )
                
                lv_colorMaterials.Items.Clear()
                for mat in colorMaterials do (
                    lv_colorMaterials.Items.Add mat.name
                )
                
                lv_textureMaterials.Items.Clear()
                for mat in textureMaterials do (
                    lv_textureMaterials.Items.Add mat.name
                )
                
                lv_colorMaterials.Enabled = (colorMaterials.count > 0)
                chk_selectAllColors.enabled = (colorMaterials.count > 0)
                lv_textureMaterials.Enabled = (textureMaterials.count > 0)
                chk_selectAllTextures.enabled = (textureMaterials.count > 0)
                
                chk_selectAllColors.checked = false
                chk_selectAllTextures.checked = false
                
                updateProcessButtonState()
                updateProcessedList()
                
                format "\n=== SCAN COMPLETED ===\n"
                format "Solid colors found: %\n" colorMaterials.count
                format "Textured materials found: %\n" textureMaterials.count
                format "Already processed: %\n" coronaAdjuster_OriginalStates.count
            )
            
            on materialSelectorDialog open do (
                lv_colorMaterials.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 42 42 42
                lv_textureMaterials.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 42 42 42
                lv_processedMaterials.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 42 42 42
                
                initListView lv_colorMaterials
                initListView lv_textureMaterials
                initListView lv_processedMaterials
                
                updateProcessedList()
            )
            
            on lv_colorMaterials ItemSelectionChanged arg do (
                updateProcessButtonState()
            )
            
            on lv_textureMaterials ItemSelectionChanged arg do (
                updateProcessButtonState()
            )
            
            on lv_processedMaterials ItemSelectionChanged arg do (
                updateRevertButtonState()
            )
            
            on btn_scan pressed do (
                performScan()
            )
            
            on chk_selectAllColors changed state do (
                if state then (
                    for i = 0 to (lv_colorMaterials.Items.Count - 1) do (
                        lv_colorMaterials.Items.Item[i].Selected = true
                    )
                ) else (
                    lv_colorMaterials.SelectedItems.Clear()
                )
                updateProcessButtonState()
            )
            
            on chk_selectAllTextures changed state do (
                if state then (
                    for i = 0 to (lv_textureMaterials.Items.Count - 1) do (
                        lv_textureMaterials.Items.Item[i].Selected = true
                    )
                ) else (
                    lv_textureMaterials.SelectedItems.Clear()
                )
                updateProcessButtonState()
            )
            
            on chk_selectAllProcessed changed state do (
                if state then (
                    for i = 0 to (lv_processedMaterials.Items.Count - 1) do (
                        lv_processedMaterials.Items.Item[i].Selected = true
                    )
                ) else (
                    lv_processedMaterials.SelectedItems.Clear()
                )
                updateRevertButtonState()
            )
            
            on btn_process pressed do (
                local colorIndices = getSelectedIndices lv_colorMaterials
                local textureIndices = getSelectedIndices lv_textureMaterials
                local maxValueUI = spn_maxValue.value
                local maxValueCode = uiValueToCodeValue maxValueUI
                
                format "\n=== PROCESSING (UI: % / Code: %) ===\n\n" maxValueUI maxValueCode
                
                for idx in colorIndices do (
                    local mat = colorMaterials[idx]
                    format "% [Clamp]\n" mat.name
                    
                    if mat.baseTexmap != undefined and hasProperty mat.baseTexmap "color" then (
                        local originalColor = mat.baseTexmap.color
                        saveOriginalState mat #colorNode #(mat, mat.baseTexmap, originalColor)
                        
                        local maxVal = getColorValue originalColor
                        mat.baseTexmap.color = limitColorValue originalColor maxValue:maxValueCode
                        format "  Adjusted: % -> %\n" (maxVal as integer) maxValueCode
                    ) else (
                        local originalColor = mat.baseColor
                        saveOriginalState mat #baseColor #(mat, originalColor)
                        
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
                    
                    saveOriginalState mat #texture #(mat, existingMap) createdNode:ccMap
                    format "  CoronaColorCorrect inserted\n"
                )
                

                performScan()

                
                format "\n=== COMPLETED ===\n"
                format "Processed: Colors % | Textures %\n" colorIndices.count textureIndices.count
                
                messageBox ("Processing completed.\n\n" + \
                           "Colors adjusted: " + (colorIndices.count as string) + "\n" + \
                           "ColorCorrect inserted: " + (textureIndices.count as string)) \
                           title:"Completed"
            )
            
            on btn_revert pressed do (
                local selectedIndices = getSelectedIndices lv_processedMaterials
                
                format "\n=== REVERTING SELECTED ===\n\n"
                
                local statesToRemove = #()
                
                for idx in selectedIndices do (
                    local state = coronaAdjuster_OriginalStates[idx]
                    
                    try (
                        local mat = state[1]
                        local stateType = state[2]
                        local data = state[3]
                        
                        case stateType of (
                            #baseColor: (
                                data[1].baseColor = data[2]
                                format "% - Base color restored\n" mat.name
                            )
                            #colorNode: (
                                data[2].color = data[3]
                                format "% - Color node restored\n" mat.name
                            )
                            #texture: (
                                data[1].baseTexmap = data[2]
                                local createdNode = state[4]
                                if createdNode != undefined then (
                                    try (
                                        deleteSmeNodes #(createdNode)
                                        format "% - Texture restored, node deleted\n" mat.name
                                    ) catch (
                                        format "% - Texture restored\n" mat.name
                                    )
                                ) else (
                                    format "% - Texture restored\n" mat.name
                                )
                            )
                        )
                        append statesToRemove idx
                    ) catch (
                        format "% - Failed to revert\n" state[1].name
                    )
                )
                
                for i = statesToRemove.count to 1 by -1 do (
                    deleteItem coronaAdjuster_OriginalStates statesToRemove[i]
                )
                

                performScan()

                
                format "\n=== COMPLETED ===\n"
                messageBox "Materials reverted successfully." title:"Success"
            )
        )
        
        createDialog materialSelectorDialog
        
    ) catch (ex) (
        format "ERROR: %\n" ex
        messageBox ("Error: " + ex as string) title:"Error"
    )
)
