local wezterm = require('wezterm')
local umath = require('utils.math')

local nf = wezterm.nerdfonts
local M = {}

local SEPARATOR_CHAR = nf.oct_dash .. ' '
local SEPARATOR_CHAR2 = utf8.char(0xe0b2)

local discharging_icons = {
   nf.md_battery_10,
   nf.md_battery_20,
   nf.md_battery_30,
   nf.md_battery_40,
   nf.md_battery_50,
   nf.md_battery_60,
   nf.md_battery_70,
   nf.md_battery_80,
   nf.md_battery_90,
   nf.md_battery,
}
local charging_icons = {
   nf.md_battery_charging_10,
   nf.md_battery_charging_20,
   nf.md_battery_charging_30,
   nf.md_battery_charging_40,
   nf.md_battery_charging_50,
   nf.md_battery_charging_60,
   nf.md_battery_charging_70,
   nf.md_battery_charging_80,
   nf.md_battery_charging_90,
   nf.md_battery_charging,
}

local colors = {
   date_fg = '#fab387',
   date_bg = 'rgba(0, 0, 0, 0.4)',
   battery_fg = '#f9e2af',
   battery_bg = 'rgba(0, 0, 0, 0.4)',
   separator_fg = '#74c7ec',
   separator_bg = 'rgba(0, 0, 0, 0.4)',
}

local __cells__ = {} -- wezterm FormatItems (ref: https://wezfurlong.org/wezterm/config/lua/wezterm/format.html)

---@param text string
---@param icon string
---@param fg string
---@param bg string
---@param separate boolean
local _push = function(text, icon, fg, bg, separate)
   table.insert(__cells__, { Foreground = { Color = fg } })
   table.insert(__cells__, { Background = { Color = bg } })
   table.insert(__cells__, { Attribute = { Intensity = 'Bold' } })
   table.insert(__cells__, { Text = icon .. ' ' .. text .. ' ' })

   if separate then
      table.insert(__cells__, { Foreground = { Color = colors.separator_fg } })
      table.insert(__cells__, { Background = { Color = colors.separator_bg } })
      table.insert(__cells__, { Text = SEPARATOR_CHAR })
   end
end

local _set_date = function()
   local date = wezterm.strftime(' %a %H:%M:%S')
   _push(date, nf.fa_calendar, colors.date_fg, colors.date_bg, true)
end

  -- Figure out the hostname of the pane on a best-effort basis
local _set_hostname = function(pane)
   local hostname = wezterm.hostname()
   -- local cwd_uri = pane:get_current_working_dir()
   -- if cwd_uri and cwd_uri.host then
   --    hostname = cwd_uri.host
   -- end
   _push(' ' .. hostname, nf.fa_laptop, colors.date_fg, colors.date_bg, false)
end

local _set_battery = function()
   -- ref: https://wezfurlong.org/wezterm/config/lua/wezterm/battery_info.html

   local charge = ''
   local icon = ''

   for _, b in ipairs(wezterm.battery_info()) do
      local idx = umath.clamp(umath.round(b.state_of_charge * 10), 1, 10)
      charge = string.format('%.0f%%', b.state_of_charge * 100)

      if b.state == 'Charging' then
         icon = charging_icons[idx]
      else
         icon = discharging_icons[idx]
      end
   end

   -- _push(charge, icon, colors.battery_fg, colors.battery_bg, true)
   return { charge, icon }
end

local function segments_for_right_status(window, pane)
   local hostname = wezterm.hostname()
   -- local cwd_uri = pane:get_current_working_dir()
   -- if cwd_uri and cwd_uri.host then
   --    hostname = cwd_uri.host
   -- end
   local battery = _set_battery()
   local batteryTextWithIcon = battery[2] .. ' ' .. battery[1]

  return {
   --  window:active_workspace(),
    wezterm.strftime('%a %b %-d %H:%M'),
    batteryTextWithIcon,
    hostname,
  }
end

M.setup = function()
   wezterm.on('update-status', function(window, _pane)
      local color_scheme = window:effective_config().resolved_palette
      local bg = wezterm.color.parse(color_scheme.background)
      local fg = color_scheme.foreground
      local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
      local segments = segments_for_right_status(window, _pane)

        local gradient_to, gradient_from = bg, bg
        gradient_from = gradient_to:lighten(0.2)

         local gradient = wezterm.color.gradient(
            {
               orientation = 'Horizontal',
               colors = { gradient_from, gradient_to },
            },
            #segments -- only gives us as many colours as we have segments.
         )

      local elements = {}

         for i, seg in ipairs(segments) do
            local is_first = i == 1

            if is_first then
               table.insert(elements, { Background = { Color = 'none' } })
            end
            table.insert(elements, { Foreground = { Color = gradient[i] } })
            table.insert(elements, { Text = SOLID_LEFT_ARROW })

            table.insert(elements, { Foreground = { Color = fg } })
            table.insert(elements, { Background = { Color = gradient[i] } })
            table.insert(elements, { Text = ' ' .. seg .. ' ' })
         end

         window:set_right_status(wezterm.format(elements))
   end)

   -- wezterm.on('update-right-status', function(window, _pane)
      -- __cells__ = {}
      -- _set_date()
      -- _set_battery()
      -- _set_hostname(_pane)

      -- window:set_right_status(wezterm.format(__cells__))

      --   local elements = {}

      --    for i, seg in ipairs(segments) do
      --       local is_first = i == 1

      --       if is_first then
      --          table.insert(elements, { Background = { Color = 'none' } })
      --       end
      --       table.insert(elements, { Foreground = { Color = gradient[i] } })
      --       table.insert(elements, { Text = SOLID_LEFT_ARROW })

      --       table.insert(elements, { Foreground = { Color = fg } })
      --       table.insert(elements, { Background = { Color = gradient[i] } })
      --       table.insert(elements, { Text = ' ' .. seg .. ' ' })
      --    end

      --    window:set_right_status(wezterm.format(elements))

   -- end)
end

return M
