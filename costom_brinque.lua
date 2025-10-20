-- ===========================================================
-- Community Scripts - Modo OFFLINE (corrigido e otimizado)
-- ===========================================================

script_bot = {}

-- --- Configs rápidas ---------------------------------------
local TAB_ID = 'Main'
local actualVersion = 0.4
local RAW = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts'
local LOAD_ACTIVE_ON_START = true

-- --- Setup de aba ------------------------------------------
setDefaultTab(TAB_ID)
local tabName = getTab(TAB_ID) or setDefaultTab(TAB_ID)

-- --- Storage -----------------------------------------------
storage.cs_enabled   = storage.cs_enabled   or {}   -- [cat][name] = true/false
storage.cs_last_tab  = storage.cs_last_tab  or nil

-- --- Utils --------------------------------------------------
local function logStatus(msg)
  print('[Community Scripts]', msg)
  if script_bot.widget and script_bot.widget.statusLabel then
    script_bot.widget.statusLabel:setText(msg)
  end
end

-- evita carregar mesma URL duas vezes na mesma sessão
local loadedUrls = loadedUrls or {}

local function safeLoadUrl(url)
  if loadedUrls[url] then
    logStatus('Já carregado: ' .. url)
    return
  end
  modules.corelib.HTTP.get(url, function(content, err)
    if not content then
      logStatus('Erro ao baixar: ' .. (err or 'sem resposta'))
      return
    end
    local ok, res = pcall(loadstring(content))
    if not ok then
      logStatus('Erro ao executar: ' .. tostring(res))
    else
      loadedUrls[url] = true
      logStatus('Script carregado com sucesso.')
    end
  end)
end

local function isEnabled(cat, name)
  return storage.cs_enabled[cat] and storage.cs_enabled[cat][name] == true
end

local function setEnabled(cat, name, value)
  storage.cs_enabled[cat] = storage.cs_enabled[cat] or {}
  storage.cs_enabled[cat][name] = value and true or false
end

-- ===========================================================
-- LISTA LOCAL (adicione/edite aqui)
-- ===========================================================
script_manager = {
  actualVersion = actualVersion,
  _cache = {
    Dbo = {
      ['Reflect'] = {
        url = RAW .. '/Dbo/Reflect.lua',
        description = 'Reflect para DBOverse.',
        author = 'Brinquee',
      },
    },
    Nto = {
      ['Bug Map Kunai'] = {
        url = RAW .. '/Nto/Bug_map_kunai.lua',
        description = 'Bug map kunai (PC).',
        author = 'Brinquee',
      },
    },
    Tibia = {
      ['Utana Vid'] = {
        url = RAW .. '/Tibia/utana_vid.lua',
        description = 'Invisibilidade automática.',
        author = 'Brinquee',
      },
    },
    PvP = {
      ['Follow Attack'] = {
        url = RAW .. '/PvP/follow_attack.lua',
        description = 'Seguir e atacar target.',
        author = 'VictorNeox',
      },
    },
    Healing = {
      ['Regeneration'] = {
        url = RAW .. '/Healing/Regeneration.lua',
        description = 'Cura por % de HP.',
        author = 'Brinquee',
      },
    },
    Utilities = {
      ['Dance'] = {
        url = RAW .. '/Utilities/dance.lua',
        description = 'Gira aleatório (fun).',
        author = 'Brinquee',
      },
    },
  }
}

-- ===========================================================
-- UI
-- ===========================================================
local itemRow = [[
UIWidget
  background-color: alpha
  focusable: true
  height: 30

  $focus:
    background-color: #00000055

  Label
    id: textToSet
    font: terminus-14px-bold
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
]]

