package  
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import fluidsolver.bitmap.UVRenderer;
	import fluidsolver.core.FluidSolverIO;
	import fluidsolver.core.worker.FluidSolverWorkerIO;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class Crossbridge_Bitmap_UV extends AbstractTest 
	{
		
		public function Crossbridge_Bitmap_UV() 
		{
			var stamp:BitmapData = new ALPHA_STAMP().bitmapData;
			var renderer:UVRenderer = new UVRenderer(RENDER_W, RENDER_H);
			addChild(new Bitmap(renderer.bitmapData, PixelSnapping.NEVER, false));
			super(new FluidSolverWorkerIO(), renderer, false, false, true);
		}
		
	}

}