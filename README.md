# Material You macOS

This is an experimental project that generates Material 3 color scheme from the current wallpaper on macOS. The goal is to build apps that adapt their theme to whatever wallpaper that is set.

## How it works 💡

A polling mechanism is setup to take a screenshot of the main macOS window every second. The screenshot is cropped to remove the top controls, scaled down aggresively to use as little memory as possible and then sent over an EventChannel to the Flutter side if it is a visually distinct image. Visual distinction is determined by computing the variance between the last screenshot and current one. If the variance does not exceed the set threshold, no events are sent to the Flutter side to prevent unnecessary rebuilds and message hopping.

On the Flutter side, the image is used to create a ColorScheme using `ColorScheme.fromImageProvider`. Whenever a new image is received, a new color scheme is generated and the app rebuilt to reflect the new theme.

## Demo 📷

<img src="https://raw.githubusercontent.com/Crazelu/material-you-macos/main/screenshots/material-you-macos-demo.gif" alt="Material You macOS experiment demo">
