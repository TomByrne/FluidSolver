package fluidsolver.away3d
{
	import away3d.animators.AnimationSetBase;
	import away3d.animators.data.VertexAnimationMode;
	import away3d.animators.IAnimationSet;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import flash.display.BlendMode;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	import flash.display3D.Context3D;
	
	import flash.utils.Dictionary;
	
	use namespace arcane;
	
	/**
	 * The animation data set used by vertex-based animators, containing vertex animation state data.
	 *
	 * @see away3d.animators.VertexAnimator
	 */
	public class FluidAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		public var minScale:Number = 1;
		public var maxScale:Number = 5;
		
		
		public function FluidAnimationSet()
		{
			super();
		
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAGALVertexCode(pass:MaterialPassBase, sourceRegisters:Vector.<String>, targetRegisters:Vector.<String>, profile:String):String
		{
			var temp:String = "vt4";
			var data1:String = "vt5";
			var data2:String = "vt6";
			var minScale:String = "vc10.x";
			var maxScale:String = "vc10.y";
			var scaleRange:String = "vc10.z";
			var const0:String = "vc11.x";
			var const1:String = "vc11.y";
			var const2:String = "vc11.z";
			var byteIndex:String = "vc11.w";
			
			var endPos:String = "vt0";
			
			return  "mov " + endPos + ", va0 \n" + 
					"mov "+temp+".x, "+endPos+".z \n" + 
					"mul "+temp+".x, "+temp+".x, "+const2+" \n" + 
					"add "+temp+".x, "+temp+".x, "+byteIndex+" \n" + 
					"add " + temp + ".y, " + temp + ".x, " + const1 + " \n" + 
					
					"mov " + data1 + ", vc[" + temp + ".x] \n" + 						// get particle data 1
					"mov " + data2 + ", vc[" + temp + ".x] \n" +  						// get particle data 2
					
					"sub "+temp+".z, "+const1+", "+data1+".x \n" +  					// 1 - alpha
					"mul "+temp+".z, "+temp+".z, "+scaleRange+" \n" +  					// multiply inv alpha by scaleRange
					"add "+temp+".z, "+temp+".z, "+minScale+" \n" +     				// add min scale
					"mul " + endPos + ".xy, " + endPos + ".xy, " + temp + ".z \n" +     // scale
					
					"add " + endPos + ".x, " + endPos + ".x,"+data1+".y \n" +
					"sub " + endPos + ".y, " + endPos + ".y,"+data1+".z \n" +
					"mov v1, " + data1+" \n" +
					"mov v2, " + data2+" \n";
		}
		
		/**
		 * @inheritDoc
		 */
		public function activate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):void
		{
			var context : Context3D = stage3DProxy._context3D;
			if (_particleData) {
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 10, Vector.<Number>([minScale, maxScale, maxScale-minScale, 0]), 1);
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 11, Vector.<Number>([0, 1, 2, 12]), 1);
				
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 4, Vector.<Number>([0, 1, 2, 0xff]), 1);
				
				var regCount:int = Math.ceil(_maxParticles * 2);
				_particleData.position = 0;
				context.setProgramConstantsFromByteArray(Context3DProgramType.VERTEX, 12, regCount, _particleData, _dataOffset);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function deactivate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):void
		{
			var context:Context3D = stage3DProxy._context3D;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAGALFragmentCode(pass:MaterialPassBase, shadedTarget:String, profile:String):String
		{
			if(pass.material.blendMode == BlendMode.MULTIPLY || pass.material.blendMode == BlendMode.DARKEN){
				return  "sub ft2.x, fc4.y, v1.x \n" +   // 1 - alpha
						
						"mul ft0.x, ft0.x, v1.x \n" +   // multiply r by alpha
						"add ft0.x, ft0.x, ft2.x \n" +  // add 1- alpha to r
						
						"mul ft0.y, ft0.y, v1.x \n" +  // multiply b by alpha
						"add ft0.y, ft0.y, ft2.x \n" +  // add 1- alpha to b
						
						"mul ft0.z, ft0.z, v1.x \n" +  // multiply g by alpha
						"add ft0.z, ft0.z, ft2.x \n";  // add 1- alpha to g
						
			}else if (pass.material.blendMode == BlendMode.ADD || pass.material.blendMode == BlendMode.LIGHTEN) {
				return  "mul ft0.x, ft0.x, v1.x \n" +  // multiply r by a
						"mul ft0.y, ft0.y, v1.x \n" +  // multiply b by a
						"mul ft0.z, ft0.z, v1.x \n";   // multiply g by a
						
			}else if(pass.material.blendMode == BlendMode.NORMAL){
				return  "mul ft0.w, ft0.w, v1.x \n" ;  // multiply a by particle alpha
				
			}else {
				throw new Error("Unsupported blend mode");
			}
					
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAGALUVCode(pass:MaterialPassBase, UVSource:String, UVTarget:String):String
		{
			return "mov " + UVTarget + "," + UVSource + "\n";
		}
		
		/**
		 * @inheritDoc
		 */
		public function doneAGALCode(pass:MaterialPassBase):void
		{
		
		}
		
		
		
		private var _particleData:ByteArray;
		private var _dataOffset:uint;
		private var _maxParticles:int;
		
		public function getParticleData():ByteArray
		{
			return _particleData;
		}
		
		public function setParticleData(value:ByteArray):void
		{
			_particleData = value;
		}
		
		public function getDataOffset():uint
		{
			return _dataOffset;
		}
		public function setDataOffset(value:uint):void
		{
			_dataOffset = value;
		}
		
		public function getMaxParticles():int
		{
			return _maxParticles;
		}
		public function setMaxParticles(value:int):void
		{
			_maxParticles = value;

		}
	}
}