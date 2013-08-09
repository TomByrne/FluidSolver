
#ifndef _FLUIDSOLVER_H_
#define _FLUIDSOLVER_H_

//-----------------------------------------------------------------------------
// Platform-specific functions and macros

// Microsoft Visual Studio

#if defined(_MSC_VER)

typedef unsigned char uint8_t;
typedef unsigned long uint32_t;
typedef unsigned __int64 uint64_t;

// Other compilers

#else	// defined(_MSC_VER)

//#include <stdint.h>

#endif // !defined(_MSC_VER)

//-----------------------------------------------------------------------------

void setupSolver(int gridWidth, int gridHeight, int screenW, int screenH, int drawFluid, int isRGB, int doParticles, int maxParticles, float cullAlpha);
void updateSolver(double timeDelta);
int addParticleEmitter(double x, double y, double rate, double xSpread, double ySpread, double alphVar, double massVar, double decay);
void changeParticleEmitter(int index,  double x, double y, double rate, double xSpread, double ySpread, double alphVar, double massVar, double decay);
void clearParticles();

void setForce(double tx, double ty, double dx, double dy);
void setColour(double tx, double ty, float r, float g, float b);
void setForceAndColour(double tx, double ty, double dx, double dy, float r, float g, float b);

void setWrap(int wrapX, int wrapY);
void setColorDiffusion(double colorDiffusion);
void setSolverIterations(int solverIterations);
void setVorticityConfinement(int doVorticityConfinement);
void setFadeSpeed(double fadeSpeed);
void setViscosity(double viscosity);

int* getParticlesCountPos();
int* getMaxParticlesPos();
double* getParticleEmittersPos();
float* getParticlesDataPos();
int* getParticleImagePos();
int* getFluidImagePos();

double* getROldPos();
double* getGOldPos();
double* getBOldPos();
double* getUOldPos();
double* getVOldPos();

//-----------------------------------------------------------------------------

#endif // _FLUIDSOLVER_H_
