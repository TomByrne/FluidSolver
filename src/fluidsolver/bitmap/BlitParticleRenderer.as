package fluidsolver.bitmap 
{
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import fluidsolver.core.IFluidRenderer;
	import fluidsolver.core.IFluidSolver;
	import fluidsolver.utils.CustomMemory;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class BlitParticleRenderer implements IFluidRenderer
	{
		private var _width:int;
		private var _height:int;
		private var _bitmapData:BitmapData;
		private var _clearColour:BitmapData;
		private var _solver:IFluidSolver;
		private var _sharedMemory:CustomMemory;
		private var _backgroundColor:uint;
		private var _blendMode:String;
		
		private var _matrix:Matrix;
		private var _colorTrans:ColorTransform;
		
		private var _renderInfo:Array;
		
		public function get bitmapData():BitmapData {
			return _bitmapData;
		}
		
		public function BlitParticleRenderer(width:int, height:int, transparent:Boolean = true, fillColor:uint = 0xffffffff) 
		{
			_width = width;
			_height = height;
			_backgroundColor = fillColor;
			_bitmapData = new BitmapData(width, height, transparent, fillColor);
			
			_clearColour = new BitmapData(width, height, transparent, fillColor);
			_matrix = new Matrix();
			_colorTrans = new ColorTransform();
			
			_renderInfo = [];
		}
		public function setEmitterRender(emitterIndex:int, stamp:BitmapData, transformAffector:Function = null, colorMatAffector:Function = null):void {
			var info:EmitterRenderInfo = _renderInfo[emitterIndex];
			if (!info) {
				info = new EmitterRenderInfo();
				_renderInfo[emitterIndex] = info;
			}
			info.stamp = stamp;
			info.transformAffector = transformAffector;
			info.colorMatAffector = colorMatAffector;
		}
		/*public function setTransformAffector(value:Function):void {
			_transformAffector = value;
		}
		public function setColorMatAffector(value:Function):void {
			_colorMatAffector = value;
		}*/
		public function setBlendMode(value:String):void {
			_blendMode = value;
		}
		
		public function solverInited(fluidSolver:IFluidSolver):void {
			_solver = fluidSolver;
		}
		
		public function update():void {
			if (!_sharedMemory) {
				_sharedMemory = new CustomMemory(_solver.sharedBytes);
			}
			
				
			_bitmapData.lock();
			_bitmapData.copyPixels(_clearColour, _bitmapData.rect, new Point());
			
			var step:int = 8 << 2;
			var emitters:int = _sharedMemory.readInt(_solver.emittersSetPos);
			var particleOffset:int = 0;
			
			for (var i:int = 0; i < emitters; ++i){
				var pn:int = _sharedMemory.readInt(_solver.particlesCountPos + i * 4);
				var pos:int = _sharedMemory.readInt(_solver.particlesDataPos) + particleOffset;
				particleOffset += _sharedMemory.readInt(_solver.particlesMaxPos + i * 4) * 8 * 4;
				
				var renderInfo:EmitterRenderInfo = _renderInfo[i];
				if (!renderInfo) {
					trace("No rendering information set for emitter "+i);
					continue;
				}
				
				var aa:int, x:int, y:int, velX:int, velY:int, pixelColor:uint;
				var alpha:Number;
				
				var stamp:BitmapData = renderInfo.stamp;
				var transformAffector:Function = renderInfo.transformAffector;
				var colorMatAffector:Function = renderInfo.colorMatAffector;
				
				while( --pn > -1 )
				{
					alpha = _sharedMemory.readFloat(pos + 0);
					x = int( _sharedMemory.readFloat(pos + 4) + 0.5 );
					y = int( _sharedMemory.readFloat(pos + 8) + 0.5 );
					velX = int( _sharedMemory.readFloat(pos + 12) + 0.5 );
					velY = int( _sharedMemory.readFloat(pos + 16) + 0.5 );
					pixelColor = (aa << 24) | (aa << 16) | (aa << 8) | aa; // temporary, should get pixel value from fluid image
					
					_matrix.identity();
					if (transformAffector != null) {
						transformAffector(_matrix, x, y, velX, velY, alpha, pixelColor);
					}else {
						_matrix.tx = x - (stamp.width / 2);
						_matrix.ty = y - (stamp.height / 2);
					}
					
					_colorTrans.redMultiplier = 1;
					_colorTrans.greenMultiplier = 1;
					_colorTrans.blueMultiplier = 1;
					_colorTrans.alphaMultiplier = 1;
					
					_colorTrans.redOffset = 0;
					_colorTrans.greenOffset = 0;
					_colorTrans.blueOffset = 0;
					_colorTrans.alphaOffset = 0;
					
					if (colorMatAffector != null) {
						colorMatAffector(_colorTrans, x, y, velX, velY, alpha, pixelColor);
					}else {
						_colorTrans.alphaMultiplier = alpha;
					}
					_bitmapData.draw(stamp, _matrix, _colorTrans, _blendMode);
					
					pos += step;
				}
			}
			_bitmapData.unlock(_bitmapData.rect);
		}
	}

}
import flash.display.BitmapData;
class EmitterRenderInfo {
	public var stamp:BitmapData;
	public var transformAffector:Function;
	public var colorMatAffector:Function;
}
