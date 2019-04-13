//calculate the geospatial distance between 2 sets of coordinates using the haversine formula

//GLOBALS
PI:3.14159
R:6371 //radius of Earth in Km

haversine:{[lat1;lon1;lat2;lon2] 
//deltas of latitude in raidans
  dLat:(lat2-lat1)*PI%180;
  dLon:(lon2-lon1)*PI%180;
  rlat1:lat1*PI%180;
  rlat2:lat2*PI%180;
  2*R*asin sqrt xexp[sin .5*dLat;2]+cos[rlat1]*cos[rlat2]*xexp[sin .5*dLon;2]
 }

//TODO move this into acutal functions
//some tests to get distances 
coords:("JJFFFFFF";enlist",")0:`:/home/paul/Documents/coords.csv
coords:select turbine_key,latitude,longitude from coords
ids:{cross[x;x]}coords.turbine_key
dist:(ids[;1];haversine .'raze each flip each value each flip each (exec last latitude,last longitude by turbine_key from coords)each ids)
dist:(!) .' flip each count[coords] cut flip dist

coords:coords,'flip enlist[`dist]!enlist dist
coords:update dist:1_'asc each dist from coords
