-- Ustawienie URL webhooka Discord
local webhookURL = "https://discord.com/api/webhooks/1250913211226521691/AawTOR9TzzE8XZzPsDjKVuYff8EjQAF5eaa6sMXVUCg6ybjZc-mVtTjNLhC9OIJ7ynB5"

-- Funkcja wysyłająca wiadomość do webhooka
function sendToDiscord(message, topPlayer)
    local embedColor = 3447003 -- Domyślny kolor embed (opcjonalnie można zmienić)
    
    local currentDate = os.date('%Y-%m-%d %H:%M:%S') -- Aktualna data i godzina
    local connect = {
        {
            ["color"] = embedColor,
            ["title"] = "Ranking Graczy",
            ["description"] = message,
            ["footer"] = {
                ["text"] = "Data i godzina: " .. currentDate,
            },
        }
    }

    PerformHttpRequest(webhookURL, function(err, text, headers)
        if err ~= 200 then
            print("Error sending message to Discord:", err)
            print("Response:", text)
        end
    end, 'POST', json.encode({username = "Server Bot", embeds = connect}), { ['Content-Type'] = 'application/json' })
end

-- Funkcja pobierająca dane z bazy danych
function getTopPlayers()
    MySQL.query([[
        SELECT firstname, lastname, identifier,
               JSON_UNQUOTE(JSON_EXTRACT(accounts, "$.money")) AS money,
               JSON_UNQUOTE(JSON_EXTRACT(accounts, "$.bank")) AS bank,
               JSON_UNQUOTE(JSON_EXTRACT(accounts, "$.black_money")) AS black_money
        FROM users 
        ORDER BY CAST(JSON_UNQUOTE(JSON_EXTRACT(accounts, "$.money")) AS UNSIGNED) DESC, 
                 CAST(JSON_UNQUOTE(JSON_EXTRACT(accounts, "$.bank")) AS UNSIGNED) DESC, 
                 CAST(JSON_UNQUOTE(JSON_EXTRACT(accounts, "$.black_money")) AS UNSIGNED) DESC 
        LIMIT 50;
    ]], {}, function(players)
        if #players > 0 then
            local topPlayer = players[1]
            local message = "Najbogatszy gracz: " .. (topPlayer.firstname .. " " .. topPlayer.lastname or "Unknown") .. " z identyfikatorem: " .. topPlayer.identifier .. " z ilością pieniędzy: " .. topPlayer.money .. "\n\nTop 50 graczy:\n"

            for i=1, #players, 1 do
                local player = players[i]
                local playerName = player.firstname .. " " .. player.lastname or "Unknown"

                message = message .. i .. ". " .. playerName .. " (ID: " .. player.identifier .. ") - " .. player.money .. " $ (Bank: " .. player.bank .. ", Black Money: " .. player.black_money .. ")\n"
            end

            sendToDiscord(message, topPlayer)
        else
            sendToDiscord("Brak graczy w bazie danych.")
        end
    end)
end

-- Uruchomienie funkcji natychmiast po starcie serwera i co minutę
Citizen.CreateThread(function()
    while true do
        getTopPlayers()
        Citizen.Wait(3600000) -- 3600000 ms = 1 godzina
    end
end)
