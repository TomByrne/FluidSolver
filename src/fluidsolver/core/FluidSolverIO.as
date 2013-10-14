package fluidsolver.core 
{
	import flash.events.TimerEvent;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.setTimeout;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import fluidsolver.core.crossbridge.CModule;
	import fluidsolver.core.crossbridge.FluidSolverCrossbridge;
	import fluidsolver.utils.ConsoleProxy;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class FluidSolverIO implements IFluidSolver 
	{
		private var _updateTimer:Timer;
		private var _isSetup:Boolean;
		private var _lastTime:int;
		private var _updateHandler:Function;
		private var _speed:Number = 1;
		private var _gridW:int;
		private var _gridH:int;
		
		public function FluidSolverIO() 
		{
			setFPS(30);
			
			CModule.vfs.console = new ConsoleProxy(trace);
		}
		public function setFPS(value:int, returnHandler:Function = null):void {
			if(_updateTimer){
				_updateTimer.removeEventListener(TimerEvent.TIMER, onUpdateTimer);
				_updateTimer.stop();
			}
			_updateTimer = new Timer(1000 / value, 0);
			_updateTimer.addEventListener(TimerEvent.TIMER, onUpdateTimer);
			if (_isSetup) {
				_lastTime = getTimer();
				_updateTimer.start();
			}else {
				_updateTimer.stop();
			}
			
			if(returnHandler!=null)returnHandler();
		}
		
		private function onUpdateTimer(e:TimerEvent):void {
			var time:int = getTimer();
			FluidSolverCrossbridge.updateSolver((time-_lastTime) / 100 * _speed);
			_lastTime = time;
			if (_updateHandler != null)_updateHandler();
		}
		
		public function setupSolver(gridWidth:int, gridHeight:int, screenW:int, screenH:int, drawFluid:Boolean, isRGB:Boolean, doParticles:Boolean, emitterCounts:Vector.<int>=null, returnHandler:Function=null, updateHandler:Function=null):void {
			FluidSolverCrossbridge.setupSolver(gridWidth, gridHeight, screenW, screenH, drawFluid?1:0, isRGB?1:(drawFluid?0:-1), doParticles?1:0, emitterCounts?emitterCounts.join(","):"");
			_isSetup = true;
			if (returnHandler != null) returnHandler();
			_lastTime = getTimer();
			_updateTimer.start();
			_updateHandler = updateHandler;
			_gridW = gridWidth;
			_gridH = gridHeight;
		}
		public function addEmitter(x:Number, y:Number, rate:Number, emDecay:Number, partDecay:Number, initVX:Number, initVY:Number, initMass:Number, returnHandler:Function = null):void {
			var ret:int = FluidSolverCrossbridge.addEmitter(x, y, rate, emDecay, partDecay, initVX, initVY, initMass);
			if(returnHandler!=null)returnHandler(ret);
		}
		public function setEmitterProps(index:int, x:Number, y:Number, rate:Number, emDecay:Number, partDecay:Number, initVX:Number, initVY:Number, initMass:Number, returnHandler:Function=null):void {
			FluidSolverCrossbridge.setEmitterProps(index, x, y, rate, emDecay, partDecay, initVX, initVY, initMass);
			if(returnHandler!=null)returnHandler();
		}
		public function setEmitterVariance(index:int, xSpread:Number, ySpread:Number, ageVar:Number, massVar:Number, vxVar:Number, vyVar:Number, returnHandler:Function=null):void {
			FluidSolverCrossbridge.setEmitterVariance(index, xSpread, ySpread, ageVar, massVar, vxVar, vyVar);
			if(returnHandler!=null)returnHandler();
		}
		public function updateSolver(timeDelta:Number, returnHandler:Function=null):void {
			FluidSolverCrossbridge.updateSolver(timeDelta);
			if(returnHandler!=null)returnHandler();
		}
		public function clearParticles(returnHandler:Function = null):void {
			FluidSolverCrossbridge.clearParticles();
			if(returnHandler!=null)returnHandler();
		}
		public function setForce(x:int, y:int, dx:Number, dy:Number, returnHandler:Function = null):void {
			FluidSolverCrossbridge.setForce(x, y, dx, dy);
			if(returnHandler!=null)returnHandler();
		}
		public function setColour(x:int, y:int, r:Number, g:Number, b:Number, returnHandler:Function = null):void {
			FluidSolverCrossbridge.setColour(x, y, r, g, b);
			if(returnHandler!=null)returnHandler();
		}
		public function setForceAndColour(x:int, y:int, dx:Number, dy:Number, r:Number, g:Number, b:Number, returnHandler:Function = null):void {
			FluidSolverCrossbridge.setForceAndColour(x, y, dx, dy, r, g, b);
			if(returnHandler!=null)returnHandler();
		}
		public function setGravity(x:Number, y:Number, returnHandler:Function = null):void {
			FluidSolverCrossbridge.setGravity(x, y);
			if(returnHandler!=null)returnHandler();
		}
		public function setEdgeTypes(x:int, y:int, returnHandler:Function = null):void {
			FluidSolverCrossbridge.setEdgeTypes(x, y);
			if(returnHandler!=null)returnHandler();
		}
		
		private var _sharedBytes:ByteArray;
		public function get sharedBytes():ByteArray {
			if(!_sharedBytes){
				_sharedBytes = ApplicationDomain.currentDomain.domainMemory;
			}
			return _sharedBytes;
		}
		public function get emittersSetPos():int {
			return FluidSolverCrossbridge.getEmittersSetPos();
		}
		public function get particlesCountPos():int {
			return FluidSolverCrossbridge.getParticlesCountPos();
		}
		public function get particlesMaxPos():int {
			return FluidSolverCrossbridge.getParticlesMaxPos();
		}
		public function get particlesDataPos():int {
			return FluidSolverCrossbridge.getParticlesDataPos();
		}
		public function get maxParticlesPos():int {
			return FluidSolverCrossbridge.getParticlesMaxPos();
		}
		public function get particleEmittersPos():int {
			return FluidSolverCrossbridge.getParticleEmittersPos();
		}
		public function get fluidImagePos():int {
			return FluidSolverCrossbridge.getFluidImagePos();
		}
		public function get uPos():int {
			return FluidSolverCrossbridge.getUPos();
		}
		public function get vPos():int {
			return FluidSolverCrossbridge.getVPos();
		}
		
		public function get speed():Number {
			return _speed;
		}
		public function set speed(value:Number):void {
			_speed = value;
		}
		
		public function get viscosity():Number {
			return FluidSolverCrossbridge.getViscosity();
		}
		public function set viscosity(value:Number):void {
			FluidSolverCrossbridge.setViscosity(value);
		}
		
		public function get fadeSpeed():Number {
			return FluidSolverCrossbridge.getFadeSpeed();
		}
		public function set fadeSpeed(value:Number):void {
			FluidSolverCrossbridge.setFadeSpeed(value);
		}
		
		public function get vorticityConfinement():Boolean {
			return FluidSolverCrossbridge.getVorticityConfinement()==1?true:false;
		}
		public function set vorticityConfinement(value:Boolean):void {
			FluidSolverCrossbridge.setVorticityConfinement(value?1:0);
		}
		
		public function get solverIterations():int {
			return FluidSolverCrossbridge.getSolverIterations();
		}
		public function set solverIterations(value:int):void {
			FluidSolverCrossbridge.setSolverIterations(value);
		}
		
		public function get colorDiffusion():Number {
			return FluidSolverCrossbridge.getColorDiffusion();
		}
		public function set colorDiffusion(value:Number):void {
			FluidSolverCrossbridge.setColorDiffusion(value);
		}
		
		public function get fluidForce():Number {
			return FluidSolverCrossbridge.getFluidForce();
		}
		public function set fluidForce(value:Number):void {
			FluidSolverCrossbridge.setFluidForce(value);
		}
		
		public function get gridWidth():int {
			return _gridW;
		}
		public function get gridHeight():int {
			return _gridH;
		}
	}

}