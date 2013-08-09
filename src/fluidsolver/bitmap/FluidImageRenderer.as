package fluidsolver.bitmap 
{
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import fluidsolver.core.IFluidRenderer;
	import fluidsolver.core.IFluidSolver;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class FluidImageRenderer implements IFluidRenderer
	{
		private var _width:int;
		private var _height:int;
		private var _bitmapData:BitmapData;
		private var _rect:Rectangle;
		private var _solver:IFluidSolver;
		
		public function get bitmapData():BitmapData {
			return _bitmapData;
		}
		
		public function FluidImageRenderer(width:int, height:int) 
		{
			_width = width;
			_height = height;
			_bitmapData = new BitmapData(width, height, false, 0);
			_rect = _bitmapData.rect;
		}
		
		public function solverInited(fluidSolver:IFluidSolver):void {
			_solver = fluidSolver;
		}
		
		public function update():void {
			_solver.sharedBytes.position = _solver.fluidImagePos;
			_bitmapData.setPixels(_rect, _solver.sharedBytes);
		}
	}

}