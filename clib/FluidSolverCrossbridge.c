#include <math.h>
#include <time.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

void linearSolver(int b, double *x, double *x0, double a, double c);
void linearSolverRGB(double a, double c);
void linearSolverUV(double a, double c);
void destroy();
void reset();
void drawFluidImage();
void fadeR();
void fadeRGB();
void advect(int b, double *_d, double *d0, double *du, double *dv);
void advectRGB(double *du, double *dv);
void project(double *x, double *y, double *p, double *div);
void setBoundary(int bound, double *x);
void setBoundaryRGB();
//void drawLine(int *layer, int x0, int y0, int x1, int y1, int c);
int compareParticles(const void *vp1, const void *vp2);


static const double FLUID_DEFAULT_DT					= 0.5;
static const double FLUID_DEFAULT_VISC					= 0.0001;
static const double FLUID_DEFAULT_COLOR_DIFFUSION 		= 0.0;
static const double FLUID_DEFAULT_FADESPEED				= 0.003;
static const int FLUID_DEFAULT_SOLVER_ITERATIONS		= 10;
static const int FLUID_DEFAULT_VORTICITY_CONFINEMENT 	= 0;

static const double FLUID_DEFAULT_FORCE 				= 50;

static const int PARTICLE_MEM 	 						= 8;
static const int EMITTER_MEM 	 						= 11;

int gridW;
int gridH;
int gridW2;
int gridH2;
int numCells;
int screenW;
int screenH;
double isw;
double ish;
double invgridW;
double invgridH;
double invNumCells;

double _dt = 0.5;
int _isRGB = 0;
int _drawFluid = 1;
int _doParticles = 1;
int _solverIterations;
double _colorDiffusion;
int _doVorticityConfinement = 0;

float gravityX = 0.0;
float gravityY = 0.0;

int wrap_x = 0;
int wrap_y = 0;

double _visc;
double _fadeSpeed;

double _fluidForce;

double _avgDensity;			// this will hold the average color of the last frame (how full it is)
double _uniformity;			// this will hold the uniformity of the last frame (how uniform the color is);
double _avgSpeed;

double *r;
double *g;
double *b;
double *rOld;
double *gOld;
double *bOld;
double *u;
double *uOld;
double *v;
double *vOld;
double *curl_abs;
double *curl_orig;

int *fluidsImage;

int totalParticles;
int particleEmitterMax;
int particleEmittersSet;
int *particleEmitterCounts;
double nextEmitterIndex;
double *particleEmitters;

float *particles;
float *particles2;
float *_particles;
float *_particles2;
int *particlesNum;
int *particlesNextIndex;

inline double FMIN(register double a, register double b)
{
	return ((a) < (b) ? (a) : (b));
}
inline int IMIN(register int a, register int b)
{
	return ((a) < (b) ? (a) : (b));
}
inline double FMAX(register double a, register double b)
{
	return ((a) < (b) ? (b) : (a));
}
inline int IMAX(register int a, register int b)
{
	return ((a) < (b) ? (b) : (a));
}
inline int FLUID_IX(register int i, register int j)
{
	return (int)((i) + ((gridW2) * (j)));
}

inline double randFract(){
	return (double)rand()/(double)RAND_MAX;
}


inline void addSourceUV()
{
	register double *up, *vp, *uop, *vop;

	for(up = u, vp = v, uop = uOld, vop = vOld; up < u+numCells;)
	{
		*(up++) += (_dt * *(uop++));
		*(vp++) += (_dt * *(vop++));
	}
}

inline void addSourceRGB()
{
	register double *rp, *gp, *bp, *rop, *bop, *gop;
	for(rp = r, gp = g, bp = b, rop = rOld, bop = bOld, gop = gOld; rp < r+numCells;)
	{
		*(rp++) += (_dt * (*(rop++)));
		*(gp++) += (_dt * (*(gop++)));
		*(bp++) += (_dt * (*(bop++)));
	}
}

inline void addSource(register double *x, register double *x0)
{
	for(; x < x+numCells;)
	{
		*(x++) += (_dt * (*(x0++)));
	}
}

inline void diffuse(const int b, double *c, double *c0, const double _diff)
{
	const double a = _dt * _diff * gridW * gridH;
	linearSolver(b, c, c0, a, 1.0 + 4 * a);
}

inline void diffuseRGB(const double _diff)
{
	const double a = _dt * _diff * gridW * gridH;
	linearSolverRGB(a, 1.0 + 4 * a);
}

inline void diffuseUV(const double _diff)
{
	const double a = _dt * _diff * gridW * gridH;
	linearSolverUV(a, 1.0 + 4 * a);
}

