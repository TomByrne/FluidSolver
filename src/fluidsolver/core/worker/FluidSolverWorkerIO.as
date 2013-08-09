package  fluidsolver.core.worker
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	import fluidsolver.core.IFluidSolver;
	
	
	
	public class FluidSolverWorkerIO implements IFluidSolver
	{
		[Embed(source="../../../../bin/worker.swf", mimeType="application/octet-stream")]
		private var WorkerSWF:Class;
		private var swfByteArray:ByteArray;
		
		public var collateCalls:Boolean = false;
		
		private var worker:Worker;
		private var mainToBack:MessageChannel;
		private var backToMain:MessageChannel;
		
		public var isInited:Boolean;
		private var _lastHandlerId:int = 0;
		private var _returnHandlerLookup:Dictionary = new Dictionary();
		
		private var _pendingCalls:Object;
		
		public function FluidSolverWorkerIO() 
		{
			swfByteArray = new WorkerSWF();
			worker = WorkerDomain.current.createWorker(swfByteArray, true);
			mainToBack = Worker.current.createMessageChannel(worker);
			backToMain = worker.createMessageChannel(Worker.current);
			
			backToMain.addEventListener(Event.CHANNEL_MESSAGE, onBackToMain, false, 0, true);
			worker.setSharedProperty("backToMain", backToMain);
			worker.setSharedProperty("mainToBack", mainToBack);
			
			worker.start();
			
			setFPS(30);
		}
		public function setFPS(value:int, returnHandler:Function=null):void {
			appendCall("setFPS",[registerCall(returnHandler), value]);
		}
		public function setupSolver(gridWidth:int, gridHeight:int, screenW:int, screenH:int, drawFluid:Boolean, isRGB:Boolean, doParticles:Boolean, maxParticles:int=5000, cullAlpha:Number=0, returnHandler:Function=null):void {
			appendCall("setupSolver",[registerCall(returnHandler), gridWidth, gridHeight, screenW, screenH, drawFluid, isRGB, doParticles, maxParticles, cullAlpha]);
		}
		public function addParticleEmitter(x:Number, y:Number, rate:Number, xSpread:Number, ySpread:Number, alphVar:Number, massVar:Number, decay:Number, returnHandler:Function=null):void {
			appendCall("addParticleEmitter",[registerCall(returnHandler), x, y, rate, xSpread, ySpread, alphVar, massVar, decay]);
		}
		public function changeParticleEmitter(index:int, x:Number, y:Number, rate:Number, xSpread:Number, ySpread:Number, alphVar:Number, massVar:Number, decay:Number, returnHandler:Function=null):void {
			appendCall("changeParticleEmitter",[registerCall(returnHandler), index, x, y, rate, xSpread, ySpread, alphVar, massVar, decay]);
		}
		public function updateSolver(timeDelta:Number, returnHandler:Function=null):void {
			appendCall("updateSolver",[registerCall(returnHandler), timeDelta]);
		}
		public function clearParticles(returnHandler:Function=null):void {
			appendCall("clearParticles",[registerCall(returnHandler)]);
		}
		public function setForce(tx:Number, ty:Number, dx:Number, dy:Number, returnHandler:Function=null):void {
			appendCall("setForce",[registerCall(returnHandler), tx, ty, dx, dy]);
		}
		public function setColour(tx:Number, ty:Number, r:Number, g:Number, b:Number, returnHandler:Function=null):void{
			appendCall("setColour",[registerCall(returnHandler), tx, ty, r, g, b]);
		}
		public function setForceAndColour(tx:Number, ty:Number, dx:Number, dy:Number, r:Number, g:Number, b:Number, returnHandler:Function=null):void{
			appendCall("setForceAndColour",[registerCall(returnHandler), tx, ty, dx, dy, r, g, b]);
		}
		
		private function appendCall(methodName:String, args:Array):void {
			if (isInited && !collateCalls) {
				var obj:Object = { };
				obj[methodName] = args;
				mainToBack.send({calls:obj});
			}else {
				if (!_pendingCalls)_pendingCalls = { };
				_pendingCalls[methodName] = args;
			}
		}
		public function executeCalls():void {
			if (isInited)_executeCalls();
		}
		private function _executeCalls():void {
			if (_pendingCalls) {
				mainToBack.send({calls:_pendingCalls});
				_pendingCalls = null;
			}
		}
		
		private function registerCall(returnHandler:Function):int {
			if (returnHandler != null) {
				_returnHandlerLookup[_lastHandlerId] = returnHandler;
				return _lastHandlerId++;
			}else {
				return -1;
			}
		}
		
		/*public function send(object:Object):void
		{
			mainToBack.send(object);
		}*/
		
		protected function onBackToMain(event:Event):void 
		{
			//var returnObject:* = MessageChannel(event.target).receive();
			//workerFinished.dispatch(returnObject);
			
			if (!backToMain.messageAvailable) return;
			var returnObject:Object = backToMain.receive();
			
			if (!isInited) {
				isInited = true;
				_executeCalls();
			}
			
			var returns:Object = returnObject.returns;
			for (var i:String in returns) {
				var id:int = parseInt(i);
				var handler:Function = _returnHandlerLookup[id];
				handler.apply(null, returns[i]);
				delete _returnHandlerLookup[id];
			}
		 
			var calls:Object = returnObject.calls;
			if (calls) {
				var didSetup:Boolean = false;
				var returnObj:Object = { };
				var doReturn:Boolean = false;
				for (i in calls) {
					if (i == "setupSolver") {
						didSetup = true;
					}
					var args:Array = calls[i];
					var target:Object = this;
					if (i == "trace") {
						trace.apply(null, args);
						continue;
					}
					id = args.shift();
					//trace(this, "main-call: "+i+" "+args);
					var ret:* = target[i].apply(target, args);
					if (id != -1) {
						returnObj[String(id)] = ret;
						doReturn = true;
					}
				}
				if(doReturn)backToMain.send(returnObj);
			}
			
		}
		
		private var _sharedBytes:ByteArray;
		public function get sharedBytes():ByteArray {
			if(!_sharedBytes){
				_sharedBytes = worker.getSharedProperty("sharedBytes");
				_sharedBytes.endian = Endian.LITTLE_ENDIAN;
			}
			return _sharedBytes;
		}
		public function get particlesCountPos():int {
			return worker.getSharedProperty("particlesCountPos");
		}
		public function get particlesDataPos():int {
			return worker.getSharedProperty("particlesDataPos");
		}
		public function get maxParticlesPos():int {
			return worker.getSharedProperty("maxParticlesPos");
		}
		public function get particleEmittersPos():int {
			return worker.getSharedProperty("particleEmittersPos");
		}
		public function get particleImagePos():int {
			return worker.getSharedProperty("particleImagePos");
		}
		public function get fluidImagePos():int {
			return worker.getSharedProperty("fluidImagePos");
		}
		
		public function get rOldPos():int {
			return worker.getSharedProperty("rOldPos");
		}
		public function get gOldPos():int {
			return worker.getSharedProperty("gOldPos");
		}
		public function get bOldPos():int {
			return worker.getSharedProperty("bOldPos");
		}
		public function get uOldPos():int {
			return worker.getSharedProperty("uOldPos");
		}
		public function get vOldPos():int {
			return worker.getSharedProperty("vOldPos");
		}
		/*

		void setWrap(int wrapX, int wrapY);
		void setColorDiffusion(double colorDiffusion);
		void setSolverIterations(int solverIterations);
		void setVorticityConfinement(int doVorticityConfinement);
		void setFadeSpeed(double fadeSpeed);
		void setViscosity(double viscosity);*/
	}

}