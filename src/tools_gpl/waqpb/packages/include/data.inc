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

c
c     DATA STRUCTURE FOR PROCESSES LIBRARY MANAGEMENT
c
c     Reference: bespreekverslag van Gils 3-9-1998 R3252

      integer      nsubsm, nitemm, nfortm, nprocm, nfluxm,
     j             nconfm, ninpum, noutpm, noutfm, nmodvm,
     j             nstocm, nvelom, ndispm, nsgrpm, ncnsbm
      parameter   (nsubsm=3000, nitemm=30000, nfortm=800, nmodvm=4000,
     j             nprocm=3000, nfluxm=   1, nconfm=20, ninpum=30000,
     j             noutpm=15000, noutfm=6000, nstocm=9000, nvelom=3000,
     j             ndispm=3000, nsgrpm=20  , ncnsbm=4000)
      integer      nsubs , nitem , nfort , nproc , nflux ,
     j             nconf , ninpu , noutp , noutf , nstoc ,
     j             nvelo , ndisp , nsgrp , ncnsb , nmodv ,
     j             ncnpr
      common /dims/
     j             nsubs , nitem , nfort , nproc , nflux ,
     j             nconf , ninpu , noutp , noutf , nstoc ,
     j             nvelo , ndisp , nsgrp , ncnsb , nmodv ,
     j             ncnpr

c     Substances groups table P1

      character*30 sgrpid(nsgrpm)
      character*50 sgrpnm(nsgrpm)

      common /sgrp/ sgrpid, sgrpnm

c     Substances table obsolete, included in P2

      character*10 subsid(nsubsm)
c     character*2  subswk(nsubsm)
c     character*10 subsgr(nsubsm)
c     character*20 subsun(nsubsm)
c     character*50 subsnm(nsubsm)

      common /subs/ subsid
c     common /subs/ subswk, subsid, subsgr, subsun, subsnm

c     Items table P2

      character*1  itemse(nitemm), itemex(nitemm)
      character*10 itemid(nitemm)
      character*20 itemun(nitemm)
      character*50 itemnm(nitemm)
      real         itemde(nitemm)
      character*1  itemwk(nitemm)
      character*10 itemag(nitemm),
     +             itemda(nitemm)
      character*30 itemgr(nitemm)
      integer      item_i(nitemm)

      common /item/ itemse, itemex, itemid, itemun, itemnm,
     +              itemde, itemwk, itemag, itemda, itemgr,
     j              item_i

c     FORTRAN subroutines table P3

      character*10 fortid(nfortm)
      integer      fort_i(nfortm)

      common /fort/ fortid, fort_i

c     Processes table P4

      character*10 procid(nprocm), procfo(nprocm)
      character*50 procnm(nprocm)
      integer      procco(nprocm), proc_i(nprocm)

      common /proc/ procid, procfo, procnm, procco, proc_i

c     Fluxes table obsolete, included in P2

c     character*10 fluxid(nfluxm)
c     character*20 fluxun(nfluxm)
c     character*50 fluxnm(nfluxm)
c
c     common /flux/ fluxid, fluxun, fluxnm

c     Configurations table P5

      character*10 confid(nconfm)
      character*50 confnm(nconfm)

      common /conf/ confid, confnm

c     internal license on conf

      integer      liconf(nconfm)

      common /lconf/ liconf

c     Configurations and processes matrix R1

      logical      conpro(nconfm,nprocm)
      integer      icnpro(nconfm*nprocm)
      character*10 r1_cid(nconfm*nprocm)
      character*10 r1_pid(nconfm*nprocm)

      common /copr/ conpro,icnpro, r1_cid, r1_pid

c     Configurations and substances table R2

      character*10 r2_cid(ncnsbm)
      character*10 r2_sid(ncnsbm)
      integer      r2_iin(ncnsbm)

      common /tabr2/ r2_cid,r2_sid,r2_iin

c     Input items table R3

      character*10 inpupr(ninpum), inpuit(ninpum)
      character*1  inpude(ninpum), inpudo(ninpum)
      integer      inpunm(ninpum), inpusx(ninpum),
     j             inpu_i(ninpum)
      integer      inpuii(ninpum), inpupi(ninpum)

      common /inpu/ inpupr, inpuit, inpude, inpudo, inpunm,
     +              inpusx, inpu_i, inpuii, inpupi

c     Output items table R4

      character*10 outppr(noutpm), outpit(noutpm)
      character*1  outpdo(noutpm)
      integer      outpnm(noutpm), outpsx(noutpm),
     j             outp_i(noutpm)
      integer      outpii(noutpm), outppi(noutpm)

      common /outp/ outppr, outpit, outpdo, outpnm, outpsx, outp_i,
     j              outpii, outppi

c     Output fluxes table R5

      character*10 outfpr(noutfm), outffl(noutfm)
      character*1  outfdo(noutfm)
      integer      outfnm(noutfm), outf_i(noutfm)

      common /outf/ outfpr, outffl, outfdo, outfnm, outf_i

c     Stochi lines table R6

      character*10 stocfl(nstocm), stocsu(nstocm)
      real         stocsc(nstocm)
      integer      stoc_i(nstocm)

      common /stoc/ stocfl, stocsu, stocsc, stoc_i

c     Velocity lines table R7

      character*10 veloit(nvelom), velosu(nvelom)
      real         velosc(nvelom)
      integer      velo_i(nvelom)

      common /velo/ veloit, velosu, velosc, velo_i

c     Dispersion lines table R8

      character*10 dispit(ndispm), dispsu(ndispm)
      real         dispsc(ndispm)
      integer      disp_i(ndispm)

      common /disp/ dispit, dispsu, dispsc, disp_i

c     Modelled variables table R9

      character*10 modvci(nmodvm), modvit(nmodvm)

      common /modv/ modvit, modvci

c     old_items

      integer, parameter :: n_old_items_max = 1000                       ! maximum number of old items
      integer            :: n_old_items                                  ! number of old items
      character*10       :: old_items_old_name(n_old_items_max)          ! old name (if equal to new name then use old_default if target serial is less then
      character*10       :: old_items_new_name(n_old_items_max)          ! new name
      real               :: old_items_old_default(n_old_items_max)       ! old default value
      character*10       :: old_items_configuration(n_old_items_max)     ! (only use this new name if a specific configuration is used?)
      integer            :: old_items_serial(n_old_items_max)            ! the proces definition serial number up to where this old name, old default was used
      integer            :: old_items_action_type(n_old_items_max)       ! process rename, process parameter rename, default value change

      common /old_items/ n_old_items,
     j                   old_items_old_name,
     j                   old_items_new_name,
     j                   old_items_old_default,
     j                   old_items_configuration,
     j                   old_items_serial,
     j                   old_items_action_type