script_bot.widget = setupUI([[
MainWindow
  !text: tr('Community Scripts')
  font: terminus-14px-bold
  color: #d2cac5
  size: 380 460

  TabBar
    id: macrosOptions
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    width: 180

  ScrollablePanel
    id: scriptList
    layout:
      type: verticalBox
    anchors.fill: parent
    margin-top: 45
    margin-left: 2
    margin-right: 15
    margin-bottom: 52
    vertical-scrollbar: scriptListScrollBar

  VerticalScrollBar
    id: scriptListScrollBar
    anchors.top: scriptList.top
    anchors.bottom: scriptList.bottom
    anchors.right: scriptList.right
    step: 14
    pixels-scroll: true
    margin-right: -10

  Label
    id: statusLabel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-bottom: 28
    text-align: center
    font: terminus-14px
    color: yellow

  TextEdit
    id: searchBar
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    margin-right: 5
    width: 180

  Button
    id: refreshButton
    !text: tr('Atualizar')
    font: cipsoftFont
    anchors.left: searchBar.right
    anchors.bottom: parent.bottom
    size: 70 21
    margin-bottom: 1
    margin-left: 5

  Button
    id: toggleAllButton
    !text: tr('All ON/OFF')
    font: cipsoftFont
    anchors.left: refreshButton.right
    anchors.bottom: parent.bottom
    size: 78 21
    margin-bottom: 1
    margin-left: 5

  Button
    id: closeButton
    !text: tr('Fechar')
    font: cipsoftFont
    anchors.right: parent.right
    anchors.left: toggleAllButton.right
    anchors.bottom: parent.bottom
    size: 80 23
    margin-bottom: 1
    margin-right: 5
    margin-left: 5
]], g_ui.getRootWidget())

script_bot.widget:hide()
script_bot.widget:setText('Community Scripts - ' .. actualVersion)
script_bot.widget.statusLabel:setText('Pronto.')

-- Botão principal no painel
script_bot.buttonWidget = UI.Button('CS Manager (NEW)', function()
  if script_bot.widget:isVisible() then
    reload()
  else
    script_bot.widget:show()
    local last = storage.cs_last_tab
    if last then
      -- seleciona com segurança
      safeSelectTab(script_bot.widget.macrosOptions, last)
    else
      script_bot.widget.macrosOptions:selectPrevTab()
    end
  end
end, tabName)
script_bot.buttonWidget:setColor('#d2cac5')

-- Fechar
script_bot.widget.closeButton:setTooltip('Fechar e recarregar.')
script_bot.widget.closeButton.onClick = function()
  reload()
  script_bot.widget:hide()
end

-- Busca (debounce)
do
  local searchTimer
  script_bot.widget.searchBar:setTooltip('Search...')
  script_bot.widget.searchBar.onTextChange = function(_, text)
    if searchTimer then removeEvent(searchTimer) end
    searchTimer = scheduleEvent(function()
      searchTimer = nil
      script_bot.filterScripts(text)
    end, 150)
  end
end

-- === helpers de TabBar (evita passar string pra selectTab) ===
function findTabByTextOrId(tabbar, key)
  if not tabbar or not key then return nil end
  for _, w in ipairs(tabbar:getChildren()) do
    if w.getText and (w:getText() == key) then return w end
    if w.getId   and (w:getId()   == key) then return w end
  end
  return nil
end

function safeSelectTab(tabbar, keyOrWidget)
  if not tabbar then return end
  if type(keyOrWidget) == 'userdata' then
    tabbar:selectTab(keyOrWidget); return
  end
  local w = findTabByTextOrId(tabbar, keyOrWidget)
  if w then tabbar:selectTab(w) end
end

-- Toggle All da aba
script_bot.widget.toggleAllButton.onClick = function()
  local tab = script_bot.widget.macrosOptions:getCurrentTab()
  if not tab then return end
  local cat = tab.text
  local list = script_manager._cache[cat]
  if not list then return end

  local onCount, allCount = 0, 0
  for name, _ in pairs(list) do
    allCount = allCount + 1
    if isEnabled(cat, name) then onCount = onCount + 1 end
  end
  local turnOn = onCount < allCount

  for name, data in pairs(list) do
    setEnabled(cat, name, turnOn)
    if turnOn and data.url then
      safeLoadUrl(data.url)
    end
  end
  script_bot.updateScriptList(cat)
end

