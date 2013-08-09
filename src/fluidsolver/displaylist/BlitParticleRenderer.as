package fluidsolver.displaylist 
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
		private var _stamp:BitmapData;
		private var _solver:IFluidSolver;
		private var _sharedMemory:CustomMemory;
		private var _backgroundColor:uint;
		private var _blendMode:String;
		
		private var _colorMatAffector:Function;
		private var _transformAffector:Function;
		
		private var _matrix:Matrix;
		private var _colorTrans:ColorTransform;
		
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
		}
		public function setParticleStamp(stamp:BitmapData):void {
			_stamp = stamp;
		}
		public function setTransformAffector(value:Function):void {
			_transformAffector = value;
		}
		public function setColorMatAffector(value:Function):void {
			_colorMatAffector = value;
		}
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
			//_sharedMemory.byteArray.position = 0;
			var pos:int = _sharedMemory.readInt(_solver.particlesDataPos);
			var pn:int = _sharedMemory.readInt(_solver.particlesCountPos);
			//var pos:int = 0;
			//var pn:int = _sharedMemory.readInt(0);
			
			var step:int = 8 << 2;
			var aa:int, x:int, y:int, velX:int, velY:int, pixelColor:uint;
			var alpha:Number;
			
			_bitmapData.lock();
			_bitmapData.copyPixels(_clearColour, _bitmapData.rect, new Point());
			
			while( --pn > -1 )
			{
				alpha = _sharedMemory.readFloat(pos + 0);
				x = int( _sharedMemory.readFloat(pos + 4) + 0.5 );
				y = int( _sharedMemory.readFloat(pos + 8) + 0.5 );
				velX = int( _sharedMemory.readFloat(pos + 12) + 0.5 );
				velY = int( _sharedMemory.readFloat(pos + 16) + 0.5 );
				pixelColor = (aa << 24) | (aa << 16) | (aa << 8) | aa; // temporary, should get pixel value from fluid image
				
				_matrix.identity();
				if (_transformAffector != null) {
					_transformAffector(_matrix, x, y, velX, velY, alpha, pixelColor);
				}else {
					_matrix.tx = x - (_stamp.width / 2);
					_matrix.ty = y - (_stamp.height / 2);
				}
				
				_colorTrans.redMultiplier = 1;
				_colorTrans.greenMultiplier = 1;
				_colorTrans.blueMultiplier = 1;
				_colorTrans.alphaMultiplier = 1;
				
				_colorTrans.redOffset = 0;
				_colorTrans.greenOffset = 0;
				_colorTrans.blueOffset = 0;
				_colorTrans.alphaOffset = 0;
				
				if (_colorMatAffector != null) {
					_colorMatAffector(_colorTrans, x, y, velX, velY, alpha, pixelColor);
				}else {
					_colorTrans.alphaMultiplier = alpha;
				}
				_bitmapData.draw(_stamp, _matrix, _colorTrans, _blendMode);
				
				
				pos += step;
			}
			
			_bitmapData.unlock(_bitmapData.rect);
		}
	}

}