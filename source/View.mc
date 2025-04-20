using Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Sensor;
using Toybox.Weather as Weath;

// supported view modes
enum {
	VIEW_TEXT,
	VIEW_ARCS
}

class CommuterBlissUKView extends WatchUi.View {

	// storage for the screen size
	var WIDTH, HEIGHT;

	// storage for half the screen size (for positioning relative to the centre)
	var WIDTH_2, HEIGHT_2;
	
	// local reference to the train data
	var trainData = null;
	
	const SECONDS_IN_59_MINUTES = 3540;
	
	// defines the starting coordinates for the first train info, other elements are positioned relative to this
	const START_X = 45;
	const START_Y = 95;

	// UI component positions
	const BATTERY_Y = 6;
	const TRAIN_INFO_HEIGHT = 17;
	const TIME_Y_OFFSET = -23;
	const DATE_Y_OFFSET_TEXT = -72;
	const DATE_Y_OFFSET_ARC = -32;
	const JOURNEY_Y_OFFSET_TEXT = 115;
	const JOURNEY_Y_OFFSET_ARC = 32;
	const CLEAR_LOADING_AREA_OFFSET = $.SERVICES_TO_DISPLAY * TRAIN_INFO_HEIGHT + 8;
	const ARC_WIDTH = 20;

	// defines if the view mode has been requested to change
	var changeViewMode = false;

	// specify the default view mode
	var viewMode = VIEW_TEXT;
	
	// store font
	var weeNumbers;
	
	// lateness threshold for showing amber colour instead of red
	const DELAYED_SLIGHTLY_THRESHOLD_MINUTES = 2;
	
	// colours for train status
	const COLOUR_ON_TIME = 0x008800;
	const COLOUR_DELAYED = 0xFF0000;
	const COLOUR_DELAYED_SLIGHTLY = 0xFF7700;
	
	// colours for train status (where the train should have departed already)
	const COLOUR_IN_THE_PAST_ON_TIME = 0x003300;
	const COLOUR_IN_THE_PAST_DELAYED = 0x330000;
	
	// indicators for selected "bank" of trains
	const BANK_DOT_WIDTH = 50;
	var bankDotStart = 0;
	var bankDotSpacing = 0;
	
	function setViewMode() {
		changeViewMode = true;
		if (viewMode == VIEW_TEXT) {
			viewMode = VIEW_ARCS;
		}
		else if (viewMode == VIEW_ARCS) {
			viewMode = VIEW_TEXT;
		}
		WatchUi.requestUpdate();
	}
	
	function initialize() {
		View.initialize();
		
		weeNumbers = Graphics.FONT_SYSTEM_TINY;
	}

	// load resources here
	function onLayout(dc) {
		WIDTH = dc.getWidth();
		HEIGHT = dc.getHeight();
		WIDTH_2 = WIDTH / 2;
		HEIGHT_2 = HEIGHT / 2;
		
		bankDotStart = WIDTH_2 - BANK_DOT_WIDTH / 2;
		if (bankSize <= 1) {
			bankDotSpacing = BANK_DOT_WIDTH / 2;
		} else {
			bankDotSpacing = BANK_DOT_WIDTH / (bankSize - 1);
		}

		dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		dc.clear();
	}

	// Called when this View is brought to the foreground. Restore
	// the state of this View and prepare it to be shown. This includes
	// loading resources into memory.
	function onShow() {
	}
	
	function toArcAngle(ang) {
		var ang2 = ((360 - ang).toNumber() % 360) + 90;
		
		if (ang2 >= 360) {
			ang2 = ang2 - 360;
		}
		
		return ang2;
	}

