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
		
		public var _isInited:Boolean;
		private var _lastHandlerId:int = 0;
		private var _returnHandlerLookup:Dictionary = new Dictionary();
		
		private var _pendingCalls:Array;
		
		private var _updateHandler:Function;
		
		public function FluidSolverWorkerIO() 
		{
			swfByteArray = new WorkerSWF();
			worker = WorkerDomain.current.createWorker(swfByteArray, true);
			mainToBack = Worker.current.createMessageChannel(worker);
			backToMain = worker.createMessageChannel(Worker.current);
			
			backToMain.addEventListener(Event.CHANNEL_MESSAGE, onBackToMain, false, 0, true);
			worker.setSharedProperty("backToMain", backToMain);
			worker.setSharedProperty("mainToBack", mainToBack);
			worker.setSharedProperty("setFPS", setFPS);
			
			worker.start();
			
			setFPS(30);
		}
		public function setFPS(value:int, returnHandler:Function=null):void {
			appendCall("setFPS",[value],registerCall(returnHandler));
		}
		public function setupSolver(gridWidth:int, gridHeight:int, screenW:int, screenH:int, drawFluid:Boolean, isRGB:Boolean, doParticles:Boolean, maxParticles:int = 5000, cullAlpha:Number = 0, returnHandler:Function = null, updateHandler:Function = null):void {
			_updateHandler = updateHandler;
			appendCall("setupSolver",[gridWidth, gridHeight, screenW, screenH, drawFluid, isRGB, doParticles, maxParticles, cullAlpha],registerCall(returnHandler));
		}
		public function addParticleEmitter(x:Number, y:Number, rate:Number, xSpread:Number, ySpread:Number, alphVar:Number, massVar:Number, decay:Number, returnHandler:Function=null):void {
			appendCall("addParticleEmitter",[x, y, rate, xSpread, ySpread, alphVar, massVar, decay],registerCall(returnHandler));
		}
		public function changeParticleEmitter(index:int, x:Number, y:Number, rate:Number, xSpread:Number, ySpread:Number, alphVar:Number, massVar:Number, decay:Number, returnHandler:Function=null):void {
			appendCall("changeParticleEmitter",[index, x, y, rate, xSpread, ySpread, alphVar, massVar, decay],registerCall(returnHandler));
		}
		public function updateSolver(timeDelta:Number, returnHandler:Function=null):void {
			appendCall("updateSolver",[timeDelta],registerCall(returnHandler));
		}
		public function clearParticles(returnHandler:Function=null):void {
			appendCall("clearParticles",[],registerCall(returnHandler));
		}
		public function setForce(tx:Number, ty:Number, dx:Number, dy:Number, returnHandler:Function=null):void {
			appendCall("setForce",[tx, ty, dx, dy],registerCall(returnHandler));
		}
		public function setColour(tx:Number, ty:Number, r:Number, g:Number, b:Number, returnHandler:Function=null):void{
			appendCall("setColour",[tx, ty, r, g, b],registerCall(returnHandler));
		}
		public function setForceAndColour(tx:Number, ty:Number, dx:Number, dy:Number, r:Number, g:Number, b:Number, returnHandler:Function=null):void{
			appendCall("setForceAndColour",[tx, ty, dx, dy, r, g, b],registerCall(returnHandler));
		}
		public function setGravity(x:Number, y:Number, returnHandler:Function=null):void{
			appendCall("setGravity",[x, y],registerCall(returnHandler));
		}
		
		private function appendCall(methodName:String, args:Array, returnId:int):void {
			var callObj:Object = { meth:methodName, args:args, retId:returnId };
			if (_isInited && !collateCalls) {
				mainToBack.send({calls:[callObj]});
			}else {
				if (!_pendingCalls)_pendingCalls = [];
				_pendingCalls.push(callObj);
			}
		}
		public function executeCalls():void {
			if (_isInited)_executeCalls();
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
		
		protected function onBackToMain(event:Event):void 
		{
			if (!backToMain.messageAvailable) return;
			var returnObject:Object = backToMain.receive();
			
			if (!_isInited) {
				_isInited = true;
				_executeCalls();
			}
			if (returnObject.msg == "update" && _updateHandler!=null) {
				_updateHandler();
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
		public function get fluidImagePos():int {
			return worker.getSharedProperty("fluidImagePos");
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