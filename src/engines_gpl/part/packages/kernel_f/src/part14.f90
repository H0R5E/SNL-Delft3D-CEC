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

module part14_mod

   contains
      subroutine part14 ( itime  , idelt  , nodye  , nocont , ictime ,    &
                          ictmax , nwaste , mwaste , xwaste , ywaste ,    &
                          zwaste , aconc  , rem    , npart  , ndprt  ,    &
                          mpart  , xpart  , ypart  , zpart  , wpart  ,    &
                          iptime , nopart , pblay  , radius , lgrid  ,    &
                          dx     , dy     , ftime  , tmassu , nosubs ,    &
                          ncheck , t0buoy , modtyp , abuoy  , t0cf   ,    &
                          acf    , lun2   , kpart  , layt   , tcktot ,    &
                          nplay  , kwaste , nolay  , linear , track  ,    &
                          nmconr , spart  , rhopart, noconsp, const)

!       Deltares Software Centre

!>\file
!>         Adds mass for continuous releases per time step
!>
!>         The routine:
!>         - Determines start and end interval in the time series of continuous
!>           loads. It is NOT required that start and end are in the same interval
!>           like in Delwaq. Part functionality is more recent ;-)
!>         - For each interval in the time series the average load (m/s) is determined
!>           and multiplied with the time span in that interval. This gives an
!>           exact integration of the linear interpolation of the release mass.
!>         - From the total mass of a wasteload and the amount of particles for a
!>           wasteload, the mass per particle is derived for the wasteload. This is
!>           used to determine the amount of particles to be released in this time interval.
!>         - A rem(ainder) array per wasteload stores what remains for the next time interval.
!>         - From the mass/particle divided by average load (mass/s), the amount of seconds
!>           per particle is determined. This results in an even distribution of the particles
!>           during the time step rather than discrete indian 'smoke signals'.
!>         - A further fine tuning could be in following the shape of the linear curve during
!>           the time step instead of the present even spreading. Something for the future.
!>         - Then location information for the wasteload is set as the location of the
!>           released particles.
!>         - This information is perturbed in the <find> routine to spread the particles
!>           along a circle. Because even mass per distance means lower concentrations at
!>           the edge of the circle, the find routine compensates somewhat for that.
!>         - This only was the horizontal. Particles are distributed over the layers
!>           vertically and depending on the type of modelling randomly distributed vertically
!>           in their layer
!>         - The particle tracking array gets the thus computed initial states of the particles

!     System administration : Antoon Koster

!     Created               : February 1990 by Leo Postma

!     Modified              : May      1996 by Robert Vos    : 3d version
!                             July     2001 by Antoon koster : mass conservation &
!                                                              suppression round off errors

!     Note                  : none

!     Logical unit numbers  : lun2 - output file to print statistics

!     Subroutines called    : find - distributes particles over a circel

!     functions   called    : rnd  - random number generator

      use precision_part          ! single/double precision
      use timers
      use grid_search_mod
      use spec_feat_par
      implicit none

!     Arguments

