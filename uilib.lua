--[[

v1 (rough) ui lib
@nulare on discord

UILib.new(name) -> Window
Window:Tab(name) -> tabName
Window:Checkbox(tabName, itemLabel, defaultValue <boolean>, callback <function>)
Window:Slider(tabName, itemLabel, defaultValue <int>, step <int>, min <int>, max <int>, callback <function>)
Window:Button(tabName, itemText, callback <function>)
Window:Destroy()

General example
local myGui = UILib.new('chatgpthaxx')

local tabEsp = myGui:Tab('ESP')
myGui:Checkbox(tabEsp, 'Ally ESP', true, nil)
myGui:Slider(tabEsp, 'Range', 1000, 100, 100, 2000, ' studs', nil)

local tabTeleports = myGui:Tab('Teleports')
myGui:Button(tabTeleports, 'Teleport to Base', nil)

pcall(function()
    while true do
        myGui:Step()

        wait(1/240)
    end
end)

myGui:Destroy()

]]

UILib = {}
UILib.__index = UILib

local myPlayer = game:GetService('Players').LocalPlayer
local myMouse = myPlayer:GetMouse()

local function ismouse1pressed()
    -- implement your own method
end

local function getMousePos()
    return Vector2(myMouse.X, myMouse.Y) 
end

local function undrawAll(drawingsTable)
    for _, drawing in pairs(drawingsTable) do
        drawing.Visible = false
    end
end

function UILib.new(name)
    local self = setmetatable({}, UILib)

    self._click_frame = false
    self._m1_down = false
    self._m1_held = false

    self.x = 150
    self.y = 150
    self.w = 350
    self.h = 300

    self._dragging = false
    self._drag_offset = Vector2(0, 0)

    self._padding = 4

    self._title_h = 20

    self._tab_h = 18

    self._item_h = 26

    local uiBase = Drawing.new('Square')
    uiBase.Filled = true

    local uiTitle = Drawing.new('Text')
    uiTitle.Text = name

    self._tree = {
        ['_tabs'] = {},
        ['_drawings'] = { uiBase, uiTitle }
    }

    return self
end

function UILib._IsMouseWithinBounds(origin, size)
    local mousePos = getMousePos()
    return mousePos.x >= origin.x and mousePos.x <= origin.x + size.x and mousePos.y >= origin.y and mousePos.y <= origin.y + size.y
end

function UILib:Tab(name)
    local tabBackdrop = Drawing.new('Square')
    tabBackdrop.Filled = true

    local tabText = Drawing.new('Text')

    table.insert(self._tree['_tabs'], {
        ['name'] = name,
        ['_items'] = {},
        ['_collapsed'] = true,
        ['_drawings'] = { tabBackdrop, tabText }
    })

    return name
end

function UILib:_AddToTab(masterTab, itemType, value, callback, drawings, meta)
    for _, tab in pairs(self._tree._tabs) do
        if tab.name == masterTab then
            local item = {
                ['type'] = itemType,
                ['value'] = value,
                ['callback'] = callback,
                ['_drawings'] = drawings
            }

            if meta then
                for key, val in pairs(meta) do
                    item[key] = val
                end
            end

            table.insert(tab._items, item)
            break
        end
    end
end

function UILib:Checkbox(masterTab, label, defaultValue, callback)
    local checkboxOutline = Drawing.new('Square')
    checkboxOutline.Thickness = 2
    checkboxOutline.Filled = false

    local checkboxFill = Drawing.new('Square')
    checkboxFill.Filled = true

    local labelText = Drawing.new('Text')
    labelText.Text = label

    self:_AddToTab(masterTab, 'checkbox', defaultValue, callback, {
        checkboxOutline,
        checkboxFill,
        labelText
    })
end

function UILib:Button(masterTab, label, callback)
    local masterText = Drawing.new('Text')
    masterText.Text = ':: ' .. label .. ' ::'

    self:_AddToTab(masterTab, 'button', nil, callback, {
        masterText
    })
end

function UILib:Slider(masterTab, label, defaultValue, step, min, max, unit, callback)
    local barOutline = Drawing.new('Square')
    barOutline.Thickness = 2
    barOutline.Filled = false

    local barFill = Drawing.new('Square')
    barFill.Filled = true

    local labelText = Drawing.new('Text')
    labelText.Text = label

    self:_AddToTab(masterTab, 'slider', defaultValue, callback, {
        barOutline,
        barFill,
        labelText
    }, {
        ['step'] = step,
        ['min'] = min,
        ['max'] = max,
        ['unit'] = unit,
        ['_label'] = label
    })