inline void swapUV()
{
	register double *_tmp;
	_tmp = u;
	u = uOld;
	uOld = _tmp;

	_tmp = v;
	v = vOld;
	vOld = _tmp;
}

inline void swapR()
{
	register double *_tmp;
	_tmp = r;
	r = rOld;
	rOld = _tmp;
}

inline void swapRGB()
{
	register double *_tmp;
	_tmp = r;
	r = rOld;
	rOld = _tmp;

	_tmp = g;
	g = gOld;
	gOld = _tmp;

	_tmp = b;
	b = bOld;
	bOld = _tmp;
}

// inline void drawLine(int *layer, int x0, int y0, int x1, int y1, const int c)
// {
// 	int dy = y1 - y0;
// 	int dx = x1 - x0;
// 	int stepx, stepy, fraction;

// 	if (dy < 0) { dy = -dy;  stepy = -screenW; } else { stepy = screenW; }
// 	if (dx < 0) { dx = -dx;  stepx = -1; } else { stepx = 1; }
// 	dy <<= 1;
// 	dx <<= 1;

// 	y0 *= screenW;
// 	y1 *= screenW;
// 	layer[x0+y0] = c;
// 	if (dx > dy) {
// 		fraction = dy - (dx>>1);
// 		while (x0 != x1) {
// 			if (fraction >= 0) {
// 				y0 += stepy;
// 				fraction -= dx;
// 			}
// 			x0 += stepx;
// 			fraction += dy;
// 			layer[x0+y0] = c;
// 		}
// 	} else {
// 		fraction = dx - (dy>>1);
// 		while (y0 != y1) {
// 			if (fraction >= 0) {
// 				x0 += stepx;
// 				fraction -= dy;
// 			}
// 			y0 += stepy;
// 			fraction += dx;
// 			layer[x0+y0] = c;
// 		}
// 	}
// }

void destroy()
{
	if(fluidsImage)	free(fluidsImage);

    if(r)		free(r);
    if(rOld)	free(rOld);

    if(g)		free(g);
    if(gOld)	free(gOld);

    if(b)		free(b);
    if(bOld)	free(bOld);

    if(u)		free(u);
    if(uOld)	free(uOld);
    if(v)		free(v);
    if(vOld)	free(vOld);
    if(curl_abs)	free(curl_abs);
    if(curl_orig)	free(curl_orig);

	free(particleEmitters);
	free(particles);
	free(particles2);
}


void reset()
{
	destroy();

	r    = (double*)calloc( numCells, sizeof(double) );
	rOld = (double*)calloc( numCells, sizeof(double) );

	g    = (double*)calloc( numCells, sizeof(double) );
	gOld = (double*)calloc( numCells, sizeof(double) );

	b    = (double*)calloc( numCells, sizeof(double) );
	bOld = (double*)calloc( numCells, sizeof(double) );

	u    = (double*)calloc( numCells, sizeof(double) );
	uOld = (double*)calloc( numCells, sizeof(double) );
	v    = (double*)calloc( numCells, sizeof(double) );
	vOld = (double*)calloc( numCells, sizeof(double) );

	curl_abs = (double*)calloc( numCells, sizeof(double) );
	curl_orig = (double*)calloc( numCells, sizeof(double) );

	fluidsImage = (int*)calloc( gridW*gridH, sizeof(int) );

	particleEmitters = (double*)calloc( particleEmitterMax*EMITTER_MEM, sizeof(double) );

    for(int i=0; i<particleEmitterMax; i++){
		particlesNum[i] = 0;
		particlesNextIndex[i] = 0;
	}
	particles = (float*)calloc( totalParticles*PARTICLE_MEM, sizeof(float) );
	particles2 = (float*)calloc( totalParticles*PARTICLE_MEM, sizeof(float) );

	gravityX = 0.0;
	gravityY = 0.0;

	nextEmitterIndex = 0;
	particleEmittersSet = 0;

	srand( (unsigned)time(NULL) );
}

void drawFluidImage()
{
	int i, j;
	register int *ip;
	register double *rp, *gp, *bp;

	ip = fluidsImage;
	rp = r+gridW2+1;
	gp = g+gridW2+1;
	bp = b+gridW2+1;
	
	for( i = 1; i < gridH+1; i++ )
	{
		for( j = 1; j < gridW+1; j++ )
		{
			*(ip++) = (int)( (int)((int)(*(rp++) * 0xFF)<<16) | (int)((int)(*(gp++) * 0xFF)<<8) | (int)(*(bp++) * 0xFF) );
		}
		rp+=2;
		gp+=2;
		bp+=2;
	}
}

