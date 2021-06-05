---------------------------------------------------------------------------
--- CPU graph widget
--
-- @module widget.common.cpu_graph
-- @alias cpu_graph
---------------------------------------------------------------------------

local gears = require("gears")
local beautiful = require("beautiful")
local sys_stat = require("cosy.system.status")
local wibox = require("wibox")

local d = require("cosy.dbg")

local floor = math.floor

local cpu_graph = {}

cpu_graph.defaults = {
    samples = 100,
    bg_color = gears.color(beautiful.bg_normal.."00"),
    used_color = gears.color(beautiful.fg_normal.."a0"),
    iowait_color = gears.color(beautiful.fg_normal.."60"),
}

local ring_buffer = {}

function ring_buffer.new(val, len)
    local ring_buffer = {
        buffer = {},
        idx = len
    }

    -- preallocate array of required size
    ring_buffer.buffer[len] = 0
    for i = 1,len do
        ring_buffer.buffer[i] = 0
    end

    return ring_buffer
end

function ring_buffer.get(ring, idx)
    return ring.buffer[(ring.idx + idx - 1) % #ring.buffer + 1]
end

function ring_buffer.push(ring, val)
    ring.idx = (ring.idx + 1) % #ring.buffer
    ring.buffer[ring.idx] = val
end

local function draw(self, context, cr, width, height)
    local used = floor(height * sys_stat.cpu.load.total.used)
    local iowait = floor(height * sys_stat.cpu.load.total.iowait)
    ring_buffer.push(self.cpu_used, used)
    ring_buffer.push(self.cpu_iowait, iowait)

    -- background
    cr:set_source(self.bg_color)
    cr:set_line_width(0)
    cr:rectangle(0, 0, width, height)
    cr:fill_preserve()
    cr:stroke()

    -- CPU used
    cr:set_source(self.used_color)
    cr:set_line_width(0)

    cr:move_to(0, height)
    cr:line_to(0, height - ring_buffer.get(self.cpu_used, 1))
    for i = 2,self.samples do
        local x = width / self.samples * i - 1
        local y = height - ring_buffer.get(self.cpu_used, i)
        cr:line_to(x, y)
    end
    cr:line_to(width, height)
    cr:close_path()

    cr:fill_preserve()
    cr:stroke()

    -- CPU iowait
    cr:set_source(self.iowait_color)
    cr:set_line_width(0)
    cr:move_to(0, height - ring_buffer.get(self.cpu_used, 1))
    cr:line_to(0, height - ring_buffer.get(self.cpu_used, 1) - ring_buffer.get(self.cpu_iowait, 1))
    for i = 2,self.samples do
        local x = width / self.samples * i - 1
        local y = height - ring_buffer.get(self.cpu_used, i) - ring_buffer.get(self.cpu_iowait, i)
        cr:line_to(x, y)
    end
    for i = self.samples,1,-1 do
        local x = width / self.samples * i - 1
        local y = height - ring_buffer.get(self.cpu_used, i)
        cr:line_to(x, y)
    end
    cr:close_path()

    cr:fill_preserve()
    cr:stroke()
end

--- Create a new CPU load graph widget
-- @tparam[opt={}] table properties A widget configuration table.
-- @tparam[opt=100] number properties.samples Amount of samples to show.
-- @tparam[opt=beautiful.bg_color.."00"] gears.color properties.bg_color Background color.
-- @tparam[opt=beautiful.fg_color.."a0"] gears.color properties.used_color CPU active color.
-- @tparam[opt=beautiful.fg_color.."60"] gears.color properties.iowait_color CPU iowait color.
-- @return CPU graph widget to be used in wibox.
function cpu_graph.new(properties)
    local properties = gears.table.join(cpu_graph.defaults, properties or {})
    local cpu_graph_widget = gears.table.join(properties, wibox.widget.base.make_widget())

    cpu_graph_widget.cpu_used = ring_buffer.new(0, properties.samples)
    cpu_graph_widget.cpu_iowait = ring_buffer.new(0, properties.samples)

    function cpu_graph_widget:fit(context, width, height) return width, height end
    cpu_graph_widget.draw = draw

    sys_stat.cpu:init(1)

    cpu_graph_widget:emit_signal("widget::updated")

    sys_stat.connect_signal("cpu::updated", function() cpu_graph_widget:emit_signal("widget::updated") end)

    return cpu_graph_widget
end

return cpu_graph
