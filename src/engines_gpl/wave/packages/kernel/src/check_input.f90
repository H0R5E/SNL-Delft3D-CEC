subroutine check_input(sr, wavedata)
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
!  $Id: check_input.f90 4612 2015-01-21 08:48:09Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/engines_gpl/wave/packages/kernel/src/check_input.f90 $
!!--description-----------------------------------------------------------------
!
!
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
   use precision
   use swan_input
   use wave_data
   !
   implicit none
!
! Global variables
!
   type(swan)                  :: sr
   type(wave_data_type)        :: wavedata
!
! Local variables
!
!
!! executable statements -------------------------------------------------------
!
    if (wavedata%mode /= stand_alone) then
       if (.not.sr%swwav) then
          write(*,'(a)') '*** ERROR: Online calculation but no writing to com-file'
          write(*,'(a)') '           Is flag ''WriteCOM'' set to true?'
          stop
       endif
    endif
end subroutine check_input