void updateParticles(float timeDelta)
{
	register float *pp;
	register float *pp2;
	int fluidIndex;
	float x, y, vx, vy, age, mass;
	double emitter;

	int cnt = 0;


	int particleOffset = 0;
	double *pep = particleEmitters;
	for(int i=0; i<particleEmittersSet; ++i)
	{

		int maxPart = particleEmitterCounts[i];
		double particleDecay = *(pep+8);
		register int total = particlesNum[i];

		for( int j=0; j<total; j++)
		{
			float *pp = _particles + particleOffset + j * PARTICLE_MEM;
			float *pp2 = _particles2 + particleOffset + j * PARTICLE_MEM;

			age = *(pp++);
			x = *(pp++);
			y = *(pp++);
			vx = *(pp++);
			vy = *(pp++);
			mass = *(pp++);
			emitter = *(pp++);
			pp++;

			fluidIndex = (int)(x*isw*gridW+1.5) + (int)(y*ish*gridH+1.5) * gridW2;
			float forceX = _fluidForce * u[fluidIndex];
			if(forceX<0)forceX = -forceX;
			if(forceX>1)forceX = 1;

			float forceY = _fluidForce * v[fluidIndex];
			if(forceY<0)forceY = -forceY;
			if(forceY>1)forceY = 1;

			vx = u[fluidIndex] * screenW * mass * forceX + vx * (1-forceX) + gravityX * timeDelta;
			vy = v[fluidIndex] * screenH * mass * forceY + vy * (1-forceY) + gravityY * timeDelta;

			float newX = x + vx;
			float newY = y + vy;
			x = newX * timeDelta + x * (1 - timeDelta);
			y = newY * timeDelta + y * (1 - timeDelta);

			if (x < 1.) {
				if (wrap_x == 1) {
					x = screenW-1;
				} else {
					x = timeDelta;
					vx *= -timeDelta;
				}
			}
			else if (x > screenW) {
				if (wrap_x == 1) {
					x = timeDelta;
				} else {
					x = screenW - 1;
					vx *= -timeDelta;
				}
			}

			if (y < 1.) {
				if (wrap_y == 1) {
					y = screenH - 1;
				} else {
					y = timeDelta;
					vy *= -timeDelta;
				}
			}
			else if (y > screenH) {
				if (wrap_y == 1) {
					y = timeDelta;
				} else {
					y = screenH - 1;
					vy *= -timeDelta;
				}
			}

			age = (timeDelta * age * particleDecay) + (age * (1 - timeDelta));

			
			*(pp2++) = age;
			*(pp2++) = x;
			*(pp2++) = y;
			*(pp2++) = vx;
			*(pp2++) = vy;
			*(pp2++) = mass;
			*(pp2++) = emitter;
			pp2++;
		}
		particleOffset += maxPart * PARTICLE_MEM;
		pep += EMITTER_MEM;
	}
	register float *tmp = _particles;
	_particles = _particles2;
	_particles2 = tmp;
}

void calcVorticityConfinement(register double *_x, register double *_y)
{
	double dw_dx, dw_dy, length, vv;
	int i, j, index;

	// Calculate magnitude of (u,v) for each cell. (|w|)
	for (j = gridH; j > 0; --j)
	{
		  index = FLUID_IX(gridW, j);
		  for (i = gridW; i > 0; --i)
		  {
			    dw_dy = u[index + gridW2] - u[index - gridW2];
			    dw_dx = v[index + 1] - v[index - 1];

			    vv = (dw_dy - dw_dx) * .5;

			    curl_orig[ index ] = vv;
			    curl_abs[ index ] = vv < 0 ? -vv : vv;

			    --index;
		  }
	}

	for (j = gridH-1; j > 1; --j)
	{
		  index = FLUID_IX(gridW-1, j);
		  for (i = gridW-1; i > 1; --i)
		  {
			    dw_dx = curl_abs[index + 1] - curl_abs[index - 1];
			    dw_dy = curl_abs[index + gridW2] - curl_abs[index - gridW2];

			    length = sqrt(dw_dx * dw_dx + dw_dy * dw_dy) + 0.000001;

			    length = 2 / length;
			    dw_dx *= length;
			    dw_dy *= length;

			    vv = curl_orig[ index ];

			    _x[ index ] = dw_dy * -vv;
			    _y[ index ] = dw_dx * vv;

			    --index;
		  }
	}
}

void fadeR()
{
	const double holdAmount = 1 - _fadeSpeed;

	_avgDensity = 0;
	_avgSpeed = 0;

	double totalDeviations = 0, currentDeviation, tmp_r;
	register double *uop, *vop, *rop, *rp;

	int i = -1;
	uop = uOld;
	vop = vOld;
	rop = rOld;
	rp = r;
	while ( ++i < numCells )
	{
		*(uop++) = *(vop++) = *(rop++) = 0.0;

		_avgSpeed += u[i] * u[i] + v[i] * v[i];

		tmp_r = FMIN(1.0, *(rp++));
		_avgDensity += tmp_r;

		currentDeviation = tmp_r - _avgDensity;
		totalDeviations += currentDeviation * currentDeviation;

		r[i] = tmp_r * holdAmount;
	}
	_avgDensity *= invNumCells;

	_uniformity = 1.0 / (1 + totalDeviations * invNumCells);
}

