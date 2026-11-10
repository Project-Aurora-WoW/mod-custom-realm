-- ============================================================
-- Store_Server.lua — серверная логика магазина «Эхо Пустоты»
-- Референс: eluna-aio-storesystem (AIO Store System).
--
-- Отличия от оригинала:
--   1. Локализация ru/en сообщений по DBC-локали клиента (8 = ruRU).
--   2. Фикс бага OnClick: в оригинале превью вещей проверяло
--      service.Flags == 1 (глобальный сервис, а не выбранный) —
--      на клиенте заменено на self.Flags.
--   3. Журнал покупок: realm_store_logs (acore_world), с индексом.
--   4. Вузы валют: золото (GOLD) + Жетон Эха (ITEM_TOKEN 70005)
--      настроены в realm_store_currencies; SERVER_HANDLED — заглушка.
-- ============================================================

local AIO = AIO
if not AIO then
    print("[EchoOfTheVoid] Store_Server: AIO не найден — магазин отключён.")
    return
end

local CONFIG = {
	maxLevel = 80, -- Максимальный уровень реалма
	mailSenderGUID = 1, -- GUID персонажа-отправителя писем о покупках
	strings = {
		ru = {
			insufficientFunds = "Недостаточно",
			alreadyKnown = "У вас уже есть это",
			tooHighLevel = "Ваш уровень слишком высок",
			mailSubject = "Покупка:",
			mailBody = "Благодарим за покупку! Орден Рассвета признателен вам.",
			successfulPurchase = "успешно приобретено!",
			mount = "маунт",
			pet = "питомец",
			title = "титул",
		},
		en = {
			insufficientFunds = "You don't have enough",
			alreadyKnown = "You already have this",
			tooHighLevel = "Your level is too high",
			mailSubject = "Purchase of:",
			mailBody = "Thank you for your purchase! The Dawn Order appreciates you.",
			successfulPurchase = "successfully purchased!",
			mount = "mount",
			pet = "pet",
			title = "title",
		},
	}
}

local function S(player, key)
	local loc = player:GetSession():GetSessionDbcLocale()
	return (loc == 8) and CONFIG.strings.ru[key] or CONFIG.strings.en[key]
end

--------------------

local AIO = AIO or require("AIO") and require("Store_DataStruct")

local CURRENCY_TYPES = {
	[1] = "GOLD",
	[2] = "ITEM_TOKEN",
	[3] = "SERVER_HANDLED"
}

local SHOP_UI = {
	serviceHandlers = {
		[1] = "ItemHandler", 		-- предметы (письмом)
		[2] = "GoldHandler", 		-- золото
		[3] = "MountHandler",		-- маунты
		[4] = "PetHandler",  		-- питомцы
		[5] = "BuffHandler", 		-- баффы
		[6] = "UnusedHandler",		-- НЕ ИСПОЛЬЗУЕТСЯ
		[7] = "ServiceHandler", 	-- услуги (AtLogin-флаги: смена имени/расы/фракции)
		[8] = "LevelHandler", 		-- уровни
		[9] = "TitleHandler",		-- титулы
	}
}

local KEYS = GetDataStructKeys();

local StoreHandler = AIO.AddHandlers("STORE_SERVER", {})

function StoreHandler.FrameData(player)
	AIO.Handle(player, "STORE_CLIENT", "FrameData", GetServiceData(), GetLinkData(), GetNavData(), GetCurrencyData(), player:GetGMRank())
end

function StoreHandler.UpdateCurrencies(player)
	local tmp = {}
	for currencyId, currency in pairs(GetCurrencyData()) do
		local val = 0
		local currencyTypeText = CURRENCY_TYPES[currency[KEYS.currency.currencyType]]

		-- Обработка типов валют
		if(currencyTypeText == "GOLD") then
			val = math.floor(player:GetCoinage() / 10000)
		end

		if(currencyTypeText == "ITEM_TOKEN") then
			val = player:GetItemCount(currency[KEYS.currency.data])
		end

		if(currencyTypeText == "SERVER_HANDLED") then
			-- Кастомные валюты (донат/голосование) — добавить сюда
		end

		-- Ограничение отображения для фрейма
		if(val > 9999) then
			val = "9999+"
		end

		table.insert(tmp, val)
	end
	AIO.Handle(player, "STORE_CLIENT", "UpdateCurrencies", tmp)
end

