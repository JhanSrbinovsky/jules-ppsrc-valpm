! *****************************COPYRIGHT*******************************
! (C) Crown copyright Met Office. All rights reserved.
! For further details please refer to the file COPYRIGHT.txt
! which you should have received as part of this distribution.
! *****************************COPYRIGHT*******************************
!+ Convert a proportion of fresh soot to aged soot
MODULE agesoot_mod

IMPLICIT NONE

CONTAINS

SUBROUTINE agesoot(                                                            &
  ! Arguments IN
  row_length, rows, off_x, off_y,                                              &
  model_levels, timestep,                                                      &
  ! Arguments INOUT
  soot_new,                                                                    &
  ! Arguments OUT
  delta_agesoot )

! Purpose:
!   To convert a proportion of the fresh soot to aged soot. This
!   conversion takes place as an exponential decay with an e-folding
!   time of 1.0 days.
!
!   Called by Aero_ctl
!
! Code Owner: See Unified Model Code Owners HTML page
! This file belongs in section: Aerosols
!
! Code Description:
!  Language: Fortran 90
!  This code is written to UMDP3 v8 programming standards
!
! Documentation: UMDP20

USE yomhook, ONLY: lhook, dr_hook
USE parkind1, ONLY: jprb, jpim
IMPLICIT NONE

! Arguments with intent IN:

INTEGER ::  row_length         ! no. of pts along a row
INTEGER ::  rows               ! no. of rows
INTEGER ::  off_x              ! size of small halo in i
INTEGER ::  off_y              ! size of small halo in j.
INTEGER ::  model_levels       ! no. of model levels
REAL    ::  timestep           ! timestep

! Arguments with intent IN:
! mmr of fresh soot
REAL :: soot_new(1-off_x:row_length+off_x,1-off_y:rows+off_y,model_levels)    

! Arguments with intent OUT:
! Soot increment due to ageing
REAL :: delta_agesoot(row_length, rows, model_levels)

! Local variables:
INTEGER ::  i,j,k  ! loop counters
! conversion rate equivalent to 1/(1.0 days expressed in seconds)
REAL, PARAMETER :: rate=1.157e-5
! 
REAL ::  a      ! Local workspace, equal to 1.0-exp(-rate*timestep)

INTEGER(KIND=jpim), PARAMETER :: zhook_in  = 0
INTEGER(KIND=jpim), PARAMETER :: zhook_out = 1
REAL(KIND=jprb)               :: zhook_handle

! Cycle through all points in the field, calculating the amount
! of soot converted on each point on this timestep.

IF (lhook) CALL dr_hook('AGESOOT',zhook_in,zhook_handle)
a = 1.0 - EXP(-rate*timestep)

DO k=1,model_levels
  DO j=1,rows
    DO i=1,row_length
      delta_agesoot(i,j,k) = a * soot_new(i,j,k)
    END DO
  END DO
END DO

IF (lhook) CALL dr_hook('AGESOOT',zhook_out,zhook_handle)
RETURN
END SUBROUTINE agesoot
END MODULE agesoot_mod
