-- 📚 Library.lua - Biblioteca principal (Offline)
script_manager = script_manager or {}

function loadRemoteScript(url)
  print('[Offline Mode] loadRemoteScript ignorado:', url)
end

print('[Library.lua] Carregado com sucesso (modo offline).')
