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

      subroutine dlwqn4 ( a     , j     , c     , lun   , lchar  ,
     &                    action, dlwqd , gridps)

!       Deltares Software Centre

!>\file
!>                         Horizontal ADI (Waqua method) vertical implicit (4)
!>
!>                         Performs time dependent integration according to the Alternate
!>                         Direction Implicit method as implemented in WAQUA. The vertical
!>                         is resolved fullimplicit and centrally discretized.

!     CREATED            : june 1988 by L. Postma
!
!     LOGICAL UNITS      : LUN(19) , output, monitoring file
!                          LUN(20) , output, formatted dump file
!                          LUN(21) , output, unformatted hist. file
!                          LUN(22) , output, unformatted dump file
!                          LUN(23) , output, unformatted dump file
!
!     SUBROUTINES CALLED : DLWQTR, user transport routine
!                          DLWQWQ, user waterquality routine
!                          PROCES, DELWAQ proces system
!                          DLWQO2, DELWAQ output system
!                          DLWQPP, user postprocessing routine
!                          DLWQ13, system postpro-dump routine
!                          DLWQ14, scales waterquality
!                          DLWQ15, wasteload routine
!                          DLWQ17, boundary routine
!                          DLWQ40, explicit derivative
!                          DLWQ41, update volumes
!                          DLWQ42, set explicit step
!                          DLWQ43, implicit step
!                          DLWQ44, update arrays
!                          DLWQT0, update other time functions
!                          DLWQ46, makes mass balance impicit step
!                          PROINT, integration of fluxes
!                          DHOPNF, opens files
!                          SRSTOP, stops execution
!                          ZERCUM, zero's the cummulative array's
!
!     PARAMETERS    :
!
!     NAME    KIND     LENGTH   FUNC.  DESCRIPTION
!     ---------------------------------------------------------
!     A       REAL       *      LOCAL  real      workspace array
!     J       INTEGER    *      LOCAL  integer   workspace array
!     C       CHARACTER  *      LOCAL  character workspace array
!     LUN     INTEGER    *      INPUT  array with unit numbers
!     LCHAR   CHARACTER  *      INPUT  filenames
!
!     Declaration of arguments
!
      use grids
      use timers
      use m_timers_waq
      use m_couplib
      use delwaq2_data
      use m_openda_exchange_items, only : get_openda_buffer
      use waqmem          ! module with the more recently added arrays
      use report_progress

      implicit none

      include 'actions.inc'

!     Declaration of arguments

      real                           :: a      (*)
      integer                        :: j      (*)
      integer                        :: lun    (*)
      character*(*)                  :: c      (*)
      character*(*)                  :: lchar  (*)
      integer                        :: action
      type(delwaq_data), target      :: dlwqd
      type(GridPointerColl)          :: GridPs               ! collection of all grid definitions
!
!     COMMON  /  SYSN   /   System characteristics
!
      INCLUDE 'sysn.inc'
!
!     COMMON  /  SYSI  /    Timer characteristics
!
      INCLUDE 'sysi.inc'
!
!     COMMON  /  SYSA   /   Pointers in real array workspace
!
      INCLUDE 'sysa.inc'
!
!     COMMON  /  SYSJ   /   Pointers in integer array workspace
!
      INCLUDE 'sysj.inc'
!
!     COMMON  /  SYSC   /   Pointers in character array workspace
!
      INCLUDE 'sysc.inc'
