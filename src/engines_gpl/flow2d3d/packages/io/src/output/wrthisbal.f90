subroutine wrthisbal(ithisc    ,filename  ,lundia    ,error     ,irequest  , &
                   & fds       ,gdp       )
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
!  $Id: wrthisbal.f90 4649 2015-02-04 15:38:11Z ye $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/engines_gpl/flow2d3d/packages/io/src/output/wrthisbal.f90 $
!!--description-----------------------------------------------------------------
!
! Writes the time varying mass balance data to the FLOW HIS file
!
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
    use precision
    use datagroups
    use globaldata
    use netcdf, only: nf90_unlimited
    use dfparall, only: inode, master
    use wrtarray, only: wrtvar
    !
    implicit none
    !
    type(globdat),target :: gdp
    !
    ! The following list of pointer parameters is used to point inside the gdp structure
    !
    integer                        , pointer :: celidt
    type (datagroup)               , pointer :: group
    !
    logical                        , pointer :: massbal
    integer                        , pointer :: nbalpol
    integer                        , pointer :: nneighb
    integer      , dimension(:,:)  , pointer :: neighb
    real(fp)     , dimension(:)    , pointer :: accdps
    real(fp)     , dimension(:)    , pointer :: horareas
    real(fp)     , dimension(:)    , pointer :: volumes
    real(fp)     , dimension(:,:)  , pointer :: mass_r1
    real(fp)     , dimension(:,:)  , pointer :: fluxes
    real(fp)     , dimension(:,:,:), pointer :: fluxes_r1
    real(fp)     , dimension(:,:,:), pointer :: fluxes_sd
    !
    integer                        , pointer :: lstsci
    integer                        , pointer :: lsedtot
!
! Global variables
!
    integer                                                             , intent(in)  :: irequest !  REQUESTTYPE_DEFINE: define variables, REQUESTTYPE_WRITE: write variables
    integer                                                             , intent(in)  :: ithisc   !!  Current time counter for the HIS data file
    integer                                                             , intent(in)  :: lundia   !  Description and declaration in inout.igs
    character(*)                                                        , intent(in)  :: filename !  File name
    logical                                                             , intent(out) :: error    !!  Flag=TRUE if an error is encountered
    integer                                                             , intent(in)  :: fds      !  File handle of output NEFIS/NetCDF file
!
! Local variables
!
    integer                                           :: iddim_time
    integer                                           :: iddim_nbalpol
    integer                                           :: iddim_nneighb
    integer                                           :: iddim_lsedtot
    integer                                           :: iddim_lstsci
    integer                                           :: iddim_2
    !
    integer                                           :: idatt_coord
    !
    real(fp)        , dimension(:)    , allocatable   :: rbuff1
    real(fp)        , dimension(:,:)  , allocatable   :: rbuff2
    integer                                           :: filetype
    integer                                           :: istat
    integer                                           :: ierror       ! Local error flag
    integer                                           :: l
    integer                                           :: n
    character(16)                                     :: grpnam       ! Data-group name for the NEFIS-file
