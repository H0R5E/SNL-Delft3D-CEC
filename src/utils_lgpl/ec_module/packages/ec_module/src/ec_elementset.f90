!----- LGPL --------------------------------------------------------------------
!                                                                               
!  Copyright (C)  Stichting Deltares, 2011-2013.                                
!                                                                               
!  This library is free software; you can redistribute it and/or                
!  modify it under the terms of the GNU Lesser General Public                   
!  License as published by the Free Software Foundation version 2.1.            
!                                                                               
!  This library is distributed in the hope that it will be useful,              
!  but WITHOUT ANY WARRANTY; without even the implied warranty of               
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU            
!  Lesser General Public License for more details.                              
!                                                                               
!  You should have received a copy of the GNU Lesser General Public             
!  License along with this library; if not, see <http://www.gnu.org/licenses/>. 
!                                                                               
!  contact: delft3d.support@deltares.nl                                         
!  Stichting Deltares                                                           
!  P.O. Box 177                                                                 
!  2600 MH Delft, The Netherlands                                               
!                                                                               
!  All indications and logos of, and references to, "Delft3D" and "Deltares"    
!  are registered trademarks of Stichting Deltares, and remain the property of  
!  Stichting Deltares. All rights reserved.                                     

!  $Id: ec_elementset.f90 5609 2015-11-25 17:21:04Z ye $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/utils_lgpl/ec_module/packages/ec_module/src/ec_elementset.f90 $

