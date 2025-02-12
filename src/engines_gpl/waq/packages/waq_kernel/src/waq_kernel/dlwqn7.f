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

      subroutine dlwqn7 ( a     , j     , c     , lun   , lchar  ,
     &                    action, dlwqd , gridps)

!       Deltares Software Centre

!>\file
!>                         horizontally upwind, vertically central, direct stationary method (7)
!>
!>                         Stationary solution. Upwind 1st order horizontally, central
!>                         vertically. Fully implicit with a direct method.\n
!>                         Matrices become very large in 3D and method unworkable. In 2D
!>                         the method can be used. In 1D the method outperforms the
!>                         iterative methods.

!     CREATED            : june 1988 by L. Postma
!
!     LOGICAL UNITS      : LUN(19) , output, monitoring file
!                          LUN(20) , output, formatted dump file
!                          LUN(21) , output, unformatted hist. file
!                          LUN(22) , output, unformatted dump file
!
!     SUBROUTINES CALLED : DLWQTR, user transport routine
!                          DLWQWQ, user waterquality routine
!                          DLWQPP, user postprocessing routine
!                          DLWQ10, system monitoring routine
!                          DLWQ11, system dump routine
!                          DLWQ13, system postpro-dump routine
!                          DLWQ15, wasteload routine
!                          DLWQ60, scales water quality
!                          DLWQ61, clears the matrix
!                          DLWQ63, stores the results
!                          DLWQ65, computes closure error
!                          DLWQ66, makes masses
!                          DLWQ67, zeros the matrix
!                          DLWQ70, fills the matrix
!                          DLWQ71, performs mass balance computation
!                          DELMAT, inverts the matrix
!                          DHOPNF, opens files
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
      use delwaq2_data
      use m_openda_exchange_items, only : get_openda_buffer
      use report_progress
      use waqmem          ! module with the more recently added arrays

      implicit none

      include 'actions.inc'
!
!     Declaration of arguments
!
      REAL, DIMENSION(*)          :: A
      INTEGER, DIMENSION(*)       :: J
      INTEGER, DIMENSION(*)       :: LUN
      CHARACTER*(*), DIMENSION(*) :: C
      CHARACTER*(*), DIMENSION(*) :: LCHAR
      INTEGER                     :: ACTION
      TYPE(DELWAQ_DATA)           :: DLWQD
      type(GridPointerColl)       :: GridPs               ! collection off all grid definitions

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
      LOGICAL         IMFLAG , IDFLAG , IHFLAG
      LOGICAL         LDUMMY , LSTREC , LREWIN

      INTEGER         ITIME
      INTEGER         ITIMEL
      INTEGER         IAFLAG
      INTEGER         IBFLAG
      INTEGER         ISYS
      INTEGER         ICSYS
      INTEGER         NSYS
      INTEGER         INWTYP
      INTEGER         I
      INTEGER          :: NOSSS
      INTEGER          :: NOQTT
      INTEGER         sindex

      integer       :: ithandl

      !
      ! Distinguishing the actions is superfluous:
      ! there is only one step
      !
      IF ( ACTION == ACTION_INITIALISATION .OR.
     &     ACTION == ACTION_FINALISATION        ) THEN
          RETURN
      ENDIF
!
!          some initialisation
!
      ithandl = 0
      if ( timon ) call timstrt ( "dlwqn7", ithandl )

      ITIMEL = ITSTRT
      ITIME  = ITSTRT+IDT
      IBFLAG = 0
      IF ( MOD(INTOPT,16) .GE. 8 ) IBFLAG = 1
      CALL ZERO ( A(IMAS2) , NOTOT*5 )
      LDUMMY = .FALSE.
      LSTREC = .FALSE.
      nosss  = noseg + nseg2
      NOQTT  = NOQ + NOQ4
      inwtyp = intyp + nobnd

!        Determine the volumes and areas that ran dry,
!        They cannot have explicit processes during this time step

         call hsurf  ( noseg    , nopa     , c(ipnam) , a(iparm) , nosfun   ,
     &                 c(isfna) , a(isfun) , surface  , sindex   , lun(19)  )
         call dryfld ( noseg    , nosss    , nolay    , a(ivol)  , noq1+noq2,
     &                 a(iarea) , nocons   , c(icnam) , a(icons) , sindex   ,
     &                 surface  , j(iknmr) , iknmkv   )