end

function UILib:Choice(masterTab, label, defaultValue, choices, callback)
    local masterText = Drawing.new('Text')
    masterText.Text = label

    self:_AddToTab(masterTab, 'choice', defaultValue, callback, {
        masterText
    }, {
        ['choices'] = choices,
        ['_label'] = label
    })
end

function UILib:Step()
    -- our input stuff
    local mousePos = getMousePos()
    if ismouse1pressed() then
        if not self._m1_held then
            self._click_frame = true
        end

        self._m1_held = true
    else
        self._m1_held = false
    end

    -- draw menu base
    local uiBase = self._tree['_drawings'][1]
    local uiTitle = self._tree['_drawings'][2]

    uiBase.Position = Vector2(self.x, self.y)
    uiBase.Size = Vector2(self.w, self.h)
    uiBase.Color = Color3(0.22, 0.22, 0.22)
    uiBase.Visible = true

    uiTitle.Position = Vector2(self.x + self._padding, self.y + self._padding)
    uiTitle.Color = Color3(1, 0, 1)
    uiTitle.Visible = true

    -- input handling for menu dragging
    local titleOrigin = Vector2(self.x, self.y)
    local titleSize = Vector2(self.w, self._title_h)

    if self._IsMouseWithinBounds(titleOrigin, titleSize) then
        if self._click_frame then
            self._dragging = true
            self._drag_offset = getMousePos() - titleOrigin
        end
    end

    if self._dragging then
        if self._m1_held then
            local newMousePos = getMousePos()
            self.x = newMousePos.x - self._drag_offset.x
            self.y = newMousePos.y - self._drag_offset.y
        else
            self._dragging = false
        end

        self._click_frame = false
    end

    -- draw tabs
    local uiTotalY = self._title_h + self._padding
    for _, tab in pairs(self._tree['_tabs']) do
        local tabDraws = tab['_drawings']
        local tableCollapsed = tab['_collapsed']
        local tabName = tab['name']

        local tabPosition = Vector2(self.x + self._padding, self.y + uiTotalY)
        local tabSize = Vector2(self.w - self._padding * 2, self._tab_h)

        tabDraws[1].Position = tabPosition
        tabDraws[1].Size = tabSize
        tabDraws[1].Color = Color3(0.33, 0.33, 0.33)
        tabDraws[1].Visible = true

        tabDraws[2].Position = Vector2(tabPosition.x + 4, tabPosition.y + 4)
        tabDraws[2].Text = tabName .. (tab['_collapsed'] and " [+]" or " [-]")
        tabDraws[2].Color = Color3(1, 1, 1)
        tabDraws[2].Visible = true

        -- input handling for tabs
        if self._IsMouseWithinBounds(tabPosition, tabSize) then
            tabDraws[1].Color = Color3(1, 0, 1)

            if self._click_frame then
                tab['_collapsed'] = not tab['_collapsed']
            end
        end

        -- draw items
        uiTotalY = uiTotalY + self._tab_h
        for _, tabItem in pairs(tab['_items']) do
            local itemType = tabItem['type']
            local itemValue = tabItem['value']
            local itemCallback = tabItem['callback']
            local itemDraws = tabItem['_drawings']

            if not tableCollapsed then
                local itemWidth = self.w - self._padding * 2 - 15
                local itemOriginX = self.x + self._padding + 10
                local itemOriginY = self.y + uiTotalY

                -- instructions how to draw each item
                if itemType == 'checkbox' then
                    itemDraws[3].Position = Vector2(itemOriginX + 4, itemOriginY + self._item_h / 2 - 4)
                    itemDraws[3].Color = Color3(1, 1, 1)
                    itemDraws[3].Visible = true

                    local checkboxX = itemOriginX + itemWidth - self._padding * 4 - 8
                    local checkboxY = itemOriginY + self._item_h / 2 - 7
                    local checkboxSize = Vector2(14, 14)

                    itemDraws[2].Position = Vector2(checkboxX + 2, checkboxY + 2)
                    itemDraws[2].Size = Vector2(10, 10)
                    itemDraws[2].Filled = true
                    itemDraws[2].Color = Color3(1, 0, 1)
                    itemDraws[2].Visible = itemValue

                    itemDraws[1].Position = Vector2(checkboxX, checkboxY)
                    itemDraws[1].Size = checkboxSize
                    itemDraws[1].Filled = false
                    itemDraws[1].Thickness = 1

                    -- input handling for checkboxes
                    if self._IsMouseWithinBounds(Vector2(checkboxX, checkboxY), checkboxSize) then
                        itemDraws[1].Color = Color3(1, 0, 1)

                        if self._click_frame then
                            local newValue = not tabItem['value']
                            tabItem['value'] = newValue

                            if itemCallback then
                                itemCallback(newValue)
                            end
                        end
                    else
                        itemDraws[1].Color = Color3(1, 1, 1)
                    end

                    itemDraws[1].Visible = true
                elseif itemType == 'button' then
                    local buttonX = itemOriginX
                    local buttonY = itemOriginY
                    local buttonSize = Vector2(itemWidth, self._item_h)

                    itemDraws[1].Position = Vector2(buttonX, buttonY + buttonSize.y / 2 - 4)

                    -- input handling for buttons
                    if self._IsMouseWithinBounds(Vector2(buttonX, buttonY), buttonSize) then
                        itemDraws[1].Color = Color3(1, 0, 1)

                        if self._click_frame and itemCallback then
                            itemCallback()
                        end
                    else
                        itemDraws[1].Color = Color3(1, 1, 1)
                    end

                    itemDraws[1].Visible = true
                elseif itemType == 'slider' then
                    local sliderWidth = 140
                    local sliderHeight = 8
                    local sliderX = itemOriginX + itemWidth - sliderWidth - self._padding * 2
                    local sliderY = itemOriginY + self._item_h / 2 - sliderHeight / 2

                    local sliderOutline = itemDraws[1]
                    local sliderFill = itemDraws[2]
                    local sliderLabel = itemDraws[3]

                    sliderOutline.Position = Vector2(sliderX, sliderY)
                    sliderOutline.Size = Vector2(sliderWidth, sliderHeight)
                    sliderOutline.Color = Color3(1, 1, 1)
                    sliderOutline.Visible = true

                    local sliderValueRatio = (itemValue - tabItem['min']) / (tabItem['max'] - tabItem['min'])
                    local sliderFillWidth = sliderValueRatio * sliderWidth

                    sliderFill.Position = Vector2(sliderX + 3, sliderY + 3)
                    sliderFill.Size = Vector2(sliderFillWidth - 6 * (sliderValueRatio), sliderHeight - 6)
                    sliderFill.Color = Color3(1, 0, 1)
                    sliderFill.Visible = true

                    sliderLabel.Position = Vector2(itemOriginX + 4, itemOriginY + self._item_h / 2 - 4)
                    sliderLabel.Text = tabItem['_label'] .. ' :: ' .. tostring(itemValue) .. (tabItem['unit'] or '')
                    sliderLabel.Color = Color3(1, 1, 1)
                    sliderLabel.Visible = true

                    -- input handling for sliders
                    if self._IsMouseWithinBounds(Vector2(sliderX, sliderY), Vector2(sliderWidth, sliderHeight)) then
                        sliderOutline.Color = Color3(1, 0, 1)

                        if self._m1_held then
                            local mouseOffset = mousePos.x - sliderX
                            local newValue = tabItem['min'] + (mouseOffset / sliderWidth) * (tabItem['max'] - tabItem['min'])
                            
                            newValue = math.max(tabItem['min'], math.min(newValue, tabItem['max'])) -- clamp our value
                            newValue = math.ceil(newValue / tabItem['step']) * tabItem['step'] -- and "round" it
                            tabItem['value'] = newValue

                            if itemCallback then
                                itemCallback(newValue)
                            end
                        end
                    else
                        sliderOutline.Color = Color3(1, 1, 1)
                    end
                elseif itemType == 'choice' then

                end

                uiTotalY = uiTotalY + self._item_h
            else
                undrawAll(itemDraws)
            end
        end

        uiTotalY = uiTotalY + self._padding
    end

    -- finalize all input
    self._click_frame = false
end

function UILib:Destroy()
    for _, drawing in pairs(self._tree['_drawings']) do
        drawing:Remove()
    end

    for _, tab in pairs(self._tree['_tabs']) do
        for _, item in pairs(tab['_items']) do
            for _, drawing in pairs(item['_drawings']) do
                drawing:Remove()
            end
        end

        for _, drawing in pairs(tab['_drawings']) do
            drawing:Remove()
        end
    end

    self._tree = nil
end
