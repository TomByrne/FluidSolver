package  
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
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
		public static const PARTICLES:uint = 2000;
		
		public static const VELOCITY_MULTIPLIER:Number = 60;
		
		private var _fluidSolver:IFluidSolver;
		private var _fluidRenderer:IFluidRenderer;
		private var _lastMousePoint:Point;
		
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
			
			_fluidSolver.setupSolver(GRID_W, GRID_W / RENDER_W * RENDER_H, RENDER_W, RENDER_H, renderFluid, isRGB, doParticles, PARTICLES, 0,  onFluidSetup, fluidUpdate);
			_fluidSolver.setFPS(30);
			_fluidSolver.setGravity(0, -0.05);
			
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
		
		protected function onEnterFrame(e:Event):void {
			if (!_isInvalid) return;
			
			_isInvalid = false;
			_fluidRenderer.update();
		}
		
		
		protected function onMouseMove(e:MouseEvent):void 
		{
			var normX:Number = mouseX / RENDER_W;
			var normY:Number = mouseY / RENDER_H;
			
			var velX:Number = (mouseX - _lastMousePoint.x) / RENDER_W;
			var velY:Number = (mouseY - _lastMousePoint.y) / RENDER_H;
			if(_renderFluid){
				_fluidSolver.setForceAndColour(normX, normY, velX * VELOCITY_MULTIPLIER, velY * VELOCITY_MULTIPLIER, 1000, 30, 30);
			}else {
				_fluidSolver.setForce(normX, normY, velX * VELOCITY_MULTIPLIER, velY * VELOCITY_MULTIPLIER);
			}
			if(_doParticles){
				_fluidSolver.changeParticleEmitter(0, normX, normY, 5, 30, 30, 0.3, 0.7, 0.9);
			}
			
			_lastMousePoint.x = mouseX;
			_lastMousePoint.y = mouseY;
		}
	}

}