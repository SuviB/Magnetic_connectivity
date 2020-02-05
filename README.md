# Magnetic_connectivity
This code is looking for magnetic connection between a flare and an observer during an SEP event, by using PFSS model for the coronal and Parker spiral for the heliospheric magnetic field

There are two main codes for the magnetic field modelling.
They both use tools from the PFSS-package in the SolarSoftware library.

1. pfss.pro
   Traces the magnetic field up from the flare site to the source surface and finds its parameters, such as the longitudinal width of the fiel on the source surface or the connectivity lambda.
   Calls for: histogram.pro, reddot.pro, greendot.pro, bluedot.pro
   
2. pfss2.pro
   Traces the magnetic field down from the nominal Parker spiral on the source surface and calculates the connectivity value beta.
   Calls for: histogram2.pro, reddot.pro, greendot.pro, bluedot.pro