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

      subroutine VBGRO      ( pmsa   , fl     , ipoint , increm, noseg , &
                              noflux , iexpnt , iknmrk , noq1  , noq2  , &
                              noq3   , noq4   )
!
!*******************************************************************************
!
      IMPLICIT NONE
!
!     Type    Name         I/O Description
!
      real(4) pmsa(*)     !I/O Process Manager System Array, window of routine to process library
      real(4) fl(*)       ! O  Array of fluxes made by this process in mass/volume/time
      integer ipoint( 51) ! I  Array of pointers in pmsa to get and store the data
      integer increm( 51) ! I  Increments in ipoint for segment loop, 0=constant, 1=spatially varying
      integer noseg       ! I  Number of computational elements in the whole model schematisation
      integer noflux      ! I  Number of fluxes, increment in the fl array
      integer iexpnt(4,*) ! I  From, To, From-1 and To+1 segment numbers of the exchange surfaces
      integer iknmrk(*)   ! I  Active-Inactive, Surface-water-bottom, see manual for use
      integer noq1        ! I  Nr of exchanges in 1st direction (the horizontal dir if irregular mesh)
      integer noq2        ! I  Nr of exchanges in 2nd direction, noq1+noq2 gives hor. dir. reg. grid
      integer noq3        ! I  Nr of exchanges in 3rd direction, vertical direction, pos. downward
      integer noq4        ! I  Nr of exchanges in the bottom (bottom layers, specialist use only)
      integer ipnt( 51)   !    Local work array for the pointering
      integer iseg        !    Local loop counter for computational element loop
!
!*******************************************************************************
!
!     Type    Name         I/O Description                                        Unit
!
      real(4) VB1         ! I  vegetation biomass cohort 1                        (gC/m2)
      real(4) maxVB1      ! I  maximum vegetation biomass cohort 1                (Tdm/hac)
      real(4) minVB1      ! I  minimum vegetation biomass cohort 1                (Tdm/hac)
      real(4) hlfAgeVB1   ! I  age where biomass is half of maximum cohort 1      (d)
      real(4) sfVB1       ! I  shape factor growth curve cohort 1                 (-)
      real(4) dmCfVB1     ! I  dry matter carbon ratio veg. cohort 1              (dm/gC)
      real(4) iniVB1      ! I  initial veg. biomass cohort 1                      (Tdm/hac)
      real(4) iniCovVB1   ! I  initial veg. coverage cohort 1                     (hac/ha)
!     real(4), allocatable       ::SWini(:)
!                         ! I  switch 0=firsttime init 1=biomass 2=fr coverage cohort 1   (-)
      real(4) Surf        ! I  horizontal surface area of a DELWAQ segment        (m2)
      real(4) DELT        ! I  timestep for processes                             (d)
      real(4) Volume      ! I  volume of computational cell                       (m3)
      real(4) ageVB1      ! O  age of vegation cohort 1                           (d)
      real(4) VB1ha       ! O  vegetation biomass cohort 1                        (TC/hac)
      real(4) VBA1ha      ! O  attainable vegetation biomass cohort 1             (TC/hac)
      real(4) fVB1        ! O  growth rate vegetation biomass cohort 1            (gC/m2/d)
      real(4) dVB1        ! F  growth rate vegetation biomass cohort 1            (gC/m3/d)
      real(4) SwGrowth    ! I  switch 0=no growth 1=growth                        (-)
      real(4) SwMrt       ! I  switch 0=no mortality 1=mortality                  (-)
      real(4) VBAge0ha    ! O  vegetation biomass per ha at age is zero       (gC/ha)
      integer IdVB1       !    Pointer to the growth rate vegetation biomass cohort 1
      integer VBType      ! I  code of vegetation type for error and warnings      (-)
      integer SWiniVB1    !    0=no init, 1=init.
      integer SWregro     !    0=no regrowth, 1=regrowth allowed
      logical, save       :: first = .true.      !
      integer             :: ikmrk1         ! first feature
      integer             :: ikmrk2         ! second feature
      integer ILUMON
