## Building the Demos ##
Building the project has several steps, most of which can be streamlined if you're using FlashDevelop.

These are the fundamental steps to build the demos:

- Use Crossbridge to build the C into a SWC
- Build Worker SWC which wraps C code into a flash 'thread' (see bat/BuildWorker.bat)
- Build/Run the Demos
- Optionally, build the final SWC, which wraps the worker thread in a nice AS API (see bat/BuildSWC.bat)

## Crossbridge build ##
If you don't modify the C code you won't need to do this step, as the SWC is included in the repo (clib/FluidSolverCrossbridge.swc).

Compiling the Crossbridge SWC involves the following steps:

- Install Crossbridge SDK (tested on version 1.0.1)
- Run Crossbridge using run.bat in SDK
- Navigate to FluidSolver/clib directory
- Run Crossbridge (the command should be printed in the comments at the top of the Crossbridge prompt), something like this:
	- `make FLASCC="/cygdrive/c/SDKs/Crossbridge_1.0.1/sdk" FLEX="/path/to/flexsdk"`


## Using FlashDevelop ##
When building the demos from FlashDevelop, everything except the Crossbridge compile is built into the project, it will automatically compile the worker SWC before compiling and the final SWC after compiling the demos.


