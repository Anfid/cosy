---------------------------------------------------------------------------
--- Battery panel widget
--
-- @module widget.panel.battery
-- @alias battery
---------------------------------------------------------------------------

local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local sys_stat = require("cosy.system.status")

local d = require("cosy.dbg")

local battery = {}
battery.mt = {}

battery.defaults = {
    rotation = "north",
    size = 90,
    width = 27,
    outline = 1,
    centered = true,
}

local function draw(self, context, cr, width, height)
    local width = math.min(self.width, width)
    local height = math.min(self.size, height)

    if self.status == "charging" then
        cr:set_source(gears.color(beautiful.color_green.."60"))
    elseif self.charge <= 0.05 then
        cr:set_source(gears.color(beautiful.color_red.."60"))
    elseif self.charge <= 0.15 then
        cr:set_source(gears.color(beautiful.color_yellow.."60"))
    else
        cr:set_source(gears.color(beautiful.fg_normal.."60"))
    end

    cr:set_line_width(0)

    local effective_h = height - self.outline * 2
    cr:rectangle(
        self.outline,
        effective_h - self.charge * effective_h + self.outline,
        width - self.outline * 2,
        self.charge * height - self.outline * 2
    )
    cr:fill_preserve()
    cr:stroke()

    cr:set_line_width(self.outline)
    cr:set_source(gears.color(beautiful.fg_normal.."80"))
    cr:rectangle(
        0.5 * self.outline,
        0.5 * self.outline,
        width - self.outline,
        height - self.outline
    )
    cr:stroke()

    cr:move_to()
end

local function fit(self, context, width, height)
    return math.min(self.width, width), math.min(self.size, height)
end

local function update(self)
    self.charge = sys_stat.power.battery.charge_now
    self.status = sys_stat.power.battery.status
    self:emit_signal("widget::updated")
end

--- Create a new battery charge widget
-- @tparam[opt={}] table properties A widget configuration table.
-- @tparam[opt="north"] string properties.rotation Widget rotation. See wibox.container.rotate documentation for explaination.
-- @tparam[opt=90] number properties.size Size from charged to discharged.
-- @tparam[opt=27] number properties.size Width.
-- @tparam[opt=1] number properties.outline Outline width.
-- @tparam[opt=true] boolean properties.centered Center widget across available space.
-- @return battery charge widget to be used in panel.
function battery.new(properties)
    local properties = gears.table.join(battery.defaults, properties or {})
    local battery_widget = gears.table.join(properties, wibox.widget.base.make_widget())

    battery_widget.update = update
    battery_widget.fit = fit
    battery_widget.draw = draw

    sys_stat.power:init(2)

    battery_widget:update()
    sys_stat.connect_signal("power::updated", function() battery_widget:update() end)

    local transformed = wibox.container.rotate(battery_widget, properties.rotation)

    if battery_widget.centered then
        transformed = wibox.container.place(transformed)
    end

    return transformed
end

function battery.mt:__call(...)
    return battery.new(...)
end

return setmetatable(battery, battery.mt)
