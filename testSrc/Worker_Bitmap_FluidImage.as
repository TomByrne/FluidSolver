package  
{
	import away3d.debug.AwayStats;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import fluidsolver.core.worker.FluidSolverWorkerIO;
	import fluidsolver.bitmap.FluidImageRenderer;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class Worker_Bitmap_FluidImage extends AbstractTest 
	{
		
		public function Worker_Bitmap_FluidImage() 
		{
			var renderer:FluidImageRenderer = new FluidImageRenderer(GRID_W, GRID_W / RENDER_W * RENDER_H);
			var bitmap:Bitmap = new Bitmap(renderer.bitmapData, PixelSnapping.NEVER, true);
			bitmap.width = RENDER_W;
			bitmap.height = RENDER_H;
			addChild(bitmap);
			super(new FluidSolverWorkerIO(), renderer, true, true, false);
			
			addChild(new AwayStats());
		}
		
	}

}