!     kind            function         name                    description

      integer  ( ip), intent(in   ) :: nocont                !< nr of continuous loads
      integer  ( ip), intent(in   ) :: nodye                 !< nr of dye release points
      integer  ( ip), intent(in   ) :: nosubs                !< nr of substances
      integer  ( ip), intent(in   ) :: layt                  !< number of hydr. layer
      integer  ( ip), intent(in   ) :: itime                 !< actual time
      integer  ( ip), intent(in   ) :: idelt                 !< time step size
      integer  ( ip), intent(in   ) :: ictime (nocont,*)     !< array of breakpoint times
      integer  ( ip), intent(in   ) :: ictmax (nocont)       !< nr of breakpoints per load
      integer  ( ip), intent(in   ) :: nwaste (nodye+nocont) !< n-values of waste locations
      integer  ( ip), intent(in   ) :: mwaste (nodye+nocont) !< m-values of waste locations
      real     ( rp), intent(in   ) :: xwaste (nodye+nocont) !< x-values of waste locations
      real     ( rp), intent(in   ) :: ywaste (nodye+nocont) !< y-values of waste locations
      real     ( rp), intent(in   ) :: zwaste (nodye+nocont) !< z-values of waste locations
      real     ( rp), intent(in   ) :: aconc  (nocont+nodye,nosubs)    !< mass per particle
      real     ( rp), intent(inout) :: rem    (nocont)       !< remainder of mass to be released
      integer  ( ip), intent(  out) :: npart  (*)            !< n-values particles
      integer  ( ip), intent(in   ) :: ndprt  (nodye+nocont) !< no. particles per waste entry
      integer  ( ip), intent(  out) :: mpart  (*)            !< m-values particles
      real     ( rp), intent(  out) :: xpart  (*)            !< x-in-cell of particles
      real     ( rp), intent(  out) :: ypart  (*)            !< y-in-cell of particles
      real     ( rp), intent(  out) :: zpart  (*)            !< z-in-cell of particles
      real     ( rp), intent(  out) :: wpart  (nosubs,*)     !< weight of the particles
      integer  ( ip), intent(  out) :: iptime (*)            !< particle age
      integer  ( ip), intent(inout) :: nopart                !< number of active particles
      real     ( rp), intent(in   ) :: pblay                 !< relative thickness lower layer
      real     ( rp), intent(in   ) :: radius (nodye+nocont) !< help var. radius (speed)
      integer  ( ip), pointer       :: lgrid  (:,:)          !< grid numbering active
      real     ( rp), pointer       :: dx     (:)            !< dx of the grid cells
      real     ( rp), pointer       :: dy     (:)            !< dy of the grid cells
      real     ( rp), intent(in   ) :: ftime  (nocont,*)     !< time matrix for wasteloads (mass/s)
      real     ( rp), intent(in   ) :: tmassu (nocont)       !< total unit masses cont releases
      integer  ( ip), intent(  out) :: ncheck (nocont)       !< check number of particles per load
      real     ( rp), intent(  out) :: t0buoy (*)            !< t0 for particles for buoyancy spreading
      integer  ( ip), intent(in   ) :: modtyp                !< for model type 2 temperature
      real     ( rp), intent(  out) :: abuoy  (*)            !< 2*sqrt(a*dt) particles-buoyancy spreading
      real     ( rp), intent(in   ) :: t0cf   (nocont)       !< coefficients for loads
      real     ( rp), intent(in   ) :: acf    (nocont)       !< coefficients for loads
      integer  ( ip), intent(in   ) :: lun2                  !< output report unit number
      integer  ( ip), intent(  out) :: kpart  (*)            !< k-values particles
      real     ( rp), intent(in   ) :: tcktot (layt)         !< thickness hydrod.layer
      integer  ( ip)                :: nplay  (layt)         !< work array that could as well remain inside
      integer  ( ip), intent(in   ) :: kwaste (nodye+nocont) !< k-values of wasteload points
      integer  ( ip), intent(in   ) :: nolay                 !< number of comp. layer
      integer  ( ip), intent(in   ) :: linear (nocont)       !< 1 = linear interpolated loads
      real     ( rp), intent(inout) :: track  (8,*)          !< track array for all particles
      character( 20), intent(in   ) :: nmconr (nocont)       !< names of the continuous loads
      real     ( rp), intent(  in)  :: spart  (nosubs,*)     !< size of the particles
      real     ( rp), intent(inout) :: rhopart  (nosubs,*)   !< density of the particles
      integer  ( ip), intent(in   ) :: noconsp               !< number of constants
      real     ( rp), intent(in   ) :: const(*)              !< constant values

      save

!     Locals

      logical     :: first  =  .true.
      logical        lcircl            ! this thing is always false !
      real   (dp) :: rseed             ! seed of the random number generator
      integer(ip) :: ic                ! loop variable continuous loads
      integer(ip) :: id                ! loop variable to identify time locations
      integer(ip) :: ids, ide          ! interval numbers of start and stop time
      real   (rp) :: fac1s, fac2s      ! interpolation factors start location time interval
      real   (rp) :: fac1e, fac2e      ! interpolation factors end   location time interval
      real   (dp) :: aconu             ! mass per particle of this wasteload (constant !)
      integer(ip) :: ipb               ! help variable for particle number
      real   (dp) :: rest              ! help variable remainder for this wasteload
      real   (dp) :: avcon             ! average mass/s load over a time interval
      real   (dp) :: amass             ! avcon multiplied with its duration
      real   (dp) :: dts               ! (mass/particle) / (mass/s) gives s/particle for spreaded release
      real   (dp) :: rpnul             ! same is dts, but for the rest from last time => time first particle
      integer(ip) :: nopnow            ! number of particles to be released for this continuos load
      integer(ip) :: ibegin, iend      ! number of first and last particle of the batch of this load
      integer(ip) :: ie                ! ic + nodye, entry number in combined arrays
      integer(ip) :: i, ipart          ! loop/help variables for particles
      integer(ip) :: ntot              ! help variables for particles
      integer(ip) :: nulay             ! help variables for the actual layer in a particle loop
      integer(ip) :: mwasth, nwasth    ! help variables for n and m of wastelocation
      real   (rp) :: xwasth, ywasth    ! help variables for x and y of wastelocation within (n,m)
      real   (rp) :: radiuh            ! help variable for the radius
      integer(ip) :: ilay  , isub      ! loop variables layers and substances