!     integer, allocatable, save  ::  SWDying(:)     ! keep track off whether veg. is dying
      integer  SWDying


      real(4) navail      ! i  available nitrogen                                 (g/m2)
      real(4) pavail      ! i  available nitrogen                                 (g/m2)
      real(4) savail      ! i  available nitrogen                                 (g/m2)
      real(4) FravailM    ! i  fraction available nutrient for uptake             (-)
      real(4) F1VB        ! I  allocation factor comp. 1 (stem) VB01              (-)
      real(4) F2VB        ! I  allocation factor comp. 2 (foliage) VB01           (-)
      real(4) F3VB        ! I  allocation factor comp. 3 (branch) VB01            (-)
      real(4) F4VB        ! I  allocation factor comp. 4 (root) VB01              (-)
      real(4) F5VB        ! I  allocation factor comp. 5 (fineroot) VB01          (-)
      real(4) CNf1VB      ! I  carbon-nitrogen ratio in stem VB01                 (gC/gN)
      real(4) CNf2VB      ! I  carbon-nitrogen ratio in foliage VB01              (gC/gN)
      real(4) CNf3VB      ! I  carbon-nitrogen ratio in branch VB01               (gC/gN)
      real(4) CNf4VB      ! I  carbon-nitrogen ratio in root VB01                 (gC/gN)
      real(4) CNf5VB      ! I  carbon-nitrogen ratio in fineroot VB01             (gC/gN)
      real(4) CPf1VB      ! I  carbon-phosporus ratio in stem VB01                (gC/gP)
      real(4) CPf2VB      ! I  carbon-phosporus ratio in foliage VB01             (gC/gP)
      real(4) CPf3VB      ! I  carbon-phosporus ratio in branch VB01              (gC/gP)
      real(4) CPf4VB      ! I  carbon-phosporus ratio in root VB01                (gC/gP)
      real(4) CPf5VB      ! I  carbon-phosporus ratio in fineroot VB01            (gC/gP)
      real(4) CSf1VB      ! I  carbon-sulphur ratio in stem VB01                  (gC/gS)
      real(4) CSf2VB      ! I  carbon-sulphur ratio in foliage VB01               (gC/gS)
      real(4) CSf3VB      ! I  carbon-sulphur ratio in branch VB01                (gC/gS)
      real(4) CSf4VB      ! I  carbon-sulphur ratio in root VB01                  (gC/gS)
      real(4) CSf5VB      ! I  carbon-sulphur ratio in fineroot                   (gC/gS)
      real(4) weighCN     ! I  n content of VB01                                     (gN)
      real(4) weighCP     ! I  p content of VB01                                     (gP)
      real(4) weighCS     ! I  s content of VB01                                     (gS)
      real(4) NutGroFac   ! I  nutrient growth factor <0=full lim, 1=no lim           (-)
      real(4) dVB1MaxNl   ! O  maximum growth rate acc to avail nutrients       (gC/m2/d)
      real(4) initAge     ! I  iniial age of vegetation at start of simulation        (d)
      real(4) iniSWDying  ! I  iniial status of vegetation at start of simulation     (d)


      integer, save       :: ifirst(1:18) = 0     !    for 2x initialisation of 9 types veg
!      integer, allocatable, save  :: iknmrk_save(:) ! copy of the original feature array
!
!*******************************************************************************
!
      ipnt        = ipoint
      IdVB1       = 1

      CALL GETMLU(ILUMON)
!

!      SWiniVB1   = nint(pmsa( ipnt(  9) ))
!      if (SWiniVB1) .ne. 0) then
!            allocate(SWini(noseg))
!!         store SWiniVB values to array
!          do iseg = 1,noseg
!               SWini(iseg) = 0
!            enddo
!      first = .false.
!        endif

!      if  ( first )  then
!          allocate (SWDying(noseg))
!          do iseg = 1, noseg
!                   SWDying(iseg) = 0
!          enddo
!          first = .false.
!      endif

      do  iseg = 1 , noseg

