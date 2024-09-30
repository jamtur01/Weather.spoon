-- Weather.spoon
-- A Hammerspoon Spoon to display current weather information based on macOS location.

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

-- Weather Emojis
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

-- Temperature Emojis
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

local function logMessage(level, message)
    if obj.logger and obj.logger[level] then
        obj.logger[level](message)
    else
        print(string.format("[%s] %s", level, message))
    end
end

function obj:init()
    self.menubar = hs.menubar.new()
    if self.menubar then
        self.menubar:setTitle('⌛ Loading...')
        self.menubar:setTooltip('Weather Info - Waiting for location...')
    end
    self.menuData = {}
    
    self.locationTag = "WeatherLocationCallback"
    hs.location.register(self.locationTag, function(location)
        if location and location.horizontalAccuracy >= 0 then
            self.currentLocation = location
            self:getWeather()
        else
            logMessage('error', 'Received invalid location data')
        end
    end)
    
    hs.location.start()
    
    self.locationRetryCount = 0
    self.locationMaxRetries = 5
    self.locationTimeout = hs.timer.doEvery(10, function()
        self.locationRetryCount = self.locationRetryCount + 1
        if not self.currentLocation then
            if self.locationRetryCount < self.locationMaxRetries then
                logMessage('info', 'Retrying to fetch location...')
            else
                logMessage('error', 'Max retries reached, using cityName instead')
                self:getWeather()
                self.locationTimeout:stop()
            end
        else
            self.locationTimeout:stop()
        end
    end)
    
    self:start()
end

function obj:updateMenubar()
    if self.menubar then
        self.menubar:setMenu(self.menuData)
    end
end

function obj:getWeather()
    local urlApi
    local isUsingLocation = false
    local latitude, longitude
    
    if self.currentLocation then
        latitude = string.format("%.2f", self.currentLocation.latitude)
        longitude = string.format("%.2f", self.currentLocation.longitude)
        urlApi = string.format("https://wttr.in/%s,%s?format=j1", latitude, longitude)
        isUsingLocation = true
    else
        logMessage('error', 'Current location not available, using cityName instead')
        self.cityName = self.cityName or "Brooklyn USA"
        urlApi = string.format("https://wttr.in/%s?format=j1", hs.http.encodeForQuery(self.cityName))
    end

    if self.menubar then
        self.menubar:setTitle('⌛ Fetching...')
    end

    hs.http.asyncGet(urlApi, nil, function(code, body, _)
        if code ~= 200 then
            logMessage('error', string.format('Weather API error: %d', code))
            if self.menubar then
                self.menubar:setTitle('⚠️ Error')
                self.menubar:setTooltip('Weather API error')
            end
            return
        end

        local data = hs.json.decode(body)
        if not data or not data.current_condition or #data.current_condition == 0 then
            logMessage('error', 'Weather: Invalid data received')
            if self.menubar then
                self.menubar:setTitle('⚠️ Invalid Data')
                self.menubar:setTooltip('Received invalid weather data')
            end
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

        local areaName = data.nearest_area and
                         data.nearest_area[1] and
                         data.nearest_area[1].areaName and
                         data.nearest_area[1].areaName[1] and
                         data.nearest_area[1].areaName[1].value or
                         self.cityName

        if self.menubar then
            self.menubar:setTitle(string.format("%s %.1f°C", weatherEmoji, temp))
            self.menubar:setTooltip(string.format("%s %s %.1f°C", weather, tempEmoji, temp))
        end

        local menuItems = {
            {
                title = string.format("%s %s %.1f°C (Feels like %.1f°C) 💦 %d%% ☔ %d%%",
                                      areaName, tempEmoji, temp, feelsLike, humidity, chanceofRain),
                fn = function()
                    if isUsingLocation then
                        hs.urlevent.openURL(string.format("https://wttr.in/%s,%s", latitude, longitude))
                    else
                        hs.urlevent.openURL(string.format("https://wttr.in/%s", hs.http.encodeForQuery(self.cityName)))
                    end
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
                local desc = forecast.hourly and
                             forecast.hourly[4] and
                             forecast.hourly[4].weatherDesc and
                             forecast.hourly[4].weatherDesc[1] and
                             forecast.hourly[4].weatherDesc[1].value or "N/A"

                table.insert(menuItems, {
                    title = string.format("%s: %s (%s %.1f°C - %s %.1f°C)",
                                          date, desc, minEmoji, minTemp, maxEmoji, maxTemp)
                })
            end
        end

        self.menuData = menuItems
        self:updateMenubar()
    end)
end

function obj:start()
    if self.timer then
        self.timer:stop()
    end
    self.timer = hs.timer.doEvery(self.updateInterval, function()
        self:getWeather()
    end)
end

function obj:stop()
    if self.timer then
        self.timer:stop()
        self.timer = nil
    end
end

function obj:configure(cityName, updateInterval)
    self.cityName = cityName or self.cityName
    self.updateInterval = updateInterval or self.updateInterval

    for k, v in pairs({cityName = self.cityName, updateInterval = self.updateInterval}) do
        hs.settings.set("Weather_" .. k, v)
    end

    self:stop()
    self:start()
    self:getWeather()
end

function obj:deinit()
    hs.location.unregister(self.locationTag)
    self:stop()
    if self.menubar then
        self.menubar:delete()
        self.menubar = nil
    end
    if self.locationTimeout then
        self.locationTimeout:stop()
        self.locationTimeout = nil
    end
end

return obj
 