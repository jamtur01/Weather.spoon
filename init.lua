local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Weather"
obj.version = "1.2.15"
obj.author = "James Turnbull <james@lovedthanlost.net>"
obj.license = "MIT"
obj.homepage = "https://github.com/jamtur01/Weather.spoon"

-- Default settings
obj.cityName = hs.settings.get("Weather_cityName") or "Brooklyn USA"
obj.updateInterval = hs.settings.get("Weather_updateInterval") or 3600
obj.logger = hs.logger.new('Weather', 'info')

obj.weatherEmojis = {
    Clear = '☀️',                                         -- Clear
    Sunny = '🌞',                                         -- Sunny
    ["Partly cloudy"] = '⛅',                             -- Partly cloudy
    Cloudy = '☁️',                                        -- Cloudy
    Overcast = '🌥️',                                     -- Overcast
    Mist = '🌫',                                          -- Mist
    ["Patchy rain possible"] = '🌦️',                     -- Patchy rain possible
    ["Patchy snow possible"] = '🌨️',                     -- Patchy snow possible
    ["Patchy sleet possible"] = '🌧️',                    -- Patchy sleet possible
    ["Patchy freezing drizzle possible"] = '🌧',          -- Patchy freezing drizzle possible
    ["Thundery outbreaks possible"] = '⛈️',              -- Thundery outbreaks possible
    ["Blowing snow"] = '🌬️❄️',                           -- Blowing snow
    Blizzard = '❄️🌪',                                    -- Blizzard
    Fog = '🌁',                                           -- Fog
    ["Freezing fog"] = '❄️🌫️',                           -- Freezing fog
    ["Patchy light drizzle"] = '🌦️',                     -- Patchy light drizzle
    ["Light drizzle"] = '🌧',                             -- Light drizzle
    ["Freezing drizzle"] = '❄️🌧',                        -- Freezing drizzle
    ["Heavy freezing drizzle"] = '🌧❄️',                  -- Heavy freezing drizzle
    ["Patchy light rain"] = '🌦️',                        -- Patchy light rain
    ["Light rain"] = '🌧',                                -- Light rain
    ["Moderate rain at times"] = '🌦️🌧',                  -- Moderate rain at times
    ["Moderate rain"] = '🌧',                             -- Moderate rain
    ["Heavy rain at times"] = '🌧🌩',                      -- Heavy rain at times
    ["Heavy rain"] = '🌧💧',                              -- Heavy rain
    ["Light freezing rain"] = '❄️🌧',                    -- Light freezing rain
    ["Moderate or heavy freezing rain"] = '❄️🌧💧',        -- Moderate or heavy freezing rain
    ["Light sleet"] = '🌧❄️',                             -- Light sleet
    ["Moderate or heavy sleet"] = '🌧❄️🌨',                -- Moderate or heavy sleet
    ["Patchy light snow"] = '🌨',                         -- Patchy light snow
    ["Light snow"] = '❄️',                               -- Light snow
    ["Patchy moderate snow"] = '🌨❄️',                    -- Patchy moderate snow
    ["Moderate snow"] = '❄️🌨',                           -- Moderate snow
    ["Patchy heavy snow"] = '🌨❄️💨',                     -- Patchy heavy snow
    ["Heavy snow"] = '❄️❄️',                             -- Heavy snow
    ["Ice pellets"] = '🧊',                               -- Ice pellets
    ["Light rain shower"] = '🌦️',                        -- Light rain shower
    ["Moderate or heavy rain shower"] = '🌧⛈️',           -- Moderate or heavy rain shower
    ["Torrential rain shower"] = '🌧🌊',                  -- Torrential rain shower
    ["Light sleet showers"] = '🌨️❄️',                    -- Light sleet showers
    ["Moderate or heavy sleet showers"] = '🌧❄️🌨',        -- Moderate or heavy sleet showers
    ["Light snow showers"] = '🌨❄️',                      -- Light snow showers
    ["Moderate or heavy snow showers"] = '❄️🌨💨',         -- Moderate or heavy snow showers
    ["Patchy light rain with thunder"] = '🌦️⛈',          -- Patchy light rain with thunder
    ["Moderate or heavy rain with thunder"] = '🌧⛈️',     -- Moderate or heavy rain with thunder
    ["Patchy light snow with thunder"] = '❄️⚡',          -- Patchy light snow with thunder
    ["Moderate or heavy snow with thunder"] = '❄️🌨⚡',    -- Moderate or heavy snow with thunder
    default = '🌡️'                                       -- Default
}

