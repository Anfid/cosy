---------------------------------------------------------------------------
--- Volume panel widget
--
-- @module widget.panel.volume
---------------------------------------------------------------------------

local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local audio = require("cosy.system.audio")

local min = math.min
local max = math.max

local volume = {}
volume.mt = {}

volume.defaults = {
    timeout = 3,
    rotation = "north",
    size = 100,
    bar_width = 3,
    indicator_width = 2,
    indicator_offset = 5,
    fps = 60,
    hide_time = 1,
    show_time = 0.3,
}

local function draw(self, context, cr, width, height)
    local height = min(self.size, height)
    if self.vol > 100 then
        cr:set_source(gears.color(beautiful.color_red .. "a0"))
    elseif self.vol >= 75 then
        cr:set_source(gears.color(beautiful.color_yellow .. "a0"))
    else
        cr:set_source(gears.color(beautiful.color_green .. "a0"))
    end
    cr:set_line_width(self.bar_width)

    local x = width / 2
    local val = height - (self.vol <= 100 and self.vol or 100) * (height / 100)

    local off = self.offset

    cr:move_to(x, height + off)
    cr:line_to(x, val + off)
    cr:stroke()

    cr:set_source(gears.color(beautiful.bg_focus .. "a0"))
    cr:move_to(x, val + off)
    cr:line_to(x, 0 + off)
    cr:stroke()

    cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
    cr:set_line_width(self.indicator_width)
    local i = self.bar_width / 2 + self.indicator_offset
    cr:move_to(x - i, val + off)
    cr:line_to(x + i, val + off)
    cr:stroke()
end

local function fit(self, context, width, height)
    local width = min(width, max(self.indicator_width, self.bar_width))
    local height = min(height, max(0, self.size - self.offset))
    return width, height
end

function volume.new(properties)
    local properties = gears.table.join(volume.defaults, properties or {})
    local volume_widget = gears.table.join(properties, wibox.widget.base.make_widget())
    volume_widget.vol = 0
    volume_widget.shown = false
    volume_widget.offset = 0

    volume_widget.draw = draw
    volume_widget.fit = fit

    function volume_widget:update()
        self.vol = audio:volume_get() or 0

        volume_widget.shown = true
        self.animation_timer:again()
        self.timeout:again()

        volume_widget:emit_signal("widget::updated")
    end

    volume_widget.timeout = gears.timer.start_new(
        volume_widget.timeout,
        function()
            volume_widget.shown = false
            volume_widget.animation_timer:again()
            return false
        end
    )

    volume_widget.animation_timer = gears.timer.start_new(
        1/properties.fps,
        function()
            if volume_widget.shown and volume_widget.offset > 0 then
                local offset_delta = properties.size * (1 / properties.fps) / properties.show_time
                volume_widget.offset = max(volume_widget.offset - offset_delta, 0)
                volume_widget:emit_signal_recursive("widget::layout_changed")
                return true
            elseif not volume_widget.shown and volume_widget.offset < (volume_widget.size + volume_widget.indicator_width / 2)  then
                local offset_delta = properties.size * (1 / properties.fps) / properties.hide_time
                local offset_limit = volume_widget.size + volume_widget.indicator_width / 2
                volume_widget.offset = min(volume_widget.offset + offset_delta, offset_limit)
                volume_widget:emit_signal_recursive("widget::layout_changed")
                return true
            else
                return false
            end
        end)

    local transformed = wibox.container.rotate(volume_widget, properties.rotation)

    if volume_widget.centered then
        transformed = wibox.container.place(transformed)
    end

    audio.connect_signal("audio::volume", function() volume_widget:update() end)

    volume_widget:update()

    return transformed
end

function volume.mt:__call(...)
    return volume.new(...)
end

return setmetatable(volume, volume.mt)
