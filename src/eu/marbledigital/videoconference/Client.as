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
		
		public function userConnected(userId:int, username:String):void
		{
			JSProxy.log("New user connected to room. Username: " + username + ", userId: " + userId);
			VideoContainer.instance.playStream(userId,username);
		}
		
		public function userDisconnected(userId:int, username:String):void
		{
			JSProxy.log("User disconnected from the room. Username: " + username + ", userId: " + userId);
			VideoContainer.instance.removeStream(userId);
		}
		
		public function usersInRoom(userList:Array):void
		{
			JSProxy.log("Got user list from the server (" + userList.length + " users)");
			
			for(var i:Object in userList) {
				var user:Object = userList[i];
				VideoContainer.instance.playStream(user.id,user.username);
			}
		}
	}

}