!        lowest water and 2d segments only (also when dry!)
         call dhkmrk(1,iknmrk(iseg),ikmrk1)
         call dhkmrk(2,iknmrk(iseg),ikmrk2)
         if (ikmrk1.lt.3 .and. (ikmrk2.eq.0).or.(ikmrk2.eq.3)) then
!

            VB1        = pmsa( ipnt(  1) )
            maxVB1     = pmsa( ipnt(  2) )
            minVB1     = pmsa( ipnt(  3) )
            hlfAgeVB1  = pmsa( ipnt(  4) )
            sfVB1      = pmsa( ipnt(  5) )
            dmCfVB1    = pmsa( ipnt(  6) )
            iniVB1     = pmsa( ipnt(  7) )
            iniCovVB1  = pmsa( ipnt(  8) )
            SWiniVB1   = pmsa( ipnt(  9) )
            ageVB1     = pmsa( ipnt( 10) )
            Surf       = pmsa( ipnt( 11) )
            DELT       = pmsa( ipnt( 12) )
            Volume     = pmsa( ipnt( 13) )
            SwGrowth   = pmsa( ipnt( 14) )
            SwMrt      = pmsa( ipnt( 15) )
            VBType     = pmsa( ipnt( 16) )
            Navail     = pmsa( ipnt( 17) )
            Pavail     = pmsa( ipnt( 18) )
            Savail     = pmsa( ipnt( 19) )
            FravailM   = pmsa( ipnt( 20) )
            F1VB       = pmsa( ipnt( 21) )
            F2VB       = pmsa( ipnt( 22) )
            F3VB       = pmsa( ipnt( 23) )
            F4VB       = pmsa( ipnt( 24) )
            F5VB       = pmsa( ipnt( 25) )
            CNf1VB     = pmsa( ipnt( 26) )
            CNf2VB     = pmsa( ipnt( 27) )
            CNf3VB     = pmsa( ipnt( 28) )
            CNf4VB     = pmsa( ipnt( 29) )
            CNf5VB     = pmsa( ipnt( 30) )
            CPf1VB     = pmsa( ipnt( 31) )
            CPf2VB     = pmsa( ipnt( 32) )
            CPf3VB     = pmsa( ipnt( 33) )
            CPf4VB     = pmsa( ipnt( 34) )
            CPf5VB     = pmsa( ipnt( 35) )
            CSf1VB     = pmsa( ipnt( 36) )
            CSf2VB     = pmsa( ipnt( 37) )
            CSf3VB     = pmsa( ipnt( 38) )
            CSf4VB     = pmsa( ipnt( 39) )
            CSf5VB     = pmsa( ipnt( 40) )
            SWRegro    = pmsa( ipnt( 41) )
            SWDying    = pmsa( ipnt( 42) )
            InitAge    = pmsa( ipnt( 43) )
            IniSWDying = pmsa( ipnt( 44) )

           if (ifirst (vbtype) .eq. 0) then
	      AgeVB1 = InitAge
           endif


           if (ifirst (vbtype + 9) .eq. 0) then
	      SWDying = IniSWDying
           endif

!            if (vbtype .eq. 5) then
!	    WRITE (ILUMON, *) 'iniage/swdy ', 'seg:', iseg, 'ifirst: ',ifirst(5),'dec: ' , SWDying, 'age:  ', agevb1
!            endif

!           evaluate use initialisation 0=no, 1=yes
!           always use iniCovVB1, 100% (default) means ha=haC, if unequal 100% ha<>haC
            IF (  (SWiniVB1 .EQ. 1) .or. (SWiniVB1 .eq. 0 ) ) THEN
                iniCovVB1 = iniCovVB1 / 100
            ELSE
                CALL ERRSYS ('(no valid value for SWiniVB <0,1>', 1 )
            ENDIF

            IF (  (SWregro .NE. 1) .and. (SWregro .ne. 0 ) ) THEN
                CALL ERRSYS ('(no valid value for SWregro <0,1>', 1 )
            ENDIF


