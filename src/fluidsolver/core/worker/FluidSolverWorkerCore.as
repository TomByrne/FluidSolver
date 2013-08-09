package  fluidsolver.core.worker
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import fluidsolver.core.crossbridge.CModule;
	import fluidsolver.core.crossbridge.FluidSolverCrossbridge;
	import fluidsolver.utils.ConsoleProxy;
	
	/**
	 * ...
	 * @author Pete Shand
	 */
	public class FluidSolverWorkerCore extends Sprite
	{
		
		private var worker:Worker;
		private var mainToBack:MessageChannel;
		private var backToMain:MessageChannel;
		
		private var sentObject:*;
		
		public function FluidSolverWorkerCore():void 
		{
			
			CModule.vfs.console = new ConsoleProxy(log);
			
			worker = Worker.current;
			
			mainToBack = worker.getSharedProperty("mainToBack");
			if (mainToBack) {
				mainToBack.addEventListener(Event.CHANNEL_MESSAGE, onMainToBack);
			}
			
			backToMain = worker.getSharedProperty("backToMain");
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		protected function onEnterFrame(event:Event):void {
			FluidSolverCrossbridge.updateSolver(0.5);
			
			var returnObject:Object = new Object();
			returnObject.msg = "RETURN";
			if (backToMain) backToMain.send(returnObject);
		}
		
		protected function log(... params):void
		{
			trace.apply(null, params);
			if(mainToBack)backToMain.send({calls: {"trace":params}});
		}
		
		protected function onMainToBack(event:Event):void {
			try{
				if (!mainToBack.messageAvailable) return;
				var sentObject:Object = mainToBack.receive();
				
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
					if(doReturn)backToMain.send({returns:returnObj});
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
				worker.setSharedProperty("sharedBytes", ApplicationDomain.currentDomain.domainMemory);
				
				worker.setSharedProperty("fluidImagePos", FluidSolverCrossbridge.getFluidImagePos());
				worker.setSharedProperty("maxParticlesPos", FluidSolverCrossbridge.getMaxParticlesPos());
				worker.setSharedProperty("particlesCountPos", FluidSolverCrossbridge.getParticlesCountPos());
				worker.setSharedProperty("particlesDataPos", FluidSolverCrossbridge.getParticlesDataPos());
				worker.setSharedProperty("particleImagePos", FluidSolverCrossbridge.getParticleImagePos());
				worker.setSharedProperty("particleEmittersPos", FluidSolverCrossbridge.getParticleEmittersPos());
				
				worker.setSharedProperty("rOldPos", FluidSolverCrossbridge.getROldPos());
				worker.setSharedProperty("gOldPos", FluidSolverCrossbridge.getGOldPos());
				worker.setSharedProperty("bOldPos", FluidSolverCrossbridge.getBOldPos());
				worker.setSharedProperty("uOldPos", FluidSolverCrossbridge.getUOldPos());
				worker.setSharedProperty("vOldPos", FluidSolverCrossbridge.getVOldPos());
			}
			return ret;
		}
		
		private function setFPS(value:int):void {
			stage.frameRate = value;
		}
	}
}