void fadeRGB()
{
	const double holdAmount = 1 - _fadeSpeed;

	_avgDensity = 0;
	_avgSpeed = 0;

	double totalDeviations = 0.0, currentDeviation, density;
	double tmp_r, tmp_g, tmp_b;

	register double *uop, *vop, *rop, *gop, *bop, *rp, *gp, *bp, *up, *vp;

	uop = uOld;
	vop = vOld;
	rop = rOld;
	gop = gOld;
	bop = bOld;
	gp = g;
	bp = b;
	for ( rp = r, up = u, vp = v; rp < r+numCells; )
	{
		*(uop++) = *(vop++) = *(rop++) = *(gop++) = *(bop++) = 0.0;

		_avgSpeed += *(up) * *(up) + *(vp) * *(vp);

		tmp_r = FMIN(1.0, *(rp));
		tmp_g = FMIN(1.0, *(gp));
		tmp_b = FMIN(1.0, *(bp));

		density = FMAX(tmp_r, FMAX(tmp_g, tmp_b));
		_avgDensity += density;

		currentDeviation = density - _avgDensity;
		totalDeviations += currentDeviation * currentDeviation;

		*(rp++) = tmp_r * holdAmount;
		*(gp++) = tmp_g * holdAmount;
		*(bp++) = tmp_b * holdAmount;

		up++;
		vp++;
	}
	_avgDensity *= invNumCells;
	_avgSpeed *= invNumCells;

	_uniformity = 1.0 / (1 + totalDeviations * invNumCells);
}

void advect(int b, register double *_d, register double *d0, register double *du, register double *dv)
{
	int i, j, i0, j0, i1, j1, index;
	double x, y, s0, t0, s1, t1, dt0x, dt0y;

	dt0x = _dt * gridW;
	dt0y = _dt * gridH;

	for (j = gridH; j > 0; --j)
	{
		index = FLUID_IX(gridW, j);
		for (i = gridW; i > 0; --i)
		{
			x = i - dt0x * du[index];
			y = j - dt0y * dv[index];

			if (x > gridW + 0.5) x = gridW + 0.5;
			if (x < 0.5) x = 0.5;

			i0 = (int)x;
			i1 = i0 + 1;

			if (y > gridH + 0.5) y = gridH + 0.5;
			if (y < 0.5) y = 0.5;

			j0 = (int)y;
			j1 = j0 + 1;

			s1 = x - i0;
			s0 = 1 - s1;
			t1 = y - j0;
			t0 = 1 - t1;

			_d[index] = s0 * (t0 * d0[FLUID_IX(i0, j0)] + t1 * d0[FLUID_IX(i0, j1)]) + s1 * (t0 * d0[FLUID_IX(i1, j0)] + t1 * d0[FLUID_IX(i1, j1)]);
			--index;
		}
	}
	setBoundary(b, _d);
}

void advectRGB(register double *du, register double *dv)
{
	int i, j, i0, j0;
	double x, y, s0, t0, s1, t1, dt0x, dt0y;
	int index;

	dt0x = _dt * gridW;
	dt0y = _dt * gridH;

	for (j = gridH; j > 0; --j)
	{
		index = FLUID_IX(gridW, j);
		for (i = gridW; i > 0; --i)
		{
			x = i - dt0x * du[index];
			y = j - dt0y * dv[index];

			if (x > gridW + 0.5) x = gridW + 0.5;
			if (x < 0.5)     x = 0.5;

			i0 = (int)x;

			if (y > gridH + 0.5) y = gridH + 0.5;
			if (y < 0.5)     y = 0.5;

			j0 = (int)y;

			s1 = x - i0;
			s0 = 1 - s1;
			t1 = y - j0;
			t0 = 1 - t1;

			i0 = FLUID_IX(i0, j0);
            j0 = i0 + gridW2;
            r[index] = s0 * ( t0 * rOld[i0] + t1 * rOld[j0] ) + s1 * ( t0 * rOld[i0+1] + t1 * rOld[j0+1] );
            g[index] = s0 * ( t0 * gOld[i0] + t1 * gOld[j0] ) + s1 * ( t0 * gOld[i0+1] + t1 * gOld[j0+1] );
            b[index] = s0 * ( t0 * bOld[i0] + t1 * bOld[j0] ) + s1 * ( t0 * bOld[i0+1] + t1 * bOld[j0+1] );
			--index;
		}
	}
	setBoundaryRGB();
}