!
!     Local declarations
!
      LOGICAL          :: IMFLAG , IDFLAG , IHFLAG
      LOGICAL          :: LDUMMY , LSTREC , LREWIN , LDUMM2
      REAL             :: RDUMMY(1)
      INTEGER          :: IAFLAG , IBFLAG , IFFLAG
      INTEGER          :: NDDIM  , NVDIM  , NOSSS  , NOQTT  , NOPRED , NOQT
      INTEGER          :: ITIMEL
      INTEGER          :: ITIME
      INTEGER          :: NSTEP
      INTEGER          :: INWTYP

      INTEGER          :: LLENG  , LFLOW  , LAREA  , LDIFF  , LDISP
      INTEGER          :: LNOQ   , KVELO  , KLENG  , KXPNT  , KFLOW
      INTEGER          :: KNOQ   , KDISP  , KDIFF  , KAREA  , KQDMP
      INTEGER          :: LVELO  , LQDMP  , LXPNT
      INTEGER          :: IBND
      INTEGER          :: ISYS
      INTEGER          :: I
      INTEGER         sindex

      INTEGER          :: ithandl

      !
      ! Dummy variables - used in DLWQD
      !
      integer          :: ioptzb
      integer          :: nowarn
      logical          :: forester
      logical          :: updatr
      real(kind=kind(1.0d0)) :: tol

      INCLUDE 'state_data.inc'

      if ( action == action_finalisation ) then
          include 'dlwqdata_restore.inc'
          goto 20
      endif

      IF ( ACTION == ACTION_INITIALISATION  .OR.
     &     ACTION == ACTION_FULLCOMPUTATION        ) THEN

!
!          some initialisation
!
          IF ( NOQ3 .GT. 0 ) THEN
             WRITE ( LUN(19),*)  ' ERROR: NO THIRD DIMENSION IMPLEMENTED '
             CALL SRSTOP(1)
          ENDIF

          ithandl = 0
          ITIME   = ITSTRT
          NSTEP   = (ITSTOP-ITSTRT)/IDT
          IFFLAG  = 0
          IAFLAG  = 0
          IBFLAG  = 0
          IF ( MOD(INTOPT,16) .GE. 8 ) IBFLAG = 1
          LDUMMY = .FALSE.
          IF ( NDSPN .EQ. 0 ) THEN
             NDDIM = NODISP
          ELSE
             NDDIM = NDSPN
          ENDIF
          IF ( NVELN .EQ. 0 ) THEN
             NVDIM = NOVELO
          ELSE
             NVDIM = NVELN
          ENDIF
          LSTREC = ICFLAG .EQ. 1
          nosss  = noseg + nseg2
          NOQTT  = NOQ + NOQ4
          inwtyp = intyp + nobnd

          call initialise_progress( dlwqd%progress, nstep, lchar(44) )
!
!          initialize second volume array with the first one
!
          CALL MOVE   ( A(IVOL ), A(IVOL2) , NOSSS   )
      ENDIF

!
!     Save/restore the local persistent variables,
!     if the computation is split up in steps
!
!     Note: the handle to the timer (ithandl) needs to be
!     properly initialised and restored
!
      IF ( ACTION == ACTION_INITIALISATION ) THEN
          if ( timon ) call timstrt ( "dlwqn4", ithandl )
          INCLUDE 'dlwqdata_save.inc'
          if ( timon ) call timstop ( ithandl )
          RETURN
      ENDIF

      IF ( ACTION == ACTION_SINGLESTEP ) THEN
          INCLUDE 'dlwqdata_restore.inc'
          call apply_operations( dlwqd )
      ENDIF

      if ( timon ) call timstrt ( "dlwqn4", ithandl )

!======================= simulation loop ============================

   10 continue

!        Determine the volumes and areas that ran dry at start of time step

         call hsurf  ( noseg    , nopa     , c(ipnam) , a(iparm) , nosfun   ,
     &                 c(isfna) , a(isfun) , surface  , lun(19)  )
         call dryfld ( noseg    , nosss    , nolay    , a(ivol)  , noq1+noq2,
     &                 a(iarea) , nocons   , c(icnam) , a(icons) , surface  ,
     &                 j(iknmr) , iknmkv   )

