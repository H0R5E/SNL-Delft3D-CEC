module m_rdstm
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
!  $Id: rdstm.f90 4750 2015-03-03 10:13:11Z jagers $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/utils_gpl/morphology/packages/morphology_io/src/rdstm.f90 $
!-------------------------------------------------------------------------------

use morphology_data_module
use bedcomposition_module
use precision
use m_rdsed
use m_rdmor
use m_rdtrafrm
!
private
!
public stmtype
!
public rdstm
public clrstm

type stmtype
    integer                                                :: iopsus
    real(fp)                                               :: fwfac
    type(sedpar_type)                        , pointer     :: sedpar
    type(morpar_type)                        , pointer     :: morpar
    type(bedcomp_data)                       , pointer     :: morlyr
    type(trapar_type)                        , pointer     :: trapar
    integer                                                :: lsedsus
    integer                                                :: lsedtot
    real(fp)      , dimension(:), allocatable              :: facdss
    real(fp)      , dimension(:,:), allocatable            :: ws
    character(20) , dimension(:), allocatable              :: namcon
end type stmtype

contains

subroutine rdstm(stm, griddim, filsed, filmor, filtrn, lundia, lsal, ltem, ltur, lsec, julrefday, nambnd, error)
!!--description-----------------------------------------------------------------
!
! Read sediment transport and morphology data from filsed, filemor and filtrn
! (and files referenced therein).
!
!!--declarations----------------------------------------------------------------
    use grid_dimens_module
    use properties ! includes tree_structures
    !
    implicit none
!
! Call variables
!
    type(stmtype)               , intent(out) :: stm
    type(griddimtype)   , target, intent(in)  :: griddim
    character(*)                , intent(in)  :: filsed
    character(*)                , intent(in)  :: filmor
    character(*)                , intent(in)  :: filtrn
    integer                     , intent(in)  :: lundia
    integer                     , intent(in)  :: lsal
    integer                     , intent(in)  :: ltem
    integer                     , intent(in)  :: ltur
    integer                     , intent(in)  :: lsec
    integer                     , intent(in)  :: julrefday
    character(20) , dimension(:), intent(in)  :: nambnd
    logical                     , intent(out) :: error
!
! Local variables
!
    type(tree_data)             , pointer     :: sedfil_tree
    type(tree_data)             , pointer     :: morfil_tree
    integer                   :: istat
    integer                   :: lstsci
    integer                   :: nto
    integer                   :: nmaxus
    integer                   :: nmlb
    integer                   :: nmub
    integer                   :: l
    !
    integer                   , parameter    :: NPARDEF = 20
    integer, dimension(2,NPARDEF)            :: ipardef
    real(fp), dimension(NPARDEF)             :: rpardef