void project(register double *x, register double *y, register double *p, register double *div)
{
	int i, j, index;

	double const h = -0.5 / gridW;

	for (j = gridH; j > 0; --j)
    {
		index = FLUID_IX(gridW, j);
		for (i = gridW; i > 0; --i)
		{
			div[index] = h * ( x[index+1] - x[index-1] + y[index+gridW2] - y[index-gridW2] );
			p[index] = 0;
			--index;
		}
    }

	setBoundary(0, div);
	setBoundary(0, p);

	linearSolver(0, p, div, 1.0, 4.0);

	double const fx = 0.5 * gridW;
	double const fy = 0.5 * gridH;
	for (j = gridH; j > 0; --j)
	{
		index = FLUID_IX(gridW, j);
		for (i = gridW; i > 0; --i)
		{
			x[index] -= fx * (p[index+1] - p[index-1]);
			y[index] -= fy * (p[index+gridW2] - p[index-gridW2]);
			--index;
		}
	}

	setBoundary(1, x);
	setBoundary(2, y);
}

void linearSolver(int b, register double *x, register double *x0, double a, double c)
{
	int k, i, j, index;

	if( a == 1. && c == 4. )
	{
		for (k = 0; k < _solverIterations; ++k)
		{
			for (j = gridH; j > 0 ; --j)
			{
				index = FLUID_IX(gridW, j);
				for (i = gridW; i > 0 ; --i)
				{
					x[index] = ( x[index-1] + x[index+1] + x[index - gridW2] + x[index + gridW2] + x0[index] ) * 0.25;
					--index;
				}
			}
			setBoundary( b, x );
		}
	}
	else
	{
		c = 1.0 / c;
		for (k = 0; k < _solverIterations; ++k)
		{
			for (j = gridH; j > 0 ; --j)
			{
				index = FLUID_IX(gridW, j);
				for (i = gridW; i > 0 ; --i)
				{
					x[index] = ( ( x[index-1] + x[index+1] + x[index - gridW2] + x[index + gridW2] ) * a + x0[index] ) * c;
					--index;
				}
			}
			setBoundary( b, x );
		}
	}
}

void linearSolverRGB(double a, double c)
{
	int k, i, j, index3, index4, index;

	c = 1.0 / c;

	for ( k = 0; k < _solverIterations; ++k )
	{
	    for (j = gridH; j > 0; --j)
	    {
	            index = FLUID_IX(gridW, j);
				index3 = index - gridW2;
				index4 = index + gridW2;
				for (i = gridW; i > 0; --i)
				{
					r[index] = ( ( r[index-1] + r[index+1]  +  r[index3] + r[index4] ) * a  +  rOld[index] ) * c;
					g[index] = ( ( g[index-1] + g[index+1]  +  g[index3] + g[index4] ) * a  +  gOld[index] ) * c;
					b[index] = ( ( b[index-1] + b[index+1]  +  b[index3] + b[index4] ) * a  +  bOld[index] ) * c;

					--index;
					--index3;
					--index4;
				}
		}
		setBoundaryRGB();
	}
}

void linearSolverUV(double a, double c)
{
	int index, k, i, j;
	c = 1.0 / c;
	for (k = 0; k < _solverIterations; ++k) {
		for (j = gridH; j > 0; --j) {
			index = FLUID_IX(gridW, j);
			for (i = gridW; i > 0; --i) {
				u[index] = ( ( u[index-1] + u[index+1] + u[index - gridW2] + u[index + gridW2] ) * a  +  uOld[index] ) * c;
				v[index] = ( ( v[index-1] + v[index+1] + v[index - gridW2] + v[index + gridW2] ) * a  +  vOld[index] ) * c;
				--index;
			}
		}
		setBoundary( 1, u );
        setBoundary( 2, v );
	}
}