!          set alternating set of pointers

         if ( mod((itime-itstrt)/idt,2) .eq. 0 ) then
              knoq  = noq1
              kdisp = idisp
              kdiff = idnew
              karea = iarea
              kflow = iflow
              kleng = ileng
              kvelo = ivnew
              kxpnt = ixpnt
              kqdmp = iqdmp
              lnoq  = noq2
              ldisp = idisp+1
              ldiff = idnew+nddim*noq1
              larea = iarea+noq1
              lflow = iflow+noq1
              lleng = ileng+noq1*2
              lvelo = ivnew+nvdim*noq1
              lxpnt = ixpnt+noq1*4
              if ( ilflag .eq. 0 ) lleng = ileng+1
              lqdmp = iqdmp + noq1
         else
              knoq  = noq2
              kdisp = idisp+1
              kdiff = idnew+nddim*noq1
              karea = iarea+noq1
              kflow = iflow+noq1
              kleng = ileng+noq1*2
              kvelo = ivnew+nvdim*noq1
              kxpnt = ixpnt+noq1*4
              if ( ilflag .eq. 0 ) kleng = ileng+1
              kqdmp = iqdmp + noq1
              lnoq  = noq1
              ldisp = idisp
              ldiff = idnew
              larea = iarea
              lflow = iflow
              lleng = ileng
              lvelo = ivnew
              lxpnt = ixpnt
              lqdmp = iqdmp
         endif

!          user transport processes

         call dlwqtr ( notot    , nosys    , nosss    , noq      , noq1     ,
     &                 noq2     , noq3     , nopa     , nosfun   , nodisp   ,
     &                 novelo   , j(ixpnt) , a(ivol)  , a(iarea) , a(iflow) ,
     &                 a(ileng) , a(iconc) , a(idisp) , a(icons) , a(iparm) ,
     &                 a(ifunc) , a(isfun) , a(idiff) , a(ivelo) , itime    ,
     &                 idt      , c(isnam) , nocons   , nofun    , c(icnam) ,
     &                 c(ipnam) , c(ifnam) , c(isfna) , ldummy   , ilflag   ,
     &                 npartp   )

!jvb     Temporary ? set the variables grid-setting for the DELWAQ variables

         call setset ( lun(19)  , nocons   , nopa     , nofun    , nosfun   ,
     &                 nosys    , notot    , nodisp   , novelo   , nodef    ,
     &                 noloc    , ndspx    , nvelx    , nlocx    , nflux    ,
     &                 nopred   , novar    , nogrid   , j(ivset) )

!        return conc and take-over from previous step or initial condition,
!        and do particle tracking of this step (will be back-coupled next call)

         call delpar01( itime   , noseg    , nolay    , noq      , nosys    ,
     &                  notot   , a(ivol)  , surface  , a(iflow) , c(isnam) ,
     &                  nosfun  , c(isfna) , a(isfun) , a(imass) , a(iconc) ,
     &                  iaflag  , intopt   , ndmps    , j(isdmp) , a(idmps) ,
     &                  a(imas2))

!        call PROCES subsystem

         call proces ( notot    , nosss    , a(iconc) , a(ivol)  , itime    ,
     &                 idt      , a(iderv) , ndmpar   , nproc    , nflux    ,
     &                 j(iipms) , j(insva) , j(iimod) , j(iiflu) , j(iipss) ,
     &                 a(iflux) , a(iflxd) , a(istoc) , ibflag   , ipbloo   ,
     &                 ipchar   , ioffbl   , ioffch   , a(imass) , nosys    ,
     &                 itfact   , a(imas2) , iaflag   , intopt   , a(iflxi) ,
     &                 j(ixpnt) , iknmkv   , noq1     , noq2     , noq3     ,
     &                 noq4     , ndspn    , j(idpnw) , a(idnew) , nodisp   ,
     &                 j(idpnt) , a(idiff) , ndspx    , a(idspx) , a(idsto) ,
     &                 nveln    , j(ivpnw) , a(ivnew) , novelo   , j(ivpnt) ,
     &                 a(ivelo) , nvelx    , a(ivelx) , a(ivsto) , a(idmps) ,
     &                 j(isdmp) , j(ipdmp) , ntdmpq   , a(idefa) , j(ipndt) ,
     &                 j(ipgrd) , j(ipvar) , j(iptyp) , j(ivarr) , j(ividx) ,
     &                 j(ivtda) , j(ivdag) , j(ivtag) , j(ivagg) , j(iapoi) ,
     &                 j(iaknd) , j(iadm1) , j(iadm2) , j(ivset) , j(ignos) ,
     &                 j(igseg) , novar    , a        , nogrid   , ndmps    ,
     &                 c(iprna) , intsrt   , j(iowns) , j(iownq) , mypart   ,
     &                 j(iprvpt), j(iprdon), nrref    , j(ipror) , nodef    ,
     &                 surface  , lun(19)  )

