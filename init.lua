local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Weather"
obj.version = "1.2.13"
obj.author = "James Turnbull <james@lovedthanlost.net>"
obj.license = "MIT"
obj.homepage = "https://github.com/jamtur01/Weather.spoon"

-- Default settings
obj.cityName = hs.settings.get("Weather_cityName") or "Brooklyn+USA"
obj.updateInterval = hs.settings.get("Weather_updateInterval") or 3600
obj.logger = hs.logger.new('Weather', 'info')

obj.weatherEmojis = {
    Thunderstorm = '⛈', Drizzle = '🌦', Rain = '🌧', Snow = '❄️',
    Mist = '🌫', Smoke = '🌫', Haze = '🌫', Dust = '🌫',
    Fog = '🌫', Sand = '🌫', Ash = '🌫', Squall = '🌪',
    Tornado = '🌪', Clear = '☀️', Clouds = '☁️', default = '🌡️'
}

-- Helper function: use obj.logger directly
local function logMessage(level, message)
    if obj.logger and obj.logger[level] then
        obj.logger[level](message)
    else
        print(string.format("[%s] %s", level, message))
    end
end

-- Initialize the Spoon
function obj:init()
    self.menubar = hs.menubar.new()
    self.menubar:setTitle('⌛')
    self.menuData = {}
    self:start()
end

-- Update the menubar
function obj:updateMenubar()
    self.menubar:setTooltip("Weather Info")
    self.menubar:setMenu(self.menuData)
end

-- Fetch and display the weather
function obj:getWeather()
    local urlApi = string.format("https://wttr.in/%s?format=j1", hs.http.encodeForQuery(self.cityName))

    hs.http.asyncGet(urlApi, nil, function(code, body, _)
        if code ~= 200 then
            logMessage('error', string.format('Weather API error: %d', code))
            return
        end

        local data = hs.json.decode(body)
        if not data or not data.current_condition or #data.current_condition == 0 then
            logMessage('error', 'Weather: Invalid data received')
            return
        end

        local current = data.current_condition[1]
        local weather = current.weatherDesc and current.weatherDesc[1] and current.weatherDesc[1].value or "Unknown"
        local temp = tonumber(current.temp_C) or 0
        local humidity = tonumber(current.humidity) or 0
        local feelsLike = tonumber(current.FeelsLikeC) or 0

        local weatherEmoji = self.weatherEmojis[weather] or self.weatherEmojis.default
        self.menubar:setTitle(string.format("%s %.1f°C", weatherEmoji, temp))

        local menuItems = {
            {
                title = string.format("%s 🌡️%.1f°C (Feels like %.1f°C) 💧%d%%", self.cityName, temp, feelsLike, humidity),
                fn = function()
                    hs.urlevent.openURL(string.format("https://wttr.in/%s", hs.http.encodeForQuery(self.cityName)))
                end,
                tooltip = "Click to open detailed weather info"
            },
            {title = '-'},
            {title = "Weather: " .. weather},
            {title = "Wind: " .. (current.windspeedKmph or "N/A") .. " km/h " .. (current.winddir16Point or "N/A")},
            {title = "Pressure: " .. (current.pressure or "N/A") .. " hPa"},
            {title = "Visibility: " .. (current.visibility or "N/A") .. " km"},
        }

        if data.weather then
            for i = 1, math.min(3, #data.weather) do
                local forecast = data.weather[i]
                local date = forecast.date
                local maxTemp = forecast.maxtempC
                local minTemp = forecast.mintempC
                local desc = forecast.hourly and forecast.hourly[4] and forecast.hourly[4].weatherDesc
                             and forecast.hourly[4].weatherDesc[1] and forecast.hourly[4].weatherDesc[1].value
                             or "N/A"

                table.insert(menuItems, {title = string.format("%s: %s (%.1f°C - %.1f°C)", date, desc, tonumber(minTemp) or 0, tonumber(maxTemp) or 0)})
            end
        end

        self.menuData = menuItems
        self:updateMenubar()
    end)
end

-- Start the Spoon's update loop
function obj:start()
    self:getWeather()
    if self.timer then self.timer:stop() end
    self.timer = hs.timer.doEvery(self.updateInterval, function() self:getWeather() end)
end

-- Stop the Spoon's update loop
function obj:stop()
    if self.timer then self.timer:stop() end
end

-- Configure the Spoon
function obj:configure(cityName, updateInterval)
    self.cityName = cityName or self.cityName
    self.updateInterval = updateInterval or self.updateInterval

    for k, v in pairs({cityName = self.cityName, updateInterval = self.updateInterval}) do
        hs.settings.set("Weather_" .. k, v)
    end

    self:stop()
    self:start()
end

return obj