void setBoundary(int bound, register double *x)
{
	int dst1, dst2, src1, src2, i;
	const int step = FLUID_IX(0, 1) - FLUID_IX(0, 0);

	dst1 = FLUID_IX(0, 1);
	src1 = FLUID_IX(1, 1);
	dst2 = FLUID_IX(gridW+1, 1 );
	src2 = FLUID_IX(gridW, 1);

	if( wrap_x == 1 ) {
		src1 ^= src2;
		src2 ^= src1;
		src1 ^= src2;
	}
	if( bound == 1 && wrap_x == 0 ) {
		for (i = gridH; i > 0; --i )
		{
			x[dst1] = -x[src1];     dst1 += step;   src1 += step;
			x[dst2] = -x[src2];     dst2 += step;   src2 += step;
		}
	} else {
		for (i = gridH; i > 0; --i )
		{
			x[dst1] = x[src1];      dst1 += step;   src1 += step;
			x[dst2] = x[src2];      dst2 += step;   src2 += step;
		}
	}

	dst1 = FLUID_IX(1, 0);
	src1 = FLUID_IX(1, 1);
	dst2 = FLUID_IX(1, gridH+1);
	src2 = FLUID_IX(1, gridH);

	if( wrap_y == 1 ) {
		src1 ^= src2;
		src2 ^= src1;
		src1 ^= src2;
	}
	if( bound == 2 && wrap_y == 0 ) {
		for (i = gridW; i > 0; --i )
		{
		        x[dst1++] = -x[src1++];
		        x[dst2++] = -x[src2++];
		}
	} else {
		for (i = gridW; i > 0; --i )
		{
		        x[dst1++] = x[src1++];
		        x[dst2++] = x[src2++];
		}
	}

	x[FLUID_IX(  0,   0)] = 0.5 * (x[FLUID_IX(1, 0  )] + x[FLUID_IX(  0, 1)]);
	x[FLUID_IX(  0, gridH+1)] = 0.5 * (x[FLUID_IX(1, gridH+1)] + x[FLUID_IX(  0, gridH)]);
	x[FLUID_IX(gridW+1,   0)] = 0.5 * (x[FLUID_IX(gridW, 0  )] + x[FLUID_IX(gridW+1, 1)]);
	x[FLUID_IX(gridW+1, gridH+1)] = 0.5 * (x[FLUID_IX(gridW, gridH+1)] + x[FLUID_IX(gridW+1, gridH)]);

}

void setBoundaryRGB()
{
	if( wrap_x == 0 && wrap_y == 0 ) return;

	int dst1, dst2, src1, src2, i;
	const int step = FLUID_IX(0, 1) - FLUID_IX(0, 0);

	if ( wrap_x == 1 ) {
		dst1 = FLUID_IX(0, 1);
		src1 = FLUID_IX(1, 1);
		dst2 = FLUID_IX(gridW+1, 1 );
		src2 = FLUID_IX(gridW, 1);

		src1 ^= src2;
		src2 ^= src1;
		src1 ^= src2;

		for (i = gridH; i > 0; --i )
		{
			r[dst1] = r[src1]; g[dst1] = g[src1]; b[dst1] = b[src1]; dst1 += step;   src1 += step;
			r[dst2] = r[src2]; g[dst2] = g[src2]; b[dst2] = b[src2]; dst2 += step;   src2 += step;
		}
	}

	if ( wrap_y == 1 ) {
		dst1 = FLUID_IX(1, 0);
		src1 = FLUID_IX(1, 1);
		dst2 = FLUID_IX(1, gridH+1);
		src2 = FLUID_IX(1, gridH);

		src1 ^= src2;
		src2 ^= src1;
		src1 ^= src2;

		for (i = gridW; i > 0; --i )
		{
			r[dst1] = r[src1]; g[dst1] = g[src1]; b[dst1] = b[src1];  ++dst1; ++src1;
			r[dst2] = r[src2]; g[dst2] = g[src2]; b[dst2] = b[src2];  ++dst2; ++src2;
		}
	}
}

void setupSolver(int gridWidth, int gridHeight, int screenWidth, int screenHeight, int drawFluid, int isRGB, int doParticles, char* emitterParticles)
{
	gridW = gridWidth;
	gridH = gridHeight;
	screenW = screenWidth;
	screenH = screenHeight;

	numCells = (gridW + 2) * (gridH + 2);
	gridW2 = gridW + 2;
	gridH2 = gridH + 2;

	invgridW = 1.0 / gridW;
	invgridH = 1.0 / gridH;
	invNumCells = 1.0 / numCells;

	isw = (double)(1.0 / screenW);
	ish = (double)(1.0 / screenH);

	_isRGB = isRGB;
	_drawFluid = drawFluid;
	_doParticles = doParticles;

	_dt = FLUID_DEFAULT_DT;
	_fadeSpeed = FLUID_DEFAULT_FADESPEED;
	_visc = FLUID_DEFAULT_VISC;
	_solverIterations = FLUID_DEFAULT_SOLVER_ITERATIONS;
	_colorDiffusion = FLUID_DEFAULT_COLOR_DIFFUSION;
	_doVorticityConfinement = FLUID_DEFAULT_VORTICITY_CONFINEMENT;
	_fluidForce = FLUID_DEFAULT_FORCE;

	// strtok can modify string so make a copy
	char *emitterParticles2 = (char*)calloc(1, sizeof(emitterParticles));
	strcpy (emitterParticles2, emitterParticles);

	char* count = strtok (emitterParticles," ,.-");
	int i = 0;
	while (count != NULL){
		++i;
		count = strtok (NULL, " ,.-");
	}
	particleEmitterCounts = (int*)calloc( i, sizeof(int) );
	count = strtok (emitterParticles2," ,.-");
	i = 0;
	totalParticles = 0;
	while (count != NULL){
		int emCount = atoi(count);
		totalParticles += emCount;
		*(particleEmitterCounts + i) = emCount;
		++i;
		count = strtok (NULL, " ,.-");
	}

	particleEmitterMax = i;
	particlesNum = new int[particleEmitterMax];
	particlesNextIndex = new int[particleEmitterMax];


	reset();
}