! ---       only process significant coverages
	    if (iniCovVB1 .gt. 0.001) then

!           convert Ton DM/hac to gC/m2-cohort
            iniVB1 = iniVB1 / dmCfVB1 * 100
            minVB1 = minVB1 / dmCfVB1 * 100
            maxVB1 = maxVB1 / dmCfVB1 * 100
            nutgrofac = 1

!           input shape factor (range 1-10) scaled to halfAge
            sfVB1 =  sfVB1 / hlfAgeVB1

!           biomass at age=0 for later use to check if vegetation is dying after mortality
            VBAge0ha = (( minVB1 - maxVB1) /(1+exp(sfVB1 * (- hlfAgeVB1))) + maxVB1  ) /100

!           Check values growth limitation (only 0 or 1)
            IF ( (NINT(SWgrowth) .NE. 1) .and. (NINT(SwGrowth) .NE. 0) ) THEN
               CALL ERRSYS ('(no valid value for SwGrowthVB <0,1>', 1 )
            ENDIF

!           Check values mort limitation (only 0 or 1)
            IF ( (NINT(SWmrt) .NE. 1) .and. (NINT(SwMrt) .NE. 0) ) THEN
               CALL ERRSYS ('(no valid value for SWMrtVB <0,1>', 1 )
            ENDIF

!           Checking for nut availabilithy

            if ( (F4VB + F5VB) - 1.E-10 .lt. 0.0 ) then
               CALL ERRSYS ('(no valid values for F4VB and F5VB (alloction factors vegetation  roots)', 1 )
            else
!              average Nutrient content of cohort
               weighCN = F1VB*CNf1VB + F2VB*CNf2VB + F3VB*CNf3VB + F4VB*CNf4VB + F5VB*CNf5VB
               weighCP = F1VB*CPf1VB + F2VB*CPf2VB + F3VB*CPf3VB + F4VB*CPf4VB + F5VB*CPf5VB
               weighCS = F1VB*CSf1VB + F2VB*CSf2VB + F3VB*CSf3VB + F4VB*CSf4VB + F5VB*CSf5VB

               dVB1MaxNL = FravailM * min( Navail  * weighCN, Pavail  * weighCP, Savail  * weighCS) * IniCovVB1 / volume * surf / delt
               dVB1MaxNL = max(0.0,dVB1MaxNL)

            endif

!           Evaluate initial conditions at start of simulation
            IF ( SWiniVB1 .NE. 0 ) THEN

!                calculate age matching initial biomass
!                check and maximise age to 2xhalfage

!                initial biomass exceeds minimum
                 IF ( (iniVB1 - minVB1) .gt. 1.E-10) then
!                    initial biomass less than maximum biomass
!                    IF ((maxVB1 - iniVB1) .gt. 1.E-10) THEN
                     IF ( (iniVB1/maxVB1) .lt. 0.99) THEN
                        ageVB1  = hlfAgeVB1 + LOG((minVB1-maxVB1) /(iniVB1-maxVB1) - 1 ) / sfVB1
                     ELSE
                        WRITE (ILUMON, *) 'WARNING : Vegtype ',vbtype, ' init biom .ge. Max: ', iniVB1*dmcfVB1/100, '>=',maxVB1*dmcfVB1/100
!                       age representing 99% of initial mass
                        ageVB1= hlfAgeVB1 + LOG((minVB1-maxVB1) /( (0.99 - 1) * maxVB1) - 1 ) / sfVB1
                     ENDIF
                 ELSE
                     ageVB1 =0.0
                 ENDIF

                 VBA1ha = (( minVB1 - maxVB1) /(1+exp(sfVB1 * (ageVB1 - hlfAgeVB1))) + maxVB1  ) /100

                 VB1ha  = VB1 / iniCovVB1 /100
                 dVB1   = ( VBA1ha - VB1ha ) * 100.0 * surf / volume / delt * iniCovVB1
