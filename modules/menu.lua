function menu.information()
    if imgui.BeginTabItem("Information") then
        gui.title("Help", true)

        function helpItem(item, text)
            imgui.BulletText(item)
            gui.helpMarker(text)
        end

        helpItem("Linear SV", "Creates an SV gradient based on two points in time")
        helpItem("Stutter SV", "Creates a normalized stutter effect with start, equalize and end SV")
        helpItem("Cubic Bezier", "Creates velocity points for a path defined by a cubic bezier curve")
        helpItem("Range Editor", "Edit SVs/Notes/BPM points in the map in nearly limitless ways")

        gui.title("About", false, "Hyperlinks have been removed so copy-able links have been provided to paste into your browser")

        function listItem(text, url)
            imgui.TextWrapped(text)
            gui.hyperlink(url)
        end

        listItem("iceSV Wiki (in progress)", "https://github.com/IceDynamix/iceSV/wiki")
        listItem("Github Repository", "https://github.com/IceDynamix/iceSV")
        listItem("Heavily inspired by Evening's re:amber", "https://github.com/Eve-ning/reamber")

        gui.tooltip("let's be real this is basically a direct quaver port")

        imgui.EndTabItem()
    end
end

function menu.linearSV()

    local menuID = "linear"

    if imgui.BeginTabItem("Linear") then

        -- Initialize variables
        local vars = {
            startSV = 1,
            endSV = 1,
            intermediatePoints = 16,
            startOffset = 0,
            endOffset = 0,
            skipEndSV = false,
            lastSVs = {}
        }

        util.retrieveStateVariables(menuID, vars)

        -- Create UI Elements

        gui.title("Offset", true)
        gui.startEndOffset(vars)

        gui.title("Velocities")

        local velocities = { vars.startSV, vars.endSV }
        imgui.PushItemWidth(style.CONTENT_WIDTH)
        _, velocities = imgui.DragFloat2("Start/End Velocity", velocities, 0.01, -10.0, 10.0, "%.2fx")
        imgui.PopItemWidth()
        vars.startSV, vars.endSV = table.unpack(velocities)
        gui.helpMarker("Ctrl+Click to enter as text!")

        local widths = util.calcAbsoluteWidths({0.7,0.3})

        if imgui.Button("Swap start and end velocity", {widths[1], style.DEFAULT_WIDGET_HEIGHT}) then
            vars.startSV, vars.endSV = vars.endSV, vars.startSV
        end

        gui.sameLine()

        if imgui.Button("Reset", {widths[2], style.DEFAULT_WIDGET_HEIGHT}) then
            vars.startSV = 1
            vars.endSV = 1
        end

        gui.title("Utilities")

        gui.intermediatePoints(vars)

        gui.title("Calculate")

        if gui.insertButton() then
            vars.lastSVs = sv.linear(
                vars.startSV,
                vars.endSV,
                vars.startOffset,
                vars.endOffset,
                vars.intermediatePoints,
                vars.skipEndSV
            )
            editor.placeElements(vars.lastSVs)
        end

        if imgui.Button("Cross multiply in map", style.FULLSIZE_WIDGET_SIZE) then
            baseSV = util.filter(
                map.ScrollVelocities,
                function (k, v)
                    return v.StartTime >= vars.startOffset
                        and vars.startOffset <= vars.endOffset
                end
            )
            crossSV = sv.linear(
                vars.startSV,
                vars.endSV,
                vars.startOffset,
                vars.endOffset,
                500, -- used for more accurate linear values when looking up
                vars.skipEndSV
            )
            newSV = sv.crossMultiply(baseSV, crossSV)
            actions.RemoveScrollVelocityBatch(baseSV)
            editor.placeElements(newSV)
        end

        gui.tooltip("Multiplies all SVs in the map between the given start and end offset linearly with the given parameters")

        -- Save variables
        util.saveStateVariables(menuID, vars)

        imgui.EndTabItem()
    end
end

