subroutine usage ( )
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
!  $Id: usage.f90 4612 2015-01-21 08:48:09Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/engines_gpl/wave/packages/wave/src/usage.f90 $
!!--description-----------------------------------------------------------------
!
! Explains how to start the WAVE program
!
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
    implicit none
!
!! executable statements -------------------------------------------------------
!
    write(*,*)
    write(*,'(a)') 'Usage: waves.exe <mdw-file> [mode]'
    write(*,'(a)') '       <mdw-file>: Name of the (input) mdw-file'
    write(*,'(a)') '       [mode]    :   0  Run alone'
    write(*,'(a)') '                     1  Run in combination with Delft3D-FLOW'
    write(*,'(a)') '                     2  Run in combination with Delft3D-FLOW'
    write(*,'(a)') '                        Water and Mud interaction'
    write(*,'(a)') '                  default mode = 0'
    write(*,'(a)')
end subroutine usage
