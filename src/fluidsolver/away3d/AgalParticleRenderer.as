package fluidsolver.away3d 
{
	import away3d.containers.ObjectContainer3D;
	import away3d.entities.Mesh;
	import away3d.materials.MaterialBase;
	import away3d.primitives.PlaneGeometry;
	import away3d.tools.commands.Merge;
	import flash.utils.Dictionary;
	import fluidsolver.core.IFluidRenderer;
	import fluidsolver.core.IFluidSolver;
	import fluidsolver.utils.CustomMemory;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class AgalParticleRenderer implements IFluidRenderer
	{
		
		public function get display():ObjectContainer3D {
			return _container;
		}
		
		private var _container:ObjectContainer3D;
		private var _solver:IFluidSolver;
		private var _sharedMemory:CustomMemory;
		private var _animationSets:Vector.<FluidAnimationSet>;
		private var _animationSetByEmitter:Dictionary;
		private var _meshes:Vector.<Mesh>;
		private var _meshesByEmitter:Vector.<Vector.<Mesh>>;
		
		public function AgalParticleRenderer(emitterCounts:Vector.<int>, materialCreators:Array, centerX:Number=0, centerY:Number=0, particleW:Number=32, particleH:Number=32, doubleSided:Boolean=false)
		{
			_animationSetByEmitter = new Dictionary();
			_container = new ObjectContainer3D();
			
			_meshesByEmitter = new Vector.<Vector.<Mesh>>();
			_animationSets = new Vector.<FluidAnimationSet>();
			_meshes = new Vector.<Mesh>();
			for (var j:int = 0; j < emitterCounts.length; ++j) {
				var totalParticles:int = emitterCounts[j];
				var materialCreator:Function = materialCreators[j%materialCreators.length];
				var totalGroups:int = Math.ceil(totalParticles / FluidAnimationSet.MAX_PARTICLES);
				var emitterSets:Vector.<FluidAnimationSet> = new Vector.<FluidAnimationSet>();
				var emitterMeshes:Vector.<Mesh> = new Vector.<Mesh>();
				for (var i:int = 0; i < totalGroups; i++){
					var meshes:Vector.<Mesh> = new Vector.<Mesh>();
					var geo:PlaneGeometry = new PlaneGeometry(particleW, particleH, 1, 1, false, doubleSided);
					
					var count:int = Math.min(FluidAnimationSet.MAX_PARTICLES, totalParticles - (i * FluidAnimationSet.MAX_PARTICLES));
					for (var k:int = 0; k < count; ++k) {
						var mesh:Mesh = new Mesh(geo.clone(), null);
						mesh.z = k;
						meshes.push(mesh);
					}
					
					var receiver:Mesh = new Mesh(geo, materialCreator());
					_container.addChild(receiver);
					emitterMeshes.push(receiver);
					
					var merge:Merge = new Merge(false, true);
					merge.applyToMeshes(receiver, meshes);
					
					var trailAnimationSet:FluidAnimationSet = new FluidAnimationSet();
					trailAnimationSet.offsetX = centerX;
					trailAnimationSet.offsetY = centerY;
					trailAnimationSet.setMaxParticles(count);
					var trailAnimator:FluidAnimator = new FluidAnimator(trailAnimationSet);
					receiver.animator = trailAnimator;
					
					_animationSets.push(trailAnimationSet);
					emitterSets.push(trailAnimationSet);
				}
				_meshesByEmitter[j] = emitterMeshes;
				_animationSetByEmitter[j] = emitterSets;
			}
		}
		
		public function setScale(emitter:int, minScale:Number, maxScale:Number):void {
			var emitterSets:Vector.<FluidAnimationSet> = _animationSetByEmitter[emitter];
			for (var i:int = 0; i < emitterSets.length; ++i ) {
				var animSet:FluidAnimationSet = emitterSets[i];
				animSet.minScale = minScale;
				animSet.maxScale = maxScale;
			}
		}
		
		public function setAlpha(emitter:int, minAlpha:Number, maxAlpha:Number):void {
			var emitterSets:Vector.<FluidAnimationSet> = _animationSetByEmitter[emitter];
			for (var i:int = 0; i < emitterSets.length; ++i ) {
				var animSet:FluidAnimationSet = emitterSets[i];
				animSet.minAlpha = minAlpha;
				animSet.maxAlpha = maxAlpha;
			}
		}
		
		public function setColorTrans(emitter:int, rM:Number=1, gM:Number=1, bM:Number=1, rO:Number=0, gO:Number=0, bO:Number=0):void {
			var emitterSets:Vector.<FluidAnimationSet> = _animationSetByEmitter[emitter];
			for (var i:int = 0; i < emitterSets.length; ++i ) {
				var animSet:FluidAnimationSet = emitterSets[i];
				animSet.redMultiply = rM;
				animSet.greenMultiply = gM;
				animSet.blueMultiply = bM;
				
				animSet.redOffset = rO;
				animSet.greenOffset = gO;
				animSet.blueOffset = bO;
			}
		}
		
		public function solverInited(fluidSolver:IFluidSolver):void {
			_solver = fluidSolver;
			
			
			_sharedMemory = new CustomMemory(_solver.sharedBytes);
			
			var countOffset:int = 0;
			for (var i:int = 0; i < _animationSets.length; ++i ) {
				var animSet:FluidAnimationSet = _animationSets[i];
				animSet.setDataOffset(_sharedMemory.readInt(_solver.particlesDataPos) + countOffset * (8 << 2));
				animSet.setParticleData(_sharedMemory.byteArray);
				countOffset += animSet.getMaxParticles();
			}
		}
		public function iterateMeshes(emitter:int, func:Function):void {
			var meshes:Vector.<Mesh> = _meshesByEmitter[emitter];
			for (var i:int = 0; i < meshes.length; ++i ) {
				var mesh:Mesh = meshes[i];
				func(mesh);
			}
		}
		public function update():void{}
	}

}