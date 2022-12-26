using Toybox.WatchUi;

class CommuterBlissUKAppDelegate extends WatchUi.BehaviorDelegate {

    var view_;

	function initialize(view) {
        BehaviorDelegate.initialize();
	    view_ = view;
	}
  
    function onKey(keyEvent) {
//        System.println(keyEvent.getKey());

		if (keyEvent.getKey() == KEY_ENTER) {
	        view_.setViewMode();
	        
			Application.getApp().timerCallback();
        	return true;
		}
		else if (keyEvent.getKey() == KEY_UP) {
			$.bank = $.bank - 1;
			if ($.bank < 0) {
				$.bank = $.bankSize - 1;
			}
	        
			Application.getApp().trainData = {"services"=>[]};
			view_.requestUpdate();
			Application.getApp().timerCallback();
        	return true;
		}
		else if (keyEvent.getKey() == KEY_DOWN) {
			$.bank = $.bank + 1;
			if ($.bank == $.bankSize) {
				$.bank = 0;
			}
	        
			Application.getApp().trainData = {"services"=>[]};
			view_.requestUpdate();
			Application.getApp().timerCallback();
        	return true;
		}
		
		return false;
    }
}
