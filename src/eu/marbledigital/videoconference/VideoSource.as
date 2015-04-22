package eu.marbledigital.videoconference
{
	
	/**
	 * ...
	 * @author Zsolt Petrik
	 */
	public class VideoSource
	{
		
		import flash.display.InteractiveObject;
		import flash.events.AsyncErrorEvent;
		import flash.events.IOErrorEvent;
		import flash.events.MouseEvent;
		import flash.events.NetStatusEvent;
		import flash.events.StatusEvent;
		import flash.events.TimerEvent;
		import flash.external.ExternalInterface;
		import flash.media.Camera;
		import flash.media.H264Level;
		import flash.media.H264Profile;
		import flash.media.H264VideoStreamSettings;
		import flash.media.Microphone;
		import flash.media.MicrophoneEnhancedMode;
		import flash.media.MicrophoneEnhancedOptions;
		import flash.media.SoundCodec;
		import flash.media.SoundTransform;
		import flash.net.NetConnection;
		import flash.net.NetStream;
		import flash.net.ObjectEncoding;
		import flash.utils.*;
		
		import org.osmf.net.StreamType;
		
		import spark.components.mediaClasses.DynamicStreamingVideoItem;
		import spark.components.mediaClasses.DynamicStreamingVideoSource;
		
		private var userId:int;
		private var netConnection:NetConnection;
		private var camera:Camera;
		private var microphone:Microphone;
		private var rtmpUrl:String;
		private var streamHandle:String;
		private var netStream:NetStream;
		
		private var streamerUi:StreamerUI;
		private var videoContainer:VideoContainer;
		
		private var cameraAttached:Boolean = false;
		private var microphoneAttached:Boolean = false;
		
		private var isPublisher:Boolean = false;
		
		private var roomId:int;
		private var roomToken:String;
		
		public function VideoSource(videoContainer:VideoContainer, streamerUi:StreamerUI)
		{
			this.videoContainer = videoContainer;
			this.streamerUi = streamerUi;
		}
		
		/**
		 * Closes all streams and removes webcam/audio
		 */
		public function destroy():void
		{
			try
			{
				if (netStream)
				{
					attachMicrophone(false);
					attachCamera(false);
					netStream.close();
				}
				if (netConnection)
				{
					netConnection.close();
				}
				
			}
			catch (ex:Error)
			{
				JSProxy.log("Unable to close stream: " + ex.message);
			}
		}
		
		public function publishStream(rtmpUrl:String,userId:int,roomToken:String):void
		{
			this.userId = userId;
			this.rtmpUrl = rtmpUrl;
			this.isPublisher = true;
			this.roomToken = roomToken;
			
			if (!isCameraSupported())
			{
				JSProxy.log("camera is not supported.");
				return;
			}
			
			var dynSrc:DynamicStreamingVideoSource = new DynamicStreamingVideoSource();
			
			var videoItems:Vector.<DynamicStreamingVideoItem>;
			videoItems = new Vector.<DynamicStreamingVideoItem>();
			videoItems.push(new DynamicStreamingVideoItem());
			
			dynSrc.host = "";
			dynSrc.streamType = StreamType.LIVE;
			dynSrc.streamItems = videoItems;
			streamerUi.display.source = dynSrc;
			
			try
			{
				camera = Camera.getCamera();
				
				if (camera != null)
				{
					camera.setMode(640, 480, 20);
					camera.setKeyFrameInterval(1);
					camera.setLoopback(false);
					camera.setQuality(1024000, 100);
				}
			}
			catch (e:Error)
			{
				JSProxy.log("Camera initialization failed: " + e.message);
			}
			
			microphone = createMicrophone();
			
			connect();
		}
		
		public function playStream(rtmpUrl:String, userId:int,roomToken:String):void
		{
			this.userId = userId;
			this.rtmpUrl = rtmpUrl;
			this.isPublisher = false;
			this.roomToken = roomToken;
			
			if (streamHandle == null || streamHandle == '')
			{
				return;
			}
			
			var dynSrc:DynamicStreamingVideoSource = new DynamicStreamingVideoSource();
			
			var videoItems:Vector.<DynamicStreamingVideoItem>;
			videoItems = new Vector.<DynamicStreamingVideoItem>();
			videoItems.push(new DynamicStreamingVideoItem());
			
			dynSrc.host = "";
			dynSrc.streamType = StreamType.DVR;
			dynSrc.streamItems = videoItems;
			
			streamerUi.display.source = dynSrc;
			connect();
		}
		
		private static function setCodecOnNs(netStream:NetStream):void
		{
			var videoStreamSettings:H264VideoStreamSettings = new H264VideoStreamSettings();
			videoStreamSettings.setProfileLevel(H264Profile.BASELINE, H264Level.LEVEL_2_1);
			videoStreamSettings.setQuality(1024000, 100);
			try
			{
				netStream.videoStreamSettings = videoStreamSettings;
			}
			catch (e:Error)
			{
				JSProxy.log("Setting video stream settings failed: " + e.message);
			}
		}
		
		private function onConnectionStatus(event:NetStatusEvent):void
		{
			JSProxy.log("connectionStatusHandler: " + event.info.code);
			
			if (event.target != netConnection)
			{
				return;
			}
			
			try
			{
				if (event.info.code == "NetConnection.Connect.Success")
				{
					netStream = new NetStream(netConnection);
					
					netStream.addEventListener(NetStatusEvent.NET_STATUS, onStreamStatus);
					netStream.addEventListener(IOErrorEvent.IO_ERROR, onStreamIOError);
					netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onStreamAsyncError);
					setCodecOnNs(netStream);
					
					if (isPublisher)
					{
						netStream.soundTransform = new SoundTransform();
						netStream.publish(streamHandle, "live");
						
						cameraAttached = false;
						attachCamera(true);
						streamerUi.display.videoObject.visible = true;
						
						microphoneAttached = false;
						attachMicrophone(true);
						
						JSProxy.event("Publishing", null);
					}
					else
					{
						netStream.bufferTime = 0;
						netStream.play(streamHandle, -1);
						
						streamerUi.display.videoObject.attachNetStream(netStream);
						streamerUi.display.videoObject.visible = true;
						
						JSProxy.event("Playing", null);
					}
				}
			}
			catch (ex:Error)
			{
				JSProxy.log("onConnectionStatus excepton: " + ex);
			}
		}
		
		private function toString():String
		{
			return "VideoSource of userId: " + userId;
		}
		
		protected function onConnectionAsyncError(event:AsyncErrorEvent):void
		{
			JSProxy.log("connectionAsyncError: " + event + " in " + this.toString());
		}
		
		protected function onConnectionIOError(event:IOErrorEvent):void
		{
			JSProxy.log("connectionIOError: " + event + " in " + toString());
		}
		
		private function connect():void
		{
			JSProxy.log("Connecting, dropping current connection first.");
			
			try
			{
				if (netStream != null)
				{
					netStream.close();
					netStream.dispose();
					netStream = null;
				}
			}
			catch (e:Error)
			{
				JSProxy.log("NetStream close error: " + e.message);
			}
			
			try
			{
				if (netConnection != null)
				{
					netConnection.removeEventListener(NetStatusEvent.NET_STATUS, onConnectionStatus);
					netConnection.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, onConnectionAsyncError);
					netConnection.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionIOError);
					netConnection.close();
				}
			}
			catch (e:Error)
			{
				JSProxy.log("NetConnection close failed: " + e.message);
			}
			
			netConnection = new NetConnection();
			
			netConnection.client = new Client();
			netConnection.objectEncoding = ObjectEncoding.AMF3;
			netConnection.addEventListener(NetStatusEvent.NET_STATUS, onConnectionStatus);
			netConnection.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onConnectionAsyncError);
			netConnection.addEventListener(IOErrorEvent.IO_ERROR, onConnectionIOError);
			netConnection.connect(rtmpUrl,{user_Id:userId,room_Token:roomToken});
	
		}
		
		/**
		 *  called when playing stream, not publishing
		 */
		private function onStreamStatus(evt:NetStatusEvent):void
		{
			if (evt.info.code == "NetStream.Publish.Start") {
			JSProxy.event("publishing", null);	
			}
			JSProxy.log("stream status handler called: " + evt.info.code + toString());
			
		}
		
		protected function onStreamAsyncError(evt:IOErrorEvent):void
		{
			JSProxy.log("stream async handler called: " + evt + toString());
		
		}
		
		protected function onStreamIOError(evt:IOErrorEvent):void
		{
			JSProxy.log("stream error handler called: " + evt + toString());
		
		}
		
		public function getUserId():int
		{
			return userId;
		}
		
		private function createMicrophone():Microphone
		{
			microphone = Microphone.getEnhancedMicrophone();
			
			if (microphone)
			{
				var options:MicrophoneEnhancedOptions = microphone.enhancedOptions;
				
				options.mode = MicrophoneEnhancedMode.FULL_DUPLEX;
				options.echoPath = 128;
				options.nonLinearProcessing = true;
				
				microphone.enhancedOptions = options;
			}
			else
			{
				microphone = Microphone.getMicrophone();
				
				if (microphone)
				{
					microphone.setUseEchoSuppression(true);
				}
			}
			
			if (microphone)
			{
				microphone.rate = 44;
				microphone.framesPerPacket = 1;
				microphone.setLoopBack(false);
				microphone.setSilenceLevel(0, 2000);
				microphone.gain = 50;
			}
			
			return microphone;
		}
		
		private function cameraStatusHandler(event:StatusEvent):void
		{
			JSProxy.log("Camera status " + event);
		}
		
		private function microphoneStatusHandler(event:StatusEvent):void
		{
			JSProxy.log("Microphone status " + event);
		}
		
		private function attachCamera(attach:Boolean):void
		{
			if (attach)
			{
				if (!cameraAttached)
				{
					streamerUi.display.videoObject.attachCamera(camera);
					netStream.attachCamera(camera);
				}
			}
			else
			{
				netStream.attachCamera(null);
				streamerUi.display.videoObject.attachCamera(null);
			}
			cameraAttached = attach;
		}
		
		private function attachMicrophone(attach:Boolean):void
		{
			if (attach)
			{
				if (!microphoneAttached)
				{
					netStream.attachAudio(microphone);
				}
			}
			else
			{
				netStream.attachAudio(null);
			}
			microphoneAttached = attach;
		}
		
		public function enableWebcam(enable:Boolean):void
		{
			if (camera)
			{
				attachCamera(enable);
			}
		}
		
		public function isCameraSupported():Boolean
		{
			return Camera.isSupported && Camera.getCamera() != null;
		}
	
	}

}
