## LICENSE
##   Copyright 2018 GEOPHYSTECH LLC
##
##   Licensed under the Apache License, Version 2.0 (the "License");
##   you may not use this file except in compliance with the License.
##   You may obtain a copy of the License at
##
##       http://www.apache.org/licenses/LICENSE-2.0
##
##   Unless required by applicable law or agreed to in writing, software
##   distributed under the License is distributed on an "AS IS" BASIS,
##   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##   See the License for the specific language governing permissions and
##   limitations under the License.

## initial release by Andrey Stepnov a.stepnov@geophsytech.ru

"""
**PGA ON GRID**

`pga_as2008(eq::Earthquake,grid::Array{Point_vs30,N},config_as2008::Params_as2008,min_pga::Number)` 

where `min_pga=0` by default
  
Output will be `Array{Point_pga_out,N}` with points where `g > min_pga` (g is Acceleration of gravity in percent rounded to ggg.gg)

**PGA FOR PLOTTING**
  
`pga_as2008(eq::Earthquake,config::Params_as2008,VS30::Number=350,distance::Int64=1000)` 

where `VS30=30` [m/s^2], `distance=1000` [km] by default.
  
Output will be `Array{Float64,1}` with `1:distance` values of `g` (that is Acceleration of gravity in percent rounded to ggg.gg)

**EXAMPLES:**
```  
pga_as2008(eq,grid,config_as2008,0.1) # for PGA on GRID
pga_as2008(eq,config_as2008) # for PGA PLOTS
```
"""
## AS2008 PGA modeling ON GRID
function pga_as2008(eq::Earthquake,grid::Array{Point_vs30},config::Params_as2008,min_pga::Number=0)
  vs30_row_num = length(grid[:,1])
  eq.moment_mag == 0 ? magnitude = eq.local_mag : magnitude = eq.moment_mag
  epicenter = LatLon(eq.lat, eq.lon)
  # define t6
  if magnitude < 5.5
    t6 = 1
  elseif magnitude <= 6.5 && magnitude >= 5.5
    t6 = (0.5 * (6.5 - magnitude) + 0.5)
  else 
    t6 = 0.5
  end
  # debug
  #info("DEBUG pring")
  #println("vs30_row_num=",vs30_row_num," ", 
  #        "magnitude=",magnitude," ",
  #        "epicenter=",epicenter," ",
  #        "t6=",t6," ")
  #info("DEBUG pring")
  #println(" vs30 ", " r_rup ", " f1 "," f8 ",
  #        " pga1100 "," f5 ", "g ")
  # modeling
  output_data = Array{Point_pga_out}(0)
  for i=1:vs30_row_num
    # rrup
    current_point = LatLon(grid[i].lat,grid[i].lon)
    r_rup = sqrt((distance(current_point,epicenter)/1000)^2 + eq.depth^2)
    # F1
    if magnitude <= config.c1
      f1 = config.a1 + config.a4 * (magnitude - config.c1) +
        config.a8 * (8.5 - magnitude)^2 + 
        (config.a2 + config.a3 * (magnitude - config.c1)) *
        log(sqrt(r_rup^2 + config.c4^2))
    else 
      f1 = config.a1 + config.a5 * (magnitude - config.c1) +
        config.a8 * (8.5 - magnitude)^2 +
        (config.a2 + config.a3 * (magnitude - config.c1)) *
            log(sqrt(r_rup^2 + config.c4^2))
    end
    # F8
    if r_rup < 100 
      f8 = 0;
    else 
      f8 = config.a18 * (r_rup - 100) * t6
    end
    # PGA1100
    pga1100 = exp((f1 + (config.a10 + config.b * config.n) *
               log(config.vs30_1100 / config.vlin) + f8))
    # F5
    if grid[i].vs30 < config.vlin
      f5 =  config.a10 * log(grid[i].vs30 / config.vlin) -
        config.b * log(pga1100 + config.c) + config.b * 
        log(pga1100 + config.c * (grid[i].vs30 / config.vlin)^config.n)
    elseif (grid[i].vs30 > config.vlin) && (grid[i].vs30 < config.v1)
      f5 = (config.a10 + config.b * config.n) *
        log(grid[i].vs30 / config.vlin)
    else
      f5 = (config.a10 + config.b * config.n) * 
        log(config.v1 / config.vlin)
    end
    g = round((exp(f1 + f5 + f8) * 100),2)
    if g >= min_pga
      output_data = push!(output_data, Point_pga_out(grid[i].lon,grid[i].lat,g))
    end
    # debug
    #println(hcat(grid[i].vs30,r_rup,f1,f8,pga1100,f5,g[i]))
  end
  return output_data
end

## AS2008 PGA modeling for PLOTTING
function pga_as2008(eq::Earthquake,config::Params_as2008,VS30::Number=350,distance::Int64=1000)
  eq.moment_mag == 0 ? magnitude = eq.local_mag : magnitude = eq.moment_mag
  # define t6
  if magnitude < 5.5
    t6 = 1
  elseif magnitude <= 6.5 && magnitude >= 5.5
    t6 = (0.5 * (6.5 - magnitude) + 0.5)
  else 
    t6 = 0.5
  end
  output_data = Array{Float64}(0)
  for i=1:distance
    # rrup
    r_rup = sqrt((i)^2 + eq.depth^2)
    # F1
    if magnitude <= config.c1
      f1 = config.a1 + config.a4 * (magnitude - config.c1) +
        config.a8 * (8.5 - magnitude)^2 + 
        (config.a2 + config.a3 * (magnitude - config.c1)) *
        log(sqrt(r_rup^2 + config.c4^2))
    else 
      f1 = config.a1 + config.a5 * (magnitude - config.c1) +
        config.a8 * (8.5 - magnitude)^2 +
        (config.a2 + config.a3 * (magnitude - config.c1)) *
            log(sqrt(r_rup^2 + config.c4^2))
    end
    # F8
    if r_rup < 100 
      f8 = 0;
    else 
      f8 = config.a18 * (r_rup - 100) * t6
    end
    # PGA1100
    pga1100 = exp((f1 + (config.a10 + config.b * config.n) *
               log(config.vs30_1100 / config.vlin) + f8))
    # F5
    if VS30 < config.vlin
      f5 =  config.a10 * log(VS30 / config.vlin) -
        config.b * log(pga1100 + config.c) + config.b * 
        log(pga1100 + config.c * (VS30 / config.vlin)^config.n)
    elseif (VS30 > config.vlin) && (VS30 < config.v1)
      f5 = (config.a10 + config.b * config.n) *
        log(VS30 / config.vlin)
    else
      f5 = (config.a10 + config.b * config.n) * 
        log(config.v1 / config.vlin)
    end
    g = round((exp(f1 + f5 + f8) * 100),2)
    output_data = push!(output_data, g)
  end
  return output_data
end