!
!          makes closure error
!
      IF ( IDT.EQ.0 ) THEN
         CALL ZERO ( A(IVOL2), NOSEG )
      ELSE IF ( J(INRH2+1).GE.0 .AND. IVFLAG.EQ.0 ) THEN
         CALL DLWQ41 ( LUN     , ITIME   , ITIMEL  , A(IHARM), A(IFARR),
     *                 J(INRHA), J(INRH2), J(INRFT), NOSEG   , A(IVOL2),
     *                 J(IBULK), LCHAR   , ftype   , ISFLAG  , IVFLAG  ,
     *                 LDUMMY  , J(INISP), A(INRSP), J(INTYP), J(IWORK),
     *                 LSTREC  , LREWIN  , A(IVOLL), MYPART  , dlwqd   )
         CALL DLWQ65 ( A(IVOL2), A(IVOL) , IDT     , NOSEG   )
      ELSE
         CALL ZERO ( A(IVOL2) , NOSEG )
         WRITE ( LUN(19), 1000 )
      ENDIF
!
!          loop over the systems
!
      NSYS   = 1
      IAFLAG = 1
      DO 10 ISYS = 1 , NOSYS
         IF ( ISYS .EQ. NOSYS ) NSYS   = 1 + NOTOT - NOSYS
!
!             do the user transport processes
!
         ICSYS = ISYS
         CALL DLWQTR ( NOTOT   , NOSYS   , NOSEG   , NOQ     , NOQ1    ,
     *                 NOQ2    , NOQ3    , NOPA    , NOSFUN  , NODISP  ,
     *                 NOVELO  , J(IXPNT), A(IVOL) , A(IAREA), A(IFLOW),
     *                 A(ILENG), A(ICONC), A(IDISP), A(ICONS), A(IPARM),
     *                 A(IFUNC), A(ISFUN), A(IDIFF), A(IVELO), ICSYS   ,
     *                 IDT     , C(ISNAM), NOCONS  , NOFUN   , C(ICNAM),
     *                 C(IPNAM), C(IFNAM), C(ISFNA), LDUMMY  , ILFLAG  ,
     *                 NPARTp  )
!
!             do the user water quality processes
!
         CALL DLWQWQ ( NOTOT   , NOSYS   , NOSEG   , NOPA    , NOSFUN  ,
     *                 A(IVOL) , A(ICONC), A(ICONS), A(IPARM), A(IFUNC),
     *                 A(ISFUN), A(IDERV), ICSYS   , IDT     , A(ISMAS),
     *                 IBFLAG  , C(ISNAM), NOCONS  , NOFUN   , C(ICNAM),
     *                 C(IPNAM), C(IFNAM), C(ISFNA), NODUMP  , J(IDUMP))
         CALL DLWQ60 ( A(IDERV), A(ICONC), NOTOT   , NOSEG   , ITFACT  ,
     *                 A(IMAS2), ISYS    , NSYS    , A(IDMPS), INTOPT  ,
     *                 J(ISDMP))
!
!             add the waste loads
!
         call dlwq15 ( nosys     , notot    , noseg    , noq      , nowst    ,
     &                 nowtyp    , ndmps    , intopt   ,     1    , itime    ,
     &                 iaflag    , c(isnam) , a(iconc) , a(ivol)  , a(ivol2) ,
     &                 a(iflow ) , j(ixpnt) , c(iwsid) , c(iwnam) , c(iwtyp) ,
     &                 j(inwtyp) , j(iwast) , iwstkind , a(iwste) , a(iderv) ,
     &                 iknmkv    , nopa     , c(ipnam) , a(iparm) , nosfun   ,
     &                 c(isfna ) , a(isfun) , j(isdmp) , a(idmps) , a(imas2) ,
     &                 a(iwdmp)  , isys     , nsys     , j(iowns ), mypart   )
