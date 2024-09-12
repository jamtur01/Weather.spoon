# WeatherSpoon

**WeatherSpoon** is a Hammerspoon Spoon that displays the current weather in the menu bar, updating periodically. You can click on the weather to see more details, such as the temperature, humidity, and wind speed.

## Installation

1. Download the Spoon and place it in your `~/.hammerspoon/Spoons/` directory.
2. Add the following to your Hammerspoon configuration:

```lua
  -- Replace with location, and update interval (in seconds)
spoon.Weather:init()hs.loadSpoon("Weather")
spoon.Weather:configure("Brooklyn+USA", 3600)
spoon.Weather:start()
```

## Configuration

- [Location](https://wttr.in/): Replace "Brooklyn+USA" with the name of your city.
- Update Interval: Set how frequently the weather updates (in seconds).

## License

This Spoon is licensed under the MIT License. See LICENSE for more information.

## Acknowledgements

This Spoon uses the [WTTR API](https://wttr.in/) to fetch weather data. It owes some of its heritage to [this Spoon](https://github.com/wangshub/hammerspoon-config/blob/master/weather/weather.lua)