function StoreHandler.Purchase(player, serviceId)
	local services = GetServiceData()

	-- Проверка существования услуги
	if(services[serviceId])then
		-- id в под-таблицу сервиса, чтобы не таскать доп. переменную
		services[serviceId].ID = serviceId
		local typeId = services[serviceId][KEYS.service.serviceType]

		local serviceHandler = SHOP_UI[SHOP_UI.serviceHandlers[typeId]]
		if(serviceHandler) then
			local success = serviceHandler(player, services[serviceId])
			if(success) then
				-- Обновить валюты в UI и записать в журнал
				StoreHandler.UpdateCurrencies(player)
				SHOP_UI.LogPurchase(player, services[serviceId])

				-- Звук успеха
				player:PlayDirectSound(120, player)

				-- Тост об успехе
				player:SendAreaTriggerMessage(services[serviceId][KEYS.service.name] .. " " .. S(player, "successfulPurchase"))
			end
		end
	end
end

-- Вспомогательные функции
function SHOP_UI.DeductCurrency(player, currencyId, amount)
	local currency = GetCurrencyData()
	local currencyType = currency[currencyId][KEYS.currency.currencyType]
	local currencyName = currency[currencyId][KEYS.currency.name]
	local currencyData = currency[currencyId][KEYS.currency.data]

	-- Золото
	if(CURRENCY_TYPES[currencyType] == "GOLD") then
		if(player:GetCoinage() < amount * 10000) then
			player:SendAreaTriggerMessage("|cFFFF0000" .. S(player, "insufficientFunds") .. " " .. currencyName .. "|r")
			player:PlayDirectSound(GetSoundEffect("notEnoughMoney", player:GetRace(), player:GetGender()), player)
			return false
		end

		player:SetCoinage(player:GetCoinage() - (amount * 10000))
	end

	-- Предмет-токен
	if(CURRENCY_TYPES[currencyType] == "ITEM_TOKEN") then
		if not(player:HasItem(currencyData, amount)) then
			player:SendAreaTriggerMessage("|cFFFF0000" .. S(player, "insufficientFunds") .. " " .. currencyName .. "|r")
			player:PlayDirectSound(GetSoundEffect("notEnoughMoney", player:GetRace(), player:GetGender()), player)
			return false
		end

		player:RemoveItem(currencyData, amount)
	end

	-- Прочие валюты — своя интеграция
	if(CURRENCY_TYPES[currencyType] == "SERVER_HANDLED") then
		return false
	end

	return true
end

function SHOP_UI.LogPurchase(player, data)
	local currency, amount = data[KEYS.service.currency], data[KEYS.service.price] - data[KEYS.service.discount]
	WorldDBExecute("INSERT INTO realm_store_logs(account, guid, serviceId, currencyId, cost) VALUES("..player:GetAccountId()..", "..player:GetGUIDLow()..", "..data.ID..", "..currency..", "..amount..");")
end

-- ПРЕДМЕТЫ
function SHOP_UI.ItemHandler(player, data)
	local currency, amount = data[KEYS.service.currency], data[KEYS.service.price] - data[KEYS.service.discount]

	local deducted = SHOP_UI.DeductCurrency(player, currency, amount)
	if not(deducted) then
		return false
	end

	-- Собираем все награды
	local items = {}
	for i = 0, 7 do
		if(data[KEYS.service.reward_1+i] > 0 and data[KEYS.service.rewardCount_1+i] > 0) then
			table.insert(items, data[KEYS.service.reward_1+i])
			table.insert(items, data[KEYS.service.rewardCount_1+i])
		end
	end

	-- Письмо с наградой
	SendMail(S(player, "mailSubject") .. " " .. data[KEYS.service.name], S(player, "mailBody"), player:GetGUIDLow(), CONFIG.mailSenderGUID, 62, 0, 0, 0, unpack(items))
	return true
end

-- ЗОЛОТО
function SHOP_UI.GoldHandler(player, data)
	local currency, amount = data[KEYS.service.currency], data[KEYS.service.price] - data[KEYS.service.discount]

	local deducted = SHOP_UI.DeductCurrency(player, currency, amount)
	if not(deducted) then
		return false
	end

	player:ModifyMoney(data[KEYS.service.reward_1]*10000)
	return true
end

-- МАУНТЫ
function SHOP_UI.MountHandler(player, data)
	local currency, amount = data[KEYS.service.currency], data[KEYS.service.price] - data[KEYS.service.discount]

	local knownCount, rewardCount = 0, 0
	for i = 0, 7 do
		if(data[KEYS.service.reward_1+i] > 0) then
			if(player:HasSpell(data[KEYS.service.reward_1+i])) then
				knownCount = knownCount + 1
			end
			rewardCount = rewardCount + 1
		end
	end

	-- Уже выучены?
	if(knownCount == rewardCount) then
		player:SendAreaTriggerMessage("|cFFFF0000" .. S(player, "alreadyKnown") .. " " .. S(player, "mount") .. "|r")
		player:PlayDirectSound(GetSoundEffect("cantLearn", player:GetRace(), player:GetGender()), player)
		return false
	end

	local deducted = SHOP_UI.DeductCurrency(player, currency, amount)
	if not(deducted) then
		return false
	end

	for i = 0, 7 do
		if(data[KEYS.service.reward_1+i] > 0) then
			player:LearnSpell(data[KEYS.service.reward_1+i])
		end
	end
	return true
