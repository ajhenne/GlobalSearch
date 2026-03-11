GlobalSearch = {
    name     = "GlobalSearch",
    author   = "AHenneUK",
    color    = "eba834",
    menuName = "Global Search",
}

GlobalSearch.Default = {
    accountWide    = true,
    showFavourites = true,
    showRecent     = true,
}

ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_SEARCH", "Toggle Search Menu")

function GlobalSearch.Colorize(text, color)
    if not color then color = GlobalSearch.color end
    text = string.format('|c%s%s|r', color, text)
    return text
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function GlobalSearch.DisplayMenu()
    local isHidden = GS_Window:IsHidden()
    GS_Window:SetHidden(not isHidden)

    if not isHidden then
        SetGameCameraUIMode(false)
        GS_WindowSearchBar:LoseFocus()
    else
        SetGameCameraUIMode(true)
        GS_WindowSearchBar:TakeFocus()
    end
end

function GlobalSearch.OnSearchTextChanged(control)
    local text = control:GetText()

    if text == "" then
        GS_WindowOutput:SetText("|c666666Type something to search...|r")
    else
        GS_WindowOutput:SetText("Searching for: " .. "|c" .. GlobalSearch.color .. text .. "|r")
    end

end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function GlobalSearch.OnAddOnLoaded(event, addonName)
    if addonName ~= GlobalSearch.name then return end
    EVENT_MANAGER:UnregisterForEvent(GlobalSearch.name, EVENT_ADD_ON_LOADED)

    GlobalSearch.characterSavedVars = ZO_SavedVars:New("GlobalSearchSavedVariables", 1, nil, GlobalSearch.Default)
    GlobalSearch.accountSavedVars = ZO_SavedVars:NewAccountWide("GlobalSearchSavedVariables", 1, nil,
        GlobalSearch.Default)

    if not GlobalSearch.characterSavedVars.accountWide then
        GlobalSearch.savedVars = GlobalSearch.characterSavedVars
    else
        GlobalSearch.savedVars = GlobalSearch.accountSavedVars
    end

    GlobalSearch.CreateSettingsMenu()
    SLASH_COMMANDS["/gs"] = GlobalSearch.DisplayMenu

    GS_WindowOutput:SetText("|c666666Type something to search...|r")
end

EVENT_MANAGER:RegisterForEvent(GlobalSearch.name, EVENT_ADD_ON_LOADED, GlobalSearch.OnAddOnLoaded)
