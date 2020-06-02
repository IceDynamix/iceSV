function editor.placeSVs(SVs)
    if #SVs == 0 then return end
        actions.PlaceScrollVelocityBatch(SVs)
    statusMessage = "Inserted " .. #SVs .. " SV points!"
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