void updateSolver(double timeDelta)
{
	_dt = timeDelta;

	addSourceUV();

	if( _doVorticityConfinement )
	{
		calcVorticityConfinement(uOld, vOld);
		addSourceUV();
	}

	swapUV();

	diffuseUV(_visc);

	project(u, v, uOld, vOld);

	swapUV();

	advect(1, u, uOld, uOld, vOld);
	advect(2, v, vOld, uOld, vOld);

	project(u, v, uOld, vOld);

	if(_isRGB == 1) {
		addSourceRGB();
		swapRGB();

		if( _colorDiffusion != 0 && _dt != 0 )
        {
			diffuseRGB(_colorDiffusion);
			swapRGB();
        }

		advectRGB(u, v);

		fadeRGB();
	} else if(_isRGB == 0){
		addSource(r, rOld);
		swapR();

		if( _colorDiffusion != 0 && _dt != 0 )
        {
			diffuse(0, r, rOld, _colorDiffusion);
			swapR();
        }

		advect(0, r, rOld, u, v);
		fadeR();
	}

	register double *pep;
	int emitterIndex = 0;
	int particleOffset = 0;
	for(pep = particleEmitters; pep < particleEmitters+particleEmittersSet*sizeof(double);)
	{
		int maxPart = particleEmitterCounts[emitterIndex];

		double x = *(pep++);
		double y = *(pep++);
		double rate = *(pep++);
		double xSpread = *(pep++);
		double ySpread = *(pep++);
		double ageVar = *(pep++);
		double massVar = *(pep++);
		double emitterDecay = *(pep++);
		double particleDecay = *(pep++);
		double initVX = *(pep++);
		double initVY = *(pep++);

		if(rate>0){

			float hXSpread = xSpread/2;
			float hYSpread = ySpread/2;
			float invMassVar = 1-massVar;
			float invAgeVar = 1-ageVar;

			float timeRate = _dt*rate;

			double fract = fmod(timeRate,1.0);
			int count = (int) floor(timeRate);
			if(fract>0 && randFract()>1-fract){
				++count;
			}


			register float *pp;
			register int nextIndex = particlesNextIndex[emitterIndex];
			register int total = particlesNum[emitterIndex];

			for(int i = 0; i < count; ++i)
			{
				pp = _particles + particleOffset + (nextIndex++)*PARTICLE_MEM;
				if(nextIndex==maxPart){
					nextIndex = 0;
				}else{
					++total;
				}

				float pX = x + (float)((randFract()*(xSpread))-hXSpread);
				if(pX>screenW)pX = screenW;
				else if(pX<0)pX = 0;

				float pY = y + (float)((randFract()*(ySpread))-hYSpread);
				if(pY>screenH)pY = screenH;
				else if(pY<0)pY = 0;

				*(pp++) = (float)(randFract()*(ageVar)+invAgeVar);
				*(pp++) = pX;
				*(pp++) = pY;
				*(pp++) = initVX;
				*(pp++) = initVY;
				*(pp++) = (float)(randFract()*(massVar)+invMassVar);
				*(pp++) = emitterIndex;
				pp++;
			}
			particlesNextIndex[emitterIndex] = nextIndex;
			if(total<maxPart){
				particlesNum[emitterIndex] = total;
			}else{
				particlesNum[emitterIndex] = maxPart;
			}

			if(emitterDecay!=0 && emitterDecay!=1){
				rate *= emitterDecay;
				*(particleEmitters+emitterIndex*EMITTER_MEM+2) = rate;
			}
		}
		particleOffset += maxPart * PARTICLE_MEM;
		++emitterIndex;
	}
	if(_drawFluid)drawFluidImage();
	if(_doParticles)updateParticles(timeDelta);
}
void clearParticles()
{
	register double *pep;
	for(int i=0; i<particleEmittersSet; i++)
	{
		particlesNum[i] = 0;
		particlesNextIndex[i] = 0;
	}

	memset(particles, 0.0, totalParticles*PARTICLE_MEM*sizeof(float));
	memset(particles2, 0.0, totalParticles*PARTICLE_MEM*sizeof(float));
	
	_particles = particles;
	_particles2 = particles2;
}
void changeParticleEmitter(int index,  double x, double y, double rate, double xSpread, double ySpread, double ageVar, double massVar, double emitterDecay, double particleDecay, double initVX, double initVY){
	if(index>particleEmitterMax){
		printf("ERROR: setting emitter out of range (%i)\n", particleEmitterMax);
		return;
	}
	register double *pp = particleEmitters+index*EMITTER_MEM;
	*(pp ++) = x * screenW;
	*(pp ++) = y * screenH;
	*(pp ++) = rate;
	*(pp ++) = xSpread;
	*(pp ++) = ySpread;
	*(pp ++) = ageVar;
	*(pp ++) = massVar;
	*(pp ++) = emitterDecay;
	*(pp ++) = particleDecay;
	*(pp ++) = initVX;
	*(pp ++) = initVY;
	if(particleEmittersSet < index + 1)particleEmittersSet = index + 1;
}
int addParticleEmitter(double x, double y, double rate, double xSpread, double ySpread, double ageVar, double massVar, double emitterDecay, double particleDecay, double initVX, double initVY){
	int emitterIndex = ++nextEmitterIndex;
	if(nextEmitterIndex==particleEmitterMax){
		nextEmitterIndex = 0;
	}
	if(particleEmittersSet<particleEmitterMax){
		particleEmittersSet++;
	}
	changeParticleEmitter(emitterIndex, x, y, rate, xSpread, ySpread, ageVar, massVar, emitterDecay, particleDecay, initVX, initVY);

	return emitterIndex;
}

