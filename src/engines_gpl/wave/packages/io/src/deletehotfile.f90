function deletehotfile(wavedata) result (dodelete)
!----- GPL ---------------------------------------------------------------------
!                                                                               
!  Copyright (C)  Stichting Deltares, 2011-2015.                                
!                                                                               
!  This program is free software: you can redistribute it and/or modify         
!  it under the terms of the GNU General Public License as published by         
!  the Free Software Foundation version 3.                                      
!                                                                               
!  This program is distributed in the hope that it will be useful,              
!  but WITHOUT ANY WARRANTY; without even the implied warranty of               
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                
!  GNU General Public License for more details.                                 
!                                                                               
!  You should have received a copy of the GNU General Public License            
!  along with this program.  If not, see <http://www.gnu.org/licenses/>.        
!                                                                               
!  contact: delft3d.support@deltares.nl                                         
!  Stichting Deltares                                                           
!  P.O. Box 177                                                                 
!  2600 MH Delft, The Netherlands                                               
!                                                                               
!  All indications and logos of, and references to, "Delft3D" and "Deltares"    
!  are registered trademarks of Stichting Deltares, and remain the property of  
!  Stichting Deltares. All rights reserved.                                     
!                                                                               
!-------------------------------------------------------------------------------
!  $Id: deletehotfile.f90 4612 2015-01-21 08:48:09Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/engines_gpl/wave/packages/io/src/deletehotfile.f90 $
!!--description-----------------------------------------------------------------
!
!    Function: Return true if the hotfile with time hotfiletime can be deleted
!
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
use precision
use wave_data
use swan_input
!
implicit none
!
! Global variables
!
logical        :: dodelete
type(wave_data_type), target :: wavedata
!
! Local variables
!
real(hp)                :: rkeeptime
real(hp)                :: rusetime
real, pointer           :: timseckeephot
character(15), external :: datetime_to_string
!
!! executable statements -------------------------------------------------------
!
   timseckeephot => wavedata%output%timseckeephot
   ! Always delete the hotfile when
   ! - running standalone
   ! or
   ! - no "int2keephotfile" specified
   !
   if (wavedata%mode==stand_alone .or. comparereal(swan_run%int2keephotfile,0.0)<=0) then
      dodelete = .true.
      return
   endif
   read (swan_run%usehottime ,*) rusetime
   read (swan_run%keephottime,*) rkeeptime
   !
   ! increase rkeeptime until it is equal to or greater than rusetime
   !
   do while (comparereal(rkeeptime,rusetime) < 0)
      timseckeephot = timseckeephot + swan_run%int2keephotfile*60.0
      swan_run%keephottime = datetime_to_string(wavedata%time%refdate, timseckeephot)
      read (swan_run%keephottime,*) rkeeptime
   enddo
   if (comparereal(rkeeptime,rusetime) == 0) then
      dodelete = .false.
   else
      dodelete = .true.
   endif
end function deletehotfile
