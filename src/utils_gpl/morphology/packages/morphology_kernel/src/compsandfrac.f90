subroutine compsandfrac(frac      ,seddm     ,nmmax     ,lsedtot   , &
                      & sedtyp    ,sandfrac  ,sedd50fld , &
                      & nmlb      ,nmub      )
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
!  $Id: compsandfrac.f90 4612 2015-01-21 08:48:09Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/utils_gpl/morphology/packages/morphology_kernel/src/compsandfrac.f90 $
!!--description-----------------------------------------------------------------
!
!  compsandfrac returns the total proportion of sand sized material on the bed
!  surface (sandfrac). This is required in order to implement the Wilcock and
!  Crowe sediment transport formula.
!
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
    use precision
    !
    implicit none
!
! Parameters
!
    integer, parameter :: SEDTYP_NONCOHESIVE_TOTALLOAD = 0
    integer, parameter :: SEDTYP_NONCOHESIVE_SUSPENDED = 1
    integer, parameter :: SEDTYP_COHESIVE              = 2
!
! Global variables
!
    integer                                 , intent(in)  :: lsedtot   ! number of sediment fractions
    integer                                 , intent(in)  :: nmmax     ! last space index to be processed
    integer                                 , intent(in)  :: nmlb      ! start space index
    integer                                 , intent(in)  :: nmub      ! end space index
    integer , dimension(lsedtot)            , intent(in)  :: sedtyp    ! Sediment type: 0=total/1=noncoh/2=coh
    real(fp), dimension(nmlb:nmub, lsedtot) , intent(in)  :: frac      ! fractional composition of sediment
    real(fp), dimension(lsedtot)            , intent(in)  :: seddm     ! mean diameter of sediment fraction
    real(fp), dimension(nmlb:nmub)          , intent(out) :: sandfrac  ! sand fraction
    real(fp), dimension(nmlb:nmub)          , intent(in)  :: sedd50fld ! D50 field (in case of 1 sediment fraction)
!
! Local variables
!
    integer  :: l
    integer  :: nm
    real(fp) :: fracnonmud
    
!
!! executable statements -------------------------------------------------------
!
    if (lsedtot==1 .and. sedtyp(1) /= SEDTYP_COHESIVE) then
      ! Single size fraction
      do nm = 1, nmmax
        if (sedd50fld(nm) < 0.002_fp) then
          sandfrac(nm) = 1
        else
          sandfrac(nm) = 0
        endif
      enddo
    else
      ! Multiple size fractions
      do nm = 1, nmmax
        fracnonmud = 0.0_fp
        sandfrac(nm) = 0.0_fp
        do l = 1, lsedtot
          if (sedtyp(l) /= SEDTYP_COHESIVE) then
            fracnonmud = fracnonmud + frac(nm,l)
            if (seddm(l) < 0.002_fp) then
              sandfrac(nm) = sandfrac(nm) + frac(nm,l)                
            endif  
          endif         
           
        enddo
        
        if (fracnonmud > 0.0_fp) then
             sandfrac(nm) = sandfrac(nm) / fracnonmud
        endif
        
      enddo
    endif
end subroutine compsandfrac