!        communicate boundaries

         call dlwq_boundio ( lun(19)  , notot    , nosys    , nosss    , nobnd    ,
     &                       c(isnam) , c(ibnid) , j(ibpnt) , a(iconc) , a(ibset) ,
     &                       lchar(19))

!        set new boundaries

         if ( itime .ge. 0   ) then
             ! first: adjust boundaries by OpenDA
             if ( dlwqd%inopenda ) then
                 do ibnd = 1,nobnd
                     do isys = 1,nosys
                         call get_openda_buffer(isys,ibnd, 1,1,
     &                                   A(ibset+(ibnd-1)*nosys + isys-1))
                     enddo
                  enddo
             endif
             call dlwq17 ( a(ibset), a(ibsav), j(ibpnt), nobnd   , nosys   ,
     &                     notot   , idt     , a(iconc), a(iflow), a(iboun))
         endif
!
!     Call OUTPUT system
!
      CALL DLWQO2 ( NOTOT   , NOSEG   , NOPA    , NOSFUN  , ITIME   ,
     +              C(IMNAM), C(ISNAM), C(IDNAM), J(IDUMP), NODUMP  ,
     +              A(ICONC), A(ICONS), A(IPARM), A(IFUNC), A(ISFUN),
     +              A(IVOL) , NOCONS  , NOFUN   , IDT     , NOUTP   ,
     +              LCHAR   , LUN     , J(IIOUT), J(IIOPO), A(IRIOB),
     +              C(IONAM), NX      , NY      , J(IGRID), C(IEDIT),
     +              NOSYS   , A(IBOUN), J(ILP)  , A(IMASS), A(IMAS2),
     +              A(ISMAS), NFLUX   , A(IFLXI), ISFLAG  , IAFLAG  ,
     +              IBFLAG  , IMSTRT  , IMSTOP  , IMSTEP  , IDSTRT  ,
     +              IDSTOP  , IDSTEP  , IHSTRT  , IHSTOP  , IHSTEP  ,
     +              IMFLAG  , IDFLAG  , IHFLAG  , NOLOC   , A(IPLOC),
     +              NODEF   , A(IDEFA), ITSTRT  , ITSTOP  , NDMPAR  ,
     +              C(IDANA), NDMPQ   , NDMPS   , J(IQDMP), J(ISDMP),
     +              J(IPDMP), A(IDMPQ), A(IDMPS), A(IFLXD), NTDMPQ  ,
     +              C(ICBUF), NORAAI  , NTRAAQ  , J(IORAA), J(NQRAA),
     +              J(IQRAA), A(ITRRA), C(IRNAM), A(ISTOC), NOGRID  ,
     +              NOVAR   , J(IVARR), J(IVIDX), J(IVTDA), J(IVDAG),
     +              J(IAKND), J(IAPOI), J(IADM1), J(IADM2), J(IVSET),
     +              J(IGNOS), J(IGSEG), A       , NOBND   , NOBTYP  ,
     +              C(IBTYP), J(INTYP), C(ICNAM), NOQ     , J(IXPNT),
     +              INTOPT  , C(IPNAM), C(IFNAM), C(ISFNA), J(IDMPB),
     +              NOWST   , NOWTYP  , C(IWTYP), J(IWAST), J(INWTYP),
     +              A(IWDMP), iknmkv  , J(IOWNS), MYPART  , isegcol )

!        zero cummulative array's

         if ( imflag .or. ( ihflag .and. noraai .gt. 0 ) ) then
            call zercum ( notot   , nosys   , nflux   , ndmpar  , ndmpq   ,
     &                    ndmps   , a(ismas), a(iflxi), a(imas2), a(iflxd),
     &                    a(idmpq), a(idmps), noraai  , imflag  , ihflag  ,
     &                    a(itrra), ibflag  , nowst   , a(iwdmp))
         endif
         if (mypart.eq.1) call write_progress( dlwqd%progress )

