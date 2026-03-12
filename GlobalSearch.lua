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

    searchSets     = true,
}

ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_SEARCH", "Toggle Search Menu")

function GlobalSearch.Colorize(text, color)
    if not color then color = GlobalSearch.color end
    text = string.format('|c%s%s|r', color, text)
    return text
end

GlobalSearch.Cache = {
    sets = {}
}

-------------------------------------------------------------------------------
-- MENU TOGGLE

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

-------------------------------------------------------------------------------
-- SEARCH FUNCTIONALITY

function GlobalSearch.OnSearchTextChanged(control)
    GlobalSearch.Search(control)

    -- throttling - hide for now, may need when more functionality is added.
    -- EVENT_MANAGER:UnregisterForUpdate(GlobalSearch.name .. "SearchUpdate")
    -- EVENT_MANAGER:RegisterForUpdate(GlobalSearch.name .. "SearchUpdate", 250, function()
    --     EVENT_MANAGER:UnregisterForUpdate(GlobalSearch.name .. "SearchUpdate")
    --     GlobalSearch.Search(control)
    -- end)
end

function GlobalSearch.Search(control)
    local searchText = control:GetText()

    if searchText == "" then
        GS_WindowOutput:SetText("|c666666Type something to search...|r")
        return
    end

    local output = ""

    local resultSets = ""

    if GlobalSearch.savedVars.searchSets then
        resultSets = GlobalSearch.SearchSetItems(searchText)
        output = output .. resultSets
    end

    GS_WindowOutput:SetText(output)
end

function GlobalSearch.SearchSetItems(searchQuery)
    if not LibSets then return "|cFF0000Error: LibSets not found|r" end

    local foundStr = ""
    local query = searchQuery:lower()
    local count = 0
    local maxResults = 14

    for _, setData in ipairs(GlobalSearch.Cache.sets) do
        if setData.lowerName:find(query, 1, true) then
            foundStr = foundStr .. "- " .. setData.name .. " / " .. setData.setType .. "\n"
            count = count + 1
        end
        if count >= maxResults then break end
    end

    if foundStr == "" then
        return "No sets match the name.\n"
    end

    return foundStr
end

-------------------------------------------------------------------------------

function GlobalSearch.IndexSets()
    if not LibSets then return end

    GlobalSearch.Cache.sets = {}

    local allSets = LibSets.GetAllSetIds()
    for setId, _ in pairs(allSets) do
        
        local name = LibSets.GetSetName(setId)
        local setType = LibSets.GetSetTypeName(LibSets.GetSetType(setId))

        table.insert(GlobalSearch.Cache.sets, {
            id = setId,
            name = name,
            setType = setType,
            lowerName = name:lower()
        })
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

    GlobalSearch.IndexSets()
    GS_WindowOutput:SetText("|c666666Type something to search...|r")
end

EVENT_MANAGER:RegisterForEvent(GlobalSearch.name, EVENT_ADD_ON_LOADED, GlobalSearch.OnAddOnLoaded)