end

-- ПИТОМЦЫ
function SHOP_UI.PetHandler(player, data)
	local currency, amount = data[KEYS.service.currency], data[KEYS.service.price] - data[KEYS.service.discount]

	local knownCount, rewardCount = 0, 0
	for i = 0, 7 do
		if(data[KEYS.service.reward_1+i] > 0) then
			if(player:HasSpell(data[KEYS.service.reward_1+i])) then
				knownCount = knownCount + 1
			end
			rewardCount = rewardCount + 1
		end
	end

	if(knownCount == rewardCount) then
		player:SendAreaTriggerMessage("|cFFFF0000" .. S(player, "alreadyKnown") .. " " .. S(player, "pet") .. "|r")
		player:PlayDirectSound(GetSoundEffect("cantLearn", player:GetRace(), player:GetGender()), player)
		return false
	end

	local deducted = SHOP_UI.DeductCurrency(player, currency, amount)
	if not(deducted) then
		return false
	end

	for i = 0, 7 do
		if(data[KEYS.service.reward_1+i] > 0) then
			player:LearnSpell(data[KEYS.service.reward_1+i])
		end
	end
	return true
end

-- БАФФЫ
function SHOP_UI.BuffHandler(player, data)
	local currency, amount = data[KEYS.service.currency], data[KEYS.service.price] - data[KEYS.service.discount]

	local deducted = SHOP_UI.DeductCurrency(player, currency, amount)
	if not(deducted) then
		return false
	end

	for i = 0, 7 do
		if(data[KEYS.service.reward_1+i] > 0) then
			player:CastSpell(player, data[KEYS.service.reward_1+i], true)
		end
	end
	return true
end

-- УСЛУГИ (AtLogin-флаги)
function SHOP_UI.ServiceHandler(player, data)
	local currency, amount = data[KEYS.service.currency], data[KEYS.service.price] - data[KEYS.service.discount]

	local deducted = SHOP_UI.DeductCurrency(player, currency, amount)
	if not(deducted) then
		return false
	end

	player:SetAtLoginFlag(data[KEYS.service.reward_1])

	return true
end

-- УРОВНИ
function SHOP_UI.LevelHandler(player, data)
	local currency, amount = data[KEYS.service.currency], data[KEYS.service.price] - data[KEYS.service.discount]
	-- flags = 1: выставить уровень вместо добавления; проверка ДО списания
	if(data[KEYS.service.flags] == 1) then
		if(player:GetLevel() >= data[KEYS.service.reward_1]) then
			player:SendAreaTriggerMessage("|cFFFF0000" .. S(player, "tooHighLevel") .. "|r")
			player:PlayDirectSound(GetSoundEffect("cantUse", player:GetRace(), player:GetGender()), player)
			return false
		end
	end

	local deducted = SHOP_UI.DeductCurrency(player, currency, amount)
	if not(deducted) then
		return false
	end

	local level = player:GetLevel() + data[KEYS.service.reward_1]

	if(level > CONFIG.maxLevel) then
		level = CONFIG.maxLevel
	end

	if(data[KEYS.service.flags] == 1) then
		level = data[KEYS.service.reward_1]
	end

	player:SetLevel(level)
	return true
end

-- ТИТУЛЫ
function SHOP_UI.TitleHandler(player, data)
	local currency, amount = data[KEYS.service.currency], data[KEYS.service.price] - data[KEYS.service.discount]

	if(player:HasTitle(data[KEYS.service.reward_1])) then
		player:SendAreaTriggerMessage("|cFFFF0000" .. S(player, "alreadyKnown") .. " " .. S(player, "title") .. "|r")
		player:PlayDirectSound(GetSoundEffect("cantLearn", player:GetRace(), player:GetGender()), player)
		return false
	end

	local deducted = SHOP_UI.DeductCurrency(player, currency, amount)
	if not(deducted) then
		return false
	end

	player:SetKnownTitle(data[KEYS.service.reward_1])
	return true
end

-- НЕ ИСПОЛЬЗУЕТСЯ
function SHOP_UI.UnusedHandler(player, data)
	return false
end

print("[EchoOfTheVoid] Store_Server.lua загружен (AIO-магазин, валюты: золото + Жетон Эха).")
