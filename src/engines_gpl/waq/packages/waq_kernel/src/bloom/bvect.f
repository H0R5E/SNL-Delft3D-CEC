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

!    Date:       30 Oct 1989
!    Time:       14:47
!    Program:    BVECT    FORTRAN
!    Version:    1.1
!    Programmer: Hans Los
!    (c) 1989 Deltares Sektor W&M
!    Previous versions:
!    1.0 -- 30 Oct 1989 -- 14:45
!    BVECT.FOR  -- 25 Apr 1989 -- 10:28
!
!  *********************************************************************
!  *  SUBROUTINE TO SET THE MORTALITY CONSTRAINTS INTO THE B-VECTOR    *
!  *********************************************************************
!
      SUBROUTINE BVECT(X,XDEF)
      IMPLICIT REAL*8 (A-H,O-Z)
!
      INCLUDE 'blmdim.inc'
      INCLUDE 'phyt2.inc'
      INCLUDE 'matri.inc'
      DIMENSION X(*),B2(MS),XDEF(*)
!
! To tell Bloom how much biomass of the living phytoplankton
! species is left at the end of the time-step, the 'minimum
! biomass' of each species is set in the B-vector. This value is used
! as the mortality constraint (the minimum biomass to be returned
! by simplex).
! The new, minimum biomass levels are also stored in the original
! XDEF-vector. This is to enable the program to deal with infeasible
! solutions for example due to light limitation.
!

      I1 = 0
      K1 = NUROWS
      DO 40 I=1,NUECOG
          SUMSP = 0.0
          L1 = IT2(I,1)
          L2 = IT2(I,2)
          DO 30 K=L1,L2
              I1 = I1 + 1
              K1 = K1 + 1
              SUMSP = SUMSP + X(I1)
              XDEF(K1) = X(I1)
   30     CONTINUE
          B2(I) = DMAX1(SUMSP,0.0D0)
   40 CONTINUE
!
      I1 = NUEXRO + NUECOG
      DO 53 I = 1,NUECOG
          I1 = I1 + 1
          B(I1) = B2(I)
53    CONTINUE
!
      RETURN
      END
