;transforms a few pixels red around the given point.

pro reddot, outim=outim, x=x, y=y, redoutim

  for i=0, 4 do begin
     for j=0, 4 do begin
        outim[0, x-i, y-j] = 200
        outim[1, x-i, y-j] = 0
        outim[2, x-i, y-j] = 0
        outim[0, x+i, y+j] = 200
        outim[1, x+i, y+j] = 0
        outim[2, x+i, y+j] = 0
        outim[0, x-i, y+j] = 200
        outim[1, x-i, y+j] = 0
        outim[2, x-i, y+j] = 0
        outim[0, x+i, y-j] = 200
        outim[1, x+i, y-j] = 0
        outim[2, x+i, y-j] = 0
     endfor
  endfor

   redoutim = outim

end
