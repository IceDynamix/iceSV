function editor.placeElements(elements, type)
    if #elements == 0 then return end
    local status = "Inserted " .. #elements .. " "
    if not type or type == 0 then
        actions.PlaceScrollVelocityBatch(elements)
        status = status .. "SV"
    elseif type == 1 then
        actions.PlaceHitObjectBatch(elements)
        status = status .. "note"
    elseif type == 2 then
        actions.PlaceTimingPointBatch(elements)
        status = status .. "BPM Point"
    end
    local pluralS = #elements == 1 and "" or "s"
    statusMessage = status .. pluralS  .. "!"
end

function editor.removeElements(elements, type)
    if #elements == 0 then return end
    local status = "Removed " .. #elements .. " "
    if not type or type == 0 then
        actions.RemoveScrollVelocityBatch(elements)
        status = status .. "SVs"
    elseif type == 1 then
        actions.RemoveHitObjectBatch(elements)
        status = status .. "notes"
    elseif type == 2 then
        actions.RemoveTimingPointBatch(elements)
        status = status .. "BPM Points"
    end
    statusMessage = status .. "!"
end

editor.typeAttributes = {
    -- SV
    [0] = {
        "StartTime",
        "Multiplier"
    },
    -- "Note"
    [1] = {
        "StartTime",
        "Lane",
        "EndTime",
        -- "HitSound", left out because there's some trouble with comparing hitsound values
        "EditorLayer"
    },
    -- BPM
    [2] = {
        "StartTime",
        "Bpm",
        -- "Signature", same reason
    }
}

--- Manipulates a table of elements with specified functions and returns a new table
-- Iterates over each possible attribute for a given type, it will apply a function
-- if one has been defined for that type in the settings table.
-- @param elements Table of elements to manipulate
-- @param typeMode Number between 0 and 2, representing the type SV, note or BPM
-- @param settings Table, where each key is a attribute of a type and the value is a function to apply to that attribute

--[[
    Example:
        settings = {
            StartTime = function(t) return t + 100 end
        }

        would shift all StartTimes by 100
]]

function editor.createNewTableOfElements(elements, typeMode, settings)
    local newTable = {}

    for i, element in pairs(elements) do
        local newElement = {}
        for _, attribute in pairs(editor.typeAttributes[typeMode]) do
            if settings[attribute] then
                newElement[attribute] = settings[attribute](element[attribute])
            else
                newElement[attribute] = element[attribute]
            end
        end

        newTable[i] = newElement
    end

    local newElements = {}

    for i, el in pairs(newTable) do
        if typeMode == 0 then
            newElements[i] = utils.CreateScrollVelocity(el.StartTime, el.Multiplier)
        elseif typeMode == 1 then
            newElements[i] = utils.CreateHitObject(el.StartTime, el.Lane, el.EndTime, nil)
        elseif typeMode == 2 then
            newElements[i] = utils.CreateTimingPoint(el.StartTime, el.Bpm, nil)
        end
    end

    return newElements
end
