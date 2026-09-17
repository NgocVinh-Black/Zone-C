pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import "schema.js" as Schema
import "WeatherLogic.js" as Logic

// Current weather from Open-Meteo (no API key). Keeps the last good reading on errors.
Singleton {
    id: root

    readonly property var settings: Config.feature("weather", Schema.fields)
    readonly property bool manualLocation: settings.latitude !== null && settings.longitude !== null

    property bool available: false
    property int code: -1
    property bool isDay: true
    property real temperature: 0
    readonly property string icon: Logic.icon(code, isDay)
    readonly property string tone: Logic.tone(code)
    readonly property string temperatureText: Logic.formatTemp(temperature)

    property var latitude: null
    property var longitude: null

    onSettingsChanged: refresh()

    function refresh(): void {
        if (manualLocation) {
            latitude = settings.latitude;
            longitude = settings.longitude;
            fetchForecast();
        } else if (latitude !== null) {
            fetchForecast();
        } else {
            locate();
        }
    }

    function request(url: string, onJson: var): void {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                console.warn("[zone-c weather] request failed:", url, xhr.status);
                retry.restart();
                return;
            }
            try {
                onJson(JSON.parse(xhr.responseText));
            } catch (e) {
                console.warn("[zone-c weather] bad response:", e);
                retry.restart();
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function locate(): void {
        request("http://ip-api.com/json/?fields=status,lat,lon", data => {
            if (data.status !== "success") {
                console.warn("[zone-c weather] could not locate by IP");
                retry.restart();
                return;
            }
            latitude = data.lat;
            longitude = data.lon;
            fetchForecast();
        });
    }

    function fetchForecast(): void {
        request(Logic.forecastUrl(latitude, longitude, settings.unit), data => {
            const current = data.current;
            code = current.weather_code;
            isDay = current.is_day === 1;
            temperature = current.temperature_2m;
            available = true;
        });
    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: root.settings.intervalMinutes * 60 * 1000
        onTriggered: root.refresh()
    }

    Timer {
        id: retry

        interval: 10 * 60 * 1000
        onTriggered: root.refresh()
    }
}
