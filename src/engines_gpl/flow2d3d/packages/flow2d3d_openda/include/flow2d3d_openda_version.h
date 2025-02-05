#ifndef FLOW2D3D_OPENDA_VERSION
#define FLOW2D3D_OPENDA_VERSION

#define CAT(a, b) a ## b
#define FUNC_CAT(a, b) CAT(a, b)

#define MOD_NAME         FLOW2D3D_OPENDA
#define modname_program  "FLOW2D3D_OPENDA"
#if HAVE_CONFIG_H
#   define F90_MOD_NAME   FC_FUNC(flow2d3d_openda, FLOW2D3D_OPENDA)
#else
#   define F90_MOD_NAME   MOD_NAME
#endif

#define modname_major "2"
#define modname_minor "01"
#define modname_revision "00"
#define modname_build "000000"

#define modname_company "Deltares"
#define modname_company_url  = "http://www.deltares.nl"

/*=================================================== DO NOT MAKE CHANGES BELOW THIS LINE ===================================================================== */

static char modname_version       [] = {modname_major"."modname_minor"."modname_revision"."modname_build};
static char modname_version_short [] = {modname_major"."modname_minor};
static char modname_version_full  [] = {modname_company", "modname_program" Version "modname_major"."modname_minor"."modname_revision"."modname_build", "__DATE__", "__TIME__""};

#if HAVE_CONFIG_H
#   include "config.h"
#   define STDCALL  /* nothing */
#   define GETSHORTVERSIONSTRING FUNC_CAT( FC_FUNC(getshortversionstring,GETSHORTVERSIONSTRING), F90_MOD_NAME)
#   define GETFULLVERSIONSTRING FUNC_CAT( FC_FUNC(getfullversionstring,GETFULLVERSIONSTRING), F90_MOD_NAME)
#else
// WIN32
#   define STDCALL  /* nothing */
#   define GETSHORTVERSIONSTRING FUNC_CAT( GETSHORTVERSIONSTRING_, F90_MOD_NAME)
#   define GETFULLVERSIONSTRING FUNC_CAT( GETFULLVERSIONSTRING_, F90_MOD_NAME)
#endif


#if (defined(__cplusplus)||defined(_cplusplus))
extern "C" {
#endif

void   STDCALL GETSHORTVERSIONSTRING( char *, int );
void   STDCALL GETFULLVERSIONSTRING( char *, int );

#if (defined(__cplusplus)||defined(_cplusplus))
}
#endif

#endif // FLOW2D3D_OPENDA_VERSION

