//---- LGPL --------------------------------------------------------------------
//
// Copyright (C)  Stichting Deltares, 2011-2015.
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation version 2.1.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, see <http://www.gnu.org/licenses/>.
//
// contact: delft3d.support@deltares.nl
// Stichting Deltares
// P.O. Box 177
// 2600 MH Delft, The Netherlands
//
// All indications and logos of, and references to, "Delft3D" and "Deltares"
// are registered trademarks of Stichting Deltares, and remain the property of
// Stichting Deltares. All rights reserved.
//
//------------------------------------------------------------------------------
// $Id: component.h 932 2011-10-25 09:41:59Z mourits $
// $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20110420_OnlineVisualisation/src/utils_lgpl/d_hydro_lib/include/component.h $
//------------------------------------------------------------------------------
//  d_hydro Abstract Component
//  DEFINITIONS
//
//  Irv.Elshoff@Deltares.NL
//  23 jan 11
//------------------------------------------------------------------------------


#pragma once


class Component {
    public:
        Component (
            DeltaresHydro * DH
            );

        virtual ~Component (
            void
            );

        virtual void
        Run (
            void
            );

        virtual void
        Init (
            void
            );

        virtual void
        Step (
            double stepSize
            );

        virtual void
        Finish (
            void
            );

        virtual double
        GetStartTime (
            void
            );

        virtual double
        GetEndTime (
            void
            );

        virtual double
        GetCurrentTime (
            void
            );

        virtual double
        GetTimeStep (
            void
            );

    public:
        DeltaresHydro * DH;        // DeltaresHydro instance

    };
