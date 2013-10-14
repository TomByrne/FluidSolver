
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

void setupSolver(int gridWidth, int gridHeight, int screenW, int screenH, int drawFluid, int isRGB, int doParticles, char* emitterParticles);
void updateSolver(double timeDelta);
int addEmitter(double x, double y, double rate, double emitterDecay, double particleDecay, double initVX, double initVY, double initMass);
void setEmitterProps(int index,  double x, double y, double rate, double emitterDecay, double particleDecay, double initVX, double initVY, double initMass);
void setEmitterVariance(int index, double xSpread, double ySpread, double ageVar, double massVar, double vxVar, double vyVar);
void clearParticles();

void setForce(int x, int y, double dx, double dy);
void setColour(int x, int y, float r, float g, float b);
void setForceAndColour(int x, int y, double dx, double dy, float r, float g, float b);
void setGravity(float x, float y);

void setEdgeTypes(int edgeX, int edgeY);

void setFluidForce(double fluidForce);
void setColorDiffusion(double colorDiffusion);
void setSolverIterations(int solverIterations);
void setVorticityConfinement(int doVorticityConfinement);
void setFadeSpeed(double fadeSpeed);
void setViscosity(double viscosity);

double getFluidForce();
double getColorDiffusion();
int getSolverIterations();
int getVorticityConfinement();
double getFadeSpeed();
double getViscosity();

int* getEmittersSetPos();
int* getParticlesCountPos();
int* getParticlesMaxPos();
double* getParticleEmittersPos();
float* getParticlesDataPos();
int* getFluidImagePos();
double* getUPos();
double* getVPos();

//-----------------------------------------------------------------------------

#endif // _FLUIDSOLVER_H_
