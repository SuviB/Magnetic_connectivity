;transforms a few pixels green around the given point.

pro greendot, outim=outim, x=x, y=y, greenoutim

  for i=0, 4 do begin
     for j=0, 4 do begin
        outim[0, x-i, y-j] = 250
        outim[1, x-i, y-j] = 200
        outim[2, x-i, y-j] = 0
        outim[0, x+i, y+j] = 250
        outim[1, x+i, y+j] = 200
        outim[2, x+i, y+j] = 0
        outim[0, x-i, y+j] = 250
        outim[1, x-i, y+j] = 200
        outim[2, x-i, y+j] = 0
        outim[0, x+i, y-j] = 250
        outim[1, x+i, y-j] = 200
        outim[2, x+i, y-j] = 0
     endfor
  endfor

   greenoutim = outim

end
