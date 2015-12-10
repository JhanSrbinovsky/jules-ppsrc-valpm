! (c) British Crown Copyright 2008-2013, the Met Office.
! All rights reserved.
! 
! Redistribution and use in source and binary forms, with or without modification, are permitted 
! provided that the following conditions are met:
! 
!     * Redistributions of source code must retain the above copyright notice, this list 
!       of conditions and the following disclaimer.
!     * Redistributions in binary form must reproduce the above copyright notice, this list
!       of conditions and the following disclaimer in the documentation and/or other materials 
!       provided with the distribution.
!     * Neither the name of the Met Office nor the names of its contributors may be used 
!       to endorse or promote products derived from this software without specific prior written 
!       permission.
! 
! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR 
! IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
! FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
! CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
! DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
! DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
! IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
! OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

!  Description:  Module that prepares the inputs in the correct format,
!                and makes the call to the ISCCP simulator.
!
! Code Owner: See Unified Model Code Owners HTML page
! This file belongs in section: COSP

MODULE MOD_COSP_ISCCP_SIMULATOR
  USE cosp_constants_mod
  USE cosp_types_mod
  IMPLICIT NONE

CONTAINS


!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!-------------- SUBROUTINE COSP_ISCCP_SIMULATOR -----------------
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SUBROUTINE COSP_ISCCP_SIMULATOR(gbx,sgx,y)

  ! Arguments
  TYPE(cosp_gridbox),INTENT(IN) :: gbx  ! Gridbox info
  TYPE(cosp_subgrid),INTENT(IN) :: sgx  ! Subgridbox info
  TYPE(cosp_isccp),INTENT(INOUT) :: y   ! ISCCP simulator output

  ! Local variables 
  INTEGER :: Nlevels,Npoints
  REAL :: pfull(gbx%Npoints, gbx%Nlevels)
  REAL :: phalf(gbx%Npoints, gbx%Nlevels + 1)
  REAL :: qv(gbx%Npoints, gbx%Nlevels)
  REAL :: cc(gbx%Npoints, gbx%Nlevels)
  REAL :: conv(gbx%Npoints, gbx%Nlevels)
  REAL :: dtau_s(gbx%Npoints, gbx%Nlevels)
  REAL :: dtau_c(gbx%Npoints, gbx%Nlevels)
  REAL :: at(gbx%Npoints, gbx%Nlevels)
  REAL :: dem_s(gbx%Npoints, gbx%Nlevels)
  REAL :: dem_c(gbx%Npoints, gbx%Nlevels)
  REAL :: frac_out(gbx%Npoints, gbx%Ncolumns, gbx%Nlevels)
  INTEGER :: sunlit(gbx%Npoints)

  Nlevels = gbx%Nlevels
  Npoints = gbx%Npoints
  ! Flip inputs. Levels from TOA to surface
  pfull  = gbx%p(:,Nlevels:1:-1)
  phalf(:,1)         = 0.0 ! Top level
  phalf(:,2:Nlevels+1) = gbx%ph(:,Nlevels:1:-1)
  qv     = gbx%sh(:,Nlevels:1:-1)
  cc     = 0.999999*gbx%tca(:,Nlevels:1:-1)
  conv   = 0.999999*gbx%cca(:,Nlevels:1:-1)
  dtau_s = gbx%dtau_s(:,Nlevels:1:-1)
  dtau_c = gbx%dtau_c(:,Nlevels:1:-1)
  at     = gbx%T(:,Nlevels:1:-1)
  dem_s  = gbx%dem_s(:,Nlevels:1:-1)
  dem_c  = gbx%dem_c(:,Nlevels:1:-1)
  frac_out(1:Npoints,:,1:Nlevels) = sgx%frac_out(1:Npoints,:,Nlevels:1:-1)
  sunlit = INT(gbx%sunlit)
! DEPENDS ON: icarus
  CALL icarus(0,0,gbx%npoints,sunlit,gbx%nlevels,gbx%ncolumns,                 &
            pfull,phalf,qv,cc,conv,dtau_s,dtau_c,                              &
            gbx%isccp_top_height,gbx%isccp_top_height_direction,               &
            gbx%isccp_overlap,frac_out,                                        &
            gbx%skt,gbx%isccp_emsfc_lw,at,dem_s,dem_c,                         &
            y%fq_isccp,y%totalcldarea,y%meanptop,y%meantaucld,                 &
            y%meanalbedocld,y%meantb,y%meantbclr,y%boxtau,y%boxptop)

  ! Flip outputs. Levels from surface to TOA
  ! --- (npoints,tau=7,pressure=7)
  y%fq_isccp(:,:,:) = y%fq_isccp(:,:,7:1:-1)

! Check if there is any value slightly greater than 1
  WHERE ((y%totalcldarea > 1.0-1.e-5) .AND. (y%totalcldarea < 1.0+1.e-5))
    y%totalcldarea = 1.0
  ENDWHERE

END SUBROUTINE COSP_ISCCP_SIMULATOR

END MODULE MOD_COSP_ISCCP_SIMULATOR
