package fluidsolver.core 
{
	
	/**
	 * ...
	 * @author Tom Byrne
	 */
	public interface IFluidRenderer 
	{
		
		function solverInited(fluidSolver:IFluidSolver):void;
		function update():void;
	}
	
}