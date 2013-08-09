package fluidsolver.utils 
{
	import flash.geom.ColorTransform;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class ColorTransUtils 
	{
		public static function tint(color:uint, amount:Number, brightnessOffset:int=0):Function 
		{
			var red:Number = (( color >> 16 ) & 0xFF);
			var green:Number = (( color >> 8 ) & 0xFF);
			var blue:Number = (color & 0xFF);
			
			return function(trans:ColorTransform, x:Number, y:Number, velX:Number, velY:Number, alpha:Number, pixelColor:Number):void {
				trans.redMultiplier = amount + (1 - amount) * (red / 0xff);
				trans.greenMultiplier = amount + (1 - amount) * (green / 0xff);
				trans.blueMultiplier = amount + (1 - amount) * (blue / 0xff);
				
				trans.alphaMultiplier = alpha;
				
				trans.redOffset = amount * red + brightnessOffset;
				trans.greenOffset = amount * green + brightnessOffset;
				trans.blueOffset = amount * blue + brightnessOffset;
			}
		}
	}

}