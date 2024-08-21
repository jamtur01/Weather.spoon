local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Weather"
obj.version = "1.0"
obj.author = "James Turnbull <james@lovedthanlost.net>"
obj.license = "MIT"
obj.homepage = "https://github.com/jamtur01/Weather.spoon"

-- Default settings
obj.apiKey = hs.settings.get("WeatherSpoon_apiKey") or "API_KEY"
obj.cityName = hs.settings.get("WeatherSpoon_cityName") or "Brooklyn"  -- Default city
obj.updateInterval = hs.settings.get("WeatherSpoon_updateInterval") or 3600  -- Default: every hour
obj.latitude = nil  -- Will be dynamically set
obj.longitude = nil -- Will be dynamically set

obj.logger = hs.logger.new('Weatherspoon', 'info')

obj.weaEmoji = {
    Thunderstorm = '⛈',
    Drizzle = '🌦',
    Rain = '🌧',
    Snow = '❄️',
    Mist = '🌫',
    Smoke = '🌫',
    Haze = '🌫',
    Dust = '🌫',
    Fog = '🌫',
    Sand = '🌫',
    Ash = '🌫',
    Squall = '🌪',
    Tornado = '🌪',
    Clear = '☀️',
    Clouds = '☁️',
    default = ''
}

-- Logging helpers
function obj:logDebug(message)
    self.logger.d(message)
end

function obj:logInfo(message)
    self.logger.i(message)
end

function obj:logError(message)
    self.logger.e(message)
end

-- Initialize the Spoon
function obj:init()
    self.menubar = hs.menubar.new()
    self.menubar:setTitle('⌛')
    self.menuData = {}
    self:getCoordinates(self.cityName)
end

-- Update the menubar icon and menu
function obj:updateMenubar()
    self.menubar:setTooltip("Weather Info")
    self.menubar:setMenu(self.menuData)
end

-- Get coordinates from the city name
function obj:getCoordinates(cityName)
    local geoApi = string.format("http://api.openweathermap.org/geo/1.0/direct?q=%s&limit=1&appid=%s",
        hs.http.encodeForQuery(cityName), self.apiKey)
    
    hs.http.doAsyncRequest(geoApi, "GET", nil, nil, function(code, body, _)
        if code ~= 200 then
            self:logInfo('WeatherSpoon geocode error: ' .. code)
            return
        end

        local locationData = hs.json.decode(body)
        if #locationData == 0 then
            self:logInfo('WeatherSpoon: No location data found for ' .. cityName)
            return
        end

        -- Extract latitude and longitude from the geocode response
        self.latitude = locationData[1].lat
        self.longitude = locationData[1].lon

        -- Once the coordinates are set, start the weather retrieval process
        self:start()
    end)
end

-- Fetch and display the weather
function obj:getWeather()
    if not self.latitude or not self.longitude then
        self:logInfo('WeatherSpoon: Coordinates not set.')
        return
    end

    local urlApi = string.format("https://api.openweathermap.org/data/3.0/onecall?lat=%s&lon=%s&exclude=minutely,hourly,alerts&appid=%s&units=metric", 
        self.latitude, self.longitude, self.apiKey)

    hs.http.doAsyncRequest(urlApi, "GET", nil, nil, function(code, body, _)
        if code ~= 200 then
            self:logInfo('WeatherSpoon error: ' .. code)
            return
        end

        local rawjson = hs.json.decode(body)
        local current = rawjson.current
        local weather = current.weather[1].main
        local temp = current.temp
        local humidity = current.humidity
        local rain_chance = rawjson.daily[1].pop * 100  -- Probability of precipitation as a percentage

        -- Update the menubar title with the emoji and temperature
        self.menubar:setTitle(string.format("%s %.1f°C", self.weaEmoji[weather] or self.weaEmoji.default, temp))

        self.menuData = {}
        -- Titles in the popup menu without the emoji and wind speed, but with rain chance
        local titlestr = string.format("%s 🌡️%.1f°C 💧%s%% 🌧️%s%%", self.cityName, temp, humidity, rain_chance)
        local item = { title = titlestr }
        table.insert(self.menuData, item)
        table.insert(self.menuData, {title = '-'})

        self:updateMenubar()
    end)
end

-- Start the Spoon's update loop
function obj:start()
    self:getWeather()
    self.timer = hs.timer.doEvery(self.updateInterval, function() self:getWeather() end)
end

-- Stop the Spoon's update loop
function obj:stop()
    if self.timer then self.timer:stop() end
end

-- Configure the Spoon
function obj:configure(apiKey, cityName, updateInterval)
    self.apiKey = apiKey or self.apiKey
    self.cityName = cityName or self.cityName
    self.updateInterval = updateInterval or self.updateInterval

    hs.settings.set("WeatherSpoon_apiKey", self.apiKey)
    hs.settings.set("WeatherSpoon_cityName", self.cityName)
    hs.settings.set("WeatherSpoon_updateInterval", self.updateInterval)

    self:stop()
    self:getCoordinates(self.cityName)  -- Re-fetch the coordinates and start again
end

return obj