	// update the view
	function onUpdate(dc) {
//    	System.println("onUpdate(), " + Application.getApp().trainData);
		
		dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		
		var viewHasChanged = false;
		
		if (changeViewMode == true) {
			dc.clear();
			changeViewMode = false;
			viewHasChanged = true;
		}
		else {
			// do selective clear to avoid removing trains - data may still be valid
			if ($.requestActive) {
				if (viewMode == VIEW_TEXT) {
		//			dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_BLACK);
					dc.fillRectangle(0, 0, WIDTH, START_Y);
					dc.fillRectangle(0, START_Y + CLEAR_LOADING_AREA_OFFSET, WIDTH, HEIGHT);
		//			dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
				}
				else {
					// TODO clear a circle - rectangle below "next: ..." might be better
//					dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_BLACK);
					dc.fillCircle(WIDTH_2, HEIGHT_2, 72);
//					dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
				}
			}
			else {
				dc.clear();
			}
		}
		
		var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		var dataString = Lang.format("$1$ $2$ $3$", [today.day_of_week, today.day, today.month]);
		
		var clockTime2 = Sys.getClockTime();
		var timeString = Lang.format("$1$:$2$", [clockTime2.hour, clockTime2.min.format("%02d")]);
		
//        System.println(clockTime.dst);

		var journey_text = Application.getApp().usingSrc + " to " + Application.getApp().usingDest;
		
		if ($.selectStations == null || $.selectStations.size() == 0) {
			journey_text = "Select stations in app";
		}
		
		dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		var timeY = HEIGHT_2;
		if (viewMode == VIEW_TEXT) {
			dc.drawText(WIDTH_2, START_Y + DATE_Y_OFFSET_TEXT, Graphics.FONT_SMALL, dataString, Graphics.TEXT_JUSTIFY_CENTER);
			timeY = START_Y + TIME_Y_OFFSET;
			
			dc.drawText(WIDTH_2, START_Y + JOURNEY_Y_OFFSET_TEXT, Graphics.FONT_XTINY, journey_text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		}
		else {
			dc.drawText(WIDTH_2, timeY + DATE_Y_OFFSET_ARC, Graphics.FONT_TINY, dataString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
			
			dc.drawText(WIDTH_2, timeY + JOURNEY_Y_OFFSET_ARC, Graphics.FONT_TINY, journey_text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		}
		
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(WIDTH_2, timeY, Graphics.FONT_NUMBER_MEDIUM, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		
//			System.println(trainData);

		if (viewMode == VIEW_TEXT) {
			var battery = Sys.getSystemStats().battery;
			if (battery > 15) {
				dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
			}
			else {
				dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
			}

			var cc = Weath.getCurrentConditions();
			
			var batteryAndTemperatureString = battery.toNumber() + "%  " + cc.feelsLikeTemperature.format("%.0f") + "°C";
			
			dc.drawText(
				WIDTH_2,
				BATTERY_Y,
				Graphics.FONT_SYSTEM_XTINY,
				batteryAndTemperatureString,
				Graphics.TEXT_JUSTIFY_CENTER);
	   }

		if ($.requestActive) {
			var bankOffset = 0;
			if (viewMode == VIEW_ARCS) {
				bankOffset = 58;
			}
			for (var d = 0; d < $.bankSize; d++) {
				if (d == $.bank) {
					dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
				}
				else {
					dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
				}
				dc.drawText(
					bankDotStart + bankDotSpacing * d,
					214 - bankOffset,
					Graphics.FONT_SYSTEM_TINY,
					"•",
					Graphics.TEXT_JUSTIFY_CENTER);
			}
			
			if (viewHasChanged == false) {
				return;
			}
		}
	
//		var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
//        System.println("onUpdate() " + today.min + "m, " + today.sec + "s");
	
		var temp = Application.getApp().trainData;
		
		if (temp != null && temp instanceof Dictionary) {
			trainData = temp;
		
			var len = trainData.get("services").size();
			
			var systemTime = System.getClockTime();
			// var oneHour = new Time.Duration(Gregorian.SECONDS_PER_HOUR);
			var now = Time.now();
			var now_value = now.value() + systemTime.timeZoneOffset;	// systemTime.timeZoneOffset makes `now_value` conditional based on the DST offset

			// System.println("dst = " + systemTime.dst);
			// System.println("timeZoneOffset = " + systemTime.timeZoneOffset);
			// System.println("oneHour.value() = " + oneHour.value());

			var now_seconds = now_value % 60;
			now = new Time.Moment(now_value - now_seconds);
			
			// var now2 = Time.now();
			// var now_value2 = now.value() + oneHour.value();
			// var now_seconds2 = now_value % 60;
			// now2 = new Time.Moment(now_value2 - now_seconds2);
			
			if (len > 0 && viewMode == VIEW_ARCS) {
				var next_to = trainData.get("services")[0].get("destination_CRS");
				var serviceText4 = "";
				if (trainData.get("services")[0].get("platform") != null) {
					serviceText4 = " (" + trainData.get("services")[0].get("platform") + ")";
				}
				
				dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
				dc.drawText(WIDTH_2, timeY - 54, Graphics.FONT_XTINY, "Next: " + next_to + serviceText4, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
			}
			
			var prevMinutesToGo = null;
			
//	        dc.setPenWidth(ARC_WIDTH / 3);
			dc.setPenWidth(2);
			
			for (var i = len - 1; i >= 0; i--) {
				var inThePast = false;
				var service = trainData.get("services")[i];
				
//		    	dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
	
				// var clockTime = Sys.getClockTime();
				// var timeStringService = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
				
				var leaveTime = new Time.Moment(service.get("time")/* - oneHour.value()*/);
//				System.println(i + ": " + oneHour.value() + " " + leaveTime.value());
				try {
//					leaveTime = leaveTime.subtract(oneHour);
				}
				catch(ex) {
//					System.println("caught: " + ex.getErrorMessage() + ", " + service.get("time"));
				}
//				System.println(i + ": " + oneHour.value() + " " + leaveTime.value());
				var date = Gregorian.info(leaveTime, 0);
				date.sec = 0;
				if (systemTime.timeZoneOffset > 0) {
					date.hour = date.hour - 1; // make this conditional on systemTime.timeZoneOffset
				}
				
				// System.println(i + ": " + leaveTime.value() + ", " + now.value() + ", diff: " + (leaveTime.value() - now.value()) + ", " + systemTime.timeZoneOffset);
				
				var secondsToGo = leaveTime.subtract(now).value();
				var minutesToGo = secondsToGo / 60;
				var leaveTimeString = Lang.format("$1$:$2$", [date.hour.format("%02d"), date.min.format("%02d")]);
			
				var arriveTime = new Time.Moment(service.get("current_dest_time"));
//				arriveTime = arriveTime.subtract(oneHour);
				var secondsToGoArrive = arriveTime.subtract(now).value();
				
				if (leaveTime.lessThan(now)) {
					inThePast = true;
					minutesToGo = minutesToGo * -1;	// display the correct negative time...
					secondsToGo = 0;					// ...but position at 0 mins
//		    		System.println("less than, " + minutesToGo + " mins, " + secondsToGo + " s");
				}
				
				// fade these truncated services, also don't draw end circle
				var truncated = false;
				if (secondsToGoArrive >= SECONDS_IN_59_MINUTES) {
//		    		System.println(i + " truncated, " + secondsToGoArrive + " s");
					truncated = true;
					secondsToGoArrive = SECONDS_IN_59_MINUTES;
				}
				
				if (viewMode == VIEW_ARCS) {
					if (service.get("delayed") == true) {
						if (service.get("delayed_minutes") <= DELAYED_SLIGHTLY_THRESHOLD_MINUTES) {
							dc.setColor(COLOUR_DELAYED_SLIGHTLY, Graphics.COLOR_TRANSPARENT);
						}
						else {
							dc.setColor(COLOUR_IN_THE_PAST_DELAYED, Graphics.COLOR_TRANSPARENT);
						}
//			    		dc.setColor(COLOUR_IN_THE_PAST_DELAYED, Graphics.COLOR_TRANSPARENT);
					}
					else {
						if (inThePast) {
							dc.setColor(COLOUR_IN_THE_PAST_ON_TIME, Graphics.COLOR_TRANSPARENT);
						}
						else {
							dc.setColor(COLOUR_ON_TIME, Graphics.COLOR_TRANSPARENT);
						}
					}
				
					if (minutesToGo < 60) {
						if (i < 5) {
							var arcStart = toArcAngle(secondsToGo / 10);
							var arcEnd = toArcAngle(secondsToGoArrive / 10);
//							System.println(i + ": " + arcStart + " " + arcEnd);
							var yExtra = 0;
							var ARC_WIDTH_OFFSET = 8; 
							if (i % 3 == 2) {
//					    		yExtra = ARC_WIDTH * 2;
								yExtra = (ARC_WIDTH - ARC_WIDTH_OFFSET) * 2;
							}
							else if (i % 3 == 1) {
//					    		yExtra = ARC_WIDTH;
								yExtra = (ARC_WIDTH - ARC_WIDTH_OFFSET);
							}
							
							if (minutesToGo < 59) {
								// TODO prevent start time less than 0
								// TODO negative times are showing as positive
								
								dc.drawArc(WIDTH_2, HEIGHT_2, WIDTH_2 - yExtra - (ARC_WIDTH / 2), dc.ARC_CLOCKWISE, arcStart, arcEnd);
							}
						
							if (i > 0 && prevMinutesToGo == minutesToGo) {
								// don't draw if time label would overlap with previous
							}
							else {
//						    	var minutes_angle = toArcAngle(secondsToGo / 10);
								var angRadians = (arcStart) * Math.PI / 180.0;
								var r = WIDTH_2 - yExtra - (ARC_WIDTH / 2);
								var x = r * Math.cos(angRadians) + WIDTH_2;
								var y = -r * Math.sin(angRadians) + WIDTH_2;
		//				    	System.println(i + ": " + minutes_angle + " deg, " + angRadians + " rad, mins: " + minutesToGo + ", " + x + ", " + y);
								
//						    	dc.fillCircle(x, y, ARC_WIDTH / 2);
								dc.fillCircle(x, y, ARC_WIDTH - 8);
								
								if (truncated == false && minutesToGo < 59) {
//							    	var minutes_angle = toArcAngle(secondsToGoArrive / 10);
									angRadians = (arcEnd) * Math.PI / 180.0;
									var r2 = WIDTH_2 - yExtra - (ARC_WIDTH / 2);
									var x2 = r2 * Math.cos(angRadians) + WIDTH_2;
									var y2 = -r2 * Math.sin(angRadians) + WIDTH_2;
									
									dc.fillCircle(x2, y2, ARC_WIDTH / 4);
								}
		
								dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
								dc.drawText(
									x,
									y,
									weeNumbers,
									minutesToGo.toNumber(),
									Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
							}
						}
					}
					
					prevMinutesToGo = minutesToGo;
			  	}
				else if (viewMode == VIEW_TEXT) {
//	        		System.println(i + " delay: " + service.get("delayed"));
					if (service.get("delayed") == true) {
						
						if (inThePast) {
							dc.setColor(COLOUR_IN_THE_PAST_DELAYED, Graphics.COLOR_TRANSPARENT);
						}
						else {
							if (service.get("delayed_minutes") <= DELAYED_SLIGHTLY_THRESHOLD_MINUTES) {
								dc.setColor(COLOUR_DELAYED_SLIGHTLY, Graphics.COLOR_TRANSPARENT);
							}
							else {
								dc.setColor(COLOUR_DELAYED, Graphics.COLOR_TRANSPARENT);
							}
						}
					}
					else {
						if (inThePast) {
							dc.setColor(COLOUR_IN_THE_PAST_ON_TIME, Graphics.COLOR_TRANSPARENT);
						}
						else {
							dc.setColor(COLOUR_ON_TIME, Graphics.COLOR_TRANSPARENT);
						}
					}
				
					var serviceText1 = minutesToGo.toNumber() + " min";
					var serviceText2 = leaveTimeString;
					var serviceText3 = service.get("destination_CRS");
					var serviceText4 = "";
					if (service.get("platform") != null) {
						serviceText4 = "(" + service.get("platform") + ")";
					}
		
					var serviceFont = Graphics.FONT_SYSTEM_XTINY;
					var serviceFont_extra = Graphics.FONT_SYSTEM_XTINY;
					dc.drawText(
						START_X + 50,
						START_Y + (i * TRAIN_INFO_HEIGHT),
						serviceFont,
						serviceText1,
						Graphics.TEXT_JUSTIFY_RIGHT);
						
					if (inThePast) {
						dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
					}
					else {
						dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
					}
					
					dc.drawText(
						START_X + 55,
						START_Y + (i * TRAIN_INFO_HEIGHT),
						serviceFont_extra,
						serviceText2,
						Graphics.TEXT_JUSTIFY_LEFT);
					dc.drawText(
						START_X + 94,
						START_Y + (i * TRAIN_INFO_HEIGHT),
						serviceFont_extra,
						serviceText3,
						Graphics.TEXT_JUSTIFY_LEFT);
					dc.drawText(
						START_X + 125,
						START_Y + (i * TRAIN_INFO_HEIGHT),
						serviceFont_extra,
						serviceText4,
						Graphics.TEXT_JUSTIFY_LEFT);
				}
			}
		}
	}
	
	// var firstTime = true;
	// var timeObject;
	
	function onExitSleep() {
//		System.println("onExitSleep()");
//		if (firstTime) {
//			WatchUi.animate(timeObject, :locY, WatchUi.ANIM_TYPE_LINEAR, 0, 200, 100, null);
//			firstTime = false;
//		}
	}

	// Called when this View is removed from the screen. Save the
	// state of this View here. This includes freeing resources from
	// memory.
	function onHide() {
	}

}
