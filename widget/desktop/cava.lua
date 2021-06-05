---------------------------------------------------------------------------
--- Cava audio visualizer desktop widget
--
-- @module widget.desktop.cava
---------------------------------------------------------------------------

local gears = require("gears")
local beautiful = require("beautiful")
local wibox = require("wibox")

local audio = require("cosy.system.audio")

local d = require("cosy.dbg")

local cava_max = audio.cava.max_value

local cava = {}
cava.mt = {}

cava.defaults = {
    position = "top",
    enable_interpolation = false,
    bars = 50,
    zero_size = 2,
    spacing = 5,
    update_time = 0.04,
}

local function draw(self, context, cr, width, height)
    local w = width / self.bars - self.spacing  -- block width
    local d = w + self.spacing                  -- block distance

    cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
    cr:set_line_width(w)

    for i = 1, #self.val do
        local val = self.val[i] * (height - self.zero_size) / cava_max + self.zero_size + self.zero_size
        local pos = d * i - d / 2

        cr:move_to(pos, height      )
        cr:line_to(pos, height - val)
    end

    cr:stroke()
end

local function draw_interpolated(self, context, cr, width, height)
    local spacing = width / (self.bars + 1)
    local prev_val = self.zero_size
    local prev_pos = -spacing / 2
    local prev_d_val = 0
    local val = self.val[1] * (height - self.zero_size) / cava_max + self.zero_size
    local pos = prev_pos + spacing
    local next_pos = pos + spacing

    cr:set_source(gears.color(beautiful.fg_normal))
    cr:set_line_width(2)
    cr:move_to(prev_pos, height - self.zero_size)

    for i = 1, #self.val + 1 do
        local next_val = ((self.val[i + 1] or 0) * (height - self.zero_size) / cava_max) + self.zero_size
        next_pos = next_pos + spacing

        local d_val = spacing / 2 * (next_val - prev_val) / (next_pos - prev_pos)

        cr:curve_to(prev_pos+spacing/2, height - prev_val - prev_d_val, pos-spacing/2, height - val + d_val, pos, height - val)

        prev_val, prev_pos, prev_d_val = val, pos, d_val
        val, pos = next_val, next_pos
    end

    cr:stroke()
end

-- TODO: Document properties
function cava.new(s, properties)
    local properties = gears.table.join(cava.defaults, properties or {})
    local cava_widget = gears.table.join(properties, wibox.widget.base.make_widget())
    cava_widget.val = {}

    cava_widget.draw = cava_widget.enable_interpolation and draw_interpolated or draw

    -- positioning
    if     cava_widget.position == "top" then
        properties.w = s.geometry.width
        properties.h = properties.size
        properties.rotation = "south"
        if not properties.x then properties.x = 0 end
        if not properties.y then properties.y = 0 end
    elseif cava_widget.position == "left" then
        properties.w = properties.size
        properties.h = s.geometry.height
        properties.rotation = "west"
        if not properties.x then properties.x = 0 end
        if not properties.y then properties.y = 0 end
    elseif cava_widget.position == "bottom" then
        properties.w = s.geometry.width
        properties.h = properties.size
        properties.rotation = "north"
        if not properties.x then properties.x = 0 end
        if not properties.y then properties.y = s.geometry.height - properties.size end
    elseif cava_widget.position == "right" then
        properties.w = properties.size
        properties.h = s.geometry.height
        properties.rotation = "east"
        if not properties.x then properties.x = s.geometry.width - properties.size end
        if not properties.y then properties.y = 0 end
    else
        error("Wrong cava widget position")
    end

    for i = 1, cava_widget.bars do
        cava_widget.val[i] = 0
    end

    function cava_widget:fit(context, width, height) return width, height end

    function cava_widget:update_val()
        local cava_val = audio.cava.raw_val

        if not cava_val or #cava_val ~= audio.cava.config.bars then return false end

        -- Adjust values to fit into the desired size
        local cava_val_copy = {}
        local cava_changed = false
        for i = 1, #cava_val do
            cava_val_copy[i] = cava_val[i]
            if self.val[i] ~= cava_val_copy[i] then
                cava_changed = true
            end
        end

        -- Prevent unnecessary redraw
        if cava_changed then
            self.val = cava_val_copy
            self:emit_signal("widget::updated")
        end
    end

    local cava_box = wibox({
        screen = s,
        type = "desktop",
        visible = true,
        bg = "#00000000",
    })

    cava_box:geometry({
        x = s.geometry.x + properties.x,
        y = s.geometry.y + properties.y,
        width  = properties.w,
        height = properties.h,
    })

    local rotated = wibox.container.rotate(cava_widget, properties.rotation)

    cava_box:set_widget(rotated)

    audio.connect_signal("cava::updated", function()
        cava_widget:update_val()
    end)

    return cava_box
end

function cava.mt:__call(...)
    return cava.new(...)
end

return setmetatable(cava, cava.mt)
