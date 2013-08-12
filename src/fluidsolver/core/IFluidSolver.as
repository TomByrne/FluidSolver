package fluidsolver.core 
{
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public interface IFluidSolver 
	{
		function setFPS(value:int, returnHandler:Function = null):void;
		function setupSolver(gridWidth:int, gridHeight:int, screenW:int, screenH:int, drawFluid:Boolean, isRGB:Boolean, doParticles:Boolean, emitterCounts:Vector.<int>=null, returnHandler:Function = null, updateHandler:Function=null):void;
		
		/**
		 * 
		 * @return Returns an int identifier of the particle emitter
		 */
		function addParticleEmitter(x:Number, y:Number, rate:Number, xSpread:Number, ySpread:Number, ageVar:Number, massVar:Number, emDecay:Number, partDecay:Number, initVX:Number, initVY:Number, returnHandler:Function = null):void;
		function changeParticleEmitter(index:int, x:Number, y:Number, rate:Number, xSpread:Number, ySpread:Number, ageVar:Number, massVar:Number, emDecay:Number, partDecay:Number, initVX:Number, initVY:Number, returnHandler:Function = null):void;
		function updateSolver(timeDelta:Number, returnHandler:Function = null):void;
		function clearParticles(returnHandler:Function = null):void;
		function setForce(tx:Number, ty:Number, dx:Number, dy:Number, returnHandler:Function = null):void;
		function setColour(tx:Number, ty:Number, r:Number, g:Number, b:Number, returnHandler:Function = null):void;
		function setForceAndColour(tx:Number, ty:Number, dx:Number, dy:Number, r:Number, g:Number, b:Number, returnHandler:Function = null):void;
		function setGravity(x:Number, y:Number, returnHandler:Function = null):void;
		function setWrapping(x:Boolean, y:Boolean, returnHandler:Function = null):void;
		
		function get speed():Number;
		function set speed(value:Number):void;
		
		function get viscosity():Number;
		function set viscosity(value:Number):void;
		
		function get fadeSpeed():Number;
		function set fadeSpeed(value:Number):void;
		
		function get vorticityConfinement():Boolean;
		function set vorticityConfinement(value:Boolean):void;
		
		function get solverIterations():int;
		function set solverIterations(value:int):void;
		
		function get colorDiffusion():Number;
		function set colorDiffusion(value:Number):void;
		
		function get sharedBytes():ByteArray;
		function get emittersSetPos():int;
		function get particlesCountPos():int;
		function get particlesMaxPos():int;
		function get particlesDataPos():int;
		function get maxParticlesPos():int;
		function get particleEmittersPos():int;
		function get fluidImagePos():int;
	}
	
}