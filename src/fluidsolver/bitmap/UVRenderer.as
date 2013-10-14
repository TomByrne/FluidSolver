package fluidsolver.bitmap 
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.utils.Endian;
	import fluidsolver.core.IFluidRenderer;
	import fluidsolver.core.IFluidSolver;
	import fluidsolver.utils.CustomMemory;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class UVRenderer implements IFluidRenderer
	{
		private var _width:int;
		private var _height:int;
		private var _bitmapData:BitmapData;
		private var _clearColour:BitmapData;
		private var _solver:IFluidSolver;
		private var _sharedMemory:CustomMemory;
		private var _lineColour:uint;
		private var _backgroundColor:uint;
		
		private var _renderInfo:Array;
		
		public function get bitmapData():BitmapData {
			return _bitmapData;
		}
		
		public function UVRenderer(width:int, height:int, lineColour:uint=0xffffffff, backgroundColour:uint=0xff000000) 
		{
			_width = width;
			_height = height;
			_lineColour = lineColour;
			_backgroundColor = backgroundColour;
			
			var transparent:Boolean = ((backgroundColour >> 24) & 0xff != 0xff ? true:false);
			
			_bitmapData = new BitmapData(width, height, transparent, backgroundColour);
			_clearColour = new BitmapData(width, height, transparent, backgroundColour);
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
			
			var cells:int = _solver.gridWidth * _solver.gridHeight;
			var gridW2:int = _solver.gridWidth + 2;
			for (var i:int = 0; i < cells; i++) {
				var x:int = int(i / _solver.gridWidth);
				var y:int = i % _solver.gridWidth;
				
				//(int)(x/ screenW * gridW+1.5) + (int)(y / screenH * gridH+1.5) * gridW2;
				
				var index:int = i * 8
				
				_solver.sharedBytes.position = _solver.uPos + index;
				var u:Number = _solver.sharedBytes.readDouble();
				
				_solver.sharedBytes.position = _solver.vPos + index;
				var v:Number = _solver.sharedBytes.readDouble();
				
				if (!(u + v)) continue;
				
				/*u *= 100;
				v *= 100;*/
				
				trace("\t> "+x,y,u,v);
				//drawLine(x + 0.5 - u, y + 0.5 - v, x + 0.5 + u, y + 0.5 + v, _lineColour);
			}
			
			_bitmapData.unlock(_bitmapData.rect);
		}
		private function drawLine(x:int, y:int, x2:int, y2:int, color:uint):void
		{
			var shortLen:int = y2-y;
			var longLen:int = x2 - x;
			if((shortLen ^ (shortLen >> 31)) - (shortLen >> 31) > (longLen ^ (longLen >> 31)) - (longLen >> 31)){
				shortLen ^= longLen;
				longLen ^= shortLen;
				shortLen ^= longLen;

				var yLonger:Boolean = true;
			}else{
				yLonger = false;
			}

			var inc:int = longLen < 0 ? -1 : 1;

			var multDiff:Number = longLen == 0 ? shortLen : shortLen / longLen;

			var x:int;
			var y:int;
			if (yLonger) {
				for (var i:int = 0; i != longLen; i += inc) {
					x = x + i * multDiff;
					if (x<0 || x>=_bitmapData.width)continue;
					y = y + i;
					if (y<0 || y>=_bitmapData.height)continue;
					_bitmapData.setPixel(x,y, color);
				}
			}else{
				for (i = 0; i != longLen; i += inc){
					x = x + i;
					if (x<0 || x>=_bitmapData.width)continue;
					y = y + i * multDiff;
					if (y<0 || y>=_bitmapData.height)continue;
					_bitmapData.setPixel(x,y, color);
				}
			}
		}
		/*private function drawLine(x0:int, y0:int, x1:int, y1:int, color:int):void
		{
			var dy:int = y1 - y0;
			var dx:int = x1 - x0;
			var stepx:int, stepy:int, fraction:int;

			if (dy < 0) { dy = -dy;  stepy = -_bitmapData.width; } else { stepy = _bitmapData.width; }
			if (dx < 0) { dx = -dx;  stepx = -1; } else { stepx = 1; }
			dy <<= 1;
			dx <<= 1;

			y0 *= _bitmapData.width;
			y1 *= _bitmapData.height;
			_bitmapData.setPixel(x0,y0, color);
			if (dx > dy) {
				fraction = dy - (dx>>1);
				while (x0 != x1) {
					if (fraction >= 0) {
						y0 += stepy;
						fraction -= dx;
					}
					x0 += stepx;
					fraction += dy;
					_bitmapData.setPixel(x0,y0, color);
				}
			} else {
				fraction = dx - (dy>>1);
				while (y0 != y1) {
					if (fraction >= 0) {
						x0 += stepx;
						fraction -= dy;
					}
					y0 += stepy;
					fraction += dx;
					_bitmapData.setPixel(x0,y0, color);
				}
			}
		}*/
	}
}