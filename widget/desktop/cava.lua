---------------------------------------------------------------------------
--- Cava desktop widget
--
-- @module cosy.widget.desktop
---------------------------------------------------------------------------

local gears = require("gears")
local beautiful = require("beautiful")
local wibox = require("wibox")

local table = table
local tostring = tostring

local audio = require("cosy.system.audio")

local d = require("cosy.dbg")

-- Max value for 16 bit
local cava_max = 65536

local cava = {}
cava.mt = {}

_G.cava_global_val = {}

cava.defaults = {
    position = "top",
    enable_interpolation = false,
    bars = 50,
    size = 45,
    zero_size = 2,
    spacing = 5,
    update_time = 0.04,
}

local function draw_top(cava_widget, context, cr, width, height)
    local w = width / cava_widget.bars - cava_widget.spacing  -- block width
    local d = w + cava_widget.spacing           -- block distance

    cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
    cr:set_line_width(w)

    for i = 1, #cava_widget.val do
        local val = cava_widget.val[i] + cava_widget.zero_size
        local pos = d * i - d / 2

        cr:move_to(pos, 0  )
        cr:line_to(pos, val)
    end

    cr:stroke()
end

local function draw_left(cava_widget, context, cr, width, height)
    local w = height / cava_widget.bars - cava_widget.spacing -- block width
    local d = w + cava_widget.spacing           -- block distance

    cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
    cr:set_line_width(w)

    for i = 1, #cava_widget.val do
        local val = cava_widget.val[i] + cava_widget.zero_size
        local pos = d * i - d / 2

        cr:move_to(0,   pos)
        cr:line_to(val, pos)
    end

    cr:stroke()
end

local function draw_bottom(cava_widget, context, cr, width, height)
    local w = width / cava_widget.bars - cava_widget.spacing  -- block width
    local d = w + cava_widget.spacing           -- block distance

    cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
    cr:set_line_width(w)

    for i = 1, #cava_widget.val do
        local val = cava_widget.val[i] + cava_widget.zero_size
        local pos = d * i - d / 2

        cr:move_to(pos, height      )
        cr:line_to(pos, height - val)
    end

    cr:stroke()
end

local function draw_right(cava_widget, context, cr, width, height)
    local w = height / cava_widget.bars - cava_widget.spacing -- block width
    local d = w + cava_widget.spacing           -- block distance

    cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
    cr:set_line_width(w)

    for i = 1, #cava_widget.val do
        local val = cava_widget.val[i] + cava_widget.zero_size
        local pos = d * i - d / 2

        cr:move_to(width,       pos)
        cr:line_to(width - val, pos)
    end

    cr:stroke()
end

local function draw_top_interpolated(cava_widget, context, cr, width, height)
    local spacing = width / (cava_widget.bars + 1)
    local prev_val = cava_widget.zero_size
    local prev_pos = -spacing / 2
    local prev_d_val = 0
    local val = cava_widget.val[1] + cava_widget.zero_size
    local pos = prev_pos + spacing
    local next_pos = pos + spacing

    cr:set_source(gears.color(beautiful.fg_normal))
    cr:set_line_width(2)
    cr:move_to(prev_pos, cava_widget.zero_size)

    for i = 1, #cava_widget.val + 1 do
        local next_val = (cava_widget.val[i + 1] or 0) + cava_widget.zero_size
        next_pos = next_pos + spacing

        local d_val = spacing / 2 * (next_val - prev_val) / (next_pos - prev_pos)

        cr:curve_to(prev_pos+spacing/2, prev_val + prev_d_val, pos-spacing/2, val - d_val, pos, val)

        prev_val, prev_pos, prev_d_val = val, pos, d_val
        val, pos = next_val, next_pos
    end

    cr:stroke()
end

local function draw_left_interpolated(cava_widget, context, cr, width, height)
    local spacing = height / (cava_widget.bars + 1)
    local prev_val = cava_widget.zero_size
    local prev_pos = -spacing / 2
    local prev_d_val = 0
    local val = cava_widget.val[1] + cava_widget.zero_size
    local pos = prev_pos + spacing
    local next_pos = pos + spacing

    cr:set_source(gears.color(beautiful.fg_normal))
    cr:move_to(cava_widget.zero_size, prev_pos)
    cr:set_line_width(2)

    for i = 1, #cava_widget.val + 1 do
        local next_val = (cava_widget.val[i + 1] or 0) + cava_widget.zero_size
        next_pos = next_pos + spacing

        local d_val = spacing / 2 * (next_val - prev_val) / (next_pos - prev_pos)

        cr:curve_to(prev_val + prev_d_val, prev_pos+spacing/2, val - d_val, pos-spacing/2, val, pos)

        prev_val, prev_pos, prev_d_val = val, pos, d_val
        val, pos = next_val, next_pos
    end

    cr:stroke()
