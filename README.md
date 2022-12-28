# Commuter Bliss UK - Garmin watch app

A Garmin watch app for UK rail commuters.

This is a rewrite of the original [Pebble Time watchface]( https://github.com/stevenblair/commuter-bliss-uk) for Garmin devices.

# Features

Displays the next six trains for your daily commute to and from work. It is designed to require minimal effort to show important information that a rail commuter needs on a daily basis.

You can specify your normal home and work railway stations using the app settings. Only direct rail services are supported.

Rail service data will be obtained in real-time using the Huxley 2 web service, which accesses National Rail Enquiries data.

Updates for the data displayed by the app are requested periodically. Where specified in the data, the estimated time of departure (ETD) is displayed. Otherwise, the scheduled time of departure (STD) is shown.

The app also shows the time and date in a clear and sensible way for UK users.

## Details

* There are two display modes: text list of services, or the graphical view which shows each train service as an arc around the watch.
* It can be configured to change your normal home-to-work journeys to be shown in the morning, and work-to-home routes will be shown after midday.
* The platform number, if available, is shown in brackets.

## Acknowledgments

* [James Singleton](https://unop.uk/) for producing the [Huxley 2](https://github.com/jpsingleton/Huxley2) project, which translates National Rail Enquiries' Darwin web service into a convenient JSON REST API.
