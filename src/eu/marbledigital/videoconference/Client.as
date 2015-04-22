	package eu.marbledigital.videoconference
{
	
	/**
	 * NetConnection client
	 * 
	 * @author Robert Szabados
	 */
	public class Client
	{
		
		public function Client()
		{
		
		}
		
		public function onBWCheck(... params):void
		{
		
		}
		
		public function onBWDone(data:Object):void
		{
			trace("bandwidth = " + data.kbitDown + " Kbps.");
		}
		
		public function userConnected(userId:int,userName:String):void {
			JSProxy.log(userId + "ez a user id");
			VideoContainer.instance.playStream(userId,userName);
		}
	}

}