end

local function draw_bottom_interpolated(cava_widget, context, cr, width, height)
    local spacing = width / (cava_widget.bars + 1)
    local prev_val = cava_widget.zero_size
    local prev_pos = -spacing / 2
    local prev_d_val = 0
    local val = cava_widget.val[1] + cava_widget.zero_size
    local pos = prev_pos + spacing
    local next_pos = pos + spacing

    cr:set_source(gears.color(beautiful.fg_normal))
    cr:set_line_width(2)
    cr:move_to(prev_pos, height - cava_widget.zero_size)

    for i = 1, #cava_widget.val + 1 do
        local next_val = (cava_widget.val[i + 1] or 0) + cava_widget.zero_size
        next_pos = next_pos + spacing

        local d_val = spacing / 2 * (next_val - prev_val) / (next_pos - prev_pos)

        cr:curve_to(prev_pos+spacing/2, height - prev_val - prev_d_val, pos-spacing/2, height - val + d_val, pos, height - val)

        prev_val, prev_pos, prev_d_val = val, pos, d_val
        val, pos = next_val, next_pos
    end

    cr:stroke()
end

local function draw_right_interpolated(cava_widget, context, cr, width, height)
    local spacing = height / (cava_widget.bars + 1)
    local prev_val = cava_widget.zero_size
    local prev_pos = -spacing / 2
    local prev_d_val = 0
    local val = cava_widget.val[1] + cava_widget.zero_size
    local pos = prev_pos + spacing
    local next_pos = pos + spacing

    cr:set_source(gears.color(beautiful.fg_normal))
    cr:move_to(cava_widget.zero_size, prev_pos)
    cr:set_line_width(2)

    for i = 1, #cava_widget.val + 1 do
        local next_val = (cava_widget.val[i + 1] or 0) + cava_widget.zero_size
        next_pos = next_pos + spacing

        local d_val = spacing / 2 * (next_val - prev_val) / (next_pos - prev_pos)

        cr:curve_to(width - prev_val - prev_d_val, prev_pos+spacing/2, width - val + d_val, pos-spacing/2, width - val, pos)

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

    -- Assigning draw function prevents multiple string comparison in performance critical code
    if     cava_widget.position == "top" then
        cava_widget.draw = cava_widget.enable_interpolation and draw_top_interpolated or draw_top
        properties.w = s.geometry.width
        properties.h = properties.size
        if not properties.x then properties.x = 0 end
        if not properties.y then properties.y = 0 end
    elseif cava_widget.position == "left" then
        cava_widget.draw = cava_widget.enable_interpolation and draw_left_interpolated or draw_left
        properties.w = properties.size
        properties.h = s.geometry.height
        if not properties.x then properties.x = 0 end
        if not properties.y then properties.y = 0 end
    elseif cava_widget.position == "bottom" then
        cava_widget.draw = cava_widget.enable_interpolation and draw_bottom_interpolated or draw_bottom
        properties.w = s.geometry.width
        properties.h = properties.size
        if not properties.x then properties.x = 0 end
        if not properties.y then properties.y = s.geometry.height - properties.size end
    elseif cava_widget.position == "right" then
        cava_widget.draw = cava_widget.enable_interpolation and draw_right_interpolated or draw_right
        properties.w = properties.size
        properties.h = s.geometry.height
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
        local cava_val_fit = {}
        local cava_changed = false
        for i = 1, #cava_val do
            cava_val_fit[i] = cava_val[i] * (self.size - self.zero_size) / cava_max
            if self.val[i] ~= cava_val_fit[i] then
                cava_changed = true
            end
        end

        -- Prevent unnecessary redraw
        if cava_changed then
            self.val = cava_val_fit
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

    cava_box:set_widget(cava_widget)

    audio.connect_signal("cava::updated", function()
        cava_widget:update_val()
    end)

    return cava_box
end

function cava.mt:__call(...)
    return cava.new(...)
end

return setmetatable(cava, cava.mt)
