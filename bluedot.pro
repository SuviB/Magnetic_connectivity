;transforms a few pixels blue around the given point.

pro bluedot, outim=outim, x=x, y=y, blueoutim


  for i=0, 4 do begin
     for j=0, 4 do begin
        outim[0, x-i, y-j] = 0
        outim[1, x-i, y-j] = 0
        outim[2, x-i, y-j] = 200
        outim[0, x+i, y+j] = 0
        outim[1, x+i, y+j] = 0
        outim[2, x+i, y+j] = 200
        outim[0, x-i, y+j] = 0
        outim[1, x-i, y+j] = 0
        outim[2, x-i, y+j] = 200
        outim[0, x+i, y-j] = 0
        outim[1, x+i, y-j] = 0
        outim[2, x+i, y-j] = 200
     endfor
  endfor

  blueoutim = outim
   
end
