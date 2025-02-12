!!  Copyright (C)  Stichting Deltares, 2012-2015.
!!
!!  This program is free software: you can redistribute it and/or modify
!!  it under the terms of the GNU General Public License version 3,
!!  as published by the Free Software Foundation.
!!
!!  This program is distributed in the hope that it will be useful,
!!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!!  GNU General Public License for more details.
!!
!!  You should have received a copy of the GNU General Public License
!!  along with this program. If not, see <http://www.gnu.org/licenses/>.
!!
!!  contact: delft3d.support@deltares.nl
!!  Stichting Deltares
!!  P.O. Box 177
!!  2600 MH Delft, The Netherlands
!!
!!  All indications and logos of, and references to registered trademarks
!!  of Stichting Deltares remain the property of Stichting Deltares. All
!!  rights reserved.

      subroutine dlwq42 ( nosys  , notot  , nototp , noseg  , volume ,
     &                    surface, amass  , conc   , deriv  , idt    ,
     &                    ivflag , lun    , owners , mypart )

!     Deltares Software Centre

!>\File
!>           Sets an explicit time step from DERIV.
!>
!>           This routine deviates from dlwq18 in the sense
!>           that the resulting masses are stored in CONC
!>           rather than in AMASS to allow for an implicit step.
!>           DERIV is set to the new diagonal. This procedure
!>           is required for the old ADI solver (nr. 4) and for
!>           the 2 solvers with implicit vertical (nrs. 11 & 12)

!     Created             :    April   1988 by Leo Postma

!     Modified            : 13 Januari 2011 by Leo Postma
!                                           2D arrays, fortran 90 look and feel
!                                           conc of passive substances in mass/m2
!                                           Also equiped with computed volumes
!                                           feature.
!                            4 April   2013 by Leo Postma
!                                           take presence of particle-substances into account

!     Logical unitnumbers : LUN     = number of monitoring file

!     Subroutines called  : none

      use timers

      implicit none

!     Parameters          :
!     type     kind  function         name                      description

      integer   (4), intent(in   ) :: nosys                   !< number of transported substances
      integer   (4), intent(in   ) :: notot                   !< total number of substances
      integer  ( 4), intent(in   ) :: nototp                  !< number of particle substances
      integer   (4), intent(in   ) :: noseg                   !< number of computational volumes
      real      (4), intent(inout) :: volume(noseg )          !< volumes of the segments
      real     ( 4), intent(in   ) :: surface(noseg)          !< horizontal surface area
      real      (4), intent(inout) :: amass (notot ,noseg)    !< masses per substance per volume
      real      (4), intent(inout) :: conc  (notot ,noseg)    !< concentrations per substance per volume
      real      (4), intent(inout) :: deriv (notot ,noseg)    !< derivatives per substance per volume
      integer   (4), intent(in   ) :: idt                     !< integration time step size
      integer   (4), intent(in   ) :: ivflag                  !< if 1 computational volumes
      integer   (4), intent(in   ) :: lun                     !< unit number of the monitoring file
      integer   (4), intent(in   ) :: owners(noseg )          !< ownership array for segments
      integer   (4), intent(in   ) :: mypart                  !< number of the current subdomain

!     local variables

      integer(4)          isys            ! loopcounter substances
      integer(4)          iseg            ! loopcounter computational volumes
      real   (4)          surf            ! the horizontal surface area of the cell
      real   (4)          vol             ! helpvariable for this volume
      integer(4), save :: ivmess          ! number of messages printed
      data       ivmess  /0/
      integer(4), save :: ithandl         ! timer handle
      data       ithandl /0/
      if ( timon ) call timstrt ( "dlwq42", ithandl )

!         loop accross the number of computational volumes for the concentrations

      do iseg = 1, noseg

!         compute volumes if necessary and check for positivity

         if ( ivflag .eq. 1 ) volume(iseg) = amass(1,iseg) + idt*deriv(1,iseg)
         vol = volume(iseg)
         if ( abs(vol) .lt. 1.0e-25 ) then
            if ( ivmess .lt. 25 ) then
               ivmess = ivmess + 1
               write ( lun, 1000 ) iseg  , vol
            elseif ( ivmess .eq. 25 ) then
               ivmess = ivmess + 1
               write ( lun, 1001 )
            endif
            volume (iseg) = 1.0
            vol           = 1.0
         endif

!         transported substances first

         do isys = 1, nosys
            conc (isys,iseg) = amass(isys,iseg) + idt*deriv(isys,iseg)
            deriv(isys,iseg) = vol
         enddo

!         then the passive substances

         if ( notot - nototp .gt. nosys ) then
            surf = surface(iseg)
            do isys = nosys+1, notot - nototp
               amass(isys,iseg) = amass(isys,iseg) + idt*deriv(isys,iseg)
               conc (isys,iseg) = amass(isys,iseg) / surf
               deriv(isys,iseg) = 0.0
            enddo
         endif

      enddo

!        output formats

 1000 format ( 'Volume of segment:', I7, ' is:',
     &          E15.6, ' 1.0 assumed.' )
 1001 format ('25 or more zero volumes , further messages surpressed')

      if ( timon ) call timstop ( ithandl )
      return
      end
