package  
{
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.materials.MaterialBase;
	import away3d.materials.TextureMaterial;
	import away3d.textures.BitmapTexture;
	import flash.display.BlendMode;
	import flash.events.Event;
	import fluidsolver.away3d.AgalParticleRenderer;
	import fluidsolver.core.FluidSolverIO;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class Crossbridge_Away3d_Agal extends AbstractTest
	{
		private var view:View3D;
		private var texture:BitmapTexture;
		
		public function Crossbridge_Away3d_Agal() 
		{
			view = new View3D();
			view.width = RENDER_W;
			view.height = RENDER_H;
			view.backgroundColor = 0x000000;
			addChild(view);
			
			texture = new BitmapTexture(new BLACK_STAMP().bitmapData);
			
			var renderer:AgalParticleRenderer = new AgalParticleRenderer(PARTICLES, makeMaterial, -RENDER_W/2, RENDER_H/2);
			
			view.scene.addChild(renderer.display);
			renderer.display.scale(1.9);
			
			super(new FluidSolverIO(), renderer);
			
			addChild(new AwayStats());
		}
		
		private function makeMaterial():MaterialBase {
			var material:TextureMaterial = new TextureMaterial(texture, false);
			material.alphaBlending = true;
			material.alpha = 1;
			material.blendMode = BlendMode.ADD;
			return material;
		}
		
		override protected function onEnterFrame(e:Event):void {
			super.onEnterFrame(e);
			view.render();
		}
	}

}