!
!     note:
!       random function rnd() must be declared external, as it is an
!       intrinsic function for the lahey fortran95 compiler under linux
!
      external rnd
      real   (sp) :: rnd

      integer(4) ithndl              ! handle to time this subroutine
      data       ithndl / 0 /
      if ( timon ) call timstrt( "part14", ithndl )

!     at first zero the remainder

      if ( first ) then
         first  = .false.
         lcircl = .false.
         rem    = 0.0          ! zero remainder array for all continuous loads
         ncheck = 0            ! zero check array for number of particles per load
         rseed  = 0.5d+00      ! seed for random generator
      endif

!     loop over the continuous loads

      do 300 ic = 1, nocont
         write ( lun2, 1000 ) nmconr(ic)
         ie = ic + nodye
         if ( nwaste(ie) .eq. 0 ) then
            write ( lun2, 1030 )
            cycle
         endif

!       loop over the number of break points to find start and stop moment
!       NB: unlike Delwaq, these times may be located in different intervals

         do id = 1, ictmax(ic)
            if ( itime       .ge. ictime(ic,id) ) ids = id
            if ( itime+idelt .gt. ictime(ic,id) ) ide = id
         enddo
         if ( ide .lt. ids ) ide = ids

         fac1s  = float(itime      -ictime(ic,ids)) / float(ictime(ic,ids+1)-ictime(ic,ids))
         fac2s  = 1.0 - fac1s
         fac1e  = float(itime+idelt-ictime(ic,ide)) / float(ictime(ic,ide+1)-ictime(ic,ide))
         fac2e  = 1.0 - fac1e

         aconu  =  tmassu(ic) / ndprt(ie)
         if ( aconu .lt. 1.d-10 ) cycle

!       determine mass by integration of the linear function

         ipb  = nopart + 1
         rest = rem(ic)

         do 40 id = ids, ide
            avcon = ftime(ic,id)
            if ( ids .eq. ide ) then    !    both points in the same interval
               if ( linear(ic) .eq. 1 ) then
                  avcon = ( ( fac2s*ftime(ic,id) + fac1s*ftime(ic,id+1) ) +  &
                            ( fac2e*ftime(ic,id) + fac1e*ftime(ic,id+1) ) )  &
                                                                 / 2.0
               endif
               amass = avcon * idelt
            endif
            if ( ids .ne. ide .and. id .eq. ids ) then   !    first interval
               if ( linear(ic) .eq. 1 ) then
                  avcon = ( ( fac2s*ftime(ic,id) + fac1s*ftime(ic,id+1) ) +  &
                                                         ftime(ic,id+1)   )  &
                                                                  / 2.0
               endif
               amass = avcon * ( ictime(ic,id+1) - itime )
            endif
            if ( id .ne. ids .and. id .ne. ide ) then    !    somewhere in the middle
               if ( linear(ic) .eq. 1 ) then
                  avcon = (         ftime(ic,id) +       ftime(ic,id+1) )    &
                                                                  / 2.0
               endif
               amass = avcon * ( ictime(ic,id+1) - ictime(ic,id) )
            endif
            if ( ids .ne. ide .and. id .eq. ide ) then   !    last interval
               if ( linear(ic) .eq. 1 ) then
                  avcon = ( (       ftime(ic,id)                        ) +  &
                            ( fac2e*ftime(ic,id) + fac1e*ftime(ic,id+1) ) )  &
                                                                  / 2.0
               endif
               amass = avcon * ( itime+idelt     - ictime(ic,id) )
            endif

!     Koster 11 July 2001 : check on zero load added

            if ( amass+rest .ge. 1.d-10 .and. avcon .gt. 1.d-10) then
               dts   = aconu/avcon            ! time span per particle
!              rpnul = rest /aconu * dts
               rpnul = rest /avcon            ! time span first particle
               rest  = rest + amass
               do i = 1 , 1 + int(rest/aconu-1.d-10)
                  iptime(ipb) = int(rpnul)
                  ipb         = ipb + 1
                  rpnul       = rpnul - dts
                  rest        = rest  - aconu
               enddo
            else
               rest = rest + amass
            endif

!     end loop across time intervals

   40    continue
!     store remainder (always around zero or negative)
         rem(ic) = rest
         nopnow  = ipb - nopart - 1

