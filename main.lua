-- ===========================================================
-- 🧩 ScriptsMobileManager (Versão Forçada de Inicialização)
-- ===========================================================
setDefaultTab("Main")

local root = g_ui.getRootWidget()
local path = "/storage/emulated/0/Download/ScriptsMobileManager/"
local version = "0.4"

print("[ScriptsMobileManager] Iniciando...")

-- ================================
-- 📦 Carrega as bibliotecas locais
-- ================================
local libs = {"Library.lua", "script.list.lua"}
for _, lib in ipairs(libs) do
  local file = path .. lib
  if g_resources.fileExists(file) then
    local content = g_resources.readFileContents(file)
    local ok, err = pcall(loadstring(content))
    if not ok then
      print("[Erro] Falha ao carregar " .. lib .. ": " .. err)
    else
      print("[OK] Biblioteca carregada: " .. lib)
    end
  else
    print("[Aviso] Arquivo não encontrado:", file)
  end
end

-- ================================
-- 🎛️ Cria botão e painel base
-- ================================
local function createManagerButton()
  if not root then
    print("[Erro] RootWidget não encontrado.")
    return
  end

  -- Cria painel visual
  local managerUI = setupUI([[
UIWidget
  id: scriptsMobileManager
  size: 300 380
  background-color: #111111
  opacity: 0.95
  border: 1 white
  draggable: true

  Label
    id: title
    text: "Scripts Mobile Manager v]] .. version .. [["
    color: white
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 6

  Button
    id: close
    text: "Fechar"
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    margin-bottom: 10
]], root)

  managerUI:hide()

  -- Botão principal na aba "Main"
  local btn = UI.Button("📜 Script Manager", function()
    if managerUI:isVisible() then
      managerUI:hide()
    else
      managerUI:show()
      managerUI:raise()
      managerUI:focus()
    end
  end, getTab("Main"))
  btn:setColor("#00BFFF")
  btn:setTooltip("Abrir o painel de scripts locais")

  -- Fecha o painel
  managerUI.close.onClick = function()
    managerUI:hide()
  end

  print("[ScriptsMobileManager] Botão criado com sucesso.")
end

-- Executa
createManagerButton()
print("[ScriptsMobileManager] Inicialização concluída.")
