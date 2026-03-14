GlobalSearch = {
    name     = "GlobalSearch",
    author   = "AHenneUK",
    color    = "eba834",
    menuName = "Global Search",
}

GlobalSearch.DefaultSettings = {
    accountWide       = true,
    showFavourites    = true,
    showRecent        = true,

    searchSets        = true,
    searchFurnishings = true,
}

GlobalSearch.DefaultIndex = {
    api_version = 0,
    sets = {},
    recipes = {},
    furnishings = {},
    materials = {},
    collectibles = {}
}

-- I can't stand camel_case

local LibSets = LibSets

ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_SEARCH", "Toggle Search Menu")

function GlobalSearch.Colorize(text, color)
    if not color then color = GlobalSearch.color end
    text = string.format('|c%s%s|r', color, text)
    return text
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- MENU TOGGLE

function GlobalSearch.DisplayMenu()
    local is_hidden = GS_Window:IsHidden()
    GS_Window:SetHidden(not is_hidden)

    if not is_hidden then
        SetGameCameraUIMode(false)
        GS_WindowSearchBar:LoseFocus()
    else
        SetGameCameraUIMode(true)
        GS_WindowSearchBar:TakeFocus()
    end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SEARCH FUNCTIONALITY

function GlobalSearch.OnSearchTextChanged(control)
    local text = control:GetText()

    EVENT_MANAGER:UnregisterForUpdate(GlobalSearch.name .. "SearchUpdate")
    EVENT_MANAGER:RegisterForUpdate(GlobalSearch.name .. "SearchUpdate", 100, function()
        EVENT_MANAGER:UnregisterForUpdate(GlobalSearch.name .. "SearchUpdate")
        GlobalSearch.Search(text)
    end)
end

local SEARCH_CATEGORIES = {
    { control = GS_List_Sets,         key = "sets" },
    { control = GS_List_Furnishings,  key = "furnishings" },
    { control = GS_List_Recipes,      key = "recipes" },
    { control = GS_List_Materials,    key = "materials" },
    { control = GS_List_Collectibles, key = "collectibles" },
}

function GlobalSearch.Search(search_query)
    for _, category in ipairs(SEARCH_CATEGORIES) do
        local results

        if (search_query == "") then
            results = {}
        else
            results = GlobalSearch.GetSearchResults(category.key, search_query, 40)
        end

        GlobalSearch.PopulateColumn(category.control, results)

        -- GS_WindowStatus:SetText("You've searched for " .. search_query)
    end
end

function GlobalSearch.GetSearchResults(cache_category, search_query, max_results)
    local results = {}
    local query = search_query:lower()
    local count = 0

    local cache = GlobalSearch.index[cache_category]
    if not cache then return results end

    for _, data in ipairs(cache) do
        local item_name = data.lower_name or ""

        if item_name:find(query, 1, true) then
            table.insert(results, data)
            count = count + 1
        end
        if count >= max_results then break end
    end

    return results
end

GlobalSearch.ControlPool = GlobalSearch.ControlPool or {}

function GlobalSearch.PopulateColumn(scroll_container, items)
    local scroll_child = scroll_container:GetNamedChild("ScrollChild")
    if not scroll_child then return end

    local containerName = scroll_container:GetName()
    GlobalSearch.ControlPool[containerName] = GlobalSearch.ControlPool[containerName] or {}

    for _, row in ipairs(GlobalSearch.ControlPool[containerName]) do
        row:SetHidden(true)
    end

    local anchorY = 0
    local rowHeight = 28
    local rowWidth = scroll_container:GetWidth() - 20

    for i, item in ipairs(items) do
        local row = GlobalSearch.ControlPool[containerName][i]

        if not row then
            local rowName = containerName .. "Row" .. i
            row = WINDOW_MANAGER:CreateControlFromVirtual(rowName, scroll_child, "GS_ResultRow")
            table.insert(GlobalSearch.ControlPool[containerName], row)
        end

        row:SetHidden(false)
        row:SetWidth(rowWidth)

        row:ClearAnchors()
        row:SetAnchor(TOPLEFT, scroll_child, TOPLEFT, 5, anchorY)

        local label = row:GetNamedChild("Name")
        label:SetText(item.name)

        row:SetHandler("OnMouseEnter", function(self)
            self:GetNamedChild("Highlight"):SetHidden(false)
            InitializeTooltip(InformationTooltip, self, RIGHT, -10, 0, LEFT)
            if item.link then
                InformationTooltip:SetLink(item.link)
            else
                InformationTooltip:AddLine(item.name, "ZoFontHeader3")
            end
        end)
        row:SetHandler("OnMouseExit", function(self)
            self:GetNamedChild("Highlight"):SetHidden(true)
            ClearTooltip(InformationTooltip)
        end)

        anchorY = anchorY + rowHeight
    end

    scroll_child:SetHeight(anchorY)
    ZO_Scroll_UpdateScrollBar(scroll_container)