!     insert the particles at the end (is already done for iptime(ipb)

         ibegin = nopart + 1
         iend   = nopart + nopnow
         nopart = iend
         ncheck(ic) = ncheck(ic) + nopnow

         write ( lun2, 1010 ) tmassu(ic), aconu, nopnow*aconu, rem(ic)
         write ( lun2, 1020 ) ndprt (ie), nopnow, ncheck(ic)

         nwasth = nwaste(ie)
         mwasth = mwaste(ie)
         xwasth = xwaste(ie)
         ywasth = ywaste(ie)
         radiuh = radius(ie)

!.. layer distribution

         if ( kwaste (ie) .eq. 0 ) then              !.. uniform
            ntot  = 0
            do ilay = 1, layt
               nplay(ilay) = int(nopnow*tcktot(ilay))
               ntot = ntot + nplay(ilay)
            enddo
            nplay(1) =  nplay(1) + nopnow - ntot     !.. round off in layer 1
            if ( nplay(1) .lt. 0 ) stop 'Neg. dye release in top layer '
         else                                        !.. for the current layer only
            nplay = 0
            nplay( kwaste(ie) ) = nopnow
         endif

         nulay = 1
         ipart = 0

         do 250 i = ibegin, iend

!         give particles gridcell and coordinates of the continuous load

            npart (i) = nwasth
            mpart (i) = mwasth
            xpart (i) = xwasth
            ypart (i) = ywasth
            if ( modtyp .eq. 2 ) then
               t0buoy(i) = t0cf (ic)                    ! could be taken out of the particle loop
               abuoy (i) = 2.0*sqrt(acf(ic)*idelt)      ! even complete out of this routine
            else
               t0buoy(i) = 0.0
               abuoy (i) = 0.0
            endif

!         spreads the particles over the circle

            call find ( xpart(i), ypart(i), radiuh  , npart(i), mpart(i),   &
                        lgrid   , dx      , dy      , lcircl  )

!         give the particles a layer number

    70      ipart = ipart + 1
            if ( ipart .gt. nplay(nulay) ) then         ! next layer
               ipart = 0
               nulay = nulay + 1
               if ( nulay .gt. nolay ) then
                  nulay = nolay
                  goto 80
               endif
               goto 70
            endif
            if ( nulay .gt. nolay ) stop ' Nulay>nolay in part09 '
    80      continue
            kpart (i)  = nulay

!         give the particles a z-value within the layer

            if ( modtyp .eq. 2 ) then     ! .. two layer model use a pointe discharge (as in v3.00)
               if ( zwaste(ie) .gt. pblay ) then
                  zpart(i) = ( zwaste(ie) - pblay ) / ( 1.0 - pblay )
               else
                  zpart(i) =  zwaste(ie)/pblay
               endif
            elseif ( modtyp .eq. 4 .and. kpart(i) .eq. 1 ) then   !   for one layer models (2dh),
               zpart(i) = zwaste(ie)           !      the release will be in the user-defined location
            elseif ( nolay .eq. 1 ) then
               zpart(i) = zwaste(ie)/100.0
            else                               !      release randomly distributed over the vertical
               zpart(i) = rnd(rseed)
            endif

!         initialize rest of variables for new particle

            do isub = 1, nosubs
               wpart (isub, i) = aconc(ie, isub)
               if (modtyp .eq. 6) then
                  rhopart(isub, i) = pldensity(isub)
               endif                 
            enddo

            track(1,i) = mpart(i)              !       store information required in initial part
            track(2,i) = npart(i)              !       of nefis file for particle tracking
            track(3,i) = kpart(i)              !       (see routine wrttrk)
            track(4,i) = xpart(i)
            track(5,i) = ypart(i)
            track(6,i) = zpart(i)
            track(7,i) = itime
            track(8,i) = ic + nodye

!     end loop across the added particles for this continuous load

  250    continue

!     write test data

         if ( iend .gt. ibegin .and. iend .le. 20 ) then
            write ( lun2, '(5x,a,(10i10))' )                     &
                   ' Release times (rel.) [iptime in part14]:',  &
                    ( iptime(i) , i = ibegin, iend )
         endif

!     end of loop across continuous loads

  300 continue

!     end of subroutine

      if ( timon ) call timstop ( ithndl )
      return

!     formats

 1000 format(6x,'Continuous release ',a)
 1010 format(10x,'Total mass to be added for this run        : ',es15.7/   &
             10x,'Mass per particle                          : ',es15.7/   &
             10x,'Actual mass added this step                : ',es15.7/   &
             10x,'Actual rest mass (round off)               : ',es15.7)
 1020 format(10x,'Total number of particles to be added      : ',i12/     &
             10x,'Actual number of particles added this step : ',i12/     &
             10x,'Total number of particles added until now  : ',i12)
 1030 format( 10x,'Warning: this release is outside active area !' )

      end subroutine
end module
