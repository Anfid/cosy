---------------------------------------------------------------------------
--- Util
-- Utility functions
--
-- @module util
---------------------------------------------------------------------------
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")

local util = {
    math = {},
    bit = {},
    string = {},
    file = {},
}

--- Set wallpaper for screen s
-- @tparam screen s Screen to set wallpaper
function util.set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

--- Toggle titlebar on or off depending on s. Creates titlebar if it doesn't exist
-- @tparam client c Client to update titlebar state
function util.manage_titlebar(c)
    -- Fullscreen clients are considered floating. Return to prevent clients from shifting down in fullscreen mode
    if c.fullscreen then
        return
    end
    local show = c.floating or awful.layout.get(c.screen) == awful.layout.suit.floating
    if show then
        if c.titlebar == nil then
            c:emit_signal("request::titlebars", "rules", {})
        end
        awful.titlebar.show(c)
    else
        awful.titlebar.hide(c)
    end
    -- Prevents titlebar appearing off the screen
    awful.placement.no_offscreen(c)
end

--- Checks if client is floating and can be moved
-- @tparam client c Client to test
-- @treturn bool `true` if client is floating
function util.client_free_floating(c)
    return (c.floating or awful.layout.get(c.screen) == awful.layout.suit.floating)
        and not (c.fullscreen or c.maximized or c.maximized_vertical or c.maximized_horizontal)
end

--- Count table elements
-- @tparam table table Table to count elements
-- @treturn number Amount of key-value pairs in the table
function util.table_count(table)
    local count = 0
    for _, v in pairs(table) do
        if v ~= nil then
            count = count + 1
        end
    end

    return count
end

function util.math.round(x) return x + 0.5 - (x + 0.5) % 1 end

if _G._VERSION == "Lua 5.3" then
    util.bit.rol = _G.bit32.lrotate
else
    util.bit.rol = _G.bit.rol
end

function util.string.trim(str)
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function util.file.exists(path)
    local handle = io.open(path)
    if handle then
        handle:close()
    end
    return handle and true or false
end

function util.file.read(path)
    local handle = io.open(path)
    if not handle then
        return nil
    end
    local text = handle:read('*all')
    handle:close()
    return text
end

function util.file.new(path, content)
    local handle = io.open(path, "w")
    if not handle then
        return nil
    end
    if content ~= nil then
        handle:write(content)
    end
    handle:close()
end

util.file.delete = os.remove

return util
