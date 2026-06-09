local Util = {}

function Util.formatNumber(n)
    n = tonumber(n) or 0
    local sign = n < 0 and "-" or ""
    local s = tostring(math.floor(math.abs(n)))
    local result = s
    while true do
        local nextResult, count = result:gsub("^(%d+)(%d%d%d)", "%1,%2")
        result = nextResult
        if count == 0 then
            break
        end
    end
    return sign .. result
end

function Util.shallowCopy(t)
    local copy = {}
    for k, v in pairs(t or {}) do
        copy[k] = v
    end
    return copy
end

function Util.deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for k, v in pairs(value) do
        copy[Util.deepCopy(k)] = Util.deepCopy(v)
    end
    return copy
end

function Util.safeNumber(value, fallback)
    value = tonumber(value)
    if value == nil then
        return fallback or 0
    end
    return value
end

return Util
