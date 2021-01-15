# Cross-platform desktop automation using image template matching and keyboard shortcuts

> In image template-based [desktop automation](https://robocorp.com/docs/development-guide/desktop), you provide the robot with screenshots of the parts of the interface that it needs to interact with, like a button or input field. The images are saved together with your automation code. The robot will compare the image to what is currently displayed on the screen and find its target.

## Cross-platform desktop automation library

Robocorp provides cross-platform desktop automation support with the [RPA.Desktop library](https://robocorp.com/docs/libraries/rpa-framework/rpa-desktop). It works on Windows, Linux, and macOS.

## Travel directions robot

This example robot demonstrates the use of image templates and keyboard shortcuts to find travel directions between two random locations on Earth.

The robot:

- Interacts with a web browser to select two random locations on Earth (from https://www.randomlists.com/random-location).
- Tries to find the directions using the Maps desktop app on macOS (Big Sur), using image templates and keyboard shortcuts.
- Falls back on the web version of Google Maps if Maps fails to find directions.

> **Note:** This robot requires **macOS Big Sur**. The layout and the behavior of the Maps app vary between macOS releases. macOS will ask for permissions the first time you run the robot. Go to `System Preferences` -> `Security & Privacy` and check either `Robocorp Lab` or `Code` (depending on the IDE you are using) in the `Accessibility` and `Screen Recording` sections.

### The settings

```robot
*** Settings ***
Documentation     Finds travel directions between two random locations.
...               Selects two random locations on Earth.
...               Finds the directions using the Maps app on macOS (Big Sur).
...               Falls back on Google Maps, if Maps fails to find directions.
Library           Process
Library           RPA.Browser
Library           RPA.Desktop
Task Teardown     Close All Browsers
```

The robot uses three [libraries](https://robocorp.com/docs/languages-and-frameworks/robot-framework/basics#what-are-libraries) to automate the task. Finally, it will close all the browsers it happened to open.

### The task: Find travel directions between two random locations

```robot
*** Tasks ***
Find travel directions between two random locations
    @{locations}=    Get random locations
    Open the Maps app
    Maximize the window
    View directions    ${locations}[0]    ${locations}[1]
```

### Variables

```robot
*** Variables ***
${RANDOM_LOCATION_WEBSITE}=    https://www.randomlists.com/random-location
${DIRECTIONS_SCREENSHOT}=    ${CURDIR}${/}output${/}directions.png
```

### Keyword: Get random locations

```robot
*** Keywords ***
Get random locations
    Open Available Browser    ${RANDOM_LOCATION_WEBSITE}    headless=True
    Set Window Size    1600    1200
    @{location_elements}=    Get WebElements    css:.rand_medium
    ${location_1}=    Get Text    ${location_elements}[0]
    ${location_2}=    Get Text    ${location_elements}[1]
    [Return]    ${location_1}    ${location_2}
```

The robot uses a web browser to scrape and return two random locations from a suitable website.

### Keyword: Open the Maps app

```robot
*** Keywords ***
Open the Maps app
    Run Process    open    -a    Maps
    Wait For Element    alias:Maps.MapMode
```

The robot opens the Maps app using the `Run Process` keyword from the `Process` library. It executes the `open -a Maps` command. You can run the same command in your terminal to see what happens!

The robot knows when the Maps app is open by waiting for the `Maps.MapMode` [image template](https://robocorp.com/docs/developer-tools/robocorp-lab/locating-and-targeting-UI-elements#image-template-matching-paint-windows-10) to return a match.

### Keyword: Maximize the window

```robot
*** Keywords ***
Maximize the window
    ${not_maximized}=
    ...    Run Keyword And Return Status
    ...    Find Element    alias:Desktop.WindowControls
    Run Keyword If
    ...    ${not_maximized}
    ...    RPA.Desktop.Press Keys    ctrl    cmd    f
    Wait For Element    not alias:Desktop.WindowControls
```

The robot maximizes the Maps app window using a keyboard shortcut unless the app is already maximized. The `Run Keyword If` is used for [conditional execution](https://robocorp.com/docs/languages-and-frameworks/robot-framework/conditional-execution).

The robot knows the Maps app is maximized when the `Desktop.WindowControls` image template does **not** return a match (when the close/minimize/maximize icons are not anywhere on the screen).

### Keyword: Open and reset the directions view

```robot
*** Keywords ***
Open and reset the directions view
    ${directions_open}=
    ...    Run Keyword And Return Status
    ...    Find Element    alias:Maps.SwapLocations
    Run Keyword Unless
    ...    ${directions_open}
    ...    RPA.Desktop.Press Keys    cmd    r
    Wait For Element    alias:Maps.SwapLocations
    Click    alias:Maps.ResetFromAndToLocationsIcon
    RPA.Desktop.Press Keys    cmd    r
    Wait For Element    alias:Maps.SwapLocations
```

The robot sets the directions view in the Maps app to a known starting state (empty from and to locations).

- Conditional execution is used to handle the possible states for the view (it might or might not be open already).
- Image templates are used to wait for specific app states so that the robot knows when something has been completed.
- Keyboard shortcuts are used to toggle the directions view.

### Keyword: View directions using Google Maps

```robot
*** Keywords ***
View directions using Google Maps
    [Arguments]    ${location_1}    ${location_2}
    Go To    https://www.google.com/maps/dir/${location_1}/${location_2}/
    Wait Until Element Is Visible    css:.section-directions-options
    Screenshot    filename=${DIRECTIONS_SCREENSHOT}
```

The robot waits until Google Maps has loaded the directions and takes a full web page screenshot.

### Keyword: Enter location

```robot
*** Keywords ***
Enter location
    [Arguments]    ${locator}    ${location}
    Wait For Element    ${locator}
    Click    ${locator}
    Type Text    ${location}    enter=True
```

The robot needs to input the from and to locations. This keyword provides a generic way to target those elements on the UI.

### Keyword: View directions

```robot
*** Keywords ***
View directions
    [Arguments]    ${location_1}    ${location_2}
    Open and reset the directions view
    Enter location    alias:Maps.FromLocation    ${location_1}
    Enter location    alias:Maps.ToLocation    ${location_2}
    ${directions_found}=
    ...    Run Keyword And Return Status
    ...    Wait For Element    alias:Maps.RouteIcon    timeout=20.0
    Run Keyword Unless
    ...    ${directions_found}
    ...    View directions using Google Maps    ${location_1}    ${location_2}
    Run Keyword If
    ...    ${directions_found}
    ...    Take Screenshot    ${DIRECTIONS_SCREENSHOT}
```

The robot tries to find the directions using the Maps app. If that fails, the robot gets the directions from Google Maps.

## Summary

- Image template matching is a cross-platform way to find and target UI elements.
- Keyboard shortcuts are the preferred way to interact with desktop applications (the shortcuts are usually more stable and predictable than the UI).
- Conditional logic can be used to select different actions based on the state of the application.
