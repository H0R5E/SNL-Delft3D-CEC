subroutine write_wave_map_wind (sg, sof, n_swan_grids, wavedata, casl)
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
!  $Id: write_wave_map_wind.f90 4612 2015-01-21 08:48:09Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/engines_gpl/wave/packages/io/src/write_wave_map_wind.f90 $
!!--description-----------------------------------------------------------------
! NONE
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
    use wave_data
    use swan_flow_grid_maps
    !
    implicit none
!
! Local parameters
!
    integer, parameter :: nelmx = 3
!
! Global variables
!
    integer     , intent(in)  :: n_swan_grids ! number of swan grids
    character(*), intent(in)  :: casl         ! runid
    type (grid)               :: sg           ! swan grid
    type (output_fields)      :: sof          ! output fields defined on swan grid
    type (wave_data_type)     :: wavedata
!
! Local variables
!
    integer                         :: celidt
    integer                         :: error
    integer                         :: ind
    integer, dimension(1)           :: idummy ! Help array to read/write Nefis files 
    integer, dimension(6, nelmx)    :: elmdms
    integer, dimension(nelmx)       :: nbytsg
    logical                         :: wrswch
    character(10), dimension(nelmx) :: elmunt
    character(16)                   :: grpnam
    character(16), dimension(nelmx) :: elmnms
    character(16), dimension(nelmx) :: elmqty
    character(16), dimension(nelmx) :: elmtps
    character(256)                  :: filnam
    character(64), dimension(nelmx) :: elmdes
    character(256)                  :: gridnam
    !
    !     Define data structure; element dimensions are required only
    !     in write-mode.
    !
    data grpnam/'WIND'/
    data elmnms/'TIME', 'WINDU ', 'WINDV'/
    data elmdes/'time',                                                     &
        & 'x-component wind velocity                                     ', &
        & 'y-component wind velocity                                     '/
    data elmqty/nelmx*' '/
    data elmunt/'[TSCALE] ', '[ M/S ]  ', '[ M/S ]  '/
    data elmtps/'INTEGER', 2*'REAL'/
    data nbytsg/nelmx*4/
!
!! executable statements -------------------------------------------------------
!
    wrswch = .true.
    if (n_swan_grids == 1) then
       write(filnam,'(2a)')'wavm-',trim(casl)
    else
       gridnam = sg%grid_name
       ind = index(gridnam, '/', back = .true.)
       if (ind > 0) gridnam = gridnam(ind+1:)
       ind = index(gridnam, '\', back = .true.)
       if (ind > 0) gridnam = gridnam(ind+1:)
       ind = index(gridnam, '.', back = .true.)
       if (ind > 0) gridnam = gridnam(:ind-1)
       write(filnam,'(4a)')'wavm-',trim(casl),'-',trim(gridnam)
    endif
    !
    call filldm(elmdms, 1, 1, 1       , 0       , 0, 0, 0)
    call filldm(elmdms, 2, 2, sof%mmax, sof%nmax, 0, 0, 0)
    call filldm(elmdms, 3, 2, sof%mmax, sof%nmax, 0, 0, 0)
    !
    !        Write all elements to file; all
    !        definition and creation of files, data groups, cells and
    !        elements is handled by PUTGET
    !
    celidt=wavedata%output%count
    idummy(1) = wavedata%time%calctimtscale
    call putgti(filnam   , grpnam, nelmx , elmnms, elmdms    , &
              & elmqty   , elmunt, elmdes, elmtps, nbytsg    , &
              & elmnms(1), celidt, wrswch, error , idummy(1) )
    call putgtr(filnam   , grpnam, nelmx , elmnms, elmdms   , &
              & elmqty   , elmunt, elmdes, elmtps, nbytsg   , &
              & elmnms(2), celidt, wrswch, error , sof%windu)

    call putgtr(filnam   , grpnam, nelmx , elmnms, elmdms   , &
              & elmqty   , elmunt, elmdes, elmtps, nbytsg   , &
              & elmnms(3), celidt, wrswch, error , sof%windv)
              
end subroutine write_wave_map_wind