end

-------------------------------------------------------------------------------
-- INDEXES

function GlobalSearch.IndexSets()
    if not LibSets then return end

    local all_sets = LibSets.GetAllSetIds()
    for set_id, _ in pairs(all_sets) do
        local name = LibSets.GetSetName(set_id)
        local set_type = LibSets.GetSetTypeName(LibSets.GetSetType(set_id))

        table.insert(GlobalSearch.index.sets, {
            id = set_id,
            name = name,
            set_type = set_type,
            lower_name = name:lower()
        })
    end
end

function GlobalSearch.IndexItems(start_id)
    start_id = start_id or 1
    local batch_size = 5000
    local max_id = 230000

    for i = start_id, start_id + batch_size do
        if i > max_id then
            return
        end

        local link = string.format("|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", i)
        local name = GetItemLinkName(link)

        if name ~= "" then
            local item_type = GetItemLinkItemType(link)
            local data = { name = name, lower_name = name:lower(), link = link }

            if item_type == ITEMTYPE_RECIPE or item_type == ITEMTYPE_RACIAL_STYLE_MOTIF then
                table.insert(GlobalSearch.index.recipes, data)
            elseif item_type == ITEMTYPE_FURNISHING then
                table.insert(GlobalSearch.index.furnishings, data)
            elseif GlobalSearch.IsMaterial(item_type) then
                table.insert(GlobalSearch.index.materials, data)
            elseif item_type == ITEMTYPE_COLLECTIBLE then
                table.insert(GlobalSearch.index.collectibles, data)
            end
        end
    end
    zo_callLater(function() GlobalSearch.IndexItems(start_id + batch_size + 1) end, 10)
end

function GlobalSearch.IsMaterial(itemType)
    local m = {
        [ITEMTYPE_BLACKSMITHING_MATERIAL] = true,
        [ITEMTYPE_CLOTHIER_MATERIAL] = true,
        [ITEMTYPE_WOODWORKING_MATERIAL] = true,
        [ITEMTYPE_JEWELRYCRAFTING_MATERIAL] = true,
        [ITEMTYPE_STYLE_MATERIAL] = true,
        [ITEMTYPE_INGREDIENT] = true,
        [ITEMTYPE_ENCHANTING_RUNE_POTENCY] = true,
        [ITEMTYPE_ENCHANTING_RUNE_ESSENCE] = true,
        [ITEMTYPE_ENCHANTING_RUNE_ASPECT] = true,
        [ITEMTYPE_RAW_MATERIAL] = true
    }
    return m[itemType] or false
end

function GlobalSearch.CreateIndex()
    
    GlobalSearch.index.sets = {}
    GlobalSearch.index.recipes = {}
    GlobalSearch.index.furnishings = {}
    GlobalSearch.index.materials = {}
    GlobalSearch.index.collectibles = {}

    d("[GlobalSearch] Your game may stutter for a few moments.")

    GlobalSearch.IndexSets()
    GlobalSearch.IndexItems()
    GlobalSearch.index.api_version = GetAPIVersion()

    d("[GlobalSearch] Indexing complete!")
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function GlobalSearch.OnAddOnLoaded(event, addonName)
    if addonName ~= GlobalSearch.name then return end

    EVENT_MANAGER:UnregisterForEvent(GlobalSearch.name, EVENT_ADD_ON_LOADED)

    GlobalSearch.characterSavedVars = ZO_SavedVars:New("GlobalSearchSavedVariables", 1, nil, GlobalSearch
        .DefaultSettings)
    GlobalSearch.accountSavedVars = ZO_SavedVars:NewAccountWide("GlobalSearchSavedVariables", 1, nil,
        GlobalSearch.DefaultSettings)
    GlobalSearch.savedVars = GlobalSearch.characterSavedVars.accountWide and GlobalSearch.accountSavedVars or
        GlobalSearch.characterSavedVars

    GlobalSearch.CreateSettingsMenu()

    GlobalSearch.index = ZO_SavedVars:NewAccountWide("GlobalSearchIndex", 1, nil, GlobalSearch.DefaultIndex)

    local current_api = GetAPIVersion()
    if #GlobalSearch.index.sets == 0 or GlobalSearch.index.api_version ~= current_api then
        d("[GlobalSearch] New installation or new update detected. Creating index.")
        GlobalSearch.CreateIndex()
    end

    SLASH_COMMANDS["/gs"] = GlobalSearch.DisplayMenu

    SLASH_COMMANDS["/gsindex"] = function()
        d("[GlobalSearch] Running re-index.")
        GlobalSearch.CreateIndex()
    end
end

EVENT_MANAGER:RegisterForEvent(GlobalSearch.name, EVENT_ADD_ON_LOADED, GlobalSearch.OnAddOnLoaded)
