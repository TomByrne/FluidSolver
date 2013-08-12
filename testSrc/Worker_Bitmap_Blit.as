package  
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.PixelSnapping;
	import fluidsolver.core.worker.FluidSolverWorkerIO;
	import fluidsolver.bitmap.BlitParticleRenderer;
	import fluidsolver.utils.ColorTransUtils;
	import fluidsolver.utils.TransformUtils;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class Worker_Bitmap_Blit extends AbstractTest 
	{
		
		public function Worker_Bitmap_Blit() 
		{
			var stamp:BitmapData = new ALPHA_STAMP().bitmapData;
			var renderer:BlitParticleRenderer = new BlitParticleRenderer(RENDER_W, RENDER_H, false, 0xffffffff);
			renderer.setEmitterRender(0, stamp, TransformUtils.scale(stamp.width, stamp.height, 1, 10), ColorTransUtils.tint(0x05b5f1, 0.75, -150));
			renderer.setEmitterRender(1, stamp, TransformUtils.scale(stamp.width, stamp.height, 2, 4));
			//renderer.setTransformAffector(TransformUtils.scale(stamp.width, stamp.height, 1, 10));
			//renderer.setColorMatAffector(ColorTransUtils.tint(0x05b5f1, 0.75, -150));
			addChild(new Bitmap(renderer.bitmapData, PixelSnapping.NEVER, false));
			super(new FluidSolverWorkerIO(), renderer, false, false, true);
		}
		
	}

}