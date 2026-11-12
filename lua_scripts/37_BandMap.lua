-- ============================================================
-- 37_BandMap.lua — Серверная часть минимап-маркера «Песнь Пустоты»
--
-- Серверный хендлер клиентского аддона 38_BandMapClient.lua (AIO).
-- По запросу клиента (AIO.Handle "BAND_MAP" "GetCurrentScene") выбирает
-- сцену «Песнь Пустоты» на текущей карте игрока и отвечает:
--
--   AIO.Handle(player, "BAND_MAP", "SetTarget", mapId, x, y)
--   (если сцены на текущей карте нет — SetTarget(player, nil), маркер гаснет)
--
-- Требует: сцену/НПС из 0036 (Дюротар) и 0037 (Капельмейстер).
-- ============================================================

local AIO = AIO or nil

-- Сцена «Песнь Пустоты»: { mapId, x, y } (Дюротар).
-- Клиент сам гасит маркер, когда игрок покидает эту карту (смена зоны).
local SCENE = { 1, 1274.9, -4337.3 }

if AIO and type(AIO.AddHandlers) == "function" then
    local H = AIO.AddHandlers("BAND_MAP", {})
    function H.GetCurrentScene(player)
        if not player then return end
        AIO.Handle(player, "BAND_MAP", "SetTarget", SCENE[1], SCENE[2], SCENE[3])
    end
    print("[EchoOfTheVoid] 37_BandMap.lua загружен (серверная часть минимап-маркера).")
else
    print("[EchoOfTheVoid] 37_BandMap.lua: AIO недоступен — маркер неактивен.")
end