-- Refresh (recarrega apenas os que estão ON)
script_bot.widget.refreshButton.onClick = function()
  -- limpa cache para permitir recarga
  for cat, list in pairs(script_manager._cache) do
    for name, data in pairs(list) do
      if isEnabled(cat, name) and data.url then
        loadedUrls[data.url] = nil
      end
    end
  end

  local loaded = 0
  for cat, list in pairs(script_manager._cache) do
    for name, data in pairs(list) do
      if isEnabled(cat, name) and data.url then
        loaded = loaded + 1
        safeLoadUrl(data.url)
      end
    end
  end
  logStatus('Recarregado(s): ' .. loaded)
end

-- Filtro de itens
function script_bot.filterScripts(filterText)
  local q = (filterText or ''):lower()
  for _, child in pairs(script_bot.widget.scriptList:getChildren()) do
    local scriptName = child:getId() or ''
    child:setVisible(scriptName:lower():find(q, 1, true) ~= nil)
  end
end

-- Lista por aba
function script_bot.updateScriptList(tabText)
  script_bot.widget.scriptList:destroyChildren()
  local list = script_manager._cache[tabText]
  if not list then return end

  for name, data in pairs(list) do
    local row = setupUI(itemRow, script_bot.widget.scriptList)
    row:setId(name)
    row.textToSet:setText(name)
    row.textToSet:setColor(isEnabled(tabText, name) and 'green' or '#bdbdbd')
    row:setTooltip(('Description: %s\nAuthor: %s\n(Click = ON/OFF | Right-click = abrir URL)')
      :format(data.description or '-', data.author or '-'))

    -- Left-click: toggle
    row.onClick = function()
      local newState = not isEnabled(tabText, name)
      setEnabled(tabText, name, newState)
      row.textToSet:setColor(newState and 'green' or '#bdbdbd')
      if newState and data.url then
        safeLoadUrl(data.url)
      end
    end

    -- Right-click: abrir URL do script
    row.onMousePress = function(_, _, button)
      if button == MouseRightButton and data.url then
        if g_platform and g_platform.openUrl then
          g_platform.openUrl(data.url)
        end
        return true
      end
      return false
    end
  end
end

-- Monta abas e seleciona
do
  local cats = {}
  for cat in pairs(script_manager._cache) do table.insert(cats, cat) end
  table.sort(cats)

  for _, cat in ipairs(cats) do
    local tab = script_bot.widget.macrosOptions:addTab(cat)
    tab:setId(cat)
    tab:setTooltip(cat .. ' Macros')
    tab.onStyleApply = function(widget)
      if script_bot.widget.macrosOptions:getCurrentTab() == widget then
        widget:setColor('green')
      else
        widget:setColor('white')
      end
    end
  end

  local startTab = storage.cs_last_tab or cats[1]
  safeSelectTab(script_bot.widget.macrosOptions, startTab)

  local cur = script_bot.widget.macrosOptions:getCurrentTab()
  if cur and cur.getText then
    script_bot.updateScriptList(cur:getText())
  end

  script_bot.widget.macrosOptions.onTabChange = function(_, t)
    local name = (type(t) == 'userdata' and t.getText) and t:getText() or t
    if not name or name == '' then
      local c = script_bot.widget.macrosOptions:getCurrentTab()
      name = (c and c.getText) and c:getText() or name
    end
    if not name then return end
    storage.cs_last_tab = name
    script_bot.updateScriptList(name)
    script_bot.filterScripts(script_bot.widget.searchBar:getText())
  end
end

-- Carregar automaticamente os que já estavam ON
if LOAD_ACTIVE_ON_START then
  local bootCount = 0
  for cat, list in pairs(script_manager._cache) do
    for name, data in pairs(list) do
      if isEnabled(cat, name) and data.url then
        bootCount = bootCount + 1
        safeLoadUrl(data.url)
      end
    end
  end
  if bootCount > 0 then
    logStatus('Scripts ativos carregados: ' .. bootCount)
  end
end

logStatus('Pronto. Selecione uma aba e ative scripts.')