!          simulation done ?

         if ( itime .lt. 0      ) goto 9999
         if ( itime .ge. itstop ) goto 20

!          add processes

         call dlwq14 ( a(iderv), notot   , nosss   , itfact  , a(imas2),
     &                 idt     , iaflag  , a(idmps), intopt  , j(isdmp),
     &                 j(iowns), mypart )

!     get new volumes
         itimel = itime
         itime  = itime + idt
         select case ( ivflag )
            case ( 1 )                 !     computation of volumes for computed volumes only
               call move   ( a(ivol) , a(ivol2), noseg   )
               call dlwqb3 ( a(iarea), a(iflow), a(ivnew), j(ixpnt), notot   ,
     &                       noq     , nvdim   , j(ivpnw), a(ivol2), intopt  ,
     &                       a(imas2), idt     , iaflag  , nosys   , a(idmpq),
     &                       ndmpq   , j(iqdmp))
               updatr = .true.
            case ( 2 )                 !     the fraudulent computation option
               call dlwq41 ( lun     , itime   , itimel  , a(iharm), a(ifarr),
     &                       j(inrha), j(inrh2), j(inrft), noseg   , a(ivoll),
     &                       j(ibulk), lchar   , ftype   , isflag  , ivflag  ,
     &                       updatr  , j(inisp), a(inrsp), j(intyp), j(iwork),
     &                       lstrec  , lrewin  , a(ivol2), mypart  , dlwqd   )
               if ( lrewin ) call move ( a(ivol2), a(ivoll) , noseg   )
               call dlwqf8 ( noseg   , noq     , j(ixpnt), idt     , iknmkv  ,
     &                       a(ivol ), a(iflow), a(ivoll), a(ivol2))
               updatr = .true.
               lrewin = .true.
               lstrec = .true.
            case default               !     read new volumes from files
               call dlwq41 ( lun     , itime   , itimel  , a(iharm), a(ifarr),
     &                       j(inrha), j(inrh2), j(inrft), noseg   , a(ivol2),
     &                       j(ibulk), lchar   , ftype   , isflag  , ivflag  ,
     &                       updatr  , j(inisp), a(inrsp), j(intyp), j(iwork),
     &                       lstrec  , lrewin  , a(ivoll), mypart  , dlwqd   )
         end select

!        update the info on dry volumes with the new volumes

         call dryfle ( noseg    , nosss    , a(ivol2) , nolay    , nocons   ,
     &                 c(icnam) , a(icons) , surface  , j(iknmr) , iknmkv   )

!          add the waste loads

         call dlwq15 ( nosys    , notot    , noseg    , noq      , nowst    ,
     &                 nowtyp   , ndmps    , intopt   , idt      , itime    ,
     &                 iaflag   , c(isnam) , a(iconc) , a(ivol)  , a(ivol2) ,
     &                 a(iflow ), j(ixpnt) , c(iwsid) , c(iwnam) , c(iwtyp) ,
     &                 j(inwtyp), j(iwast) , iwstkind , a(iwste) , a(iderv) ,
     &                 iknmkv   , nopa     , c(ipnam) , a(iparm) , nosfun   ,
     &                 c(isfna ), a(isfun) , j(isdmp) , a(idmps) , a(imas2) ,
     &                 a(iwdmp) , 1        , notot    , j(iowns ), mypart   )


!        explicit part of the transport step, derivative

         call dlwq40 ( nosys   , notot   , noseg   , knoq    , nddim   ,
     &                 nvdim   , a(kdisp), a(kdiff), a(kvelo), a(karea),
     &                 a(kflow), a(kleng), j(kxpnt), iknmkv  , j(idpnw),
     &                 j(ivpnw), a(iconc), a(iboun), intopt  , ilflag  ,
     &                 idt     , a(iderv), iaflag  , a(imas2), ndmpq   ,
     &                 j(kqdmp), a(idmpq))

