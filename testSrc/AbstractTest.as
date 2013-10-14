package  
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import fluidsolver.core.FluidSolverEdgeType;
	import fluidsolver.core.IFluidRenderer;
	import fluidsolver.core.IFluidSolver;
	
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class AbstractTest extends Sprite 
	{
		[Embed(source="../embed/cloud.png", mimeType="image/png")]
		public static const ALPHA_STAMP:Class;
		
		[Embed(source="../embed/cloud-white.png", mimeType="image/png")]
		public static const WHITE_STAMP:Class;
		
		[Embed(source="../embed/cloud-black.png", mimeType="image/png")]
		public static const BLACK_STAMP:Class;
		
		public static const RENDER_W:uint = 960;
		public static const RENDER_H:uint = 540;
		public static const GRID_W:uint = 150;
		
		public static const VELOCITY_MULTIPLIER:Number = 200;
		
		public static const PARTICLES:Vector.<int> = Vector.<int>([500, 1000, 1000]);
		
		protected var _fluidSolver:IFluidSolver;
		protected var _fluidRenderer:IFluidRenderer;
		protected var _lastMousePoint:Point;
		
		private var _renderFluid:Boolean;
		private var _doParticles:Boolean;
		
		private var _isInvalid:Boolean;
		
		public function AbstractTest(solver:IFluidSolver, renderer:IFluidRenderer, renderFluid:Boolean, isRGB:Boolean, doParticles:Boolean):void {
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			_lastMousePoint = new Point(stage.mouseX, stage.mouseY);
			
			_fluidSolver = solver;
			
			_fluidRenderer = renderer;
			
			_renderFluid = renderFluid;
			_doParticles = doParticles;
			
			var gridH:int = GRID_W / RENDER_W * RENDER_H;
			_fluidSolver.setupSolver(GRID_W, gridH, RENDER_W, RENDER_H, renderFluid, isRGB, doParticles, PARTICLES,  onFluidSetup, fluidUpdate);
			_fluidSolver.setFPS(30);
			_fluidSolver.setEdgeTypes(FluidSolverEdgeType.KILL, FluidSolverEdgeType.KILL);
			_fluidSolver.fluidForce = 1;
			//_fluidSolver.viscosity = 0;
			
			_fluidSolver.setEmitterVariance(0, 30, 30, 0.3, 0.7, 0, 0);
			
			_fluidSolver.setEmitterProps(1, 0.49, 0.2, 100, 1, 0.9, -20, 40, 1);
			_fluidSolver.setEmitterVariance(1, 30, 30, 0, 0, 60, 0);
			
			_fluidSolver.setEmitterProps(2, 0.51, 0.2, 100, 1, 0.9, 20, 40, 1);
			_fluidSolver.setEmitterVariance(2, 30, 30, 0, 0, 60, 0);
			
			/*for (var i:int = 0; i < GRID_W; ++i){
				for (var j:int = 0; j < gridH; ++j) {
					_fluidSolver.setForce(i, j,  0.02 * (i / GRID_W<0.5?1:-1),0);
				}
			}*/
			
			// set up the jet stream
			/*const start:Number = 300;
			const dist:Number = (RENDER_W - start) / 8;
			const wobble:Number = 5;
			for (var i:int = 0; i < 7; ++i){
				var x:Number = (start+(dist * i)) / RENDER_W;
				var y:Number = (RENDER_H / 2 + (i % 1?wobble: -wobble)) / RENDER_H;
				_fluidSolver.changeParticleEmitter(i, x, y, 5, 30, 30, 0.3, 0.7, 1);
			}*/
		}
		protected function onFluidSetup():void {
			_fluidRenderer.solverInited(_fluidSolver);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		protected function fluidUpdate():void {
			_isInvalid = true;
		}
		
		private var _row:int = 0;
		private var _col:int = 0;
		protected function onEnterFrame(e:Event):void {
			if (!_isInvalid) return;
			
			var gridH:int = GRID_W / RENDER_W * RENDER_H;
			
			for (var j:int = 0; j < gridH; ++j) {
				_fluidSolver.setForce(_col, j, 0, 0.02 * (j/ gridH < 0.5?1:-1));
			}
			_col++;
			if (_col == GRID_W)_col = 0;
			
			/*_fluidSolver.setForce(_col, _row,  0.02 * (_col / GRID_W < 0.5?1: -1), 0);
			_row++;
			if (_row == gridH) {
				_row = 0;
				_col++;
				if (_col == GRID_W)_col = 0;
			}*/
			
			
			_isInvalid = false;
			_fluidRenderer.update();
		}
		
		
		protected function onMouseMove(e:MouseEvent):void 
		{
			var normX:Number = mouseX / RENDER_W;
			var normY:Number = mouseY / RENDER_H;
			
			//_fluidSolver.setGravity(0, 200 * normX);
			
			var velX:Number = (mouseX - _lastMousePoint.x) / RENDER_W;
			var velY:Number = (mouseY - _lastMousePoint.y) / RENDER_H;
			var gridH:int = GRID_W / RENDER_W * RENDER_H;
			/*if (_renderFluid) {
				_fluidSolver.setColour(normX * GRID_W, normY * gridH, 1000, 30, 30);
				//_fluidSolver.setForceAndColour(normX * GRID_W, normY * gridH, velX * VELOCITY_MULTIPLIER, velY * VELOCITY_MULTIPLIER, 1000, 30, 30);
			}else {
				_fluidSolver.setForce(normX * GRID_W, normY * gridH, velX * VELOCITY_MULTIPLIER, velY * VELOCITY_MULTIPLIER);
			}*/
			if(_doParticles){
				_fluidSolver.setEmitterProps(0, normX, normY, 5, 0.9, 0.9, 0, 0, 1);
			}
			
			_lastMousePoint.x = mouseX;
			_lastMousePoint.y = mouseY;
		}
	}

}