local function startup(wezterm)
    local mux = wezterm.mux
    local project_dir = wezterm.home_dir .. '/Developer/wallet'

    local tab, main_pane, window = mux.spawn_window {
        cwd = project_dir .. '/packages/wallet',
    }

    local sdk_pane = main_pane:split {
        direction = 'Right',
        -- cwd = project_dir .. '/sdk',
    }
    -- sdk_pane:send_text 'bun run build\n'

    -- local example_pane = main_pane:split {
    --     direction = 'Bottom',
    --     cwd = project_dir .. '/packages/example',
    -- }
    local dashboard_pane = main_pane:split {
        direction = 'Bottom',
        cwd = project_dir,
    }

    local root_pane = sdk_pane:split {
        direction = 'Bottom',
        cwd = project_dir,
    }
end

return {
    startup = startup
}