void setForce(double tx, double ty, double dx, double dy){

	int nx = (int)(tx * (gridW+2));
	int ny = (int)(ty * (gridH+2));
	if(nx < 1) nx=1; else if(nx > gridW) nx = gridW;
	if(ny < 1) ny=1; else if(ny > gridH) ny = gridH;

	int index = (nx + (gridW+2) * ny);
	*(uOld + index) += dx;
	*(vOld + index) += dy;
}


void setColour(double tx, double ty, float r, float g, float b){

	int nx = (int)(tx * (gridW+2));
	int ny = (int)(ty * (gridH+2));
	if(nx < 1) nx=1; else if(nx > gridW) nx = gridW;
	if(ny < 1) ny=1; else if(ny > gridH) ny = gridH;

	int index = (nx + (gridW+2) * ny);
	*(rOld + index) += r;
	*(gOld + index) += g;
	*(bOld + index) += b;
}

void setForceAndColour(double tx, double ty, double dx, double dy, float r, float g, float b){

	int nx = (int)(tx * (gridW+2));
	int ny = (int)(ty * (gridH+2));
	if(nx < 1) nx=1; else if(nx > gridW) nx = gridW;
	if(ny < 1) ny=1; else if(ny > gridH) ny = gridH;

	int index = (nx + (gridW+2) * ny);
	*(uOld + index) += dx;
	*(vOld + index) += dy;
	*(rOld + index) += r;
	*(gOld + index) += g;
	*(bOld + index) += b;
}

double* getParticleEmittersPos()
{
	return particleEmitters;
}
float** getParticlesDataPos()
{
	return &_particles;
}

int* getEmittersSetPos()
{
	return &particleEmittersSet;
}
int* getParticlesCountPos()
{
	return particlesNum;
}
int* getParticlesMaxPos()
{
	return particleEmitterCounts;
}
int* getFluidImagePos()
{
	return fluidsImage;
}
void setWrapping(int wrapX, int wrapY)
{
	wrap_x = wrapX;
	wrap_y = wrapY;
}

void setFluidForce(double fluidForce)
{
	_fluidForce = fluidForce;
}
void setColorDiffusion(double colorDiffusion)
{
	_colorDiffusion = colorDiffusion;
}
void setSolverIterations(int solverIterations)
{
	_solverIterations = solverIterations;
}
void setVorticityConfinement(int doVorticityConfinement)
{
	_doVorticityConfinement = doVorticityConfinement;
}
void setFadeSpeed(double fadeSpeed)
{
	_fadeSpeed = fadeSpeed;
}
void setViscosity(double viscosity)
{
	_visc = viscosity;
}

double getFluidForce()
{
	return _fluidForce;
}
double getColorDiffusion()
{
	return _colorDiffusion;
}
int getSolverIterations()
{
	return _solverIterations;
}
int getVorticityConfinement()
{
	return _doVorticityConfinement;
}
double getFadeSpeed()
{
	return _fadeSpeed;
}
double getViscosity()
{
	return _visc;
}

void setGravity(float x, float y)
{
	gravityX = x / 10;
	gravityY = y / 10;

}