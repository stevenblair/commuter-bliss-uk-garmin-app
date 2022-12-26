using Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Sensor;

// supported view modes
enum {
    VIEW_TEXT,
    VIEW_ARCS
}

class CommuterBlissUKView extends WatchUi.View {

	// storage for the screen size
	var width, height;

	// storage for half the screen size (for positioning relative to the centre)
	var width_2, height_2;
	
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
	var wee_numbers;
	
	// lateness threshold for showing amber colour instead of red
	const DELAYED_SLIGHTLY_THRESHOLD_MINUTES = 2;
	
	// colours for train status
	const COLOUR_ON_TIME = 0x009900;
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
        
		wee_numbers = Graphics.FONT_SYSTEM_TINY;
    }

    // load resources here
    function onLayout(dc) {
        width = dc.getWidth();
        height = dc.getHeight();
        width_2 = width / 2;
        height_2 = height / 2;
        
		bankDotStart = width_2 - BANK_DOT_WIDTH / 2;
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
					dc.fillRectangle(0, 0, width, START_Y);
					dc.fillRectangle(0, START_Y + CLEAR_LOADING_AREA_OFFSET, width, height);
		//			dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
				}
				else {
					// TODO clear a circle - rectangle below "next: ..." might be better
//					dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_BLACK);
					dc.fillCircle(width_2, height_2, 72);
//					dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
				}
			}
			else {
				dc.clear();
			}
		}
        
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		var date_string = Lang.format("$1$ $2$ $3$", [today.day_of_week, today.day, today.month]);
        
        var clockTime2 = Sys.getClockTime();
        var time_string = Lang.format("$1$:$2$", [clockTime2.hour, clockTime2.min.format("%02d")]);
        
