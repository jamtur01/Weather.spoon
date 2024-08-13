# WeatherSpoon

**WeatherSpoon** is a Hammerspoon Spoon that displays the current weather in the menubar, updating periodically.

## Installation

1. Download the Spoon and place it in your `~/.hammerspoon/Spoons/` directory.
2. Add the following to your Hammerspoon configuration:

```lua
hs.loadSpoon("Weather")
spoon.Weather:configure("YOUR_API_KEY", "40.7128", "-74.0060", 3600)  -- Replace with your API key, latitude, longitude, and update interval (in seconds)
spoon.Weather:init()
```

## Configuration

- API Key: Replace "YOUR_API_KEY" with your OpenWeatherMap API key.
- Latitude & Longitude: Set the desired location coordinates.
- Update Interval: Set how frequently the weather updates (in seconds).

## License

This Spoon is licensed under the MIT License. See LICENSE for more information.

## How to Use the Spoon

1. **Place the Spoon**: Move the `Weather.spoon` folder (containing `init.lua` and `README.md`) into your `~/.hammerspoon/Spoons/` directory.

2. **Configure the Spoon in Your `init.lua`**: Add the following code to your `~/.hammerspoon/init.lua`:

   ```lua
   hs.loadSpoon("Weather")
   spoon.Weather:configure("YOUR_API_KEY", "40.7128", "-74.0060", 3600)
   spoon.Weather:init()
   ```

## Acknowledgements

This Spoon uses the [OpenWeatherMap API](https://openweathermap.org/api) to fetch weather data. It owes some of it's heritage to [this Spoon](https://github.com/wangshub/hammerspoon-config/blob/master/weather/weather.lua)
