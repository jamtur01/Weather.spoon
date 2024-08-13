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
obj.latitude = hs.settings.get("WeatherSpoon_latitude") or "40.7128"  -- Default: Brooklyn, NY
obj.longitude = hs.settings.get("WeatherSpoon_longitude") or "-74.0060" -- Default: Brooklyn, NY
obj.updateInterval = hs.settings.get("WeatherSpoon_updateInterval") or 3600  -- Default: every hour

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

-- Initialize the Spoon
function obj:init()
    self.menubar = hs.menubar.new()
    self.menubar:setTitle('⌛')
    self.menuData = {}
    self:updateMenubar()
    self:start()
end

-- Update the menubar icon and menu
function obj:updateMenubar()
    self.menubar:setTooltip("Weather Info")
    self.menubar:setMenu(self.menuData)
end

-- Fetch and display the weather
function obj:getWeather()
    local urlApi = string.format("https://api.openweathermap.org/data/3.0/onecall?lat=%s&lon=%s&exclude=minutely,hourly,alerts&appid=%s&units=metric", 
        self.latitude, self.longitude, self.apiKey)
    
    hs.http.doAsyncRequest(urlApi, "GET", nil, nil, function(code, body, _)
        if code ~= 200 then
            print('WeatherSpoon error: ' .. code)
            return
        end
        local rawjson = hs.json.decode(body)
        local current = rawjson.current
        local weather = current.weather[1].main
        local temp = current.temp
        local humidity = current.humidity
        local city = "Brooklyn"  -- Change this to your desired city name
        local rain_chance = rawjson.daily[1].pop * 100  -- Probability of precipitation as a percentage

        -- Update the menubar title with the emoji and temperature
        self.menubar:setTitle(string.format("%s %.1f°C", self.weaEmoji[weather] or self.weaEmoji.default, temp))

        self.menuData = {}
        -- Titles in the popup menu without the emoji and wind speed, but with rain chance
        local titlestr = string.format("%s 🌡️%.1f°C 💧%s%% 🌧️%s%%", city, temp, humidity, rain_chance)
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
function obj:configure(apiKey, latitude, longitude, updateInterval)
    self.apiKey = apiKey or self.apiKey
    self.latitude = latitude or self.latitude
    self.longitude = longitude or self.longitude
    self.updateInterval = updateInterval or self.updateInterval

    hs.settings.set("WeatherSpoon_apiKey", self.apiKey)
    hs.settings.set("WeatherSpoon_latitude", self.latitude)
    hs.settings.set("WeatherSpoon_longitude", self.longitude)
    hs.settings.set("WeatherSpoon_updateInterval", self.updateInterval)

    self:stop()
    self:start()
end

return obj
