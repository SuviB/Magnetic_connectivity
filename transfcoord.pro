;+
; Purpose is to rotate the given coordinates the given angles.
; input: start: coordinates to transform [lon, lat, R]
;        newzero: how much to turn. [lon, lat]
; output: result: coordinates in [lon, lat, R]
;         xyz: new coordinates in [x,y,z]
;-

pro transfcoord, start=start, newzero=newzero, result, xyz
  
  ;lat to colat
  start[1] = 90 - start[1]
  newzero[1] = 90 - newzero[1]
  
  x = start[2]*[sin(!dtor*start[1])*sin(!dtor*newzero[1]) $
                *cos(!dtor*start[0] - !dtor*newzero[0]) $
                - cos(!dtor*start[1])*cos(!dtor*newzero[1])]
  y = start[2]*[sin(!dtor*start[1])*sin(!dtor*(start[0]-newzero[0]))]
  z = start[2]*[sin(!dtor*start[1])*cos(!dtor*newzero[1]) $
                *cos(!dtor*start[0] - !dtor*newzero[0]) $
                + cos(!dtor*start[1])*sin(!dtor*newzero[1])]              
  xyz = [x,y,z]
  R = sqrt(x*x + y*y +z*z)
;  if z ne 0 then begin
     colat = (180/!pi)* acos(z / sqrt(x*x + y*y + z*z) )
 ; endif
  if z eq 0 then begin
     print, 'z=0'
     colat = 90
  endif
 ; if x ne 0 then begin
     lon = (180/!pi)* acos(x / sqrt(x*x + y*y))
 ; endif
  if x eq 0 then begin
     print, 'x=0'
     if y gt 0 then begin
        lon = 90
     endif
     if y lt 0 then begin
        lon = 270
     endif
     if y eq 0 then begin
        lon = 0
     endif
  endif
  
  result = [lon, 90 -colat, R]

end
