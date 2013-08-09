package  fluidsolver.core.worker
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	import fluidsolver.core.crossbridge.CModule;
	import fluidsolver.core.crossbridge.FluidSolverCrossbridge;
	import fluidsolver.utils.ConsoleProxy;
	
	/**
	 * ...
	 * @author Pete Shand
	 */
	public class FluidSolverWorkerCore extends Sprite
	{
		
		private var _worker:Worker;
		private var _mainToBack:MessageChannel;
		private var _backToMain:MessageChannel;
		private var _lastTime:int;
		
		public function FluidSolverWorkerCore():void 
		{
			
			CModule.vfs.console = new ConsoleProxy(log);
			
			_worker = Worker.current;
			
			_mainToBack = _worker.getSharedProperty("mainToBack");
			if (_mainToBack) {
				_mainToBack.addEventListener(Event.CHANNEL_MESSAGE, on_mainToBack);
			}
			
			_backToMain = _worker.getSharedProperty("backToMain");
			
			var returnObject:Object = new Object();
			returnObject.msg = "ready";
			_backToMain.send(returnObject);
		}
		protected function onEnterFrame(event:Event):void {
			var time:int = getTimer();
			FluidSolverCrossbridge.updateSolver((time-_lastTime)/100);
			_lastTime = time;
			
			var returnObject:Object = new Object();
			returnObject.msg = "update";
			_backToMain.send(returnObject);
		}
		
		protected function log(... params):void
		{
			trace.apply(null, params);
			_backToMain.send({calls: {"trace":params}});
		}
		
		protected function on_mainToBack(event:Event):void {
			try{
				if (!_mainToBack.messageAvailable) return;
				var sentObject:Object = _mainToBack.receive();
				
				var calls:Object = sentObject.calls;
				if (calls) {
					var didSetup:Boolean = false;
					var returnObj:Object = { };
					var doReturn:Boolean = false;
					for each(var callObj:Object in calls) {
						var ret:* = doCall(callObj.meth, callObj.args);
						if (callObj.retId != -1) {
							returnObj[String(callObj.retId)] = ret;
							doReturn = true;
						}
					}
					if(doReturn)_backToMain.send({returns:returnObj});
				}
			}catch (e:Error) {
				log(String(e));
			}
		}
		
		public function doCall(methName:String, args:Array):* {
			var target:Object;
			if (methName == "setFPS") {
				target = this; // this is a temporary solution till we find a way around some weird bytearray index issue
			}else {
				if (methName == "setupSolver") {
					if (!args[4]) {
						// if not drawing fluid, set isRGB to -1
						args[5] = -1;
					}
				}
				target = FluidSolverCrossbridge;
			}
			for (var j:int = 0; j < args.length; ++j) {
				var val:* = args[j];
				if (typeof(val)=="boolean") {
					args[j] = (val?1:0);
				}
			}
			//log("call: " + methName + " " + args);
			
			var ret:* = target[methName].apply(target, args);
			
			if(methName=="setupSolver"){
				
				ApplicationDomain.currentDomain.domainMemory.shareable = true;
				_worker.setSharedProperty("sharedBytes", ApplicationDomain.currentDomain.domainMemory);
				
				_worker.setSharedProperty("fluidImagePos", FluidSolverCrossbridge.getFluidImagePos());
				_worker.setSharedProperty("maxParticlesPos", FluidSolverCrossbridge.getMaxParticlesPos());
				_worker.setSharedProperty("particlesCountPos", FluidSolverCrossbridge.getParticlesCountPos());
				_worker.setSharedProperty("particlesDataPos", FluidSolverCrossbridge.getParticlesDataPos());
				_worker.setSharedProperty("particleEmittersPos", FluidSolverCrossbridge.getParticleEmittersPos());
			
				addEventListener(Event.ENTER_FRAME, onEnterFrame);
				_lastTime = getTimer();
			}
			return ret;
		}
		
		private function setFPS(value:int):void {
			stage.frameRate = value;
		}
	}
}