!
!! executable statements -------------------------------------------------------
!
    error = .false.
    !
    allocate(stm%sedpar , stat = istat)
    allocate(stm%morpar , stat = istat)
    allocate(stm%trapar , stat = istat)
    allocate(stm%morlyr , stat = istat)
    !
    call nullsedpar(stm%sedpar)
    call nullmorpar(stm%morpar)
    call nulltrapar(stm%trapar)
    istat = initmorlyr (stm%morlyr)
    !
    call tree_create  ( "Sediment input", sedfil_tree )
    call tree_create  ( "Morphology input", morfil_tree )
    !
    nmaxus = griddim%nmax
    nmlb   = griddim%nmlb
    nmub   = griddim%nmub
    nto    = size(nambnd,1)
    !
    ! Open filsed file and determine the number of sediment fractions
    ! lsedsus (only fractions that included suspended transport advection diffusion solver)
    ! and lsedtot (total number of fractions). Fill names and sediment types in sedpar.
    ! Keep sediment file information in sedfil_tree.
    !
    call count_sed(lundia, error, stm%lsedsus, stm%lsedtot, filsed, &
                 & stm%sedpar, sedfil_tree)
    if (error) goto 999
    !
    lstsci = max(0,lsal,ltem) + stm%lsedsus
    !
    allocate(stm%facdss(stm%lsedsus)   , stat = istat)
    allocate(stm%namcon(lstsci+ltur), stat = istat)
    !
    if (lsal>0) then
       stm%namcon(lsal) = 'SALINITY'
    endif
    if (ltem>0) then
       stm%namcon(ltem) = 'TEMPERATURE'
    endif
    do l=1,stm%lsedsus
       stm%namcon(max(0,lsal,ltem) + l) = stm%sedpar%namsed(l)
    enddo
    !
    ! Read sediment and transport parameters
    !
    ! facdss set by rdsed
    ! iopsus set by rdsed
    ! sedpar filled by rdsed
    ! trapar set by rdtrafrm
    ! sedfil_tree NEEDS TO BE SET
    !
    ! Sediment input has been placed in input_tree in subroutine count_sed
    ! get pointer
    !
    call initrafrm(lundia, error, stm%lsedtot, stm%trapar)
    if (error) goto 999
    !
    call rdsed  (lundia, error, lsal, ltem, stm%lsedsus, &
               & stm%lsedtot, lstsci, ltur, stm%namcon, &
               & stm%iopsus, nmlb, nmub, filsed, &
               & sedfil_tree, stm%sedpar, stm%trapar, griddim)
    !
    ! Read morphology parameters
    !
    ! morpar filled by rdmor
    ! morlyr filled by rdmor
    ! morfil_tree set by rdmor
    ! fwfac set by rdmor
    !
    call rdmor  (lundia, error, filmor, lsec, stm%lsedtot, &
               & stm%lsedsus, nmaxus, nto, nambnd, julrefday, morfil_tree, &
               & stm%sedpar, stm%morpar, stm%fwfac, stm%morlyr, &
               & griddim)
    !
    ! Some other parameters are transport formula specific. Use the value
    ! historically specified in mor file as default.
    !
    ipardef = 0
    rpardef = 0.0_fp
    call setpardef(ipardef, rpardef, NPARDEF, -1, 1, stm%morpar%iopsus)
    call setpardef(ipardef, rpardef, NPARDEF, -1, 2, stm%morpar%aksfac)
    call setpardef(ipardef, rpardef, NPARDEF, -1, 3, stm%morpar%rwave)
    call setpardef(ipardef, rpardef, NPARDEF, -1, 4, stm%morpar%rdc)
    call setpardef(ipardef, rpardef, NPARDEF, -1, 5, stm%morpar%rdw)
    call setpardef(ipardef, rpardef, NPARDEF, -1, 6, stm%morpar%iopkcw)
    call setpardef(ipardef, rpardef, NPARDEF, -1, 7, stm%morpar%epspar)
    call setpardef(ipardef, rpardef, NPARDEF, -2, 1, stm%morpar%iopsus)
    call setpardef(ipardef, rpardef, NPARDEF, -2, 2, stm%morpar%pangle)
    call setpardef(ipardef, rpardef, NPARDEF, -2, 3, stm%morpar%fpco)
    call setpardef(ipardef, rpardef, NPARDEF, -2, 4, stm%morpar%subiw)
    call setpardef(ipardef, rpardef, NPARDEF, -2, 5, stm%morpar%epspar)
    !
    call rdtrafrm(lundia, error, filtrn, stm%lsedtot, &
                & ipardef, rpardef, NPARDEF, stm%trapar, &
                & stm%sedpar%sedtyp, stm%sedpar%sedblock, &
                & griddim)
    if (error) goto 999
    !--------------------------------------------------------------------------
    !
    ! Echo sediment and transport parameters
    !
    call echosed(lundia, error, stm%lsedsus, stm%lsedtot, &
               & stm%iopsus, stm%sedpar, stm%trapar)
    if (error) goto 999
    !
    ! Echo morphology parameters
    !
    call echomor(lundia, error, lsec, stm%lsedtot, nto, &
               & nambnd, stm%sedpar, stm%morpar)
    !
999 continue
    !
    ! we should deallocate sedfil_tree, morfil_tree but
    ! we can't deallocate sedfil_tree since parts are referenced from stm%sedpar
end subroutine rdstm

function clrstm(stm) result(istat)
!!--description-----------------------------------------------------------------
!
! Read sediment transport and morphology data from filsed, filemor and filtrn
! (and files referenced therein).
!
!!--declarations----------------------------------------------------------------
    use morphology_data_module
    implicit none
!
! Call variables
!
    type(stmtype)   , intent(inout) :: stm
    integer                         :: istat
!
! Local variables
!
!   NONE
!
!! executable statements -------------------------------------------------------
!
    istat = 0
    call clrsedpar(istat, stm%sedpar)
    if (istat==0) call clrmorpar(istat, stm%morpar)
    if (istat==0) call clrtrapar(istat, stm%trapar)
    if (istat==0) istat = clrmorlyr(stm%morlyr)
end function clrstm

end module m_rdstm
