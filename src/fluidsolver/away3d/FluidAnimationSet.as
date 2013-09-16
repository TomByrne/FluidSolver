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
		public static const MAX_PARTICLES:int = 61; // maximum amount of particles we can squeeze into constant space
		
		public var minScale:Number = 1;
		public var maxScale:Number = 5;
		
		public var minAlpha:Number = 0;
		public var maxAlpha:Number = 1;
		
		public var offsetX:Number = 0;
		public var offsetY:Number = 0;
		
		public var redMultiply:Number = 1;
		public var blueMultiply:Number = 1;
		public var greenMultiply:Number = 1;
		
		public var redOffset:Number = 0;
		public var blueOffset:Number = 0;
		public var greenOffset:Number = 0;
		
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
			var minScale:String = "vc5.x";
			var scaleRange:String = "vc5.y";
			var offsets:String = "vc5.zw";
			var const0:String = "vc4.x";
			var const1:String = "vc4.y";
			var const2:String = "vc4.z";
			var byteIndex:String = "vc4.w";
			
			var endPos:String = "vt0";
			
			return  "mov " + endPos + ", va0 \n" + 
					"mov "+temp+".x, "+endPos+".z \n" + 								// take particle index from object.z
					"mul "+temp+".x, "+temp+".x, "+const2+" \n" + 						// multiply 2 to particle index (2 vectors per particle)
					"add "+temp+".x, "+temp+".x, "+byteIndex+" \n" + 					// add constant start offset
					
					"mov " + data1 + ", vc[" + temp + ".x] \n" + 						// get particle data 1
					"mov " + data2 + ", vc[" + temp + ".x] \n" +  						// get particle data 2
					
					"sub "+temp+".z, "+const1+", "+data1+".x \n" +  					// 1 - alpha
					"mul "+temp+".z, "+temp+".z, "+scaleRange+" \n" +  					// multiply inv alpha by scaleRange
					"add "+temp+".z, "+temp+".z, "+minScale+" \n" +     				// add min scale
					"mul " + endPos + ".xy, " + endPos + ".xy, " + temp + ".z \n" +     // scale
					
					"add " + endPos + ".x, " + endPos + ".x,"+data1+".y \n" +			// set x pos
					"sub " + endPos + ".y, " + endPos + ".y,"+data1+".z \n" +			// set y pos
					"add " + endPos + ".xy, " + endPos + ".xy,"+offsets+" \n" +			// add offsets
					"mov " + endPos + ".z, " + const0 + " \n" +							// set z to 0
					
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
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, Vector.<Number>([minScale, maxScale-minScale, offsetX, offsetY]), 1);
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, Vector.<Number>([0, 1, 2, 6]), 1);
				
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 4, Vector.<Number>([1, minAlpha, maxAlpha-minAlpha, 0]), 1);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, Vector.<Number>([redMultiply, greenMultiply, blueMultiply, 0]), 1);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 6, Vector.<Number>([redOffset, greenOffset, blueOffset, 0]), 1);
				
				var regCount:int = Math.ceil(_maxParticles * 2);
				_particleData.position = 0;
				context.setProgramConstantsFromByteArray(Context3DProgramType.VERTEX, 6, regCount, _particleData, _dataOffset);
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
			var const1:String = "fc4.x";
			var minAlpha:String = "fc4.y";
			var alphaRange:String = "fc4.z";
			
			var colorTrans:String = "";
			
			/*if (redMultiply != 1) */colorTrans += "mul ft0.x, ft0.x, fc5.x \n";
			/*if (greenMultiply != 1) */colorTrans += "mul ft0.y, ft0.y, fc5.y \n";
			/*if (blueMultiply != 1) */colorTrans += "mul ft0.z, ft0.z, fc5.z \n";
			
			/*if (redOffset != 1) */colorTrans += "add ft0.x, ft0.x, fc6.x \n";
			/*if (greenOffset != 1) */colorTrans += "add ft0.y, ft0.y, fc6.y \n";
			/*if (blueOffset != 1) */colorTrans += "add ft0.z, ft0.z, fc6.z \n";
			
			if(pass.material.blendMode == BlendMode.MULTIPLY || pass.material.blendMode == BlendMode.DARKEN){
				return  "mul ft1.w, v1.x, " + alphaRange + " \n" +  // multiply a by alphaRange
						"add ft1.w, ft1.w, " + minAlpha + " \n" +  // add minAlpha to a
						
						"sub ft2.x, "+const1+", ft1.w \n" +   // 1 - alpha
						
						"mul ft0.x, ft0.x, ft1.w \n" +   // multiply r by alpha
						"add ft0.x, ft0.x, ft2.x \n" +  // add 1- alpha to r
						
						"mul ft0.y, ft0.y, ft1.w \n" +  // multiply b by alpha
						"add ft0.y, ft0.y, ft2.x \n" +  // add 1- alpha to b
						
						"mul ft0.z, ft0.z, ft1.w \n" +  // multiply g by alpha
						"add ft0.z, ft0.z, ft2.x \n" + colorTrans;  // add 1- alpha to g
						
			}else if (pass.material.blendMode == BlendMode.ADD || pass.material.blendMode == BlendMode.LIGHTEN) {
				return  "mul ft1.w, v1.x, " + alphaRange + " \n" +  // multiply a by alphaRange
						"add ft1.w, ft1.w, " + minAlpha + " \n" +  // add minAlpha to a
						
						"mul ft0.x, ft0.x, ft1.w \n" +  // multiply r by a
						"mul ft0.y, ft0.y, ft1.w \n" +  // multiply b by a
						"mul ft0.z, ft0.z, ft1.w \n" + colorTrans;   // multiply g by a
						
			}else if(pass.material.blendMode == BlendMode.NORMAL){
				return  "mul ft1.w, v1.x, " + alphaRange + " \n" +  // multiply a by alphaRange
						"add ft1.w, ft1.w, " + minAlpha + " \n" +  // add minAlpha to a
						
						"mul ft0.w, ft0.w, ft1.w \n"  + colorTrans;  // multiply a by particle alpha
				
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
