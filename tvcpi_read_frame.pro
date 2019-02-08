FUNCTION tvcpi_read_frame, lun, bpoint, id
   ;FUNCTION to read in an 3VCPI frame, slightly different than the 2DS/HVPS.
   ;Send lun, pointer to buffer start, and pointer to frame start
   ;  with respect to integer image array
   ;'id' is 1=Horizontal, 2=Vertical
   ;AB 5/2011
   ;Copyright © 2016 University Corporation for Atmospheric Research (UCAR). All rights reserved.


   
   point_lun,lun,bpoint
   x=spec_readint(lun,3)  ;Get size of frame
   nh=x[1] and 'fff'x
   nv=x[2] and 'fff'x

   ;Decode some flags
   missingtwh=ishft(x[1] and '1000'x,-12)  ;Missing time words
   missingtwv=ishft(x[2] and '1000'x,-12)
   fifoh=ishft(x[1] and '4000'x,-14)       ;Empty FIFO
   fifov=ishft(x[2] and '4000'x,-14)
   overloadh=ishft(x[1] and '8000'x,-15)   ;Last 2 words are overload times
   overloadv=ishft(x[2] and '8000'x,-15)
   
   ;Read the rest of the frame
   buff=spec_readint(lun,2+nh+nv)  
   
   particlecount=buff[0]
   numslices=buff[1]
   himage=0
   vimage=0
   image=bytarr(128,1)
   htime=0UL
   vtime=0UL
   time=0L
   error=1
   overload=0
   
   ;*NOTE* As of 10/2011 HVPS3, the first time word (bits 16-31) does not always 
   ;     increase monotonically.  Seems to be a problem somewhere... firmware?
   ;Have decided to skip this time word entirely for now
   
   IF (nh gt 3) and (id eq 'H') THEN BEGIN
      nh=nh-1 ;For some reason the 3VCPI is different here, this needs to be cleaned up...
      himageraw=buff[2:nh-1]                  ;Skip last two words (otherwise nh+1)
      hcounter=ulong(buff[nh:nh+1])           ;Last two words is a counter
      time=ishft(hcounter[1],16)+hcounter[0] ;Assemble timeword
      ;time=hcounter[0]  ;Skip hcounter[0] until fixed, rollovers taken care of in processbuffer
      image=spec_decompress(himageraw,overloadh)   
      error=0
      IF missingtwh THEN error=1
      overload=overloadh
   ENDIF
   
   IF (nv gt 3) and (id eq 'V') THEN BEGIN 
      nv=nv-1 ;For some reason the 3VCPI is different here, this needs to be cleaned up...
      vimageraw=buff[nh+2:nh+nv-1]            ;Skip last two words (otherwise nv+1)
      vcounter=ulong(buff[nh+nv:nh+nv+1])     ;Last two words is a counter
      time=ishft(vcounter[1],16)+vcounter[0]  ;Assemble timeword
      ;time=vcounter[0]  ;Skip vcounter[0] until fixed, rollovers taken care of in processbuffer
      image=spec_decompress(vimageraw,overloadv)   
      error=0
      IF missingtwv THEN error=1
      overload=overloadv
   ENDIF
   
   ;return,{himage:himage, vimage:vimage, nh:nh, nv:nv, htime:htime, vtime:vtime}
   return,{image:image, time:time, error:error, overload:overload, particlecount:particlecount}
END 
   
   
   
   
   