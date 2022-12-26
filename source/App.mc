using Toybox.Application;
using Toybox.WatchUi;

using Toybox.Communications;
using Toybox.Timer;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;

var bank = 0;
var bank_size = 1;

var request_active = false;
var change_view_mode = false;

var train_data;

var selectStations = [
	{"src" => "EUS", "dest" => "PRE"},
	{"src" => "GLQ", "dest" => "EDB"},
	{"src" => "PRE", "dest" => "MAN"},
] as Lang.Array<Lang.Dictionary<Lang.String,Lang.String>>;

class CommuterBlissUKApp extends Application.AppBase {

	const URL_BASE = "https://hate-snake.glitch.me/";

	// enable UI testing by mocking the response from the server
	// must be set to "false" for production builds
	const ENABLE_MOCKED_DATA = true;
	
	var myTimer;
	var train_data;
	var using_src;
	var using_dest;

	function initialize() {
		AppBase.initialize();
		
		bank_size = selectStations.size();
	}

	function mockService(i) {
		var unixTimeNow = Time.now().value();
		var nextTime = unixTimeNow + 1000 * i;
		var delayed = false;
		var delayedMinutes = i;
		if (i > 1 && i < 4) {
			delayedMinutes = i;
			delayed = true;
		}

		return {
			"time" => nextTime,
			"from" => "EUS",
			"to" => "PRE",
			"time_to_walk" => 0,
			"cancelled" => false,
			"platform" => "1",
			"delayed" => delayed,
			"service_ID" => "123",
			"unique_ID" => "EUSPRE123",
			"origin_CRS" => "EUS",
			"destination_CRS" => "PRE",
			"current_dest_time" => nextTime + 20 * 60 + delayedMinutes * 60,
			"delayed_minutes" => delayedMinutes,
		};
	}

	function mockResponse() {
		var services = {"services"=>[]};
		for (var i = 0; i < 6; i++) {
			services["services"].add(mockService(i));
		}
		return services;
	}

	// set up the response callback function
	function onReceive(responseCode, data) {
		request_active = false;
		
//		System.println("responseCode: " + responseCode);
//		System.println(data);

		if (responseCode == 200) {
			if (ENABLE_MOCKED_DATA) {
				train_data = mockResponse();
			}
			else {
				train_data = data;
			}
		}
		else {
			train_data = {"services"=>[]};
		}
		
		WatchUi.requestUpdate();
	}
	
	function timerCallback() {
		var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		if (myTimer != null) {
			var seconds_to_go = 60 - today.sec;
//	    	System.println("onStart(), seconds_to_go: " + seconds_to_go);
			myTimer.start(method(:timerCallback), seconds_to_go * 1000, false);
		}
		
		if (selectStations != null && selectStations.size() > 0) {
			using_src = selectStations[bank].get("src");
			using_dest = selectStations[bank].get("dest");
			
			if (Application.Properties.getValue("swapStations") == true && (today.hour >= 12 || today.hour < 2)) {
				using_src = selectStations[bank].get("dest");
				using_dest = selectStations[bank].get("src");
			}
			
			var url = URL_BASE + "?src=" + using_src + "&dest=" + using_dest;
			
	//        System.println("timerCallback() " + today.min + "m, " + today.sec + "s");
	//    	System.println(url);
			
			var params = null;
			var options = {
				:method => Communications.HTTP_REQUEST_METHOD_GET,
				:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
			};

			request_active = true;
			Communications.makeWebRequest(url, params, options, method(:onReceive));
		}
	}
	
	function applySettings() {
		var selectStationsSaved = Application.Properties.getValue("selectStations");
		// System.println("raw settings:\n" + selectStations);

		if (selectStationsSaved != null) {
			selectStations = [];

			// copy properties to a local array and do
			// simple validation to make the station codes uppercase
			for (var i = 0; i < selectStationsSaved.size(); i++) {
				var route = selectStationsSaved[i];
				route["src"] = route.get("src").toUpper();
				route["dest"] = route.get("dest").toUpper();
				selectStations.add(route);
			}

			bank_size = selectStations.size();
		}
		// System.println(selectStations);
		Application.Properties.setValue("selectStations", selectStations);
	}
	
	
	// onStart() is called on application start up
	function onStart(state) {
		applySettings();
		
		timerCallback();

		// TODO When dealing with date type settings that are set by Garmin Express or Garmin Connect, one should note that times are stored in UTC and that Gregorian.utcInfo() should be used in place of Gregorian.info() when working with such values to prevent unnecessary local time conversion.
		
		var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		var seconds_to_go = 60 - today.sec;
//	    System.println("onStart(), seconds_to_go: " + seconds_to_go);
		
		myTimer = new Timer.Timer();
		myTimer.start(method(:timerCallback), seconds_to_go * 1000, false);
	}

	// onStop() is called when the application is exiting
	function onStop(state) {
		if (myTimer != null) {
			myTimer.stop();
		}
	}
	
	function onSettingsChanged() {
		applySettings();
		timerCallback();
	}

	// return the initial view of the application here
	function getInitialView() {
		var view = new CommuterBlissUKView();
		return [view, new CommuterBlissUKAppDelegate(view)];
	}

}
