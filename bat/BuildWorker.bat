@echo off

rem cd clib
rem call C:/SDKs/Crossbridge_1.0.1/run.bat make FLASCC="/cygdrive/c/SDKs/Crossbridge_1.0.1/sdk" FLEX="/cygdrive/c/SDKs/4.6.0 - 3.7" exit
rem cd ../

call bat/SetupSDK.bat
call bat/SetupApplication.bat
mxmlc -load-config+=obj\FluidSolverConfig.xml -debug=false -file-specs "src/fluidsolver/core/worker/FluidSolverWorkerCore.as" -o bin\worker.swf -source-path+=src

exit

:failed
echo Build Worker FAILED.
echo.
echo Troubleshooting: 
echo - did you build your project in FlashDevelop?
echo - verify AIR SDK target version in %APP_XML%
echo.
exit

:end
echo.