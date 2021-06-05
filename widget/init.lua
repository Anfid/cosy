---------------------------------------------------------------------------
--- Widget module for cosy
--
-- @module widget
---------------------------------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")

local widget = {
    desktop = require("cosy.widget.desktop"),
    panel   = require("cosy.widget.panel"),
    common  = require("cosy.widget.common"),
}

-- Textclock
widget.textclock = {}
widget.textclock.widget = wibox.widget.textclock("<span font=\"Iosevka 10\">%a\n%H:%M\n%d/%m</span>")
-- TODO: Fix annoying juping behavior and multimonitor focus
-- issues
--widget.textclock.tooltip = awful.tooltip({
--    objects = { widget.textclock.widget },
--    timer_function = function()
--        return os.date("%d of %B %Y\n%A")
--    end
--})
widget.textclock.widget:set_align("center")
--widget.textclock.tooltip.textbox:set_align("center")

return widget