!> This module contains all the methods for the datatype tEcElementSet.
!! @author arjen.markus@deltares.nl
!! @author adri.mourits@deltares.nl
!! @author stef.hummel@deltares.nl
!! @author edwin.bos@deltares.nl
module m_ec_elementSet
   use m_ec_typedefs
   use m_ec_message
   use m_ec_support
   use m_ec_alloc
   use m_alloc
   
   implicit none
   
   private
   
   public :: ecElementSetCreate
   public :: ecElementSetFree1dArray
   public :: ecElementSetSetName
   public :: ecElementSetSetType
   public :: ecElementSetSetXArray
   public :: ecElementSetSetYArray
   public :: ecElementSetSetZArray
   public :: ecElementSetSetItype3D
   public :: ecElementSetSetX0Dx
   public :: ecElementSetSetY0Dy
   public :: ecElementSetSetLatitudeArray
   public :: ecElementSetSetLongitudeArray
   public :: ecElementSetSetDirectionArray
   public :: ecElementSetSetLat0Dlat
   public :: ecElementSetSetLon0Dlon
   public :: ecElementSetSetMaskPointer
   public :: ecElementSetSetMaskArray
   public :: ecElementSetSetNumberOfCoordinates
   public :: ecElementSetSetSouthPoleLatitude
   public :: ecElementSetSetSouthPoleLongitude
   public :: ecElementSetSetLocations
   public :: ecElementSetSetRadius
   public :: ecElementSetSetRowsCols
   public :: ecElementSetSetXyen
   
   contains
      
      ! =======================================================================
      
      !> Construct a new ElementSet with the specified id.
      !! Failure is indicated by returning a null pointer.
      function ecElementSetCreate(elementSetId) result(elementSetPtr)
         type(tEcElementSet), pointer            :: elementSetPtr !< the new ElementSet, intent(out)
         integer,                     intent(in) :: elementSetId  !< unique ElementSet id
         !
         integer :: istat !< allocate() status
         !
         ! allocation
         ! The maskArray array is allocated on-demand.
         allocate(elementSetPtr, stat = istat)
         if (istat /= 0) then
            call setECMessage("ERROR: ec_elementSet::ecElementSetCreate: Unable to allocate additional memory")
            elementSetPtr => null()
            return
         end if
         ! initialization
         elementSetPtr%id = elementSetId
         elementSetPtr%ofType = elmSetType_undefined
         elementSetPtr%nCoordinates = 0
         elementSetPtr%n_cols = 0
         elementSetPtr%n_rows = 0
         elementSetPtr%x0 = ec_undef_hp
         elementSetPtr%y0 = ec_undef_hp
         elementSetPtr%dx = ec_undef_hp
         elementSetPtr%dy = ec_undef_hp
         elementSetPtr%lat0 = ec_undef_hp
         elementSetPtr%lon0 = ec_undef_hp
         elementSetPtr%dlat = ec_undef_hp
         elementSetPtr%dlon = ec_undef_hp
         elementSetPtr%latsp = ec_undef_hp
         elementSetPtr%lonsp = ec_undef_hp
         elementSetPtr%radius = ec_undef_hp
         elementSetPtr%radius_unit = ' '
         elementSetPtr%itype3D = ec_undef_int
      end function ecElementSetCreate
      
      ! =======================================================================
      
      !> Free a tEcElementSet, after which it can be deallocated.
      function ecElementSetFree(elementSet) result (success)
         logical                            :: success    !< function status
         type(tEcElementSet), intent(inout) :: elementSet !< ElementSet to free
         !
         integer :: istat !< deallocate() status
         !
         success = .true.
         !
         ! The ElementSet owns the dynamically allocated memory, so deallocate.
         if (associated(elementSet%x)) then
            deallocate(elementSet%x, stat = istat)
            if (istat /= 0) success = .false.
         end if
         if (associated(elementSet%y)) then
            deallocate(elementSet%y, stat = istat)
            if (istat /= 0) success = .false.
         end if
         if ( elementSet%itype3D.ne.ec_undef_int ) then
            elementSet%z => null()
         else
            if (associated(elementSet%z)) then
               deallocate(elementSet%z, stat = istat)
               if (istat /= 0) success = .false.
            end if
         end if
         if (associated(elementSet%lat)) then
            deallocate(elementSet%lat, stat = istat)
            if (istat /= 0) success = .false.
         end if
         if (associated(elementSet%lon)) then
            deallocate(elementSet%lon, stat = istat)
            if (istat /= 0) success = .false.
         end if
         if (associated(elementSet%ids)) then
            deallocate(elementSet%ids, stat = istat)
            if (istat /= 0) success = .false.
         end if
         if (associated(elementSet%xyen)) then
            deallocate(elementSet%xyen, stat = istat)
            if (istat /= 0) success = .false.
         end if
         ! The arrays are not dynamically allocated so nullify.
         elementSet%mask => null()
         ! Either these arrays are used, or the above pointers point to arrays outside the EC-module.
         if (allocated(elementSet%maskArray)) then
            deallocate(elementSet%maskArray, stat = istat)
            if (istat /= 0) success = .false.
         end if
      end function ecElementSetFree
      
      ! =======================================================================
      
      !> Frees a 1D array of tEcElementSetPtrs, after which the elementSetPtr is deallocated.
      function ecElementSetFree1dArray(elementSetPtr, nElementSets) result (success)
         logical                                       :: success       !< function status
         type(tEcElementSetPtr), dimension(:), pointer :: elementSetPtr !< intent(inout)
         integer                                       :: nElementSets  !< number of ElementSets
         !
         integer :: i      !< loop counter
         integer :: istat  !< deallocate() status
         !
         success = .true.
         !
         if (.not. associated(elementSetPtr)) then
            call setECMessage("WARNING: ec_elementSet::ecElementSetFree1dArray: Dummy argument elementSetPtr is already disassociated.")
         else
            ! Free and deallocate all tEcElementSetPtrs in the 1d array.
            do i=1, nElementSets
               if (ecElementSetFree(elementSetPtr(i)%ptr)) then
                  deallocate(elementSetPtr(i)%ptr, stat = istat)
                  if (istat /= 0) success = .false.
               else
                  success = .false.
               end if
            end do
            ! Finally deallocate the tEcElementSetPtr(:) pointer.
            if (success) then
               deallocate(elementSetPtr, stat = istat)
               if (istat /= 0) success = .false.
            end if
         end if
      end function ecElementSetFree1dArray
      
      ! =======================================================================
      
      function ecElementSetSetName(instancePtr, elementSetId, newName) result(success)
         logical                               :: success     !< function status
         type(tEcInstance), pointer            :: instancePtr !< intent(in)
         integer,                   intent(in) :: elementSetId!< unique ElementSet id
         character(*),              intent(in) :: newName     !< new name of the ElementSet
         !
         type(tEcElementSet), pointer :: elementsetPtr !< Quantity corresponding to quantityId

         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            elementSetPtr%name = trim(newName)
            success = .true.
         else
            call setECMessage("ERROR: ec_elementset::ecElementSetSetName: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetName
      
      !> Change the type of the ElementSet corresponding to elementSetId.
      function ecElementSetSetType(instancePtr, elementSetId, ofType) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         integer,                   intent(in) :: ofType       !< new type of the ElementSet
         !
         type(tEcElementSet), pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         !
         success = .false.
         elementSetPtr => null()
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            elementSetPtr%ofType = ofType
            success = .true.
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetType: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetType
      
      ! =======================================================================
      
      !> Create and fill the array of xyen.
      function ecElementSetSetXyen(instancePtr, elementSetId, newXyen) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp), dimension(:,:),  intent(in) :: newXyen      !< new xyen of the ElementSet
         !
         type(tEcElementSet),      pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         real(hp), dimension(:,:), pointer :: xyen          !< ElementSet's xyen array
         integer,  dimension(2)            :: newSize       !< size of xyen
         integer                           :: istat         !< reallocation status
         integer                           :: i, j          !< loop counters
         !
         success = .false.
         elementSetPtr => null()
         xyen          => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            newSize = ubound(newXyen)
            call reallocP(elementSetPtr%xyen, newSize, stat = istat, keepExisting = .false.)
            if (istat == 0) then
               do i=1, size(newXyen, 1)
                  do j=1, size(newXyen, 2)
                     elementSetPtr%xyen(i,j) = newXyen(i,j)
                  end do
               end do
               success = .true.
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetXyen: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetXyen
      
      ! =======================================================================
      
      !> Create and fill the array of x-coordinates and infer nCoordinates.
      function ecElementSetSetXArray(instancePtr, elementSetId, xArray) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp), dimension(:),    intent(in) :: xArray       !< new x-coordinates of the ElementSet
         !
         type(tEcElementSet),    pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         integer                         :: newSize       !< size of xArray
         integer                         :: istat         !< reallocation status
         integer                         :: i             !< loop counter
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_cartesian .or. &
                elementSetPtr%ofType == elmSetType_polytim .or. &
                elementSetPtr%ofType == elmSetType_samples) then
               newSize = size(xArray)
               call reallocP(elementSetPtr%x, newSize, stat = istat, keepExisting = .false.)
               if (istat == 0) then
                  do i=1, newSize
                     elementSetPtr%x(i) = xArray(i)
                  end do
                  elementSetPtr%nCoordinates = newSize
                  success = .true.
               end if
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetXArray: Won't set x-coordinate array for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetXArray: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetXArray
      
      ! =======================================================================
      
      !> Create and fill the array of y-coordinates and infer nCoordinates.
      function ecElementSetSetYArray(instancePtr, elementSetId, yArray) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp), dimension(:),    intent(in) :: yArray       !< new y-coordinates of the ElementSet
         !
         type(tEcElementSet),    pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         integer                         :: newSize       !< size of yArray
         integer                         :: istat         !< reallocation status
         integer                         :: i             !< loop counter
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_cartesian .or. &
                elementSetPtr%ofType == elmSetType_polytim .or. &
                elementSetPtr%ofType == elmSetType_samples) then
               newSize = size(yArray)
               call reallocP(elementSetPtr%y, newSize, stat = istat, keepExisting = .false.)
               if (istat == 0) then
                  do i=1, newSize
                     elementSetPtr%y(i) = yArray(i)
                  end do
                  elementSetPtr%nCoordinates = newSize
                  success = .true.
               end if
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetYArray: Won't set y-coordinate array for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetYArray: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetYArray
      
      ! =======================================================================
      
      !> Create and fill the array of z/sigma-coordinates and infer nCoordinates.
      function ecElementSetSetZArray(instancePtr, elementSetId, zArray, Lpointer_) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp), dimension(:),    intent(in), target :: zArray       !< new z-coordinates of the ElementSet
         logical,                   intent(in), optional :: Lpointer_    !< zArray is pointer to the new z-coordinates of the ElementSet (.true.) or not (.false.)
         !
         type(tEcElementSet),    pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         integer                         :: newSize       !< size of zArray
         integer                         :: istat         !< reallocation status
         integer                         :: i             !< loop counter

         logical                         :: Lpointer

         Lpointer = .false.
         if ( present(Lpointer_) ) then
            Lpointer = Lpointer_
         end if

         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_cartesian .or. &
                elementSetPtr%ofType == elmSetType_polytim) then
               if ( Lpointer ) then
                  elementSetPtr%z => zArray
                  success = .true.
               else
                  newSize = size(zArray)
                  call reallocP(elementSetPtr%z, newSize, stat = istat, keepExisting = .false.)
                  if (istat == 0) then
                     do i=1, newSize
                        elementSetPtr%z(i) = zArray(i)
                     end do
                     success = .true.
                  end if
               end if ! if ( Lpointer) 
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetZArray: Won't set z/sigma-coordinate array for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetZArray: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetZArray
      
      ! =======================================================================
      
      !> Overwrite the seed coordinate x0 and the delta dx of an equidistant grid.
      function ecElementSetSetX0Dx(instancePtr, elementSetId, x0, dx) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp),                  intent(in) :: x0           !< new seed coordinate of the ElementSet
         real(hp),                  intent(in) :: dx           !< new step size of the ElementSet
         !
         type(tEcElementSet), pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_cartesian_equidistant) then
               elementSetPtr%x0 = x0
               elementSetPtr%dx = dx
               success = .true.
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetX0Dx: Won't set (x0,dx) for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetX0Dx: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetX0Dx
      
      ! =======================================================================
      
      !> Overwrite the seed coordinate y0 and the delta dy of an equidistant grid.
      function ecElementSetSetY0Dy(instancePtr, elementSetId, y0, dy) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp),                  intent(in) :: y0           !< new seed coordinate of the ElementSet
         real(hp),                  intent(in) :: dy           !< new step size of the ElementSet
         !
         type(tEcElementSet), pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_cartesian_equidistant) then
               elementSetPtr%y0 = y0
               elementSetPtr%dy = dy
               success = .true.
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetY0Dy: Won't set (y0,dy) array for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetY0Dy: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetY0Dy
      
      ! =======================================================================
      
      !> Create and fill the array of longitude coordinates and infer nCoordinates.
      function ecElementSetSetLongitudeArray(instancePtr, elementSetId, lonArray) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp), dimension(:),    intent(in) :: lonArray     !< new longitude coordinates of the ElementSet
         !
         type(tEcElementSet),    pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         integer                         :: newSize       !< size of lonArray
         integer                         :: istat         !< reallocate status
         integer                         :: i             !< loop counter
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_spheric) then
               newSize = size(lonArray)
               call reallocP(elementSetPtr%lon, newSize, stat = istat, keepExisting = .false.)
               if (istat == 0) then
                  do i=1, newSize
                     elementSetPtr%lon(i) = lonArray(i)
                  end do
                  elementSetPtr%nCoordinates = newSize
                  success = .true.
               end if
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetLongitudeArray: Won't set longitude coordinate array for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetLongitudeArray: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetLongitudeArray
      
      ! =======================================================================
      
      !> Create and fill the array of latitude coordinates and infer nCoordinates.
      function ecElementSetSetLatitudeArray(instancePtr, elementSetId, latArray) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp), dimension(:),    intent(in) :: latArray     !< new latitude coordinates of the ElementSet
         !
         type(tEcElementSet),    pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         integer                         :: newSize       !< size of latArray
         integer                         :: istat         !< reallocate status
         integer                         :: i             !< loop counter
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_spheric) then
               newSize = size(latArray)
               call reallocP(elementSetPtr%lat, newSize, stat = istat, keepExisting = .false.)
               if (istat == 0) then
                  do i=1, newSize
                     elementSetPtr%lat(i) = latArray(i)
                  end do
                  elementSetPtr%nCoordinates = newSize
                  success = .true.
               end if
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetLatitudeArray: Won't set latitude coordinate array for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetLatitudeArray: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetLatitudeArray
      
      ! =======================================================================
      ! =======================================================================
      
      !> Create and fill the array of angles resulting from a pole-shift transformation
      function ecElementSetSetDirectionArray(instancePtr, elementSetId, dirArray) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp), dimension(:),    intent(in) :: dirArray     !< array of transformation angles returned from a poleshift transformation 
         !
         type(tEcElementSet),    pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         integer                         :: newSize       !< size of latArray
         integer                         :: istat         !< reallocate status
         integer                         :: i             !< loop counter
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_spheric) then
               newSize = size(dirArray)
               call reallocP(elementSetPtr%dir, newSize, stat = istat, keepExisting = .false.)
               if (istat == 0) then
                  do i=1, newSize
                     elementSetPtr%dir(i) = dirArray(i)
                  end do
                  elementSetPtr%nCoordinates = newSize
                  success = .true.
               end if
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetDirectionArray: Won't set directional array for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetDirectionArray: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetDirectionArray
      
      ! =======================================================================
      
      !> Overwrite the longitude seed coordinate and the delta in longitude of an equidistant grid.
      function ecElementSetSetLon0Dlon(instancePtr, elementSetId, lon0, dlon) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp),                  intent(in) :: lon0         !< new seed coordinate of the ElementSet
         real(hp),                  intent(in) :: dlon         !< new step size of the ElementSet
         !
         type(tEcElementSet), pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_spheric_equidistant) then
               elementSetPtr%lon0 = lon0
               elementSetPtr%dlon = dlon
               success = .true.
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetLon0Dlon: Won't set (lon0,dlon) for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetLon0Dlon: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetLon0Dlon
      
      ! =======================================================================
      
      !> Overwrite the latitude seed coordinate and the delta in latitude of an equidistant grid.
      function ecElementSetSetLat0Dlat(instancePtr, elementSetId, lat0, dlat) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp),                  intent(in) :: lat0         !< new seed coordinate of the ElementSet
         real(hp),                  intent(in) :: dlat         !< new step size of the ElementSet
         !
         type(tEcElementSet), pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_spheric_equidistant) then
               elementSetPtr%lat0 = lat0
               elementSetPtr%dlat = dlat
               success = .true.
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetLat0Dlat: Won't set (lat0,dlat) for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetLat0Dlat: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetLat0Dlat
      
      ! =======================================================================
      
      !> Let the ElementSet's mask pointer point to maskPointer's target.
      function ecElementSetSetMaskPointer(instancePtr, elementSetId, maskPointer) result(success)
         logical                                    :: success      !< function status
         type(tEcInstance),     pointer             :: instancePtr  !< intent(in)
         integer,                        intent(in) :: elementSetId !< unique ElementSet id
         integer, dimension(:), pointer             :: maskPointer  !< value = 0: invalid point; value /= 0: valid point
         !
         type(tEcElementSet),   pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_cartesian .or. &
                elementSetPtr%ofType == elmSetType_cartesian_equidistant .or. &
                elementSetPtr%ofType == elmSetType_spheric .or. &
                elementSetPtr%ofType == elmSetType_spheric_equidistant) then
               elementSetPtr%mask => maskPointer
               elementSetPtr%nCoordinates = size(maskPointer)
               success = .true.
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetMaskPointer: Won't set a mask for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetMaskPointer: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetMaskPointer
      
      
      ! =======================================================================
      
      !> Copy maskArray and point to it from the ElementSet.
      function ecElementSetSetMaskArray(instancePtr, elementSetId, maskArray) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         integer, dimension(:),     intent(in) :: maskArray    !< value = 0: invalid point; value /= 0: valid point
         !
         type(tEcElementSet),   pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         integer                        :: newSize       !< size of maskArray
         integer                        :: istat         !< reallocate status
         integer                        :: i             !< loop counter
         !
         success = .true.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_cartesian .or. &
                elementSetPtr%ofType == elmSetType_cartesian_equidistant .or. &
                elementSetPtr%ofType == elmSetType_spheric .or. &
                elementSetPtr%ofType == elmSetType_spheric_equidistant) then
               newSize = size(maskArray)
               ! Reallocate 1D integer array.
               if (allocated(elementSetPtr%maskArray)) then
                  deallocate(elementSetPtr%maskArray, stat = istat)
                  if (istat /= 0) then
                     call setECMessage("ERROR: ec_elementSet::ecElementSetSetMaskArray: Unable to deallocate memory.")
                     success = .false.
                  end if
               end if
               if (success) then
                  allocate(elementSetPtr%maskArray(newSize), stat = istat)
                  if (istat /= 0) then
                     call setECMessage("ERROR: ec_elementSet::ecFieldCreate1dArray: Unable to allocate additional memory.")
                     success = .false.
                  end if
               end if
               if (success) then
                  do i=1, newSize
                     elementSetPtr%maskArray(i) = maskArray(i)
                  end do
                  elementSetPtr%mask => elementSetPtr%maskArray
               end if
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetMaskArray: Won't set a mask for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetMaskArray: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetMaskArray
      
      ! =======================================================================
      
      !> Set the number of coordinates which are available in this ElementSet.
      function ecElementSetSetNumberOfCoordinates(instancePtr, elementSetId, nCoordinates) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         integer,                   intent(in) :: nCoordinates !< new number of coordinates of the ElementSet
         !
         type(tEcElementSet), pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_cartesian .or. &
                elementSetPtr%ofType == elmSetType_cartesian_equidistant .or. &
                elementSetPtr%ofType == elmSetType_spheric .or. &
                elementSetPtr%ofType == elmSetType_spheric_equidistant .or. &
                elementSetPtr%ofType == elmSetType_Grib .or. &
                elementSetPtr%ofType == elmSetType_scalar .or. &
                elementSetPtr%ofType == elmSetType_Ids .or. &
                elementSetPtr%ofType == elmSetType_samples) then
               elementSetPtr%nCoordinates = nCoordinates
               success = .true.
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetNumberOfCoordinates: Won't set the number of coordinates for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetNumberOfCoordinates: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetNumberOfCoordinates
      
      ! =======================================================================
      
      !> Overwrite the latitude of south pole (rotated spherical coordinates) for Grib data.
      function ecElementSetSetSouthPoleLatitude(instancePtr, elementSetId, newLat) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp),                  intent(in) :: newLat       !< new latitude of south pole (rotated spherical coordinates)
         !
         type(tEcElementSet), pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_Grib) then
               elementSetPtr%latsp = newLat
               success = .true.
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetSouthPoleLatitude: Won't set the latitude of south pole for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetSouthPoleLatitude: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetSouthPoleLatitude
      
      ! =======================================================================
      
      !> Overwrite the longitude of south pole (rotated spherical coordinates) for Grib data.
      function ecElementSetSetSouthPoleLongitude(instancePtr, elementSetId, newLon) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp),                  intent(in) :: newLon       !< new longitude of south pole (rotated spherical coordinates)
         !
         type(tEcElementSet), pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_Grib) then
               elementSetPtr%lonsp = newLon
               success = .true.
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetSouthPoleLongitude: Won't set the longitude of south pole for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetSouthPoleLongitude: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetSouthPoleLongitude
      
      ! =======================================================================
      
      !> Create and fill the array of locations and infer nCoordinates.
      function ecElementSetSetLocations(instancePtr, elementSetId, locArray) result(success)
         logical                                         :: success      !< function status
         type(tEcInstance), pointer                      :: instancePtr  !< intent(in)
         integer,                             intent(in) :: elementSetId !< unique ElementSet id
         character(*), dimension(:),          intent(in) :: locArray     !< new locations of the ElementSet
         !
         type(tEcElementSet),                 pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         character(maxNameLen), dimension(:), pointer :: locations     !< ElementSet's array of locations
         character(maxNameLen)                        :: location      !< a new location, converted to the correct length
         integer                                      :: newSize       !< size of locArray
         integer                                      :: istat         !< reallocate status
         integer                                      :: i             !< loop counter
         !
         success = .false.
         elementSetPtr => null()
         locations     => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_Ids) then
               locations => elementSetPtr%ids
               newSize = size(locArray)
               call reallocP(locations, newSize, stat = istat, keepExisting = .false.)
               if (istat == 0) then
                  do i=1, newSize
                     if (len_trim(locArray(i)) > maxNameLen) then
                        call setECMessage("WARNING: ec_elementSet::ecElementSetSetLocations: A new location string is too long and will be truncated.")
                     end if
                     location = locArray(i)
                     locations(i) = location
                  end do
                  elementSetPtr%nCoordinates = newSize
                  success = .true.
               end if
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetLocations: Won't set location array for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetLocations: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetLocations
      
      ! =======================================================================
      
      !> Set the spiderweb radius and its unit.
      function ecElementSetSetRadius(instancePtr, elementSetId, radius, newUnits) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         real(hp),                  intent(in) :: radius       !< radius of the spiderweb
         character(*),              intent(in) :: newUnits     !< units of the radius
         !
         type(tEcElementSet), pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         character(len=maxNameLen)    :: units         !< new unit of the ElementSet, converted to the correct length
         !
         success = .false.
         elementSetPtr => null()
         !
         if (len_trim(newUnits) > maxNameLen) then
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetRadius: The new units string is too long, unable to change units.")
            return
         else
            units = newUnits
         end if
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            if (elementSetPtr%ofType == elmSetType_spw) then
               elementSetPtr%radius = radius
               elementSetPtr%radius_unit = units
               success = .true.
            else
               call setECMessage("WARNING: ec_elementSet::ecElementSetSetRadius: Won't set radius for this ElementSet type.")
            end if
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetRadius: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetRadius
      
      ! =======================================================================
      
      !> Set the number of rows and columns.
      !! Internally the data is stored in a 1D array, so rows and columns only serve as an optional mapping.
      function ecElementSetSetRowsCols(instancePtr, elementSetId, n_rows, n_cols) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         integer,                   intent(in) :: n_rows       !< number of rows
         integer,                   intent(in) :: n_cols       !< number of columns
         !
         type(tEcElementSet), pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            elementSetPtr%n_rows = n_rows
            elementSetPtr%n_cols = n_cols
            success = .true.
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetrOWSCols: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetRowsCols
      
      ! =======================================================================
      
      !> Set the type of the 3D mesh.
      function ecElementSetSetItype3D(instancePtr, elementSetId, itype3D) result(success)
         logical                               :: success      !< function status
         type(tEcInstance), pointer            :: instancePtr  !< intent(in)
         integer,                   intent(in) :: elementSetId !< unique ElementSet id
         integer,                   intent(in) :: iType3D      !< type of the 3D mesh, sigma (0) or z (1)
         !
         type(tEcElementSet), pointer :: elementSetPtr !< ElementSet corresponding to elementSetId
         !
         success = .false.
         elementSetPtr => null()
         !
         elementSetPtr => ecSupportFindElementSet(instancePtr, elementSetId)
         if (associated(elementSetPtr)) then
            elementSetPtr%itype3D = itype3D
            success = .true.
         else
            call setECMessage("ERROR: ec_elementSet::ecElementSetSetItype3D: Cannot find an ElementSet with the supplied id.")
         end if
      end function ecElementSetSetItype3D
end module m_ec_elementSet

