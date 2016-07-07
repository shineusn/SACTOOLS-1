PROGRAM sacstacking
!USE F90_UNIX_ENV
!Performs simple linear stacking of SAC formatted files listed
! in the input file
USE sac_i_o
IMPLICIT NONE
REAL(KIND=4), DIMENSION(:,:), ALLOCATABLE :: stacked
REAL(KIND=4), DIMENSION(:), ALLOCATABLE :: dinput, distances
REAL(KIND=4), DIMENSION(:), ALLOCATABLE :: dummy
INTEGER(KIND=4), DIMENSION(:), ALLOCATABLE :: counter
REAL(KIND=4)       :: delta1, delta2, b1, b2, e1, e2
REAL(KIND=4)       :: mindist, maxdist, dbin
REAL(KIND=4)       :: binmin, binmax
INTEGER(KIND=4)    :: NN, ios, npts1, npts2, J, KL
INTEGER(KIND=4)    :: NR, BINS
INTEGER(KIND=4), PARAMETER :: maxrecs = 1000
CHARACTER(LEN=112) :: file1, junk
CHARACTER(LEN=112) :: file2, ofile
CHARACTER(LEN=3) :: istr

!    --  R E A D  U S E R  I N P U T  --
!:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:!
NN = IARGC()
IF (NN < 4) THEN
  write(*,'(a)') "usage:  stacksac filelist mindist maxdist dbin"
  write(*,'(a)') "        filelist: list of files to be stacked"
  write(*,'(a)') "        mindist:  minimum epicentral distance"
  write(*,'(a)') "        maxdist:  maximum epicentral distance"
  write(*,'(a)') "        dbin:     size of epicentral distance bins"
  STOP
ENDIF

CALL GETARG(1,file1)
OPEN(UNIT=1,FILE=file1,STATUS='OLD',IOSTAT=ios)
IF (ios > 0) THEN
  write(*,*) "ERROR - Input file: '", TRIM(adjustl(file1)), "' does not exist ..."
  CLOSE(1)
  STOP
ENDIF

CALL GETARG(2,junk)
read(junk,*) mindist
CALL GETARG(3,junk)
read(junk,*) maxdist
CALL GETARG(4,junk)
read(junk,*) dbin

write(*,*) "Stacking SAC files in list '", TRIM(adjustl(file1)), "' ..."
write(*,*) "  Using Minimum Epicentral Distance: ", mindist, " (deg)"
write(*,*) "  Using Maximum Epicentral Distance: ", maxdist, " (deg)"
write(*,*) "  Using Epicentral Distance Bin Size: ", dbin, " (deg)"
!:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:!

!    -- DECIDE BIN LIMITS
!:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:!
BINS = NINT((maxdist - mindist)/dbin)
ALLOCATE(counter(BINS))
ALLOCATE(distances(BINS))
counter = 0
distances = 0.0


!:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:!

!    -- F I N D   T O T A L   #   O F   F I L E S
!:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:!
NR = 0
OPEN(UNIT=1,FILE=file1)
DO J=1,maxrecs
  READ(1,*,IOSTAT=ios) junk
  IF (ios == -1) EXIT
  IF (J == maxrecs) write(*,*) "Warning: Reached Maximum number of records.  Change 'maxrecs' and recompile..."
  NR = NR + 1
ENDDO
write(*,*) "Stacking ", NR, " SAC files..."
REWIND(1)
!:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:!

!    --  R E A D   I N P U T  S A C  F I L E S  A N D  S T A C K --
!:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:!
DO J=1,NR

  READ(1,*) file2

  IF ( J == 1) THEN
    CALL rbsac(file2,delta1,depmin,depmax,scale,odelta,b1,e1,o,a,internal1,      &
    t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,f,resp0,resp1,resp2,resp3,resp4,resp5,resp6,   &
    resp7,resp8,resp9,stla,stlo,stel,stdp,evla,evlo,evel,evdp,mag,user0,user1,   &
    user2,user3,user4,user5,user6,user7,user8,user9,dist,az,baz,gcarc,internal2, &
    internal3,depmen,cmpaz,cmpinc,xminimum,xmaximum,yminimum,ymaximum,unused1,   &
    unused2,unused3,unused4,unused5,unused6,unused7,nzyear,nzjday,nzhour,nzmin,  &
    nzsec,nzmsec,nvhdr,norid,nevid,npts1,internal4,nwfid,nxsize,nysize,unused8,  &
    iftype,idep,iztype,unused9,iinst,istreg,ievreg,ievtyp,iqual,isynth,imagtyp,  &
    imagsrc,unused10,unused11,unused12,unused13,unused14,unused15,unused16,      &
    unused17,leven,lpspol,lovrok,lcalda,unused18,kevnm,kstnm,khole,ko,ka,kt0,kt1,&
    kt2,kt3,kt4,kt5,kt6,kt7,kt8,kt9,kf,kuser0,kuser1,kuser2,kcmpnm,knetwk,kdatrd,&
    kinst,dinput)

    !Allocate memory
    ALLOCATE(stacked(BINS,npts1))
    stacked = 0.0

  ELSE
    CALL rbsac(file2,delta2,depmin,depmax,scale,odelta,b1,e1,o,a,internal1,      &
    t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,f,resp0,resp1,resp2,resp3,resp4,resp5,resp6,   &
    resp7,resp8,resp9,stla,stlo,stel,stdp,evla,evlo,evel,evdp,mag,user0,user1,   &
    user2,user3,user4,user5,user6,user7,user8,user9,dist,az,baz,gcarc,internal2, &
    internal3,depmen,cmpaz,cmpinc,xminimum,xmaximum,yminimum,ymaximum,unused1,   &
    unused2,unused3,unused4,unused5,unused6,unused7,nzyear,nzjday,nzhour,nzmin,  &
    nzsec,nzmsec,nvhdr,norid,nevid,npts2,internal4,nwfid,nxsize,nysize,unused8,  &
    iftype,idep,iztype,unused9,iinst,istreg,ievreg,ievtyp,iqual,isynth,imagtyp,  &
    imagsrc,unused10,unused11,unused12,unused13,unused14,unused15,unused16,      &
    unused17,leven,lpspol,lovrok,lcalda,unused18,kevnm,kstnm,khole,ko,ka,kt0,kt1,&
    kt2,kt3,kt4,kt5,kt6,kt7,kt8,kt9,kf,kuser0,kuser1,kuser2,kcmpnm,knetwk,kdatrd,&
    kinst,dinput)
  ENDIF

  IF (nvhdr /= 6) THEN  !Check Header Version
    write(*,*) "ERROR - File: '", TRIM(adjustl(file1)), "' appears to be of non-native &
    &byte-order or is not a SAC file."
    STOP
  ENDIF

  IF (delta1 /= delta2 .AND. J > 1) THEN  !Check equal sample rates
    write(*,*) "ERROR - Input files contain unequal sample rates ..."
    STOP
  ENDIF

  IF (npts1 /= npts2 .AND. J > 1) THEN  !Check vector lengths
    write(*,*) "ERROR - Input files are not equal length ..."
    !STOP
  ENDIF

  binmin = mindist
  binmax = mindist + dbin
  DO KL = 1,BINS
    IF (gcarc >= binmin .AND. gcarc <= binmax) THEN
      stacked(KL,1:npts1) = stacked(KL,1:npts1) + dinput(1:npts1) 
      counter(KL) = counter(KL) + 1
      distances(KL) = distances(KL) + gcarc
    ENDIF
    binmin = binmin + dbin
    binmax = binmax + dbin
  ENDDO

