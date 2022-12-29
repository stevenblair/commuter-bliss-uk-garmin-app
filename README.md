# Commuter Bliss UK - Garmin watch app

A Garmin watch app for UK rail commuters.

This is a rewrite of the original [Pebble Time watchface]( https://github.com/stevenblair/commuter-bliss-uk) for Garmin devices. At the moment, the Forerunner 245 and Forerunner 245 Music are supported, but other devices will be added.

![5](https://user-images.githubusercontent.com/785994/209989510-13d6abb7-da7a-4480-ab42-06b1b023afda.png)

## Features

Displays the next six trains for your daily commute to and from work. It is designed to require minimal effort to show important information that a rail commuter needs on a daily basis.

You can specify your normal home and work railway stations using the app settings. Only direct rail services are supported. Updates for the data displayed by the app are requested periodically. Where specified in the data, the estimated time of departure (ETD) is displayed. Otherwise, the scheduled time of departure (STD) is shown. The platform number, if available, is shown in brackets.

There are two display modes: text list of services, or the graphical view which shows each train service as an arc around the watch. Use the `Start/Stop` key to 

The app also shows the time and date in a clear and sensible way for UK users.

 1 |  2  |  3  |  4
--- | --- | --- | ---
![1](https://user-images.githubusercontent.com/785994/209987692-c00e7e8a-69da-43fa-ad80-fbaa9876bfad.png)  | ![2](https://user-images.githubusercontent.com/785994/209987700-85dd3a8c-8f57-47af-af95-37e32866cda2.png) | ![3](https://user-images.githubusercontent.com/785994/209987713-e618330b-56dc-45dc-ba68-df2e302ea097.png) | ![4](https://user-images.githubusercontent.com/785994/209987719-97ad62ff-e832-4afa-b119-0f1076b4fab8.png)

## App settings

* The app settings can be used to configure up to 12 sets of routes between two stations. These can be selected within the app using the `Up` and `Down` keys on the watch. Stations are specified using the three-character station code, such as "EUS" or "PAD". The app will try to find up to the next six direct services for the selected source and destination stations. The app doesn't check that a route is valid, so it won't show any routes if there are no available direct services between the selected stations. Uppercase or lowercase text can be used in the settings dialog.
* The app can be configured to automatically swap the direction of the stations in the afternoon, so that your normal home-to-work journeys to be shown in the morning, and work-to-home routes will be shown after midday.

## Implementation

The watch app is written in Garmin's Monkey C language.

Rail service data will be obtained in real-time via the Huxley 2 web service, which accesses National Rail Enquiries data. Huxley 2 runs within a container on Google Cloud Run - this container is built directly from a [fork of the GitHub repo](https://github.com/stevenblair/Huxley2). A separate container implements additional logic around the Huxley 2 API, such as ordering train services by expected arrival time. This is implemented in Node.js and is also served by Google Cloud Run.

## Acknowledgments

* [James Singleton](https://unop.uk/) for producing the [Huxley 2](https://github.com/jpsingleton/Huxley2) project, which translates National Rail Enquiries' Darwin web service into a convenient JSON REST API.
