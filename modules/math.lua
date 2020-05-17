-- Simple recursive implementation of the binomial coefficient
function math.binom(n, k)
    if k == 0 or k == n then return 1 end
    return math.binom(n-1, k-1) + math.binom(n-1, k)
end

-- Currently unused
function math.bernsteinPolynomial(i,n,t) return math.binom(n,i) * t^i * (1-t)^(n-i) end

-- Derivative for *any* bezier curve with at point t
-- Currently unused
function math.bezierDerivative(P, t)
    local n = #P
    local sum = 0
    for i = 0, n-2, 1 do sum = sum + math.bernsteinPolynomial(i,n-2,t) * (P[i+2].y - P[i+1].y) end
    return sum
end

function math.cubicBezier(P, t)
    return P[1] + 3*t*(P[2]-P[1]) + 3*t^2*(P[1]+P[3]-2*P[2]) + t^3*(P[4]-P[1]+3*P[2]-3*P[3])
end

function math.round(x, n) return tonumber(string.format("%." .. (n or 0) .. "f", x)) end

function math.clamp(x, min, max)
    if x > max then x = max end
    if x < min then x = min end
    return x
end
