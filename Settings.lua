function GlobalSearch.CreateSettingsMenu()
    local LAM = LibAddonMenu2
    if not LAM then return end

    local panelData = {
        type = "panel",
        name = GlobalSearch.menuName,
        displayName = "|c" .. GlobalSearch.color .. GlobalSearch.menuName .. "|r",
        author = GlobalSearch.author,
        version = GlobalSearch.version,
        slashCommand = "/gss",
        registerForRefresh = true,
    }
    LAM:RegisterAddonPanel("GlobalSearchOptions", panelData)

    local optionsTable = {
        {
            type = "header",
            name = "General Settings",
        },
        {
            type = "checkbox",
            name = "Account Wide Settings",
            tooltip = "Check this to use the same settings for all characters.",
            getFunc = function() return GlobalSearch.characterSavedVars.accountWide end,
            setFunc = function(v) GlobalSearch.characterSavedVars.accountWide = v end,
            requiresReload = true,
        },
        {
            type = "checkbox",
            name = "Show Favourites",
            tooltip = "Keep track of favourited items.",
            getFunc = function() return GlobalSearch.savedVars.showFavourites end,
            setFunc = function(v) GlobalSearch.savedVars.showFavourites = v end,
        },
        {
            type = "checkbox",
            name = "Show Recent",
            tooltip = "Show recently searched for items.",
            getFunc = function() return GlobalSearch.savedVars.showRecent end,
            setFunc = function(v) GlobalSearch.savedVars.showRecent = v end,
        },
        {
            type = "header",
            name = "Search Results",
        },
        {
            type = "checkbox",
            name = "Sets",
            tooltip = "Include set items.",
            getFunc = function() return GlobalSearch.savedVars.searchSets end,
            setFunc = function(v) GlobalSearch.savedVars.searchSets = v end,
        },
        -- {
        --     type = "colorpicker",
        --     name = "Highlight Color",
        --     tooltip = "The color of the search text in the results area.",
        --     getFunc = function() return GlobalSearch.savedVars.highlightColor.r, GlobalSearch.savedVars.highlightColor.g, GlobalSearch.savedVars.highlightColor.b, GlobalSearch.savedVars.highlightColor.a end,
        --     setFunc = function(r,g,b,a) GlobalSearch.savedVars.highlightColor = {r=r, g=g, b=b, a=a} end,
        -- },
    }
    LAM:RegisterOptionControls("GlobalSearchOptions", optionsTable)
end
