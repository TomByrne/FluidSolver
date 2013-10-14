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
		function addEmitter(x:Number, y:Number, rate:Number, emDecay:Number, partDecay:Number, initVX:Number, initVY:Number, initMass:Number, returnHandler:Function = null):void;
		function setEmitterProps(index:int, x:Number, y:Number, rate:Number, emDecay:Number, partDecay:Number, initVX:Number, initVY:Number, initMass:Number, returnHandler:Function = null):void;
		function setEmitterVariance(index:int, xSpread:Number, ySpread:Number, ageVar:Number, massVar:Number, vxVar:Number, vyVar:Number, returnHandler:Function = null):void;
		function updateSolver(timeDelta:Number, returnHandler:Function = null):void;
		function clearParticles(returnHandler:Function = null):void;
		function setForce(x:int, y:int, dx:Number, dy:Number, returnHandler:Function = null):void;
		function setColour(x:int, y:int, r:Number, g:Number, b:Number, returnHandler:Function = null):void;
		function setForceAndColour(x:int, y:int, dx:Number, dy:Number, r:Number, g:Number, b:Number, returnHandler:Function = null):void;
		function setGravity(x:Number, y:Number, returnHandler:Function = null):void;
		function setEdgeTypes(x:int, y:int, returnHandler:Function = null):void;
		
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
		
		function get fluidForce():Number;
		function set fluidForce(value:Number):void;
		
		function get gridWidth():int;
		function get gridHeight():int;
		
		function get sharedBytes():ByteArray;
		function get emittersSetPos():int;
		function get particlesCountPos():int;
		function get particlesMaxPos():int;
		function get particlesDataPos():int;
		function get maxParticlesPos():int;
		function get particleEmittersPos():int;
		function get fluidImagePos():int;
		function get uPos():int;
		function get vPos():int;
	}
	
}