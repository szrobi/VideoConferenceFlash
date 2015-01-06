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
		
		public function onBWDone(... params):void
		{
			if (params.length > 0)
			{
				trace("bandwidth = " + params[0] + " Kbps.");
			}
		}
	}

}