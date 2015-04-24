package eu.marbledigital.videoconference
{
	import flash.external.ExternalInterface;
	
	/**
	 * ...
	 * @author Robert Szabados
	 */
	public class JSProxy
	{
		
		public static function log(message:String):void
		{
			if (ExternalInterface.available)
			{
				ExternalInterface.call("console.log", 'VideoConference flash: ' + message);
				
			}
			else
			{
				trace(message);
			}
		}
		
		// todo: external event handler binding
		public static function event(message:String, param:String):void
		{
			/*if (ExternalInterface.available)
			{
				ExternalInterface.call("videoConferenceEvent", message, param);
			}*/
		}
	
	}

}
