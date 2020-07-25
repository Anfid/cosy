---------------------------------------------------------------------------
--- Debugging utilities
--
-- Module with various debugging utilities for Awesome WM
--
-- @module d
---------------------------------------------------------------------------
local gears = require("gears")
local naughty = require("naughty")

local d = {
    stopwatch = {}
}
d.mt = {}

local function notify(t1, t2, conf)
    local conf = conf or {}
    conf.preset = conf.preset or {}
    local body, title
    if t2 ~= nil then
        title = t1
        body = t2 or conf.body
    else
        title = conf.title
        body = t1 or conf.body
    end

    naughty.notify({
            preset = conf.preset,
            title = title,
            text = gears.debug.dump_return(body),
        })
end

function d.notify(t1, t2)
    notify(t1, t2, {
        title = "Debug",
    })
end

function d.notify_err(t1, t2)
    notify(t1, t2, {
        title = "Error",
        preset = naughty.config.presets.critical
    })
end

function d.notify_persistent(t1, t2)
    notify(t1, t2, {
        title = "Debug",
        preset = { timeout = 0 }
    })
end

function d.start(name, config)
    local name = name or "default"
    local config = config or {}
    local iter = config.iter or 1
    local skip_iter = config.skip_iter or 0

    if d.stopwatch[name] == nil then
        d.stopwatch[name] = {
            iter = iter,
            skip_iter = skip_iter,
            running = false,
            points = {},
        }
    end

    local sw = d.stopwatch[name]

    if sw.skip_iter > 0 then
        sw.skip_iter = sw.skip_iter - 1
    elseif sw.iter > 0 then
        sw.running = true
        sw.iter = sw.iter - 1
    end

    if sw.running then
        table.insert(sw.points, {})
        table.insert(sw.points[#sw.points], os.clock())
    end
end

-- Must remain minimal to reduce influence on actual result
function d.breakpoint(name)
    local name = name or "default"
    local sw = d.stopwatch[name]

    if not sw or not sw.running then return end

    table.insert(sw.points[#sw.points], os.clock())
end

function d.stop(name)
    local stop = os.clock() -- stop asap
    local name = name or "default"
    local sw = d.stopwatch[name]

    if not sw or not sw.running then return end
    sw.running = false

    table.insert(sw.points[#sw.points], stop)

    if sw.iter == 0 then
        local title = name == "default" and "Timer" or "Timer "..name
        local points_len = #sw.points[1]
        local avg = {}
        for pt = 1, points_len do
            local x = 0
            for loop = 1, #sw.points do
                x = x + sw.points[loop][pt] - sw.points[loop][1]
            end
            table.insert(avg, x / #sw.points)
        end

        local out = ""
        for i = 2, points_len - 1 do
            out = out..string.format("\nbreakpoint #%02d: %.6f; Δt: %.6f", i - 1, avg[i], avg[i] - avg[i - 1])
        end
        out = out..string.format(    "\nTotal time:     %.6f", avg[points_len])
        d.notify_persistent(title, out)
    end
end


-- shortcuts
d.n = d.notify
d.p = d.notify_persistent
d.e = d.notify_err

function d.mt:__call(...)
    return d.notify(...)
end

return setmetatable(d, d.mt)