function menu.stutterSV()
    if imgui.BeginTabItem("Stutter") then
        local menuID = "stutter"
        local vars = {
            skipEndSV = false,
            skipFinalEndSV = false,
            startSV = 1.5,
            duration = 0.5,
            averageSV = 1.0,
            lastSVs = {},
            allowNegativeValues = false,
            effectDurationMode = 0,
            effectDurationValue = 1
        }
        util.retrieveStateVariables(menuID, vars)

        gui.title("Note", true)

        imgui.Text("Select some hitobjects and play around!")

        gui.title("Settings")

        local modes = {
            "Distance between notes",
            "BPM/measure snap",
            "Absolute length"
        }

        imgui.PushItemWidth(style.CONTENT_WIDTH)
        _, vars.effectDurationMode = imgui.Combo("Effect duration mode", vars.effectDurationMode, modes, #modes)
        imgui.PopItemWidth()

        gui.helpMarker("This determines the effect duration of a single stutter. Hover over the help marker input box in each mode to find out more.")

        local helpMarkerText = ""

        imgui.PushItemWidth(style.CONTENT_WIDTH)
        -- scale with distance between notes
        if vars.effectDurationMode == 0 then
            _, vars.effectDurationValue = imgui.SliderFloat("Duration Scale", vars.effectDurationValue, 0, 1, "%.2f")
            helpMarkerText = "Scales the effect duration together with the distance between two offsets. If left on 1, then all stutters will seamlessly connect to each other."

        -- snap
        elseif vars.effectDurationMode == 1 then
            _, vars.effectDurationValue = imgui.DragFloat("Duration Length", vars.effectDurationValue, 0.01, 0, 10e10, "%.2f")
            helpMarkerText = "Input as a fraction of a beat, e.g. 0.25 would represent an interval of 1/4."

        -- absolute
        elseif vars.effectDurationMode == 2 then
            _, vars.effectDurationValue = imgui.DragFloat("Duration Length", vars.effectDurationValue, 0.01, 0, 10e10, "%.2f")
            helpMarkerText = "Fixed length, based on a millisecond value."
        end
        imgui.PopItemWidth()
        gui.helpMarker(helpMarkerText)

        gui.spacing()

        local startSVBounds = {}

        imgui.PushItemWidth(style.CONTENT_WIDTH)

        if vars.allowNegativeValues then
            startSVBounds = {-1000, 1000}
            _, vars.startSV = imgui.DragFloat("Start velocity", vars.startSV, 0.01, startSVBounds[1], startSVBounds[2], "%.2fx")
        else
            startSVBounds = {0, vars.averageSV/vars.duration}
            _, vars.startSV = imgui.SliderFloat("Start velocity", vars.startSV, startSVBounds[1], startSVBounds[2], "%.2fx")
        end

        gui.helpMarker(string.format("Current bounds: %.2fx - %.2fx", startSVBounds[1], startSVBounds[2]))

        imgui.PopItemWidth()

        imgui.PushItemWidth(style.CONTENT_WIDTH)
        _, vars.duration = imgui.SliderFloat("Start SV Duration", vars.duration, 0.0, 1.0, "%.2f")
        imgui.PopItemWidth()

        -- Update limits after duration has changed
        vars.startSV = mathematics.clamp(vars.startSV, startSVBounds[1], startSVBounds[2])

        gui.spacing()

        gui.averageSV(vars)

        if not (vars.effectDurationMode == 0 and vars.effectDurationValue == 1) then
            _, vars.skipEndSV = imgui.Checkbox("Skip end SV of individual stutters?", vars.skipEndSV)
            gui.helpMarker("If you use any other mode than \"Distance between notes\" and Scale = 1, then the stutter SVs won't directy connect to each other anymore. This adjust the behavior for the end SV of each individual stutter.")
        end

        _, vars.skipFinalEndSV = imgui.Checkbox("Skip the final end SV?", vars.skipFinalEndSV)

        _, vars.allowNegativeValues = imgui.Checkbox("Allow negative Values?", vars.allowNegativeValues)
        gui.helpMarker(
            "Unexpected things can happen with negative SV, so I do not recommend " ..
            "turning on this option unless you are an expert. This will remove the " ..
            "limits for start SV. It can then be negative and also exceed the " ..
            "value, where the projected equalize SV would be start to become negative."
        )

        gui.title("Calculate")

        if gui.insertButton() then
            local offsets = {}

            for i, hitObject in pairs(state.SelectedHitObjects) do
                offsets[i] = hitObject.StartTime
            end

            if #offsets == 0 then
                statusMessage = "No hitobjects selected!"
            elseif #offsets == 1 then
                statusMessage = "Needs hitobjects on different offsets selected!"
            else
                offsets = util.uniqueBy(offsets)

                vars.lastSVs = sv.stutter(
                    table.sort(offsets),
                    vars.startSV,
                    vars.duration,
                    vars.averageSV,
                    vars.skipEndSV,
                    vars.skipFinalEndSV,
                    vars.effectDurationMode,
                    vars.effectDurationValue
                )

                editor.placeElements(vars.lastSVs)
            end
        end

        imgui.Text("Projected equalize SV: " .. string.format("%.2fx", (vars.duration*vars.startSV-vars.averageSV)/(vars.duration-1)))
        gui.helpMarker("This represents the velocity of the intermediate SV that is used to balance out the initial SV")

        util.saveStateVariables(menuID, vars)

        imgui.EndTabItem()
    end
end

function menu.cubicBezierSV()

    local menuID = "cubicBezier"

    if imgui.BeginTabItem("Cubic Bezier") then

        local vars = {
            startOffset = 0,
            endOffset = 0,
            x1 = 0.35,
            y1 = 0.00,
            x2 = 0.65,
            y2 = 1.00,
            averageSV = 1.0,
            intermediatePoints = 16,
            skipEndSV = false,
            lastSVs = {},
            lastPositionValues = {},
            stringInput = "cubic-bezier(.35,.0,.65,1)"
        }

        local xBounds = { 0.0, 1.0}
        local yBounds = {-1.0, 2.0}

        util.retrieveStateVariables(menuID, vars)

        gui.title("Note", true)
        gui.hyperlink("https://cubic-bezier.com/", "Create a cubic bezier here first!")

        gui.title("Offset")

        gui.startEndOffset(vars)

        gui.title("Values")

        local widths = util.calcAbsoluteWidths(style.BUTTON_WIDGET_RATIOS)

        if imgui.Button("Parse", {widths[1], style.DEFAULT_WIDGET_HEIGHT}) then
            local regex = "(-?%d*%.?%d+)"
            captures = {}
            for capture, _ in string.gmatch(vars.stringInput, regex) do
                statusMessage = statusMessage .. "," .. capture
                table.insert(captures, tonumber(capture))
            end
            if #captures >= 4 then
                vars.x1, vars.y1, vars.x2, vars.y2  = table.unpack(captures)
                statusMessage = "Copied values"
            else
                statusMessage = "Invalid string"
            end
        end

        gui.sameLine()

        imgui.PushItemWidth(widths[2])
        _, vars.stringInput = imgui.InputText("String", vars.stringInput, 50, 4112)
        imgui.PopItemWidth()

        imgui.SameLine()
        imgui.TextDisabled("(?)")
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.TextWrapped("Examples:")
            gui.bulletList({
                "cubic-bezier(.35,.0,.65,1)",
                ".17,.67,.83,.67",
                "https://cubic-bezier.com/#.76,-0.17,.63,1.35"
            })
            imgui.TextWrapped("Or anything else that has 4 numbers")
            imgui.EndTooltip()
        end

        imgui.PushItemWidth(style.CONTENT_WIDTH)

        local coords = {}
        _, coords = imgui.DragFloat4("x1, y1, x2, y2", {vars.x1, vars.y1, vars.x2, vars.y2}, 0.01, -5, 5, "%.2f")
        vars.y2, vars.x1, vars.y1, vars.x2 = table.unpack(coords) -- the coords returned are in this order for some stupid reason??
        imgui.PopItemWidth()

        gui.helpMarker("x: 0.0 - 1.0\ny: -1.0 - 2.0")

        -- Set limits here instead of in the DragFloat4, since this also covers the parsed string
        vars.x1, vars.x2 = table.unpack(util.mapFunctionToTable({vars.x1, vars.x2}, mathematics.clamp, xBounds))
        vars.y1, vars.y2 = table.unpack(util.mapFunctionToTable({vars.y1, vars.y2}, mathematics.clamp, yBounds))

        gui.spacing()

        gui.averageSV(vars, widths)

        gui.title("Utilities")

        gui.intermediatePoints(vars)

        gui.title("Calculate")

        if gui.insertButton() then
            statusMessage = "pressed"
            vars.lastSVs, vars.lastPositionValues = sv.cubicBezier(
                vars.x1,
                vars.y1,
                vars.x2,
                vars.y2,
                vars.startOffset,
                vars.endOffset,
                vars.averageSV,
                vars.intermediatePoints,
                vars.skipEndSV
            )

            editor.placeElements(vars.lastSVs)
        end

        if #vars.lastSVs > 0 then
            gui.title("Plots")
            gui.plot(vars.lastPositionValues, "Position Data", "y")
            gui.plot(vars.lastSVs, "Velocity Data", "Multiplier")
        end

        util.saveStateVariables(menuID, vars)

        imgui.EndTabItem()
    end
end

function menu.rangeEditor()
    if imgui.BeginTabItem("Range Editor") then
        local menuID = "range"
        local vars = {
            startOffset = 0,
            endOffset = 0,
            selections = {
                [0] = {},
                [1] = {},
                [2] = {}
            },
            type = 0,
            windowSelectedOpen = false,
            selectionFilters = {
                StartTime = {active = false, operator = 0, value = 0},
                Multiplier = {active = false, operator = 0, value = 0},
                EndTime = {active = false, operator = 0, value = 0},
                Lane = {active = false, operator = 0, value = 0},
                EditorLayer = {active = false, operator = 0, value = 0},
                Bpm = {active = false, operator = 0, value = 0}
            },
            arithmeticActions = {
                StartTime = {active = false, operator = 0, value = 0},
                Multiplier = {active = false, operator = 0, value = 0},
                EndTime = {active = false, operator = 0, value = 0},
                Lane = {active = false, operator = 0, value = 0},
                EditorLayer = {active = false, operator = 0, value = 0},
                Bpm = {active = false, operator = 0, value = 0}
            }
        }

        util.retrieveStateVariables(menuID, vars)

        gui.title("Note", true)
        imgui.TextWrapped("This is a very powerful tool and " ..
            "can potentially erase hours of work, so please be careful and work on a " ..
            "temporary difficulty if necessary! Please keep in mind that the selection " ..
            "is cleared once you leave the editor (including testplaying).")

        gui.title("Range")
        gui.startEndOffset(vars)

        gui.title("Selection", false, "You can think of the selection as your second clipboard. Once elements are in your selection, you can edit the element's values and/or paste them at different points in the map. Or just delete it, it's up to you.\n\nFilters limit SVs/Notes/BPM Points in the given range to be added/removed. Every active condition must be true (AND). A (OR) can be simulated by adding a range multiple times with different filters.")

        local selectableTypes = {
            "SVs",
            "Notes",
            "BPM Points"
        }

        imgui.PushItemWidth(style.CONTENT_WIDTH)
        _, vars.type = imgui.Combo("Selection Type", vars.type, selectableTypes, #selectableTypes)
        imgui.PopItemWidth()

        local buttonWidths = util.calcAbsoluteWidths({0.5, 0.5})
        local addRangeButtonWidth
        if #vars.selections[vars.type] > 0 then addRangeButtonWidth = buttonWidths[1]
        else addRangeButtonWidth = style.CONTENT_WIDTH end

        gui.spacing()

        local widths = util.calcAbsoluteWidths({0.25, 0.75}, style.CONTENT_WIDTH - style.DEFAULT_WIDGET_HEIGHT - style.SAMELINE_SPACING)
        for i, attribute in pairs(editor.typeAttributes[vars.type]) do
            if attribute == "StartTime" then goto continue end -- imagine a conitnue
            _, vars.selectionFilters[attribute].active = imgui.Checkbox(
                "##ActiveCheckbox" .. attribute, vars.selectionFilters[attribute].active
            )

            gui.sameLine()
            if vars.selectionFilters[attribute].active then
                imgui.PushItemWidth(widths[1])
                _, vars.selectionFilters[attribute].operator = imgui.Combo(
                    "##comparisonOperator" .. attribute,
                    vars.selectionFilters[attribute].operator,
                    mathematics.comparisonOperators,
                    #mathematics.comparisonOperators
                )
                imgui.PopItemWidth()
                gui.sameLine()
                imgui.PushItemWidth(widths[2])
                _, vars.selectionFilters[attribute].value = imgui.InputFloat(attribute, vars.selectionFilters[attribute].value)
                imgui.PopItemWidth()
            else
                imgui.Text(attribute .. " Filter")
            end

            ::continue::
        end
        gui.spacing()

        if imgui.Button("Add range", {addRangeButtonWidth, style.DEFAULT_WIDGET_HEIGHT}) then
            local elements = {
                [0] = map.ScrollVelocities,
                [1] = map.HitObjects,
                [2] = map.TimingPoints
            }

            local previousCount = #vars.selections[vars.type]

            -- Find

            -- Range filter
            local newElements = util.filter(
                elements[vars.type],
                function(i, element)
                    return      element.StartTime >= vars.startOffset
                            and element.StartTime <= vars.endOffset
                end
            )

            -- attribute filter
            for attribute, filter in pairs(vars.selectionFilters) do
                if filter.active then
                    newElements = util.filter(
                        newElements,
                        function(i, element)
                            return mathematics.evaluateComparison(
                                mathematics.comparisonOperators[filter.operator + 1],
                                element[attribute],
                                filter.value
                            ) end
                    )
                end
            end

            -- Add
            newElements = util.mergeUnique(
                vars.selections[vars.type],
                newElements,
                editor.typeAttributes[vars.type]
            )

            -- Sort
            newElements = table.sort(
                newElements,
                function(a,b) return a.StartTime < b.StartTime end
            )

            vars.selections[vars.type] = newElements

            if #vars.selections[vars.type] - previousCount == 0 then
                statusMessage = string.format("No %s in range!", selectableTypes[vars.type + 1])
            else
                statusMessage = string.format(
                    "Added %s %s",
                    #vars.selections[vars.type] - previousCount,
                    selectableTypes[vars.type + 1]
                )
            end
        end

        if #vars.selections[vars.type] > 0 then
            gui.sameLine()

            if imgui.Button("Remove range", {buttonWidths[2], style.DEFAULT_WIDGET_HEIGHT}) then
                local previousCount = #vars.selections[vars.type]

                -- attribute filter
                for attribute, filter in pairs(vars.selectionFilters) do
                    if filter.active then
                        vars.selections[vars.type] = util.filter(
                            vars.selections[vars.type],
                            function(i, element)
                                return not (mathematics.evaluateComparison(
                                    mathematics.comparisonOperators[filter.operator + 1],
                                    element[attribute],
                                    filter.value
                                ) and (
                                    element.StartTime >= vars.startOffset and
                                    element.StartTime <= vars.endOffset
                                ))
                            end
                        )
                    end
                end

                if #vars.selections[vars.type] - previousCount == 0 then
                    statusMessage = string.format("No %s in range!", selectableTypes[vars.type + 1])
                else
                    statusMessage = string.format(
                        "Removed %s %s",
                        previousCount - #vars.selections[vars.type],
                        selectableTypes[vars.type + 1]
                    )
                end

            end

            gui.sameLine()
            imgui.Text(string.format("%s %s in selection", #vars.selections[vars.type], selectableTypes[vars.type + 1]))

            if imgui.Button("Clear selection", {buttonWidths[1], style.DEFAULT_WIDGET_HEIGHT}) then
                vars.selections[vars.type] = {}
                statusMessage = "Cleared selection"
            end

            gui.sameLine()

            if imgui.Button("Toggle window", {buttonWidths[2], style.DEFAULT_WIDGET_HEIGHT}) then
                vars.windowSelectedOpen = not vars.windowSelectedOpen
            end

            if vars.windowSelectedOpen then
                window.selectedRange(vars)
            end

            -- TODO: Crossedit (add, multiply)
            -- TODO: Subdivide by n or to time
            -- TODO: Delete nth with offset
            -- TODO: Plot (not for hitobjects)
            -- TODO: Export as CSV/YAML

            local undoHelpText = "If you decide to undo a value edit via the editor Ctrl+Z shortcut, then please keep in mind that you have to undo twice to get back to the original state, since the plugin essentially removes and then pastes the edited points. You'll need to redo your selection, since restoring the previous selection isn't doable right now. Also, editing editor layer doesn't work right now, but filtering does."

            gui.title("Edit Values", false, undoHelpText)
            widths = util.calcAbsoluteWidths({0.35, 0.25, 0.40}, style.CONTENT_WIDTH - style.DEFAULT_WIDGET_HEIGHT - style.SAMELINE_SPACING*2)
            for i, attribute in pairs(editor.typeAttributes[vars.type]) do

                if attribute == "EditorLayer" then goto continue end

                _, vars.arithmeticActions[attribute].active = imgui.Checkbox(
                    "##activeCheckbox" .. attribute, vars.arithmeticActions[attribute].active
                )

                gui.sameLine()
                if vars.arithmeticActions[attribute].active then
                    if imgui.Button("Apply##" .. attribute, {widths[1], style.DEFAULT_WIDGET_HEIGHT}) then
                        local newElements = editor.createNewTableOfElements(
                            vars.selections[vars.type],
                            vars.type,
                            {
                                [attribute] = function (value)
                                    return mathematics.evaluateArithmetics(
                                        mathematics.arithmeticOperators[vars.arithmeticActions[attribute].operator + 1],
                                        value,
                                        vars.arithmeticActions[attribute].value
                                    )
                                end
                            }
                        )
                        editor.removeElements(vars.selections[vars.type], vars.type)
                        editor.placeElements(newElements, vars.type)
                        vars.selections[vars.type] = newElements
                    end

                    gui.sameLine()
                    imgui.PushItemWidth(widths[2])
                    _, vars.arithmeticActions[attribute].operator = imgui.Combo(
                        "##arithmeticOperator" .. attribute,
                        vars.arithmeticActions[attribute].operator,
                        mathematics.arithmeticOperators,
                        #mathematics.arithmeticOperators
                    )
                    imgui.PopItemWidth()
                    gui.sameLine()
                    imgui.PushItemWidth(widths[3])
                    _, vars.arithmeticActions[attribute].value = imgui.InputFloat(
                        attribute .. "##arithmeticValue" .. attribute,
                        vars.arithmeticActions[attribute].value
                    )
                    imgui.PopItemWidth()
                else
                    imgui.Text(attribute)
                end
                ::continue::
            end

            gui.title("Editor Actions")

            if imgui.Button("Paste at current timestamp", style.FULLSIZE_WIDGET_SIZE) then
                local delta = state.SongTime - vars.selections[vars.type][1].StartTime

                local newTable = editor.createNewTableOfElements(
                    vars.selections[vars.type],
                    vars.type,
                    {
                        StartTime = function (startTime) return startTime + delta end,
                        EndTime = function (endTime) -- used for notes, ignored for svs/bpms
                            if endTime == 0 then return 0
                            else return endTime + delta end
                        end
                    }
                )

                editor.placeElements(newTable, vars.type)
            end

            if imgui.Button("Paste at all selected notes", style.FULLSIZE_WIDGET_SIZE) then
                for _, hitObject in pairs(state.SelectedHitObjects) do
                    local delta = hitObject.StartTime - vars.selections[vars.type][1].StartTime
                    local newTable = editor.createNewTableOfElements(
                        vars.selections[vars.type],
                        vars.type,
                        {
                            StartTime = function (startTime) return startTime + delta end,
                            EndTime = function (endTime) -- used for notes, ignored for svs/bpms
                                if endTime == 0 then return 0
                                else return endTime + delta end
                            end
                        }
                    )
                    editor.placeElements(newTable, vars.type)
                end
            end

            if imgui.Button("Delete selection from map", style.FULLSIZE_WIDGET_SIZE) then
                editor.removeElements(vars.selections[vars.type], vars.type)
            end

            if imgui.Button("Select in editor", style.FULLSIZE_WIDGET_SIZE) and vars.type == 1 then
                actions.SetHitObjectSelection(vars.selections[1])
            end
        end

        util.saveStateVariables(menuID, vars)
        imgui.EndTabItem()
    end
end