!
!! executable statements -------------------------------------------------------
!
    massbal        => gdp%gdmassbal%massbal
    if (.not. massbal) return
    !
    grpnam = 'his-bal-series'
    call getdatagroup(gdp, FILOUT_HIS, grpnam, group)
    celidt         => group%celidt
    filetype = getfiletype(gdp, FILOUT_HIS)
    !
    nbalpol        => gdp%gdmassbal%nbalpol
    nneighb        => gdp%gdmassbal%nneighb
    neighb         => gdp%gdmassbal%neighb
    accdps         => gdp%gdmassbal%accdps
    horareas       => gdp%gdmassbal%horareas
    volumes        => gdp%gdmassbal%volumes
    mass_r1        => gdp%gdmassbal%mass_r1
    fluxes         => gdp%gdmassbal%fluxes
    fluxes_r1      => gdp%gdmassbal%fluxes_r1
    fluxes_sd      => gdp%gdmassbal%fluxes_sd
    !
    lstsci         => gdp%d%lstsci
    lsedtot        => gdp%d%lsedtot
    !
    ierror = 0
    select case (irequest)
    case (REQUESTTYPE_DEFINE)
       !
       ! Set up the element chracteristics
       !
       iddim_time    = adddim(gdp, lundia, FILOUT_HIS, 'time', nf90_unlimited)
       iddim_nbalpol = adddim(gdp, lundia, FILOUT_HIS, 'nbalpolygons', nbalpol)
       iddim_nneighb = adddim(gdp, lundia, FILOUT_HIS, 'nbalneighbrs', nneighb)
       iddim_lsedtot = adddim(gdp, lundia, FILOUT_HIS, 'LSEDTOT', lsedtot)
       iddim_lstsci  = adddim(gdp, lundia, FILOUT_HIS, 'LSTSCI', lstsci)
       iddim_2       = adddim(gdp, lundia, FILOUT_HIS, 'length_2', 2)
       !
       idatt_coord    = addatt(gdp, lundia, FILOUT_HIS, 'coordinates', 'BALVOLNAMES')
       !
       if (filetype /= FTYPE_NETCDF) then ! don't store duplicate times
          call addelm(gdp, lundia, FILOUT_HIS, grpnam, 'ITHISC', ' ', IO_INT4       , 0, longname='timestep number (ITHISC*DT*TUNIT := time in sec from ITDATE)')
       endif
       call addelm(gdp, lundia, FILOUT_HIS, grpnam, 'BALVOLUME', ' ', IO_REAL4   , 1, dimids=(/iddim_nbalpol/), longname='Volume within polygon', unit='m3', attribs=(/idatt_coord/) )
       call addelm(gdp, lundia, FILOUT_HIS, grpnam, 'BALFLUX', ' ', IO_REAL4     , 2, dimids=(/iddim_2, iddim_nneighb/), longname='Accumulated flux between polygons', unit='m3')
       if (lstsci>0) then
          call addelm(gdp, lundia, FILOUT_HIS, grpnam, 'BALR1CONC', ' ', IO_REAL4, 2, dimids=(/iddim_nbalpol, iddim_lstsci/), longname='Average concentration within polygon', attribs=(/idatt_coord/) )
          call addelm(gdp, lundia, FILOUT_HIS, grpnam, 'BALR1FLUX', ' ', IO_REAL4, 3, dimids=(/iddim_2, iddim_nneighb, iddim_lstsci/), longname='Accumulated constituent flux between polygons')
       endif
       if (lsedtot>0) then
          call addelm(gdp, lundia, FILOUT_HIS, grpnam, 'BALDPS', ' ', IO_REAL4   , 1, dimids=(/iddim_nbalpol/), longname='Average bottom depth within polygon', unit='m', attribs=(/idatt_coord/) )
          call addelm(gdp, lundia, FILOUT_HIS, grpnam, 'BALSDFLUX', ' ', IO_REAL4, 3, dimids=(/iddim_2, iddim_nneighb, iddim_lsedtot/), longname='Accumulated sediment flux between polygons')
       endif
       !
       group%grp_dim = iddim_time
       celidt = 0
       !
    case (REQUESTTYPE_WRITE)
       !
       celidt = celidt + 1
       !
       if (inode == master) then
          if (filetype /= FTYPE_NETCDF) then ! don't store duplicate times
             call wrtvar(fds, filename, filetype, grpnam, celidt, &
                       & gdp, ierror, lundia, ithisc, 'ITHISC')
             if (ierror/=0) goto 9999
          endif
          !
          call wrtvar(fds, filename, filetype, grpnam, celidt, &
                    & gdp, ierror, lundia, volumes, 'BALVOLUME')
          if (ierror/= 0) goto 9999
          !
          call wrtvar(fds, filename, filetype, grpnam, celidt, &
                    & gdp, ierror, lundia, fluxes, 'BALFLUX')
          !
          if (lstsci>0) then
             allocate(rbuff2(nbalpol,lstsci), stat=istat)
             do l = 1,lstsci
                do n = 1,nbalpol
                   rbuff2(n,l) = mass_r1(n,l)/volumes(n)
                enddo
             enddo
             call wrtvar(fds, filename, filetype, grpnam, celidt, &
                       & gdp, ierror, lundia, rbuff2, 'BALR1CONC')
             deallocate(rbuff2)
             if (ierror/= 0) goto 9999
             !
             call wrtvar(fds, filename, filetype, grpnam, celidt, &
                       & gdp, ierror, lundia, fluxes_r1, 'BALR1FLUX')
          endif
          !
          if (lsedtot>0) then
             allocate(rbuff1(nbalpol), stat=istat)
             do n = 1,nbalpol
                rbuff1(n) = accdps(n)/horareas(n)
             enddo
             call wrtvar(fds, filename, filetype, grpnam, celidt, &
                       & gdp, ierror, lundia, rbuff1, 'BALDPS')
             deallocate(rbuff1)
             if (ierror/= 0) goto 9999
             !
             call wrtvar(fds, filename, filetype, grpnam, celidt, &
                       & gdp, ierror, lundia, fluxes_sd, 'BALSDFLUX')
             if (ierror/= 0) goto 9999
          endif
       endif
       !
    end select
    !
    ! write error message if error occured and set error = .true.
    !
9999   continue
    if (ierror /= 0) error = .true.
end subroutine wrthisbal