obj.tempEmojis = {
    {threshold = 35, emoji = '🔥'},    -- Very hot
    {threshold = 25, emoji = '🌞'},    -- Hot
    {threshold = 15, emoji = '🌤️'},   -- Warm
    {threshold = 5,  emoji = '☁️'},    -- Cool
    {threshold = 0,  emoji = '❄️'},    -- Cold
    {threshold = -10, emoji = '⛄'},   -- Very cold
    default = '🌡️'                    -- Default emoji
}

function obj:getTempEmoji(temp)
    for _, entry in ipairs(self.tempEmojis) do
        if temp >= entry.threshold then
            return entry.emoji
        end
    end
    return self.tempEmojis.default
end

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
    self.menubar:setTooltip('Weather Info')
    self.menuData = {}
    self:start()
end

-- Update the menubar
function obj:updateMenubar()
    self.menubar:setMenu(self.menuData)
end

-- Fetch and display the weather (with forecast included)
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
        local feelsLike = tonumber(current.FeelsLikeC) or 0
        local humidity = tonumber(current.humidity) or 0
        local chanceofRain = tonumber(current.chanceofrain) or 0
        local weatherEmoji = self.weatherEmojis[weather] or self.weatherEmojis.default
        local tempEmoji = self:getTempEmoji(temp)

        self.menubar:setTitle(string.format("%s %.1f°C",  weatherEmoji, temp))
        self.menubar:setTooltip(weather .. " " .. tempEmoji .. " " .. temp .. "°C")
        
        local menuItems = {
            {
                title = string.format("%s %s %.1f°C (Feels like %.1f°C) 💦 %d%% ☔ %d%%", self.cityName, tempEmoji, temp, feelsLike, humidity, chanceofRain),
                fn = function()
                    hs.urlevent.openURL(string.format("https://wttr.in/%s", hs.http.encodeForQuery(self.cityName)))
                end,
                tooltip = "Click to open detailed weather info"
            },
            {title = '-'},
            {title = "Current Weather: " .. weather},
            {title = "Wind: " .. (current.windspeedKmph or "N/A") .. " km/h " .. (current.winddir16Point or "N/A")},
            {title = "Pressure: " .. (current.pressure or "N/A") .. " hPa"},
            {title = "Visibility: " .. (current.visibility or "N/A") .. " km"},
            {title = '-'},
            {title = "Forecast:"}
        }

        if data.weather then
            for i = 1, math.min(3, #data.weather) do
                local forecast = data.weather[i]
                local date = forecast.date
                local maxTemp = tonumber(forecast.maxtempC) or 0
                local maxEmoji = self:getTempEmoji(maxTemp)
                local minTemp = tonumber(forecast.mintempC) or 0
                local minEmoji = self:getTempEmoji(minTemp)
                local desc = forecast.hourly and forecast.hourly[4] and forecast.hourly[4].weatherDesc
                             and forecast.hourly[4].weatherDesc[1] and forecast.hourly[4].weatherDesc[1].value
                             or "N/A"

                table.insert(menuItems, {title = string.format("%s: %s (%s %.1f°C - %s %.1f°C)", date, desc, minEmoji, minTemp, maxEmoji, maxTemp)})
            end
        end

        -- Update menu data
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