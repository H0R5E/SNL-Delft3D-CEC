subroutine write_bnd_loc (inest,sg)
!
! Head routine for calling write_bnd
!
use swan_flow_grid_maps
use read_grids
implicit none
type (grid)                 :: sg       ! actual swan grid
integer                     :: inest    ! swan nested grid no.
   call write_bnd(sg%x        ,sg%y       ,sg%mmax   ,sg%nmax   , &
                & inest      )
   call write_swan_grid (sg%x,sg%y,sg%mmax,sg%nmax,inest,sg%tmp_name)
end subroutine write_bnd_loc


subroutine write_bnd(xc        ,yc        ,mc        ,nc        , &
                & inest      )
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
!  $Id: write_bnd_loc.f90 4612 2015-01-21 08:48:09Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/engines_gpl/wave/packages/io/src/write_bnd_loc.f90 $
!!--description-----------------------------------------------------------------
! NONE
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
    use precision_basics
    !
    implicit none
!
! Global variables
!
    integer                   , intent(in)  :: inest
    integer                   , intent(in)  :: mc
    integer                   , intent(in)  :: nc
    real(kind=hp)   , dimension(mc, nc)     :: xc
    real(kind=hp)   , dimension(mc, nc)     :: yc
!
! Local variables
!
    integer           :: i
    integer           :: j
    integer           :: lunbot
    integer, external :: new_lun
    character(37)     :: fname
!
!! executable statements -------------------------------------------------------
!
    if (inest>1) then
       fname      = ' '
       fname(1:12) = 'SWANIN_NGRID'
       write (fname(13:15),'(I3.3)') inest
       lunbot = new_lun()
       open (unit=lunbot, file=fname(1:15))
       do i=1,mc
          if (xc(i,1)/=0.) write(lunbot,'(2(F15.6,3X))')  xc(i,1) ,yc(i,1)
       enddo
       do j=2,nc
          if (xc(mc,j)/=0.) write(lunbot,'(2(F15.6,3X))')  xc(mc,j),yc(mc,j)
       enddo
       do i=mc-1,1,-1
          if (xc(i,nc)/=0.) write(lunbot,'(2(F15.6,3X))')  xc(i,nc),yc(i,nc)
       enddo
       do j=nc-1,2,-1
          if (xc(1,j)/=0.) write(lunbot,'(2(F15.6,3X))')  xc(1,j) ,yc(1,j)
       enddo
       close(lunbot)
    endif
end subroutine write_bnd
