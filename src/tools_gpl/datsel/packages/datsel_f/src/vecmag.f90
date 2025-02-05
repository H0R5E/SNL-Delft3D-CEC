subroutine vecmag(u         ,v         ,um        ,k         ,nm        )
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
!  $Id: vecmag.f90 4612 2015-01-21 08:48:09Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/tools_gpl/datsel/packages/datsel_f/src/vecmag.f90 $
!!--description-----------------------------------------------------------------
! NONE
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
    use precision
    implicit none
! Global variables
!
    integer, intent(in)            :: nm
    integer, dimension(nm), intent(in) :: k
    real(hp), dimension(nm) :: u
    real(hp), dimension(nm), intent(out) :: um
    real(hp), dimension(nm) :: v
!
!
! Local variables
!
    integer  :: i
    real(hp) :: arg
!
!
!! executable statements -------------------------------------------------------
!
    !
    !
    !
    write (*, *) ' VECMAG'
    do i = 1, nm
       if (k(i)==1) then
          arg = u(i)**2 + v(i)**2
          if (arg>0) then
             um(i) = sqrt(arg)
          else
             um(i) = 0.
          endif
       else
          u(i) = 0.
          v(i) = 0.
          um(i) = 0.
       endif
    enddo
end subroutine vecmag