ENDDO

DO KL=1,BINS
  distances(KL) = distances(KL)/counter(KL)
  !stacked(KL,:) = stacked(KL,:)/counter(KL) + distances(KL)
  stacked(KL,:) = stacked(KL,:)/counter(KL) 
ENDDO
!:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:!

!    --  W R I T E   O U T   S T A C K  --
!:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:!

!Initialize sac file
CALL initsac(ofile,delta,depmin,depmax,scale,odelta,b,e,o,a,internal1,       &
t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,f,resp0,resp1,resp2,resp3,resp4,resp5,resp6,   &
resp7,resp8,resp9,stla,stlo,stel,stdp,evla,evlo,evel,evdp,mag,user0,user1,   &
user2,user3,user4,user5,user6,user7,user8,user9,dist,az,baz,gcarc,internal2, &
internal3,depmen,cmpaz,cmpinc,xminimum,xmaximum,yminimum,ymaximum,unused1,   &
unused2,unused3,unused4,unused5,unused6,unused7,nzyear,nzjday,nzhour,nzmin,  &
nzsec,nzmsec,nvhdr,norid,nevid,npts,internal4,nwfid,nxsize,nysize,unused8,   &
iftype,idep,iztype,unused9,iinst,istreg,ievreg,ievtyp,iqual,isynth,imagtyp,  &
imagsrc,unused10,unused11,unused12,unused13,unused14,unused15,unused16,      &
unused17,leven,lpspol,lovrok,lcalda,unused18,kevnm,kstnm,khole,ko,ka,kt0,kt1,&
kt2,kt3,kt4,kt5,kt6,kt7,kt8,kt9,kf,kuser0,kuser1,kuser2,kcmpnm,knetwk,kdatrd,&
kinst,dummy)

DO KL=1,BINS

  write(istr,"(I3.3)") KL
  ofile ='stacked_'//istr//'.sac'
  delta =delta1
  depmin =MINVAL(stacked(KL,:))
  depmax =MAXVAL(stacked(KL,:))
  b = b1
  e = e1
  npts = npts1
  kevnm ='stacksac output'
  kuser0 = 'N traces'
  user0 = counter(KL)
  gcarc = distances(KL)

  CALL wbsac(ofile,delta,depmin,depmax,scale,odelta,b,e,o,a,internal1,         &
  t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,f,resp0,resp1,resp2,resp3,resp4,resp5,resp6,   &
  resp7,resp8,resp9,stla,stlo,stel,stdp,evla,evlo,evel,evdp,mag,user0,user1,   &
  user2,user3,user4,user5,user6,user7,user8,user9,dist,az,baz,gcarc,internal2, &
  internal3,depmen,cmpaz,cmpinc,xminimum,xmaximum,yminimum,ymaximum,unused1,   &
  unused2,unused3,unused4,unused5,unused6,unused7,nzyear,nzjday,nzhour,nzmin,  &
  nzsec,nzmsec,nvhdr,norid,nevid,npts,internal4,nwfid,nxsize,nysize,unused8,   &
  iftype,idep,iztype,unused9,iinst,istreg,ievreg,ievtyp,iqual,isynth,imagtyp,  &
  imagsrc,unused10,unused11,unused12,unused13,unused14,unused15,unused16,      &
  unused17,leven,lpspol,lovrok,lcalda,unused18,kevnm,kstnm,khole,ko,ka,kt0,kt1,&
  kt2,kt3,kt4,kt5,kt6,kt7,kt8,kt9,kf,kuser0,kuser1,kuser2,kcmpnm,knetwk,kdatrd,&
  kinst,stacked(KL,1:npts1))

ENDDO
!:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:=====:!



END PROGRAM sacstacking