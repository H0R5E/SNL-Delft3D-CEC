module wave_data
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
!  $Id: wave_data.f90 5404 2015-09-10 13:52:50Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/engines_gpl/wave/packages/data/src/wave_data.f90 $
!!--description-----------------------------------------------------------------
!
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
!
! Module parameters
!
!
! Mode options:
integer, parameter :: stand_alone     = 0
integer, parameter :: flow_online     = 1
integer, parameter :: flow_mud_online = 2
!
! FlowVelocityType options:
integer, parameter :: FVT_SURFACE_LAYER  = 1
integer, parameter :: FVT_DEPTH_AVERAGED = 2
integer, parameter :: FVT_WAVE_DEPENDENT = 3
!
! Whitecapping options:
integer, parameter :: WC_OFF        = 0
integer, parameter :: WC_KOMEN      = 1
integer, parameter :: WC_WESTHUYSEN = 2
!
! Module types
!
type wave_time_type
   integer  :: refdate            ! [yyyymmdd] reference date, reference time is 0:00 h
   integer  :: timtscale          ! [tscale]   Current time of simulation since reference date (0:00h)
   integer  :: calctimtscale      ! [tscale]   Current time of SWAN calculation since reference date (0:00h)
                                  !            calctimtscale = timtscale                 when sr%modsim /= 3
                                  !            calctimtscale = timtscale+sr%deltcom*60.0 when sr%modsim == 3
   integer  :: calctimtscale_prev ! calctimtscale from "previous" time point
                                  ! Only used when sr%modsim == 3 for output at the start of the simulation
   integer  :: calccount          ! [-]        Counts the number of calculations. Used for naming the sp2 output files
   real     :: tscale             ! [sec]      Basic time unit: default = 60.0,
                                  ! when running online with FLOW tscale = FLOW_time_step
   real     :: timsec             ! [sec]      Current time of simulation since reference date (0:00h)
   real     :: timmin             ! [min]      Current time of simulation since reference date (0:00h)
end type wave_time_type
!
type wave_output_type
   integer  :: count           ! [-]        Counts the number of generated output fields
   real     :: nexttim         ! [sec]      Next time to write to wavm-file
   real     :: timseckeephot   ! [sec]      seconds since ref date on which time the hotfile should not be deleted
   logical  :: write_wavm      ! [y/n]      True when writing to wavm file
end type wave_output_type
!
type wave_data_type
   integer                :: mode
   type(wave_time_type)   :: time
   type(wave_output_type) :: output
end type wave_data_type
!
! Module parameters
!
! arch is currently 'win32' or 'linux'
!
character(10) :: arch
!
!
!
contains
!
!
!===============================================================================
subroutine initialize_wavedata(wavedata)
   type(wave_data_type) :: wavedata
   character(30)        :: txthlp

   wavedata%mode                    =  0
   wavedata%time%refdate            =  0
   wavedata%time%timtscale          =  0
   wavedata%time%calctimtscale      =  0
   wavedata%time%calctimtscale_prev =  -999
   wavedata%time%calccount          =  0
   wavedata%time%tscale             = 60.0
   wavedata%time%timsec             =  0.0
   wavedata%time%timmin             =  0.0
   wavedata%output%count            =  0
   wavedata%output%nexttim          =  0.0
   wavedata%output%timseckeephot    =  0.0
   wavedata%output%write_wavm       =  .false.
   !
   ! platform definition
   !
   call util_getenv('ARCH',txthlp)
   call small(txthlp,999)
   if (txthlp == 'win32' .or. txthlp == 'w32') then
      arch = 'win32'
   elseif (txthlp == 'win64') then
      arch = 'win64'
   else
      arch = 'linux'
   endif
end subroutine initialize_wavedata
!
!
!===============================================================================
subroutine setmode(wavedata, mode_in)
   integer :: mode_in
   type(wave_data_type) :: wavedata

   wavedata%mode = mode_in
end subroutine setmode
!
!
!===============================================================================
subroutine setrefdate(wavetime, refdate_in)
   integer :: refdate_in
   type(wave_time_type) :: wavetime

   wavetime%refdate = refdate_in
