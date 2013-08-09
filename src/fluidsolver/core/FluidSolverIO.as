package fluidsolver.core 
{
	import flash.events.TimerEvent;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.setTimeout;
	import flash.utils.Timer;
	import fluidsolver.core.crossbridge.FluidSolverCrossbridge;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class FluidSolverIO implements IFluidSolver 
	{
		private var _updateTimer:Timer;
		private var _isSetup:Boolean;
		
		public function FluidSolverIO() 
		{
			setFPS(30);
		}
		public function setFPS(value:int, returnHandler:Function = null):void {
			if(_updateTimer){
				_updateTimer.removeEventListener(TimerEvent.TIMER, onUpdateTimer);
				_updateTimer.stop();
			}
			_updateTimer = new Timer(1000 / value, 0);
			_updateTimer.addEventListener(TimerEvent.TIMER, onUpdateTimer);
			if (_isSetup)_updateTimer.start();
			else _updateTimer.stop();
			
			if(returnHandler!=null)returnHandler();
		}
		private function onUpdateTimer(e:TimerEvent):void {
			FluidSolverCrossbridge.updateSolver(0.5);
		}
		public function setupSolver(gridWidth:int, gridHeight:int, screenW:int, screenH:int, drawFluid:Boolean, isRGB:Boolean, doParticles:Boolean, maxParticles:int=5000, cullAlpha:Number=0, returnHandler:Function=null):void {
			FluidSolverCrossbridge.setupSolver(gridWidth, gridHeight, screenW, screenH, drawFluid?1:0, isRGB?1:(drawFluid?0:-1), doParticles?1:0, maxParticles, cullAlpha);
			_isSetup = true;
			if(returnHandler!=null)returnHandler();
			_updateTimer.start();
		}
		public function addParticleEmitter(x:Number, y:Number, rate:Number, xSpread:Number, ySpread:Number, alphVar:Number, massVar:Number, decay:Number, returnHandler:Function = null):void {
			var ret:int = FluidSolverCrossbridge.addParticleEmitter(x, y, rate, xSpread, ySpread, alphVar, massVar, decay);
			if(returnHandler!=null)returnHandler(ret);
		}
		public function changeParticleEmitter(index:int, x:Number, y:Number, rate:Number, xSpread:Number, ySpread:Number, alphVar:Number, massVar:Number, decay:Number, returnHandler:Function=null):void {
			FluidSolverCrossbridge.changeParticleEmitter(index, x, y, rate, xSpread, ySpread, alphVar, massVar, decay);
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
		public function setForce(tx:Number, ty:Number, dx:Number, dy:Number, returnHandler:Function = null):void {
			FluidSolverCrossbridge.setForce(tx, ty, dx, dy);
			if(returnHandler!=null)returnHandler();
		}
		public function setColour(tx:Number, ty:Number, r:Number, g:Number, b:Number, returnHandler:Function = null):void {
			FluidSolverCrossbridge.setColour(tx, ty, r, g, b);
			if(returnHandler!=null)returnHandler();
		}
		public function setForceAndColour(tx:Number, ty:Number, dx:Number, dy:Number, r:Number, g:Number, b:Number, returnHandler:Function = null):void {
			FluidSolverCrossbridge.setForceAndColour(tx, ty, dx, dy, r, g, b);
			if(returnHandler!=null)returnHandler();
		}
		
		private var _sharedBytes:ByteArray;
		public function get sharedBytes():ByteArray {
			if(!_sharedBytes){
				_sharedBytes = ApplicationDomain.currentDomain.domainMemory;
			}
			return _sharedBytes;
		}
		public function get particlesCountPos():int {
			return FluidSolverCrossbridge.getParticlesCountPos();
		}
		public function get particlesDataPos():int {
			return FluidSolverCrossbridge.getParticlesDataPos();
		}
		public function get maxParticlesPos():int {
			return FluidSolverCrossbridge.getMaxParticlesPos();
		}
		public function get particleEmittersPos():int {
			return FluidSolverCrossbridge.getParticleEmittersPos();
		}
		public function get particleImagePos():int {
			return FluidSolverCrossbridge.getParticleImagePos();
		}
		public function get fluidImagePos():int {
			return FluidSolverCrossbridge.getFluidImagePos();
		}
		
		public function get rOldPos():int {
			return FluidSolverCrossbridge.getROldPos();
		}
		public function get gOldPos():int {
			return FluidSolverCrossbridge.getGOldPos();
		}
		public function get bOldPos():int {
			return FluidSolverCrossbridge.getBOldPos();
		}
		public function get uOldPos():int {
			return FluidSolverCrossbridge.getUOldPos();
		}
		public function get vOldPos():int {
			return FluidSolverCrossbridge.getVOldPos();
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