---------------------------------------------------------------------------
--- System monitoring
--
-- @module cosy
---------------------------------------------------------------------------

local gears = require("gears")
local util = require("cosy.util")
local tonumber = tonumber

local status = {
    -- CPU statusrmation
    cpu = {
        -- Total core count
        cores = 0,
        -- CPU usage per core
        load = {
            total = 0,
            _prev = nil,
            _this = nil,
        },
        -- Virtual to physical core id
        proc_to_core = {},
    },
    ram = {
        -- Total RAM in kB
        total = 0,
        -- Free RAM in kB
        free = 0,
        -- Available RAM in kB
        available = 0,
    },
    rom = {},
    temp = {
        -- Temperature in millidegrees celcius per physical core
        cpu = {
            path = nil,
            core = {},
        }
    }
}

local signals = {}

-- TODO: implement subscriptions for various timings
function status.cpu:init(update_time)
    if type(update_time) ~= "number" then
        update_time = 1
    end

    if self.initialized == true then
        -- If default timeout is different from 1, nil is denied by design to prevent
        -- external modules from load order errors
        if update_time ~= self.update_timer.timeout then
            error("cosy.system.status: CPU status on various timeouts is not yet implemented")
        else
            -- Already initialized
            return
        end
    end

    local cpuinfo = util.file.read("/proc/cpuinfo")
    local core_count = 0
    for procinfo in cpuinfo:gmatch(".-\n\n") do
        local id, coreid = procinfo:match(
            "processor%s+:%s+(%d+).*"..
            "core id%s+:%s+(%d+).*"
        )

        self.proc_to_core[id] = coreid
        core_count = core_count + 1
    end
    self.cores = core_count

    self.update_timer = gears.timer.start_new(
        update_time,
        function()
            self:update()
            status.emit_signal("cpu::updated")
            return true
        end
    )

    self.initialized = true
end

function status.cpu:update()
    self:update_load()
end

function status.cpu:update_load()
    self.load._prev = self.load._this
    self.load._this = {}

    local stat = util.file.read("/proc/stat")

    for core, user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice
        in stat:gmatch("cpu(%d*)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
    do
        if core == "" then
            core = "total"
        else
            core = tonumber(core) + 1
        end

        self.load._this[core] = {
            user       = tonumber(user),
            nice       = tonumber(nice),
            system     = tonumber(system),
            idle       = tonumber(idle),
            iowait     = tonumber(iowait),
            irq        = tonumber(irq),
            softirq    = tonumber(softirq),
            steal      = tonumber(steal),
            guest      = tonumber(guest),
            guest_nice = tonumber(guest_nice),
        }

        if self.load._prev ~= nil and self.load._prev[core] ~= nil then
            local prev_total = 0
            for _, val in pairs(self.load._prev[core]) do
                prev_total = prev_total + val
            end
            local prev_idle = self.load._prev[core].idle + self.load._prev[core].iowait

            local this_total = 0
            for _, val in pairs(self.load._this[core]) do
                this_total = this_total + val
            end
            local this_idle = self.load._this[core].idle + self.load._this[core].iowait

            local total = prev_total - this_total
            local idle = prev_idle - this_idle

            self.load[core] = (total - idle) / total
        end
    end
end

function status.ram:init(update_time)
    if type(update_time) ~= "number" then
        update_time = 1
    end

    if self.initialized == true then
        -- If default timeout is different from 1, nil is denied by design to prevent
        -- external modules from load order errors
        if update_time ~= self.update_timer.timeout then
            error("cosy.system.status: RAM status on various timeouts is not yet implemented")
        else
            -- Already initialized
            return
        end
    end

    self.update_timer = gears.timer.start_new(
        update_time,
        function()
            self:update()
            status.emit_signal("ram::updated")
            return true
        end
    )

    self.initialized = true
end

function status.ram:update()
    local stat = util.file.read("/proc/meminfo")
    local total, free, avail = stat:match(
        "MemTotal:%s+(%d+).*"..
        "MemFree:%s+(%d+).*"..
        "MemAvailable:%s+(%d+).*"
    )
    self.total = tonumber(total)
    self.free = tonumber(free)
    self.available = tonumber(avail)
end

function status.rom:init()
end

function status.temp:init(update_time)
    if type(update_time) ~= "number" then
        update_time = 1
    end

    if self.initialized == true then
        -- If default timeout is different from 1, nil is denied by design to prevent
        -- external modules from load order errors
        if update_time ~= self.update_timer.timeout then
            error("cosy.system.status: Temperature status on various timeouts is not yet implemented")
        else
            -- Already initialized
            return
        end
    end

    for line in io.popen("for x in /sys/class/hwmon/hwmon*; do printf \"%s \" $x; cat $x/name; done"):lines() do
        local path, name = line:match("([^%s]-)%s+([^\n]-)\n")
        if name == "coretemp" then
            self.cpu.path = path
        end
    end

    self.update_timer = gears.timer.start_new(
        update_time,
        function()
            self:update()
            status.emit_signal("temperature::updated")
            return true
        end
    )

    self.initialized = true
end

function status.temp:update()
end

function status.connect_signal(name, callback)
    signals[name] = signals[name] or {}
    table.insert(signals[name], callback)
end

function status.disconnect_signal(name, callback)
    signals[name] = signals[name] or {}

    for k, v in ipairs(signals[name]) do
        if v == callback then
            table.remove(signals[name], k)
            break
        end
    end
end

function status.emit_signal(name, ...)
    signals[name] = signals[name] or {}

    for _, cb in ipairs(signals[name]) do
        cb(...)
    end
end

return status
