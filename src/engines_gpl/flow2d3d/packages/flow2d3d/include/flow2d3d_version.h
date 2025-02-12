#ifndef FLOW2D3D_VERSION
#define FLOW2D3D_VERSION

#define CAT(a, b) a ## b
#define FUNC_CAT(a, b) CAT(a, b)

#define MOD_NAME         FLOW2D3D
#define modname_program  "FLOW2D3D"
#if HAVE_CONFIG_H
#   define F90_MOD_NAME   FC_FUNC(flow2d3d, FLOW2D3D)
#else
#   define F90_MOD_NAME   MOD_NAME
#endif

#define modname_major "6"
#define modname_minor "02"
#define modname_revision "04"
#define modname_build "000000"

#define modname_company "Deltares"
#define modname_company_url  = "http://www.deltares.nl"

/*=================================================== DO NOT MAKE CHANGES BELOW THIS LINE ===================================================================== */

static char modname_version       [] = {modname_major"."modname_minor"."modname_revision"."modname_build};
static char modname_version_short [] = {modname_major"."modname_minor};
static char modname_version_full  [] = {modname_company", "modname_program" Version "modname_major"."modname_minor"."modname_revision"."modname_build", "__DATE__", "__TIME__""};

/* Needed for the output file headers */
static char com_file_version       [] = {"3.55.00"};
static char dro_file_version       [] = {"3.20.01"};
static char his_file_version       [] = {"3.52.11"};
static char map_file_version       [] = {"3.54.30"};

#if HAVE_CONFIG_H
#   include "config.h"
#   define STDCALL  /* nothing */
#   define GETSHORTVERSIONSTRING FUNC_CAT( FC_FUNC(getshortversionstring,GETSHORTVERSIONSTRING), F90_MOD_NAME)
#   define GETFULLVERSIONSTRING FUNC_CAT( FC_FUNC(getfullversionstring,GETFULLVERSIONSTRING), F90_MOD_NAME)
#   define GETCOMFILEVERSIONSTRING FUNC_CAT( FC_FUNC(getcomfileversionstring,GETCOMFILEVERSIONSTRING), F90_MOD_NAME)
#   define GETDROFILEVERSIONSTRING FUNC_CAT( FC_FUNC(getdrofileversionstring,GETDROFILEVERSIONSTRING), F90_MOD_NAME)
#   define GETHISFILEVERSIONSTRING FUNC_CAT( FC_FUNC(gethisfileversionstring,GETHISFILEVERSIONSTRING), F90_MOD_NAME)
#   define GETMAPFILEVERSIONSTRING FUNC_CAT( FC_FUNC(getmapfileversionstring,GETMAPFILEVERSIONSTRING), F90_MOD_NAME)
#else
// WIN32
#   define STDCALL  /* nothing */
#   define GETSHORTVERSIONSTRING FUNC_CAT( GETSHORTVERSIONSTRING_, F90_MOD_NAME)
#   define GETFULLVERSIONSTRING FUNC_CAT( GETFULLVERSIONSTRING_, F90_MOD_NAME)
#   define GETCOMFILEVERSIONSTRING FUNC_CAT( GETCOMFILEVERSIONSTRING_, F90_MOD_NAME)
#   define GETDROFILEVERSIONSTRING FUNC_CAT( GETDROFILEVERSIONSTRING_, F90_MOD_NAME)
#   define GETHISFILEVERSIONSTRING FUNC_CAT( GETHISFILEVERSIONSTRING_, F90_MOD_NAME)
#   define GETMAPFILEVERSIONSTRING FUNC_CAT( GETMAPFILEVERSIONSTRING_, F90_MOD_NAME)
#endif


#if (defined(__cplusplus)||defined(_cplusplus))
extern "C" {
#endif

void   STDCALL GETSHORTVERSIONSTRING( char *, int );
void   STDCALL GETFULLVERSIONSTRING( char *, int );
void   STDCALL GETCOMFILEVERSIONSTRING( char *, int );
void   STDCALL GETDROFILEVERSIONSTRING( char *, int );
void   STDCALL GETHISFILEVERSIONSTRING( char *, int );
void   STDCALL GETMAPFILEVERSIONSTRING( char *, int );

#if (defined(__cplusplus)||defined(_cplusplus))
}
#endif

#endif /* FLOW2D3D_VERSION */

