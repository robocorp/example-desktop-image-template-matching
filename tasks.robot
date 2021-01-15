*** Settings ***
Documentation     Finds travel directions between two random locations.
...               Selects two random locations on Earth.
...               Finds the directions using the Maps app on macOS (Big Sur).
...               Falls back on Google Maps, if Maps fails to find directions.
Library           Process
Library           RPA.Browser
Library           RPA.Desktop
Task Teardown     Close All Browsers

*** Variables ***
${RANDOM_LOCATION_WEBSITE}=    https://www.randomlists.com/random-location
${DIRECTIONS_SCREENSHOT}=    ${CURDIR}${/}output${/}directions.png

*** Keywords ***
Get random locations
    Open Available Browser    ${RANDOM_LOCATION_WEBSITE}    headless=True
    Set Window Size    1600    1200
    @{location_elements}=    Get WebElements    css:.rand_medium
    ${location_1}=    Get Text    ${location_elements}[0]
    ${location_2}=    Get Text    ${location_elements}[1]
    [Return]    ${location_1}    ${location_2}

*** Keywords ***
Open the Maps app
    Run Process    open    -a    Maps
    Wait For Element    alias:Maps.MapMode

*** Keywords ***
Maximize the window
    ${not_maximized}=
    ...    Run Keyword And Return Status
    ...    Find Element    alias:Desktop.WindowControls
    Run Keyword If
    ...    ${not_maximized}
    ...    RPA.Desktop.Press Keys    ctrl    cmd    f
    Wait For Element    not alias:Desktop.WindowControls

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

*** Keywords ***
View directions using Google Maps
    [Arguments]    ${location_1}    ${location_2}
    Go To    https://www.google.com/maps/dir/${location_1}/${location_2}/
    Wait Until Element Is Visible    css:.section-directions-options
    Screenshot    filename=${DIRECTIONS_SCREENSHOT}

*** Keywords ***
Enter location
    [Arguments]    ${locator}    ${location}
    Wait For Element    ${locator}
    Click    ${locator}
    Type Text    ${location}    enter=True

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

*** Tasks ***
Find travel directions between two random locations
    @{locations}=    Get random locations
    Open the Maps app
    Maximize the window
    #View directions    ${locations}[0]    ${locations}[1]
    View directions    Helsinki    Tuusula
