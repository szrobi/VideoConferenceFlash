	package eu.marbledigital.videoconference
{
	
	/**
	 * NetConnection client
	 * 
	 * @author Zsolt Petrik <petrik.zsolt@marbledigital.eu>
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
	}

}