!
!          fill the matrix
!
         CALL DLWQ61 ( A(ICONC), A(IDERV), A(IVOL2), A(ITIMR), NOSEG   ,
     *                           NOTOT   , ISYS    , NSYS    , JTRACK  )
         CALL DLWQ70 ( A(IDISP), A(IDIFF), A(IAREA), A(IFLOW), A(ILENG),
     *                 A(IVELO), A(IBOUN), J(IXPNT), NOTOT   , ISYS    ,
     *                 NSYS    , NOQ1    , NOQ2    , NOQ     , NODISP  ,
     *                 NOVELO  , J(IDPNT), J(IVPNT), A(IDERV), A(ITIMR),
     *                                     JTRACK  , INTOPT  , ILFLAG  )
         CALL DLWQ67 ( A(ITIMR), NOSEG   , JTRACK  )
!
!             invert the matrix and store the results
!
         CALL DELMAT ( NOSEG   , JTRACK  , JTRACK  , NSYS    , A(ITIMR),
     *                                               A(IDERV),    0    )
         CALL DLWQ63 ( A(ICONC), A(IDERV), A(IMAS2), NOSEG   , NOTOT   ,
     *                 ISYS    , NSYS    , A(IDMPS), INTOPT  , J(ISDMP))
   10 CONTINUE
!
!          mass balance
!
      IAFLAG = 1
      CALL DLWQ71 ( A(IDISP), A(IDIFF), A(IAREA), A(IFLOW), A(ILENG),
     *              A(IVELO), A(ICONC), A(IBOUN), J(IXPNT), NOSYS   ,
     *              NOTOT   , NOQ1    , NOQ2    , NOQ     , NODISP  ,
     *              NOVELO  , J(IDPNT), J(IVPNT), INTOPT  , A(IMAS2),
     *              ILFLAG  , A(IDMPQ), NDMPQ   , J(IQDMP))
      CALL DLWQ66 ( A(IDERV), A(IVOL) , A(ICONC), NOTOT   , NOSEG   )
!
!     Call OUTPUT system
!
      CALL DLWQO2 ( NOTOT   , NOSEG   , NOPA    , NOSFUN  , ITSTRT  ,
     +              C(IMNAM), C(ISNAM), C(IDNAM), J(IDUMP), NODUMP  ,
     +              A(ICONC), A(ICONS), A(IPARM), A(IFUNC), A(ISFUN),
     +              A(IVOL) , NOCONS  , NOFUN   , 1       , NOUTP   ,
     +              LCHAR   , LUN     , J(IIOUT), J(IIOPO), A(IRIOB),
     +              C(IONAM), NX      , NY      , J(IGRID), C(IEDIT),
     +              NOSYS   , A(IBOUN), J(ILP)  , A(IDERV), A(IMAS2),
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
!
!          close files, except monitor file
!
      call CloseHydroFiles( dlwqd%collcoll )
      call close_files( lun )
!
!          write restart file
!
      CALL DLWQ13 ( LUN      , LCHAR , A(ICONC) , ITSTRT, C(IMNAM) ,
     *              C(ISNAM) , NOTOT , NOSEG    )
!
!          user output routine
!
      CALL DLWQPP ( NOTOT   , NOSYS   , NOSEG   , NOPA    , NOSFUN  ,
     *              ITSTRT  , IMFLAG  , IDFLAG  , IHFLAG  , C(IMNAM),
     *              C(ISNAM), C(IDNAM), C(IWSID), J(IDUMP), NODUMP  ,
     *              J(IWAST), NOWST   , A(ICONC), A(ICONS), A(IPARM),
     *              A(IFUNC), A(ISFUN), A(IVOL ), A(IWSTE), A(IBOUN),
     *              NOBND   , ITSTRT  , ITSTOP  , NX      , NY      ,
     *              J(IGRID), NODISP  , NOVELO  , NOQ     , NOQ1    ,
     *              NOQ2    , NOQ3    , A(IDISP), A(IVELO), A(ISMAS),
     *              IBFLAG  , NOCONS  , NOFUN   , C(ICNAM), C(IPNAM),
     *              C(IFNAM), C(ISFNA), C(IBNID))
!
!          output formats
!
 1000 FORMAT ( 'No closure error corrections !' )
!
      if ( timon ) call timstop ( ithandl )
      RETURN
      END
