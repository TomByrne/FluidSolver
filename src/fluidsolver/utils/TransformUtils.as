package fluidsolver.utils 
{
	import flash.geom.Matrix;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class TransformUtils 
	{
		
		public static function scale(stampW:Number, stampH:Number, startScale:Number, endScale:Number):Function 
		{
			return function(matrix:Matrix, x:Number, y:Number, velX:Number, velY:Number, alpha:Number, pixelColor:Number):void {
				var scale:Number = startScale + (1 - alpha) * (endScale - startScale);
				matrix.a = scale;
				matrix.d = scale;
				matrix.tx = x - (stampW * scale / 2);
				matrix.ty = y - (stampH * scale / 2);
			}
		}
		
		// Issues with rotation
		/*public static function rotate(stampW:Number, stampH:Number, angleOffset:Number = 0):Function 
		{
			return function(matrix:Matrix, x:Number, y:Number, velX:Number, velY:Number, alpha:Number, pixelColor:Number):void {
				var rotation:Number = Math.atan(velY / velX) + angleOffset;
				matrix.rotate(rotation);
				var w:Number = (stampW / 2);
				var h:Number = (stampH / 2);
				matrix.tx = x - (w * Math.cos(rotation) + h * Math.sin(rotation));
				matrix.ty = y - (w * Math.sin(rotation) + h * Math.cos(rotation));
			}
		}
		
		public static function scaleRotate(stampW:Number, stampH:Number, startScale:Number, endScale:Number, angleOffset:Number = 0):Function 
		{
			return function(matrix:Matrix, x:Number, y:Number, velX:Number, velY:Number, alpha:Number, pixelColor:Number):void {
				var scale:Number = startScale + (1 - alpha) * (endScale - startScale);
				matrix.a = scale;
				matrix.d = scale;
				
				var w:Number = (stampW * scale / 2);
				var h:Number = (stampH * scale / 2);
				
				var rotation:Number = Math.atan(velY / velX) + angleOffset;
				matrix.rotate(rotation);
				var w:Number = (stampW / 2);
				var h:Number = (stampH / 2);
				matrix.tx = x - (w * Math.cos(rotation) + h * Math.sin(rotation));
				matrix.ty = y - (w * Math.sin(rotation) + h * Math.cos(rotation));
			}
		}*/
	}

}