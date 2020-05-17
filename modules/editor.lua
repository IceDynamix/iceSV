function editor.placeSVs(SVs)
    if #SVs == 0 then return end
        actions.PlaceScrollVelocityBatch(SVs)
    statusMessage = "Inserted " .. #SVs .. " SV points!"
end