!                no growth reduction during initialisation
!                 if (dVB1 .gt. 1.E-20) then
!                     NutGroFac = min (1.0, (dVB1MaxNL / dVB1) )
!                 else
!                     NutGroFac = 1
!                 endif
!                 dVB1 = min(dVB1MaxNL, dVB1)

            ELSE

               VB1ha  = VB1 / iniCovVB1 /100

!              vegetation is flooded
               if ( NINT (SWmrt) .eq. 1 ) then
                   SWDying = 1.0
!                  WRITE (ILUMON, *) 'vbgro-deadstart ', iseg, ' ' , SWDying
               endif

!              check if vegetation died long enough - regrowth allowed again
               if  ( (VB1ha .lt. VBAge0ha) .and. (SWDying .eq. 1) .and.  SWRegro .eq. 1 )  then
	           SWDying = 0.0
                   ageVB1 = 0
!	           WRITE (ILUMON, *) 'vbgro-decayklaar ', iseg, ' ' , SWDying
	       endif

!              calculate new age for decaying vegetation based on current biomass
!              convert VBha (Tc/ha-cohort) to maxVB1 (gC/m2-cohort)
               if ( SWDying .eq. 1) then
                  if ( VB1ha .le. VBAge0ha ) then
                     ageVB1 = 0
                  elseif ( (VB1ha*100/maxVB1) .lt. 0.99 ) then
              	     ageVB1  = hlfAgeVB1 + LOG((minVB1-maxVB1) /(VB1ha*100-maxVB1) - 1 ) / sfVB1
              	  else
!                    cannot calc age
              	  endif
!              	  if (vbtype .eq. 5) then
!	             WRITE (ILUMON, *) 'agecalc at dying', iseg,'ifirst: ',ifirst(5),agevb1, vb1ha
!	          endif
               endif

!              calculate attainable biomass per ha using age
               VBA1ha = (( minVB1 - maxVB1) /(1+exp(sfVB1 * (ageVB1 - hlfAgeVB1))) + maxVB1  ) /100

!              no growth for standing stock either
               IF ( ( NINT(SwGrowth) .EQ. 1) .and. (SWDying .eq. 0) .and. SWRegro .eq. 1) THEN

                  dVB1   = ( VBA1ha - VB1ha ) * 100.0 * surf / volume / delt * iniCovVB1
!                 growth reduction?
                  if (dVB1 .gt. 1.E-20) then
                      NutGroFac = min (1.0, (dVB1MaxNL / dVB1) )
                  else
                      NutGroFac = 1
                  endif
                  dVB1 = min(dVB1MaxNL, dVB1)

!                 there is (reduced?) growth
                  ageVB1 = ageVB1 + NutGroFac * DELT

               ELSE
!                  no growth flux = 0
                   dVB1=0
               ENDIF

            ENDIF


!
            fl  ( IdVB1       ) = dVB1
            pmsa( ipnt( 45)   ) = ageVB1
            pmsa( ipnt( 46)   ) = VB1ha
            pmsa( ipnt( 47)   ) = VBA1ha

            ! if init then no nutrient uptake, set output to zero

            if ( SWiniVB1 .NE. 0 ) then
               fVB1 = 0.0
            else
               fVB1 = dVB1 * volume / surf
            endif

            pmsa( ipnt( 48)   ) = fVB1
            pmsa( ipnt( 49)   ) = VBAge0ha
            pmsa( ipnt( 50)   ) = SWDying
            pmsa( ipnt( 51)   ) = NutGroFac

! ---       check iniCovVB1 - only significant vegetation
            endif

!        bottom and 2d segments only
         endif
!
         IdVB1       = IdVB1       + noflux
         ipnt        = ipnt        + increm
!
!     segment loop
      enddo


!     no need to initialise this cohort in next timestep
!     SWiniVB1 = 0
      pmsa(ipoint(9)) = 0.0
      ifirst (vbtype) = 1
      ifirst (vbtype+9) = 1

!
      return
      end
