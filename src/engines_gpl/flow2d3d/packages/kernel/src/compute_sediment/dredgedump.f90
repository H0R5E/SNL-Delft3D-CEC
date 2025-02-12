subroutine dredgedump(dbodsd    ,cdryb     ,nst       ,timhr     ,morft     , &
                    & gdp       )
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
!  $Id: dredgedump.f90 4612 2015-01-21 08:48:09Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/engines_gpl/flow2d3d/packages/kernel/src/compute_sediment/dredgedump.f90 $
!!--description-----------------------------------------------------------------
!
! Switch from nm to n,m
!
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
    use precision
    !
    use globaldata
    !
    implicit none
    !
    type(globdat),target :: gdp
    !
    ! The following list of pointer parameters is used to point inside the gdp structure
    !
    include 'fsm.i'
    include 'tri-dyn.igd'
    integer(pntrsize)     , pointer :: dps
    integer(pntrsize)     , pointer :: s1
    integer , dimension(:), pointer :: kfsed
    integer               , pointer :: nmmax
    integer               , pointer :: lsedtot
!
! Global variables
!
    integer                                            , intent(in) :: nst
    real(hp)                                           , intent(in) :: morft
    real(fp)                                           , intent(in) :: timhr
    real(fp), dimension(gdp%d%lsedtot)                 , intent(in) :: cdryb   !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(gdp%d%lsedtot, gdp%d%nmlb:gdp%d%nmub)       :: dbodsd  !  Description and declaration in esm_alloc_real.f90
!
! Local variables
!
    real(fp) :: morhr
!
!! executable statements -------------------------------------------------------
!
    nmmax     => gdp%d%nmmax
    lsedtot   => gdp%d%lsedtot
    dps       => gdp%gdr_i_ch%dps
    s1        => gdp%gdr_i_ch%s1
    kfsed     => gdp%gderosed%kfsed
    !
    morhr = real(morft*24.0_hp,fp)
    call dredge(nmmax   ,lsedtot ,nst     , &
              & cdryb   ,d(dps)  ,dbodsd  ,kfsed   , &
              & r(s1)   ,timhr   ,morhr   ,gdp     )
end subroutine dredgedump
