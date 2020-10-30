-- Returns a list of SV objects as defined in Quaver.API/Maps/Structures/SliderVelocityInfo.cs
function sv.linear(startSV, endSV, startOffset, endOffset, intermediatePoints, skipEndSV)

    local timeInterval = (endOffset - startOffset)/intermediatePoints
    local velocityInterval = (endSV - startSV)/intermediatePoints

    if skipEndSV then intermediatePoints = intermediatePoints - 1 end

    local SVs = {}

    for step = 0, intermediatePoints, 1 do
        local offset = step * timeInterval + startOffset
        local velocity = step * velocityInterval + startSV
        SVs[step+1] = utils.CreateScrollVelocity(offset, velocity)
    end

    return SVs
end

function sv.stutter(offsets, startSV, duration, averageSV, skipEndSV, skipFinalEndSV, effectDurationMode, effectDurationValue)
    local SVs = {}

    for i, offset in ipairs(offsets) do
        if i == #offsets then break end

        table.insert(SVs, utils.CreateScrollVelocity(offset, startSV))

        local length
        if effectDurationMode == 0 then -- scale with distance between notes
            length = (offsets[i+1] - offset) * effectDurationValue
        elseif effectDurationMode == 1 then -- scale with snap
            length = effectDurationValue * 60000/map.GetTimingPointAt(offset).Bpm
        elseif effectDurationMode == 2 then -- absolute length
            length = effectDurationValue
        end

        table.insert(SVs, utils.CreateScrollVelocity(length*duration + offset, (duration*startSV-averageSV)/(duration-1)))

        local lastOffsetEnd = offset+length
        if skipEndSV == false and (offsets[i+1] ~= lastOffsetEnd) then
            table.insert(SVs, utils.CreateScrollVelocity(lastOffsetEnd, averageSV))
        end
    end

    if skipFinalEndSV == false then
        table.insert(SVs, utils.CreateScrollVelocity(offsets[#offsets], averageSV))
    end

    return SVs
end

--[[
    about beziers

    i originally planned to support any number of control points from 3 (quadratic)
    to, idk, 10 or something

    i ran into some issues when trying to write general code for all orders of n,
    which made me give up on them for now

    the way to *properly* do it
        - find length t at position x
        - use the derivative of bezier to find y at t

    problem is that i cant reliably perform the first step for any curve
    so i guess i'll be using a very bad approach to this for now... if you know more about
    this stuff please get in contact with me
]]

-- @return table of scroll velocities
function sv.cubicBezier(P1_x, P1_y, P2_x, P2_y, startOffset, endOffset, averageSV, intermediatePoints, skipEndSV)

    local stepInterval = 1/intermediatePoints
    local timeInterval = (endOffset - startOffset) * stepInterval

    -- the larger this number, the more accurate the final sv is
    -- ... and the longer it's going to take
    local totalSampleSize = 2500
    local allBezierSamples = {}
    for t=0, 1, 1/totalSampleSize do
        local x = mathematics.cubicBezier({0, P1_x, P2_x, 1}, t)
        local y = mathematics.cubicBezier({0, P1_y, P2_y, 1}, t)
        table.insert(allBezierSamples, {x=x,y=y})
    end

    local SVs = {}
    local positions = {}

    local currentPoint = 0

    for sampleCounter = 1, totalSampleSize, 1 do
        if allBezierSamples[sampleCounter].x > currentPoint then
            table.insert(positions, allBezierSamples[sampleCounter].y)
            currentPoint = currentPoint + stepInterval
        end
    end

    for i = 2, intermediatePoints, 1 do
        local offset = (i-2) * timeInterval + startOffset
        local velocity = mathematics.round((positions[i] - (positions[i-1] or 0)) * averageSV * intermediatePoints, 2)
        SVs[i-1] = utils.CreateScrollVelocity(offset, velocity)
    end

    table.insert(SVs, utils.CreateScrollVelocity((intermediatePoints - 1) * timeInterval + startOffset, SVs[#SVs].Multiplier))

    if skipEndSV == false then
        table.insert(SVs, utils.CreateScrollVelocity(endOffset, averageSV))
    end

    return SVs, util.subdivideTable(allBezierSamples, 1, 50, true)
end


--[[
    Example for cross multiply taken from reamberPy

    baseSVs    | (1.0) ------- (2.0) ------- (3.0) |
    crossSVs   | (1.0)  (1.5) ------- (2.0) ------ |
    __________ | _________________________________ |
    result     | (1.0) ------- (3.0) ------- (6.0) |
]]

function sv.crossMultiply(baseSVs, crossSVs)
    local SVs = {}
    local crossIndex = 1

    for i, baseSV in pairs(baseSVs) do
        while crossIndex < #crossSVs and baseSV.StartTime > crossSVs[crossIndex+1].StartTime do
            crossIndex = crossIndex + 1
        end

        SVs[i] = utils.CreateScrollVelocity(
            baseSV.StartTime,
            baseSV.Multiplier * crossSVs[crossIndex].Multiplier
        )
    end

    return SVs
end
