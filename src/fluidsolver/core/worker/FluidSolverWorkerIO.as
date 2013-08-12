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
		public function setupSolver(gridWidth:int, gridHeight:int, screenW:int, screenH:int, drawFluid:Boolean, isRGB:Boolean, doParticles:Boolean, emitterCounts:Vector.<int>=null, returnHandler:Function = null, updateHandler:Function = null):void {
			_updateHandler = updateHandler;
			appendCall("setupSolver",[gridWidth, gridHeight, screenW, screenH, drawFluid?1:0, isRGB?1:(drawFluid?0:-1), doParticles?1:0, emitterCounts?emitterCounts.join(","):""],registerCall(returnHandler));
			appendCall("getViscosity",[],registerCall(_gotViscosity));
			appendCall("getFadeSpeed",[],registerCall(_gotFadeSpeed));
			appendCall("getVorticityConfinement",[],registerCall(_gotVorticityConfinement));
			appendCall("getSolverIterations",[],registerCall(_gotSolverIterations));
			appendCall("getColorDiffusion",[],registerCall(_gotColorDiffusion));
		}
		public function addParticleEmitter(x:Number, y:Number, rate:Number, xSpread:Number, ySpread:Number, ageVar:Number, massVar:Number, emDecay:Number, partDecay:Number, initVX:Number, initVY:Number, returnHandler:Function=null):void {
			appendCall("addParticleEmitter",[x, y, rate, xSpread, ySpread, ageVar, massVar, emDecay, partDecay, initVX, initVY],registerCall(returnHandler));
		}
		public function changeParticleEmitter(index:int, x:Number, y:Number, rate:Number, xSpread:Number, ySpread:Number, ageVar:Number, massVar:Number, emDecay:Number, partDecay:Number, initVX:Number, initVY:Number, returnHandler:Function=null):void {
			appendCall("changeParticleEmitter",[index, x, y, rate, xSpread, ySpread, ageVar, massVar, emDecay, partDecay, initVX, initVY],registerCall(returnHandler));
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
		public function setWrapping(x:Boolean, y:Boolean, returnHandler:Function=null):void{
			appendCall("setWrapping",[x?1:0, y?1:0],registerCall(returnHandler));
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
				var returned:* = returns[i]
				handler.apply(null, returned!=null?[returned]:null);
				delete _returnHandlerLookup[id];
			}
		 
			var calls:Object = returnObject.calls;
			if (calls) {
				var returnObj:Object = { };
				var doReturn:Boolean = false;
				for (i in calls) {
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
				if(doReturn)mainToBack.send(returnObj);
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
		public function get emittersSetPos():int {
			return worker.getSharedProperty("emittersSetPos");
		}
		public function get particlesCountPos():int {
			return worker.getSharedProperty("particlesCountPos");
		}
		public function get particlesMaxPos():int {
			return worker.getSharedProperty("particlesMaxPos");
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
		
		
		private function _gotViscosity(value:Number):void {
			_viscosity = value;
		}
		private function _gotFadeSpeed(value:Number):void {
			_fadeSpeed = value;
		}
		private function _gotVorticityConfinement(value:int):void {
			_vorticityConfinement = value==1;
		}
		private function _gotSolverIterations(value:int):void {
			_solverIterations = value;
		}
		private function _gotColorDiffusion(value:Number):void {
			_colorDiffusion = value;
		}
		
		private var _speed:Number = 1;
		public function get speed():Number {
			return _speed;
		}
		public function set speed(value:Number):void {
			_speed = value;
			appendCall("setSpeed",[value],-1);
		}
		
		private var _viscosity:Number;
		public function get viscosity():Number {
			return _viscosity;
		}
		public function set viscosity(value:Number):void {
			_viscosity = value;
			appendCall("setViscosity",[value],-1);
		}
		
		private var _fadeSpeed:Number;
		public function get fadeSpeed():Number {
			return _fadeSpeed;
		}
		public function set fadeSpeed(value:Number):void {
			_fadeSpeed = value;
			appendCall("setFadeSpeed",[value],-1);
		}
		
		private var _vorticityConfinement:Boolean;
		public function get vorticityConfinement():Boolean {
			return _vorticityConfinement;
		}
		public function set vorticityConfinement(value:Boolean):void {
			_vorticityConfinement = value;
			appendCall("setVorticityConfinement",[value?1:0],-1);
		}
		
		private var _solverIterations:int;
		public function get solverIterations():int {
			return _solverIterations;
		}
		public function set solverIterations(value:int):void {
			_solverIterations = value;
			appendCall("setSolverIterations",[value],-1);
		}
		
		private var _colorDiffusion:Number;
		public function get colorDiffusion():Number {
			return _colorDiffusion;
		}
		public function set colorDiffusion(value:Number):void {
			_colorDiffusion = value;
			appendCall("setColorDiffusion",[value],-1);
		}
	}

}