//        System.println(clockTime.dst);

		var journey_text = Application.getApp().usingSrc + " to " + Application.getApp().usingDest;
        
		if ($.selectStations == null || $.selectStations.size() == 0) {
			journey_text = "Select stations in app";
		}
        
	    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		var time_y = height_2;
        if (viewMode == VIEW_TEXT) {
			dc.drawText(width_2, START_Y + DATE_Y_OFFSET_TEXT, Graphics.FONT_SMALL, date_string, Graphics.TEXT_JUSTIFY_CENTER);
			time_y = START_Y + TIME_Y_OFFSET;
			
			dc.drawText(width_2, START_Y + JOURNEY_Y_OFFSET_TEXT, Graphics.FONT_XTINY, journey_text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		}
		else {
			dc.drawText(width_2, time_y + DATE_Y_OFFSET_ARC, Graphics.FONT_TINY, date_string, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
			
			dc.drawText(width_2, time_y + JOURNEY_Y_OFFSET_ARC, Graphics.FONT_TINY, journey_text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		}
		
	    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(width_2, time_y, Graphics.FONT_NUMBER_MEDIUM, time_string, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		
//			System.println(trainData);

        if (viewMode == VIEW_TEXT) {
	        var battery = Sys.getSystemStats().battery;
	        if (battery > 15) {
	    		dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
	    	}
	    	else {
	    		dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
	    	}
	    	
	    	var battery_string = battery.toNumber() + "%";
	    	
	        dc.drawText(
		        width_2,
		        BATTERY_Y,
		        Graphics.FONT_SYSTEM_XTINY,
		        battery_string,
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
			
			// TODO make one_hour conditional on dst or timeZoneOffset, or use UTCInfo function

			var one_hour = new Time.Duration(Gregorian.SECONDS_PER_HOUR);
			var now = Time.now();
			var now_value = now.value() /*+ one_hour.value()*/;
			var now_seconds = now_value % 60;
			now = new Time.Moment(now_value - now_seconds);
			
			var now2 = Time.now();
			var now_value2 = now.value() + one_hour.value();
			var now_seconds2 = now_value % 60;
			now2 = new Time.Moment(now_value2 - now_seconds2);
			
			if (len > 0 && viewMode == VIEW_ARCS) {
				var next_to = trainData.get("services")[0].get("destination_CRS");
				var service_text4 = "";
				if (trainData.get("services")[0].get("platform") != null) {
					service_text4 = " (" + trainData.get("services")[0].get("platform") + ")";
				}
				
	    		dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
				dc.drawText(width_2, time_y - 54, Graphics.FONT_XTINY, "Next: " + next_to + service_text4, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
			}
			
			var prev_minutes_to_go = null;
			
//	        dc.setPenWidth(ARC_WIDTH / 3);
	        dc.setPenWidth(2);
			
        	for (var i = len - 1; i >= 0; i--) {
        		var in_the_past = false;
        		var service = trainData.get("services")[i];
				
//		    	dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
	
		        var clockTime = Sys.getClockTime();
		        var timeString = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
		        
				var leave_time = new Time.Moment(service.get("time")/* - one_hour.value()*/);
//				System.println(i + ": " + one_hour.value() + " " + leave_time.value());
				try {
//					leave_time = leave_time.subtract(one_hour);
				}
				catch(ex) {
//					System.println("caught: " + ex.getErrorMessage() + ", " + service.get("time"));
				}
//				System.println(i + ": " + one_hour.value() + " " + leave_time.value());
				var date = Gregorian.info(leave_time, 0);
				date.sec = 0;
				
//				System.println(i + ": " + leave_time.value() + ", " + now.value() + ", diff: " + (leave_time.value() - now.value()));
				
				var seconds_to_go = leave_time.subtract(now).value();
				var minutes_to_go = seconds_to_go / 60;
		        var leave_time_str = Lang.format("$1$:$2$", [date.hour.format("%02d"), date.min.format("%02d")]);
			
				var arrive_time = new Time.Moment(service.get("current_dest_time"));
//				arrive_time = arrive_time.subtract(one_hour);
				var seconds_to_go_arrive = arrive_time.subtract(now).value();
		    	
		    	if (leave_time.lessThan(now)) {
		    		in_the_past = true;
		    		minutes_to_go = minutes_to_go * -1;	// display the correct negative time...
		    		seconds_to_go = 0;					// ...but position at 0 mins
//		    		System.println("less than, " + minutes_to_go + " mins, " + seconds_to_go + " s");
		    	}
		    	
		    	// fade these truncated services, also don't draw end circle
		    	var truncated = false;
		    	if (seconds_to_go_arrive >= SECONDS_IN_59_MINUTES) {
//		    		System.println(i + " truncated, " + seconds_to_go_arrive + " s");
		    		truncated = true;
		    		seconds_to_go_arrive = SECONDS_IN_59_MINUTES;
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
			    		dc.setColor(COLOUR_IN_THE_PAST_ON_TIME, Graphics.COLOR_TRANSPARENT);
			    	}
				
				    if (minutes_to_go < 60) {
					    if (i < 5) {
							var arc_start = toArcAngle(seconds_to_go / 10);
							var arc_end = toArcAngle(seconds_to_go_arrive / 10);
//							System.println(i + ": " + arc_start + " " + arc_end);
					    	var y_extra = 0;
					    	var ARC_WIDTH_OFFSET = 8; 
					    	if (i % 3 == 2) {
//					    		y_extra = ARC_WIDTH * 2;
					    		y_extra = (ARC_WIDTH - ARC_WIDTH_OFFSET) * 2;
					    	}
					    	else if (i % 3 == 1) {
//					    		y_extra = ARC_WIDTH;
					    		y_extra = (ARC_WIDTH - ARC_WIDTH_OFFSET);
					    	}
					    	
						    if (minutes_to_go < 59) {
						    	// TODO prevent start time less than 0
						    	// TODO negative times are showing as positive
						    	
						        dc.drawArc(width_2, height_2, width_2 - y_extra - (ARC_WIDTH / 2), dc.ARC_CLOCKWISE, arc_start, arc_end);
						    }
					    
					    	if (i > 0 && prev_minutes_to_go == minutes_to_go) {
					    		// don't draw if time label would overlap with previous
					    	}
					    	else {
//						    	var minutes_angle = toArcAngle(seconds_to_go / 10);
						    	var ang_radians = (arc_start) * Math.PI / 180.0;
						    	var r = width_2 - y_extra - (ARC_WIDTH / 2);
						    	var x = r * Math.cos(ang_radians) + width_2;
						    	var y = -r * Math.sin(ang_radians) + width_2;
		//				    	System.println(i + ": " + minutes_angle + " deg, " + ang_radians + " rad, mins: " + minutes_to_go + ", " + x + ", " + y);
							    
//						    	dc.fillCircle(x, y, ARC_WIDTH / 2);
						    	dc.fillCircle(x, y, ARC_WIDTH - 8);
							    
							    if (truncated == false && minutes_to_go < 59) {
//							    	var minutes_angle = toArcAngle(seconds_to_go_arrive / 10);
							    	ang_radians = (arc_end) * Math.PI / 180.0;
							    	var r2 = width_2 - y_extra - (ARC_WIDTH / 2);
							    	var x2 = r2 * Math.cos(ang_radians) + width_2;
							    	var y2 = -r2 * Math.sin(ang_radians) + width_2;
							    	
							    	dc.fillCircle(x2, y2, ARC_WIDTH / 4);
								}
		
		        				dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
						    	dc.drawText(
							        x,
							        y,
							        wee_numbers,
							        minutes_to_go.toNumber(),
							        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
						    }
						}
		        	}
		        	
		        	prev_minutes_to_go = minutes_to_go;
		      	}
	        	else if (viewMode == VIEW_TEXT) {
//	        		System.println(i + " delay: " + service.get("delayed"));
				    if (service.get("delayed") == true) {
			    		
						if (in_the_past) {
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
						if (in_the_past) {
			    			dc.setColor(COLOUR_IN_THE_PAST_ON_TIME, Graphics.COLOR_TRANSPARENT);
						}
						else {
			    			dc.setColor(COLOUR_ON_TIME, Graphics.COLOR_TRANSPARENT);
			    		}
			    	}
	        	
					var service_text1 = minutes_to_go.toNumber() + " min";
					var service_text2 = leave_time_str;
					var service_text3 = service.get("destination_CRS");
					var service_text4 = "";
					if (service.get("platform") != null) {
						service_text4 = "(" + service.get("platform") + ")";
					}
		
					var service_font = Graphics.FONT_SYSTEM_XTINY;
					var service_font_extra = Graphics.FONT_SYSTEM_XTINY;
				    dc.drawText(
				        START_X + 50,
				        START_Y + (i * TRAIN_INFO_HEIGHT),
				        service_font,
				        service_text1,
				        Graphics.TEXT_JUSTIFY_RIGHT);
				        
			    	if (in_the_past) {
			    		dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
			    	}
			    	else {
			    		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
			    	}
			    	
				    dc.drawText(
				        START_X + 55,
				        START_Y + (i * TRAIN_INFO_HEIGHT),
				        service_font_extra,
				        service_text2,
				        Graphics.TEXT_JUSTIFY_LEFT);
				    dc.drawText(
				        START_X + 94,
				        START_Y + (i * TRAIN_INFO_HEIGHT),
				        service_font_extra,
				        service_text3,
				        Graphics.TEXT_JUSTIFY_LEFT);
				    dc.drawText(
				        START_X + 125,
				        START_Y + (i * TRAIN_INFO_HEIGHT),
				        service_font_extra,
				        service_text4,
				        Graphics.TEXT_JUSTIFY_LEFT);
			    }
			}
        }
    }
    
    var first_time = true;
    var time_object;
    
    function onExitSleep() {
//		System.println("onExitSleep()");
//		if (first_time) {
//			WatchUi.animate(time_object, :locY, WatchUi.ANIM_TYPE_LINEAR, 0, 200, 100, null);
//			first_time = false;
//		}
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
