package fluidsolver.away3d 
{
	import away3d.containers.ObjectContainer3D;
	import away3d.entities.Mesh;
	import away3d.materials.MaterialBase;
	import away3d.primitives.PlaneGeometry;
	import away3d.tools.commands.Merge;
	import fluidsolver.core.IFluidRenderer;
	import fluidsolver.core.IFluidSolver;
	import fluidsolver.utils.CustomMemory;
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public class AgalParticleRenderer implements IFluidRenderer
	{
		private const TOTAL_PARTICLES_PER_GROUP:Number = 50;
		
		public function get display():ObjectContainer3D {
			return _container;
		}
		
		private var _container:ObjectContainer3D;
		private var _solver:IFluidSolver;
		private var _sharedMemory:CustomMemory;
		private var _animationSets:Vector.<FluidAnimationSet>;
		private var _meshes:Vector.<Mesh>;
		
		public function AgalParticleRenderer(totalParticles:int, materialCreator:Function, centerX:Number=0, centerY:Number=0, particleW:Number=32, particleH:Number=32)
		{
			_container = new ObjectContainer3D();
			
			_animationSets = new Vector.<FluidAnimationSet>();
			_meshes = new Vector.<Mesh>();
			var totalGroups:int = Math.ceil(totalParticles / TOTAL_PARTICLES_PER_GROUP);
			for (var i:int = 0; i < totalGroups; i++){
				var meshes:Vector.<Mesh> = new Vector.<Mesh>();
				var geo:PlaneGeometry = new PlaneGeometry(particleW, particleH, 1, 1, false);
				
				var count:int = Math.min(TOTAL_PARTICLES_PER_GROUP, totalParticles - (i * TOTAL_PARTICLES_PER_GROUP));
				for (var k:int = 0; k < count; ++k) {
					var mesh:Mesh = new Mesh(geo.clone(), null);
					mesh.z = k;
					meshes.push(mesh);
				}
				
				var receiver:Mesh = new Mesh(geo, materialCreator());
				receiver.x = centerX;
				receiver.y = centerY;
				_container.addChild(receiver);
				
				var merge:Merge = new Merge(false, true);
				merge.applyToMeshes(receiver, meshes);
				
				var trailAnimationSet:FluidAnimationSet = new FluidAnimationSet();
				trailAnimationSet.setMaxParticles(count);
				var trailAnimator:FluidAnimator = new FluidAnimator(trailAnimationSet);
				receiver.animator = trailAnimator;
			
				_animationSets.push(trailAnimationSet);
			}
		}
		
		public function setScale(minScale:Number, maxScale:Number):void {
			for (var i:int = 0; i < _animationSets.length; ++i ) {
				var animSet:FluidAnimationSet = _animationSets[i];
				animSet.minScale = minScale;
				animSet.maxScale = maxScale;
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
		public function update():void{}
	}

}