!        explicit part of transport done, volumes on diagonal

         call dlwq42 ( nosys   , notot   , nototp  , noseg   , a(ivol2),
     &                 surface , a(imass), a(iconc), a(iderv), idt     ,
     &                 ivflag  , lun(19) , j(iowns), mypart  )

!        performs the implicit part of the transport step

         call dlwq43 ( nosys   , notot   , noseg   , lnoq    , nddim   ,
     &                 nvdim   , a(ldisp), a(ldiff), a(lvelo), a(larea),
     &                 a(lflow), a(lleng), j(lxpnt), iknmkv  , j(idpnw),
     &                 j(ivpnw), a(iconc), a(iboun), intopt  , ilflag  ,
     &                 idt     , a(iderv), iaflag  , a(imas2))

!          new time values, volumes excluded

         call dlwqt0 ( lun      , itime    , itimel   , a(iharm) , a(ifarr) ,
     &                 j(inrha) , j(inrh2) , j(inrft) , idt      , a(ivol)  ,
     &                 a(idiff) , a(iarea) , a(iflow) , a(ivelo) , a(ileng) ,
     &                 a(iwste) , a(ibset) , a(icons) , a(iparm) , a(ifunc) ,
     &                 a(isfun) , j(ibulk) , lchar    , c(ilunt) , ftype    ,
     &                 intsrt   , isflag   , ifflag   , ivflag   , ilflag   ,
     &                 ldumm2   , j(iktim) , j(iknmr) , j(inisp) , a(inrsp) ,
     &                 j(intyp) , j(iwork) , .false.  , ldummy   , rdummy   ,
     &                 .false.  , gridps   , dlwqd    )

!          update the necessary arrays

         call dlwq44 ( nosys   , notot   , noseg   , a(ivol2), a(imass),
     &                 a(iconc), a(iderv), j(iowns), mypart  )

!     calculate closure error
         if ( lrewin .and. lstrec ) then
            call dlwqce ( a(imass), a(ivoll), a(ivol2), nosys , notot ,
     &                    noseg   , lun(19) )
            call move   ( a(ivoll), a(ivol) , noseg   )
         else
!     replace old by new volumes
            call move   ( a(ivol2), a(ivol) , noseg   )
         endif
!
!          mass balance of implicit part
!
      IF ( MOD(INTOPT,16) .GE. 8  )
     *CALL DLWQ46 ( A(LDISP), A(LDIFF), A(LAREA), A(LFLOW), A(LLENG),
     *              A(LVELO), A(ICONC), A(IBOUN), J(LXPNT), NOSYS   ,
     *              NOTOT   , LNOQ    , NDDIM   , NVDIM   , J(IDPNW),
     *              J(IVPNW), INTOPT  , IDT     , ILFLAG  , A(IDMPQ),
     *              NDMPQ   , J(LQDMP), 0       , NOQ3    , J(IOWNS),
     *              MYPART  )

!          integrate the fluxes at dump segments fill ASMASS with mass

         if ( ibflag .gt. 0 ) then
            call proint ( nflux   , ndmpar  , idt     , itfact  , a(iflxd),
     &                    a(iflxi), j(isdmp), j(ipdmp), ntdmpq  )
         endif

!          end of loop

         if ( ACTION == ACTION_FULLCOMPUTATION ) goto 10

   20 continue

      if ( ACTION == ACTION_FINALISATION    .or.
     &     ACTION == ACTION_FULLCOMPUTATION      ) then

!         close files, except monitor file

          call timer_start(timer_close)
          call CloseHydroFiles( dlwqd%collcoll )
          call close_files( lun )

!         write restart file

          CALL DLWQ13 ( LUN      , LCHAR , A(ICONC) , ITIME , C(IMNAM) ,
     *                  C(ISNAM) , NOTOT , NOSEG    )
          call timer_stop(timer_close)
      endif

 9999 if ( timon ) call timstop ( ithandl )

      dlwqd%itime = itime

      RETURN
      END SUBROUTINE
