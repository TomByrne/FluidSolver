package fluidsolver.away3d
{
	import away3d.animators.AnimatorBase;
	import away3d.animators.IAnimator;
	import away3d.arcane;
	import away3d.animators.states.*;
	import away3d.animators.transitions.*;
	import away3d.animators.data.*;
	import away3d.cameras.Camera3D;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.materials.passes.*;
	import flash.utils.ByteArray;
	
	import flash.display3D.*;
	
	use namespace arcane;
	
	/**
	 * Provides an interface for assigning vertex-based animation data sets to mesh-based entity objects
	 * and controlling the various available states of animation through an interative playhead that can be
	 * automatically updated or manually triggered.
	 */
	public class FluidAnimator extends AnimatorBase implements IAnimator
	{
		private var _fluidAnimationSet:FluidAnimationSet;
		private var _activeVertexState:IVertexAnimationState;
		
		
		/**
		 * Creates a new <code>VertexAnimator</code> object.
		 *
		 * @param fluidAnimationSet1 The animation data set containing the vertex animations used by the animator.
		 */
		public function FluidAnimator(fluidAnimationSet:FluidAnimationSet)
		{
			super(fluidAnimationSet);
			
			_fluidAnimationSet = fluidAnimationSet;
		}
		
		/**
		 * @inheritDoc
		 */
		public function clone():IAnimator
		{
			return new FluidAnimator(_fluidAnimationSet);
		}
		
		/**
		 * Plays a sequence with a given name. If the sequence is not found, it may not be loaded yet, and it will retry every frame.
		 * @param sequenceName The name of the clip to be played.
		 */
		public function play(name:String, transition:IAnimationTransition = null, offset:Number = NaN):void
		{
			if (_activeAnimationName == name)
				return;
			
			_activeAnimationName = name;
			
			//TODO: implement transitions in vertex animator
			
			if (!_animationSet.hasAnimation(name))
				throw new Error("Animation root node " + name + " not found!");
			
			_activeNode = _animationSet.getAnimation(name);
			
			_activeState = getAnimationState(_activeNode);
			
			if (updatePosition) {
				//update straight away to reset position deltas
				_activeState.update(_absoluteTime);
				_activeState.positionDelta;
			}
			
			_activeVertexState = _activeState as IVertexAnimationState;
			
			start();
			
			//apply a time offset if specified
			if (!isNaN(offset))
				reset(name, offset);
		}
		
		/**
		 * @inheritDoc
		 */
		public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:int, vertexStreamOffset:int, camera:Camera3D):void
		{
			
		}
		
		private function setNullPose(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:int, vertexStreamOffset:int):void
		{
			
		}
		
		/**
		 * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
		 * Needs to be called if gpu code is potentially required.
		 */
		public function testGPUCompatibility(pass:MaterialPassBase):void
		{
		}
	}
}
