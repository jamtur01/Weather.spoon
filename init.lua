local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Weather"
obj.version = "1.2"
obj.author = "James Turnbull <james@lovedthanlost.net>"
obj.license = "MIT"
obj.homepage = "https://github.com/jamtur01/Weather.spoon"

-- Default settings
obj.apiKey = hs.settings.get("Weather_apiKey") or "API_KEY"
obj.cityName = hs.settings.get("Weather_cityName") or "Brooklyn"
obj.updateInterval = hs.settings.get("Weather_updateInterval") or 3600
obj.latitude = nil
obj.longitude = nil
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
    self:getCoordinates()
end

-- Update the menubar
function obj:updateMenubar()
    self.menubar:setTooltip("Weather Info")
    self.menubar:setMenu(self.menuData)
end

-- Get coordinates from the city name
function obj:getCoordinates()
    local geoApi = string.format("http://api.openweathermap.org/geo/1.0/direct?q=%s&limit=1&appid=%s",
        hs.http.encodeForQuery(self.cityName), self.apiKey)
    
    hs.http.asyncGet(geoApi, nil, function(code, body, _)
        if code ~= 200 then
            logMessage('error', string.format('Weather geocode error: %d', code))
            return
        end

        local locationData = hs.json.decode(body)
        if not locationData or #locationData == 0 then
            logMessage('warn', string.format('Weather: No location data found for %s', self.cityName))
            return
        end

        self.latitude, self.longitude = locationData[1].lat, locationData[1].lon

        self:start()
    end)
end

-- Fetch and display the weather
function obj:getWeather()
    if not self.latitude or not self.longitude then
        logMessage('warn', 'Weather: Coordinates not set.')
        return
    end

    local urlApi = string.format("https://api.openweathermap.org/data/3.0/onecall?lat=%s&lon=%s&exclude=minutely,hourly,alerts&appid=%s&units=metric", 
        self.latitude, self.longitude, self.apiKey)

    hs.http.asyncGet(urlApi, nil, function(code, body, _)
        if code ~= 200 then
            logMessage('error', string.format('Weather API error: %d', code))
            return
        end

        local data = hs.json.decode(body)
        if not data or not data.current then
            logMessage('error', 'Weather: Invalid data received')
            return
        end

        local current = data.current
        local weather = current.weather[1].main
        local temp = current.temp
        local humidity = current.humidity
        local rainChance = data.daily[1].pop * 100

        self.menubar:setTitle(string.format("%s %.1f°C", self.weatherEmojis[weather] or self.weatherEmojis.default, temp))

        local menuItems = {
            {
                title = string.format("%s 🌡️%.1f°C 💧%d%% 🌧️%d%%", self.cityName, temp, humidity, rainChance),
                fn = function()
                    if self.latitude and self.longitude then
                        hs.urlevent.openURL(string.format("https://openweathermap.org/?lat=%s&lon=%s", self.latitude, self.longitude))
                    else
                        hs.urlevent.openURL("https://openweathermap.org")
                    end
                end,
                tooltip = "Click to open detailed weather info"
            },
            {title = '-'}
        }

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
function obj:configure(apiKey, cityName, updateInterval)
    self.apiKey = apiKey or self.apiKey
    self.cityName = cityName or self.cityName
    self.updateInterval = updateInterval or self.updateInterval

    for k, v in pairs({apiKey = self.apiKey, cityName = self.cityName, updateInterval = self.updateInterval}) do
        hs.settings.set("Weather_" .. k, v)
    end

    self:stop()
    self:getCoordinates()
end

return obj
