package  
{
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.debug.Debug;
	import away3d.materials.MaterialBase;
	import away3d.materials.TextureMaterial;
	import away3d.textures.BitmapTexture;
	import flash.display.BlendMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import fluidsolver.away3d.AgalParticleRenderer;
	import fluidsolver.core.worker.FluidSolverWorkerIO;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class Worker_Away3d_Agal extends AbstractTest
	{
		private var view:View3D;
		private var texture1:BitmapTexture;
		private var texture2:BitmapTexture;
		private var renderer:AgalParticleRenderer;
		
		public function Worker_Away3d_Agal() 
		{
			view = new View3D();
			view.width = RENDER_W;
			view.height = RENDER_H;
			view.backgroundColor = 0x000000;
			addChild(view);
			
			texture1 = new BitmapTexture(new BLACK_STAMP().bitmapData);
			texture2 = new BitmapTexture(new ALPHA_STAMP().bitmapData);
			
			//Debug.active = true;
			
			renderer = new AgalParticleRenderer(PARTICLES, [makeMaterial1, makeMaterial2], -RENDER_W / 2, RENDER_H / 2);
			renderer.setScale(1, 0.5, 0.05);
			
			renderer.setScale(2, 2, 0.05);
			renderer.setAlpha(2, 0.5, 0);
			renderer.setColorTrans(2, 1, 2);
			
			view.scene.addChild(renderer.display);
			renderer.display.scale(1.9);
			
			super(new FluidSolverWorkerIO(), renderer, false, false, true);
			
			addChild(new AwayStats());
		}
		
		private function makeMaterial1():MaterialBase {
			var material:TextureMaterial = new TextureMaterial(texture1, false);
			material.alphaBlending = true;
			material.alpha = 1;
			material.blendMode = BlendMode.ADD;
			return material;
		}
		
		private function makeMaterial2():MaterialBase {
			var material:TextureMaterial = new TextureMaterial(texture2, false);
			material.alphaBlending = true;
			material.alpha = 1;
			return material;
		}
		
		override protected function onEnterFrame(e:Event):void {
			super.onEnterFrame(e);
			view.render();
		}
		override protected function onMouseMove(e:MouseEvent):void 
		{
			super.onMouseMove(e);
			
			renderer.setColorTrans(1, stage.mouseX / stage.stageWidth, 1,1, 0, -stage.mouseY / stage.stageHeight , 0);
		}
	}

}