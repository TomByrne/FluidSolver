@echo off

call bat/SetupSDK.bat
call bat/SetupApplication.bat
compc -include-sources "src" -debug=true -o bin\FluidSolver.swc -external-library-path+=lib -external-library-path+=clib -external-library-path+="%FLEX_SDK%/frameworks/libs/air/airglobal.swc"

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