end subroutine setrefdate
!
!
!===============================================================================
subroutine settimtscale(wavetime, timtscale_in, modsim, deltcom)
   integer :: timtscale_in
   integer :: modsim                ! 1: stationary, 2: quasi-stationary, 3: non-stationary
   real    :: deltcom               ! used when modsim = 3: Interval of communication FLOW-WAVE
   type(wave_time_type) :: wavetime

   wavetime%timtscale = timtscale_in
   wavetime%timsec    = real(wavetime%timtscale) * wavetime%tscale
   wavetime%timmin    = wavetime%timsec / 60.0
   if (modsim == 3) then
      wavetime%calctimtscale      = wavetime%timtscale + int(deltcom*60.0/wavetime%tscale)
      wavetime%calctimtscale_prev = wavetime%timtscale
   else
      wavetime%calctimtscale = wavetime%timtscale
   endif
end subroutine settimtscale
!
!
!===============================================================================
subroutine settscale(wavetime, tscale_in)
   real :: tscale_in
   type(wave_time_type) :: wavetime

   wavetime%tscale    = tscale_in
   wavetime%timsec    = real(wavetime%timtscale) * wavetime%tscale
   wavetime%timmin    = wavetime%timsec / 60.0
end subroutine settscale
!
!
!===============================================================================
subroutine settimsec(wavetime, timsec_in, modsim, deltcom)
   real :: timsec_in
   integer :: modsim                ! 1: stationary, 2: quasi-stationary, 3: non-stationary
   real    :: deltcom               ! used when modsim = 3: Interval of communication FLOW-WAVE
   type(wave_time_type) :: wavetime

   wavetime%timsec    = timsec_in
   wavetime%timmin    = wavetime%timsec / 60.0
   wavetime%timtscale = nint(wavetime%timsec / wavetime%tscale)
   if (modsim == 3) then
      wavetime%calctimtscale      = wavetime%timtscale + int(deltcom*60.0/wavetime%tscale)
      wavetime%calctimtscale_prev = wavetime%timtscale
   else
      wavetime%calctimtscale = wavetime%timtscale
   endif
end subroutine settimsec
!
!
!===============================================================================
subroutine settimmin(wavetime, timmin_in, modsim, deltcom)
   real :: timmin_in
   integer :: modsim                ! 1: stationary, 2: quasi-stationary, 3: non-stationary
   real    :: deltcom               ! used when modsim = 3: Interval of communication FLOW-WAVE
   type(wave_time_type) :: wavetime

   wavetime%timmin    = timmin_in
   wavetime%timsec    = wavetime%timmin * 60.0
   wavetime%timtscale = nint(wavetime%timsec / wavetime%tscale)
   if (modsim == 3) then
      wavetime%calctimtscale      = wavetime%timtscale + int(deltcom*60.0/wavetime%tscale)
      wavetime%calctimtscale_prev = wavetime%timtscale
   else
      wavetime%calctimtscale = wavetime%timtscale
   endif
end subroutine settimmin
!
!
!===============================================================================
subroutine setcalculationcount(wavetime, count_in)
   integer :: count_in
   type(wave_time_type) :: wavetime

   wavetime%calccount = count_in
end subroutine setcalculationcount
!
!
!===============================================================================
subroutine setoutputcount(waveoutput, count_in)
   integer :: count_in
   type(wave_output_type) :: waveoutput

   waveoutput%count = count_in
end subroutine setoutputcount
!
!
!===============================================================================
subroutine setnexttim(waveoutput, nexttim_in)
   real :: nexttim_in
   type(wave_output_type) :: waveoutput

   waveoutput%nexttim = nexttim_in
end subroutine setnexttim
!
!
!===============================================================================
subroutine setwrite_wavm(waveoutput, write_in)
   logical :: write_in
   type(wave_output_type) :: waveoutput

   waveoutput%write_wavm = write_in
end subroutine setwrite_wavm



end module wave_data
