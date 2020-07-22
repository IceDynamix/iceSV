-- Simple recursive implementation of the binomial coefficient
function mathematics.binom(n, k)
    if k == 0 or k == n then return 1 end
    return mathematics.binom(n-1, k-1) + mathematics.binom(n-1, k)
end

-- Currently unused
function mathematics.bernsteinPolynomial(i,n,t) return mathematics.binom(n,i) * t^i * (1-t)^(n-i) end

-- Derivative for *any* bezier curve with at point t
-- Currently unused
function mathematics.bezierDerivative(P, t)
    local n = #P
    local sum = 0
    for i = 0, n-2, 1 do sum = sum + mathematics.bernsteinPolynomial(i,n-2,t) * (P[i+2].y - P[i+1].y) end
    return sum
end

function mathematics.cubicBezier(P, t)
    return P[1] + 3*t*(P[2]-P[1]) + 3*t^2*(P[1]+P[3]-2*P[2]) + t^3*(P[4]-P[1]+3*P[2]-3*P[3])
end

function mathematics.round(x, n) return tonumber(string.format("%." .. (n or 0) .. "f", x)) end

function mathematics.clamp(x, min, max)
    if x < min then x = min end
    if x > max then x = max end
    return x
end

function mathematics.min(t)
    local min = t[1]
    for _, value in pairs(t) do
        if value < min then min = value end
    end

    return min
end

function mathematics.max(t)
    local max = t[1]
    for _, value in pairs(t) do
        if value > max then max = value end
    end

    return max
end

mathematics.comparisonOperators = {
    "=", "!=", "<", "<=", ">=", ">"
}

-- No minus/division/root since they are present in the given operators already
-- Add negative values to subtract, multiply with 1/x to divide by x etc.
mathematics.arithmeticOperators = {
    "=", "+", "×", "^"
}

function mathematics.evaluateComparison(operator, value1, value2)
    local compareFunctions = {
        ["="]  = function (v1, v2) return v1 == v2 end,
        ["!="] = function (v1, v2) return v1 ~= v2 end,
        ["<"]  = function (v1, v2) return v1 < v2 end,
        ["<="] = function (v1, v2) return v1 <= v2 end,
        [">="] = function (v1, v2) return v1 >= v2 end,
        [">"]  = function (v1, v2) return v1 > v2 end
    }

    return compareFunctions[operator](value1, value2)
end

function mathematics.evaluateArithmetics(operator, oldValue, changeValue)
    local arithmeticFunctions = {
        ["="] = function (v1, v2) return v2 end,
        ["+"] = function (v1, v2) return v1 + v2 end,
        ["×"] = function (v1, v2) return v1 * v2 end,
        ["^"] = function (v1, v2) return v1 ^ v2 end
    }

    return arithmeticFunctions[operator](oldValue, changeValue)
end
