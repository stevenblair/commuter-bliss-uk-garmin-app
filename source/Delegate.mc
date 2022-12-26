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
	        view_.set_view_mode();
	        
			Application.getApp().timerCallback();
        	return true;
		}
		else if (keyEvent.getKey() == KEY_UP) {
			$.bank = $.bank - 1;
			if ($.bank < 0) {
				$.bank = $.bank_size - 1;
			}
	        
			Application.getApp().train_data = {"services"=>[]};
			view_.requestUpdate();
			Application.getApp().timerCallback();
        	return true;
		}
		else if (keyEvent.getKey() == KEY_DOWN) {
			$.bank = $.bank + 1;
			if ($.bank == $.bank_size) {
				$.bank = 0;
			}
	        
			Application.getApp().train_data = {"services"=>[]};
			view_.requestUpdate();
			Application.getApp().timerCallback();
        	return true;
		}
		
		return false;
    }
}
