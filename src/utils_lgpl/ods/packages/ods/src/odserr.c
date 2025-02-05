//---- LGPL --------------------------------------------------------------------
//
// Copyright (C)  Stichting Deltares, 2011-2015.
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation version 2.1.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, see <http://www.gnu.org/licenses/>.
//
// contact: delft3d.support@deltares.nl
// Stichting Deltares
// P.O. Box 177
// 2600 MH Delft, The Netherlands
//
// All indications and logos of, and references to, "Delft3D" and "Deltares"
// are registered trademarks of Stichting Deltares, and remain the property of
// Stichting Deltares. All rights reserved.
//
//------------------------------------------------------------------------------

/* @begin@ */
/*
 *  odserr.c -  ODS routine to return error text
 *
 *  Copyright (C)  Stichting Deltares, 2011-2015.
 *
 *  Arjen Markus
 */

/*
 *  General information:
 *  This file contains the following functions:
 *  - odserr():    Return error text
 */

/*
 *  $Author: Markus $
 *  $Date: 1-04-03 10:52 $
 *  $Source: /u/cvsroot/gpp/libsrc/ods/odserr.c,v $
 */

/* @end@ */

/*
 * Include files and definitions
 */

#include <stdlib.h>
#include "ods.h"

/*
 * Static variables
 */

static char *ods_error_text[100] ;

#ifndef NOPROTO
   void DllExport odserr( long ierror , char **text )
#else
   void DllExport odserr( ierror , text )
   long ierror ;
   char **text  ;
#endif
{
    static int init = 1 ;

/* Initialise the array
*/
    if ( init == 1 )
    {
       init = 0 ;
       ods_error_text[IEOK  ] = "Okay" ;
       ods_error_text[IEUNDE] = "Unable to determine filetype" ;
       ods_error_text[IEUNKN] = "File type not implemented in this version" ;
       ods_error_text[IETYPE] = "File is not of indicated type" ;
       ods_error_text[IENOFI] = "File does not exist" ;
       ods_error_text[IENOHA] = "No free handle (too many open files)" ;
       ods_error_text[IEFIAO] = "File already open" ;
       ods_error_text[IEFLCK] = "File locked by other program" ;
       ods_error_text[IEFIRO] = "Access denied/file is read-only" ;
       ods_error_text[IERLCK] = "Record locked by other program" ;
       ods_error_text[IENLCK] = "Cannot lock file/record/share not installed" ;
       ods_error_text[IEFNNW] = "File not new" ;
       ods_error_text[IEINFO] = "File does not contain wanted information" ;
       ods_error_text[IEUEOF] = "Unexpected end of file" ;
       ods_error_text[IEPMNY] = "Too many parameters found for array space" ;
       ods_error_text[IELMNY] = "Too many locations found for array space" ;
       ods_error_text[IETMNY] = "Too many times found for array space" ;
       ods_error_text[IEPLOW] = "Nr. of parameters < 1" ;
       ods_error_text[IELLOW] = "Nr. of locations < 1" ;
       ods_error_text[IETLOW] = "Nr. of times < 1" ;
       ods_error_text[IETIME] = "Bad date/time format" ;
       ods_error_text[IERUNI] = "RunId not equal" ;
       ods_error_text[IEPARI] = "Par.  not equal" ;
       ods_error_text[IELOCI] = "Loc.  not equal" ;
       ods_error_text[IETIMI] = "Time  not equal" ;
       ods_error_text[IESTEP] = "Timestep too small (time can not be represented)" ;
       ods_error_text[IEBUFF] = "Buffer space too small (warn WL technical support)" ;
       ods_error_text[IEDISK] = "No space left on device" ;
       ods_error_text[IEOTHR] = "Error of unspecified nature" ;
    }

/* Set a pointer to the error text
*/
    if ( ierror < 0 || ierror > 99 )
    {
       *text = NULL ;
    }
    else
    {
       *text = ods_error_text[ierror] ;
    }

/* Make sure an understandable text is returned
*/
    if ( *text == NULL )
    {
       *text = "Unknown error code" ;
    }
    return ;
}

/* Quick hack: solve unresolved external problem in Delft-FEWS
*/
void DllExport odserr2( long ierror , char **text ) {
    odserr( ierror, text );
}
