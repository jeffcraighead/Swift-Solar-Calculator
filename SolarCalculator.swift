//
//  SolarCalculator.swift
//  SmartAngle
//
//  Created by Jeff Craighead on 5/12/15.
//  Copyright (c) 2015 SplatSoSoft. All rights reserved.
//
//  Based on the NREL Technical Report "Solar Position Algorithm for Solar Radiation Applications"
//  NREL/TP-560-34302 - November 2005 revision

import Foundation
import UIKit

class SolarCalculator {
    let JD_MINUS = 0
    let JD_ZERO = 1
    let JD_PLUS = 2
    let JD_COUNT = 3
    
    let TERM_A = 0
    let TERM_B = 1
    let TERM_C = 2
    let TERM_COUNT = 3
    
    let TERM_PSI_A = 0
    let TERM_PSI_B = 1
    let TERM_EPS_C = 2
    let TERM_EPS_D = 3
    let TERM_PE_COUNT = 4
    
    let TERM_X0 = 0
    let TERM_X1 = 1
    let TERM_X2 = 2
    let TERM_X3 = 3
    let TERM_X4 = 4
    let TERM_X_COUNT = 5
    
    let SUN_TRANSIT = 0
    let SUN_RISE = 1
    let SUN_SET = 2
    let SUN_COUNT = 3
    
    let pi = M_PI
    let sun_radius = 0.26667
    
    
    var year : Int = 0 //4 digit year, -2000 to 6000
    var month : Int = 0 //2 digit month, 1 to 12
    var day : Int = 0 //2 digit day, 1 to 31
    var hour : Int = 0 //Local time hour, 0 to 24
    var minute : Int = 0 //Local time minute, 0 to 59
    var second : Double = 0 //Local time second, 0 < 60
    
    var delta_ut1 : Double = -0.7 //Fractional second between UTC and UT - available from US Navy time report at http://maia.usno.navy.mil/ser7/ser7.dat
    var tai_m_utc : Double = 35.0 //Difference between earth rotation time and terrestrial time - available at http://maia.usno.navy.mil/ser7/ser7.dat
    
    var delta_t : Double = 0 //Calculated in init() - delta_t = 32.184 + (TAI-UTC) - DUT1
    
    var timezone : Double = 0 //-18 to 18 hours
    var latitude : Double = 0 // -90 to 90
    var longitude : Double = 0 //-180 to 180    
    var elevation : Double = 0 //Observer elevation in meters -6500000 or higher
    var pressure : Double = 1013.25 //0 to 5000 millibars - 1013.25 is the average pressure at sea level
    var temperature : Double = 17.5 //Average annual temperature in degrees C
    
    /* slope and azimuth describe the orientation of the surface at the observation location */
    var slope : Double = 0 // Surface slope measured from the horizontal plane, -360 to 360
    var azm_rotation : Double = 0 // Surface azimuth rotation (measured from south to projection of surface normal on horizontal plane. negative east) -360 to 360
    
    
    var atmos_refract : Double = 0.5667 //Atmostpheric refraction at time of sunrise and sunset -5 to 5 degrees, typical: 0.5667
    
    
    /* Intermediate Values */
    var jd : Double = 0 //Julian day
    var jc : Double = 0  //Julian century
    var jde : Double = 0  //Julian ephermeris day
    var jce : Double = 0  //Julian ephermeris century
    var jme : Double = 0  //Julian ephermeris millennium
    
    
    var l : Double = 0  //earth heliocentric longitude [degrees]
    var b : Double = 0  //earth heliocentric latitude [degrees]
    var r : Double = 0  //earth radius vector [Astronomical Units, AU]
    var theta : Double = 0  //geocentric longitude [degrees]
    var beta : Double = 0  //geocentric latitude [degrees]
    var x0 : Double = 0  //mean elongation (moon-sun) [degrees]
    var x1 : Double = 0  //mean anomaly (sun) [degrees]
    var x2 : Double = 0 //mean anomaly (moon) [degrees]
    var x3 : Double = 0 //argument latitude (moon) [degrees]
    var x4 : Double = 0 //ascending longitude (moon) [degrees]
    var del_psi : Double = 0 //nutation longitude [degrees]
    var del_epsilon : Double = 0 //nutation obliquity [degrees]
    var epsilon0 : Double = 0 //ecliptic mean obliquity [arc seconds]
    var epsilon : Double = 0 //ecliptic true obliquity [degrees]
    var del_tau : Double = 0 //aberration correction [degrees]
    var lamda : Double = 0 //apparent sun longitude [degrees]
    var nu0 : Double = 0 //Greenwich mean sidereal time [degrees]
    var nu : Double = 0 //Greenwich sidereal time [degrees]
    var alpha : Double = 0
    var delta : Double = 0
    var h : Double = 0 //observer hour angle [degrees]
    var xi : Double = 0 //sun equatorial horizontal parallax [degrees]
    var del_alpha : Double = 0 //sun right ascension parallax [degrees]
    var delta_prime : Double = 0 //topocentric sun declination [degrees]
    var alpha_prime : Double = 0 //topocentric sun right ascension [degrees]
    var h_prime : Double = 0 //topocentric local hour angle [degrees]
    var e0 : Double = 0 //topocentric elevation angle (uncorrected) [degrees]
    var del_e : Double = 0 //atmospheric refraction correction [degrees]
    var e : Double = 0 //topocentric elevation angle (corrected) [degrees]
    var eot : Double = 0 //equation of time [minutes]
    var srha : Double = 0 //sunrise hour angle [degrees]
    var ssha : Double = 0 //sunset hour angle [degrees]
    var sta : Double = 0 //sun transit altitude [degrees]
    
    
    /*  Output Values  */
    var zenith : Double = 0  //topocentric zenith angle [degrees]
    var azimuth_astro : Double = 0  //topocentric azimuth angle (westward from south) [for astronomers]
    var azimuth : Double = 0  //topocentric azimuth angle (eastward from north) [for navigators and solar radiation]
    var incidence : Double = 0  //surface incidence angle [degrees]
    var suntransit : Double = 0  //local sun transit time (or solar noon) [fractional hour]
    var sunrise : Double = 0  //local sunrise time (+/- 30 seconds) [fractional hour]
    var sunset : Double = 0  //local sunset time (+/- 30 seconds) [fractional hour]
    
    
    let L_TERMS : [[[Double]]] = [ [ [175347046.0,0,0], [3341656.0,4.6692568,6283.07585], [34894.0,4.6261,12566.1517], [3497.0,2.7441,5753.3849], [3418.0,2.8289,3.5231], [3136.0,3.6277,77713.7715], [2676.0,4.4181,7860.4194], [2343.0,6.1352,3930.2097], [1324.0,0.7425,11506.7698], [1273.0,2.0371,529.691], [1199.0,1.1096,1577.3435], [990,5.233,5884.927], [902,2.045,26.298], [857,3.508,398.149], [780,1.179,5223.694], [753,2.533,5507.553], [505,4.583,18849.228], [492,4.205,775.523], [357,2.92,0.067], [317,5.849,11790.629], [284,1.899,796.298], [271,0.315,10977.079], [243,0.345,5486.778], [206,4.806,2544.314], [205,1.869,5573.143], [202,2.458,6069.777], [156,0.833,213.299], [132,3.411,2942.463], [126,1.083,20.775], [115,0.645,0.98], [103,0.636,4694.003], [102,0.976,15720.839], [102,4.267,7.114], [99,6.21,2146.17], [98,0.68,155.42], [86,5.98,161000.69], [85,1.3,6275.96], [85,3.67,71430.7], [80,1.81,17260.15], [79,3.04,12036.46], [75,1.76,5088.63], [74,3.5,3154.69], [74,4.68,801.82], [70,0.83,9437.76], [62,3.98,8827.39], [61,1.82,7084.9], [57,2.78,6286.6], [56,4.39,14143.5], [56,3.47,6279.55], [52,0.19,12139.55], [52,1.33,1748.02], [51,0.28,5856.48], [49,0.49,1194.45], [41,5.37,8429.24], [41,2.4,19651.05], [39,6.17,10447.39], [37,6.04,10213.29], [37,2.57,1059.38], [36,1.71,2352.87], [36,1.78,6812.77], [33,0.59,17789.85], [30,0.44,83996.85], [30,2.74,1349.87], [25,3.16,4690.48] ], [ [628331966747.0,0,0], [206059.0,2.678235,6283.07585], [4303.0,2.6351,12566.1517], [425.0,1.59,3.523], [119.0,5.796,26.298], [109.0,2.966,1577.344], [93,2.59,18849.23], [72,1.14,529.69], [68,1.87,398.15], [67,4.41,5507.55], [59,2.89,5223.69], [56,2.17,155.42], [45,0.4,796.3], [36,0.47,775.52], [29,2.65,7.11], [21,5.34,0.98], [19,1.85,5486.78], [19,4.97,213.3], [17,2.99,6275.96], [16,0.03,2544.31], [16,1.43,2146.17], [15,1.21,10977.08], [12,2.83,1748.02], [12,3.26,5088.63], [12,5.27,1194.45], [12,2.08,4694], [11,0.77,553.57], [10,1.3,6286.6], [10,4.24,1349.87], [9,2.7,242.73], [9,5.64,951.72], [8,5.3,2352.87], [6,2.65,9437.76], [6,4.67,4690.48] ], [ [52919.0,0,0], [8720.0,1.0721,6283.0758], [309.0,0.867,12566.152], [27,0.05,3.52], [16,5.19,26.3], [16,3.68,155.42], [10,0.76,18849.23], [9,2.06,77713.77], [7,0.83,775.52], [5,4.66,1577.34], [4,1.03,7.11], [4,3.44,5573.14], [3,5.14,796.3], [3,6.05,5507.55], [3,1.19,242.73], [3,6.12,529.69], [3,0.31,398.15], [3,2.28,553.57], [2,4.38,5223.69], [2,3.75,0.98] ], [ [289.0,5.844,6283.076], [35,0,0], [17,5.49,12566.15], [3,5.2,155.42], [1,4.72,3.52], [1,5.3,18849.23], [1,5.97,242.73] ], [ [114.0,3.142,0], [8,4.13,6283.08], [1,3.84,12566.15] ], [ [1,3.14,0] ] ]
    
    let B_TERMS : [[[Double]]] = [ [ [280.0,3.199,84334.662], [102.0,5.422,5507.553], [80,3.88,5223.69], [44,3.7,2352.87], [32,4,1577.34] ], [ [9,3.9,5507.55], [6,1.73,5223.69] ] ]
    
    let R_TERMS : [[[Double]]] = [ [ [100013989.0,0,0], [1670700.0,3.0984635,6283.07585], [13956.0,3.05525,12566.1517], [3084.0,5.1985,77713.7715], [1628.0,1.1739,5753.3849], [1576.0,2.8469,7860.4194], [925.0,5.453,11506.77], [542.0,4.564,3930.21], [472.0,3.661,5884.927], [346.0,0.964,5507.553], [329.0,5.9,5223.694], [307.0,0.299,5573.143], [243.0,4.273,11790.629], [212.0,5.847,1577.344], [186.0,5.022,10977.079], [175.0,3.012,18849.228], [110.0,5.055,5486.778], [98,0.89,6069.78], [86,5.69,15720.84], [86,1.27,161000.69], [65,0.27,17260.15], [63,0.92,529.69], [57,2.01,83996.85], [56,5.24,71430.7], [49,3.25,2544.31], [47,2.58,775.52], [45,5.54,9437.76], [43,6.01,6275.96], [39,5.36,4694], [38,2.39,8827.39], [37,0.83,19651.05], [37,4.9,12139.55], [36,1.67,12036.46], [35,1.84,2942.46], [33,0.24,7084.9], [32,0.18,5088.63], [32,1.78,398.15], [28,1.21,6286.6], [28,1.9,6279.55], [26,4.59,10447.39] ], [ [103019.0,1.10749,6283.07585], [1721.0,1.0644,12566.1517], [702.0,3.142,0], [32,1.02,18849.23], [31,2.84,5507.55], [25,1.32,5223.69], [18,1.42,1577.34], [10,5.91,10977.08], [9,1.42,6275.96], [9,0.27,5486.78] ], [ [4359.0,5.7846,6283.0758], [124.0,5.579,12566.152], [12,3.14,0], [9,3.63,77713.77], [6,1.87,5573.14], [3,5.47,18849.23] ], [ [145.0,4.273,6283.076], [7,3.92,12566.15] ], [ [4,2.56,6283.08] ] ]
    
    
    let Y_TERMS : [[Int]] = [ [0,0,0,0,1], [-2,0,0,2,2], [0,0,0,2,2], [0,0,0,0,2], [0,1,0,0,0], [0,0,1,0,0], [-2,1,0,2,2], [0,0,0,2,1], [0,0,1,2,2], [-2,-1,0,2,2], [-2,0,1,0,0], [-2,0,0,2,1], [0,0,-1,2,2], [2,0,0,0,0], [0,0,1,0,1], [2,0,-1,2,2], [0,0,-1,0,1], [0,0,1,2,1], [-2,0,2,0,0], [0,0,-2,2,1], [2,0,0,2,2], [0,0,2,2,2], [0,0,2,0,0], [-2,0,1,2,2], [0,0,0,2,0], [-2,0,0,2,0], [0,0,-1,2,1], [0,2,0,0,0], [2,0,-1,0,1], [-2,2,0,2,2], [0,1,0,0,1], [-2,0,1,0,1], [0,-1,0,0,1], [0,0,2,-2,0], [2,0,-1,2,1], [2,0,1,2,2], [0,1,0,2,2], [-2,1,1,0,0], [0,-1,0,2,2], [2,0,0,2,1], [2,0,1,0,0], [-2,0,2,2,2], [-2,0,1,2,1], [2,0,-2,0,1], [2,0,0,0,1], [0,-1,1,0,0], [-2,-1,0,2,1], [-2,0,0,0,1], [0,0,2,2,1], [-2,0,2,0,1], [-2,1,0,2,1], [0,0,1,-2,0], [-1,0,1,0,0], [-2,1,0,0,0], [1,0,0,0,0], [0,0,1,2,0], [0,0,-2,2,2], [-1,-1,1,0,0], [0,1,1,0,0], [0,-1,1,2,2], [2,-1,-1,2,2], [0,0,3,2,2], [2,-1,0,2,2] ]
    
    let PE_TERMS : [[Double]] = [ [-171996,-174.2,92025,8.9], [-13187,-1.6,5736,-3.1], [-2274,-0.2,977,-0.5], [2062,0.2,-895,0.5], [1426,-3.4,54,-0.1], [712,0.1,-7,0], [-517,1.2,224,-0.6], [-386,-0.4,200,0], [-301,0,129,-0.1], [217,-0.5,-95,0.3], [-158,0,0,0], [129,0.1,-70,0], [123,0,-53,0], [63,0,0,0], [63,0.1,-33,0], [-59,0,26,0], [-58,-0.1,32,0], [-51,0,27,0], [48,0,0,0], [46,0,-24,0], [-38,0,16,0], [-31,0,13,0], [29,0,0,0], [29,0,-12,0], [26,0,0,0], [-22,0,0,0], [21,0,-10,0], [17,-0.1,0,0], [16,0,-8,0], [-16,0.1,7,0], [-15,0,9,0], [-13,0,7,0], [-12,0,6,0], [11,0,0,0], [-10,0,5,0], [-8,0,3,0], [7,0,-3,0], [-7,0,0,0], [-7,0,3,0], [-7,0,3,0], [6,0,0,0], [6,0,-3,0], [6,0,-3,0], [-6,0,3,0], [-6,0,3,0], [5,0,0,0], [-5,0,3,0], [-5,0,3,0], [-5,0,3,0], [4,0,0,0], [4,0,0,0], [4,0,0,0], [-4,0,0,0], [-4,0,0,0], [-4,0,0,0], [3,0,0,0], [-3,0,0,0], [-3,0,0,0], [-3,0,0,0], [-3,0,0,0], [-3,0,0,0], [-3,0,0,0], [-3,0,0,0] ]
    
    
    
    init()
    {
        delta_t = 32.184 + tai_m_utc - delta_ut1
    }
    
    init(tai_m_utc : Double, delta_ut1 : Double)
    {
        self.tai_m_utc = tai_m_utc
        self.delta_ut1 = delta_ut1
        delta_t = 32.184 + tai_m_utc - delta_ut1
    }
    
    
    func rad2deg(radians : Double) -> Double
    {
        return (radians * 180.0) / pi
    }
    
    func deg2rad(degrees : Double) -> Double
    {
        return (degrees * pi) / 180.0
    }
    
    //Limit to 0-360
    func limit_degrees(degrees : Double) -> Double
    {
        let deg : Double = degrees / 360.0 //fractional degrees
        var limited : Double = 360.0 * (deg - floor(deg)) //limit -360 to 360
        if limited < 0{ //now limit to 0-360
            limited += 360.0
        }
        return limited
    }
    
    //Limit to -180 to 180
    func limit_degrees180pm(degrees : Double) -> Double
    {
        let deg : Double = degrees / 360.0 //fractional degrees
        var limited : Double = 360.0 * (deg - floor(deg)) //limit -360 to 360
        if limited < -180 { //now limit to 0-360
            limited += 360.0
        }
        else if limited > 180 { //now limit to 0-360
            limited -= 360.0
        }
        return limited
    }
    
    //Limit to 0 to 180
    func limit_degrees180(degrees : Double) -> Double
    {
        let deg : Double = degrees / 180.0 //fractional degrees
        var limited : Double = 180.0 * (deg - floor(deg)) //limit -360 to 360
        if limited < 0{ //now limit to 0-360
            limited += 180.0
        }
        return limited
    }
    
    //Limit to 0 to 1 by truncation
    func limit_zero2one(value : Double) -> Double{
        var limited : Double = value - floor(value)
        if limited < 0{
            limited += 1.0
        }
        
        return limited
    }
    
    func limit_minutes(minutes : Double) -> Double{
        var limited : Double = minutes
        if limited < -20.0 {
            limited += 1440.0
        }
        else if limited > 20.0 {
            limited -= 1440.0
        }
        return minutes
    }
    
    //Convert a fractional day to local fractional hour
    func dayfrac_to_local_hr(dayfrac: Double, timezone : Double) -> Double{
        return 24.0*limit_zero2one(dayfrac + timezone/24.0)
    }
    
    func third_order_polynomial(a : Double, b : Double, c : Double, d : Double, x : Double) -> Double{
        return ((a*x + b)*x + c)*x + d
    }
    
    //Validate all input parameters to make sure they are within expected bounds
    func validate_inputs() -> Int{
        if ((year < -2000) || (year > 6000)) { return 1 }
        if ((month < 1 ) || (month > 12 )) { return 2 }
        if ((day < 1 ) || (day > 31 )) { return 3 }
        if ((hour < 0 ) || (hour > 24 )) { return 4 }
        if ((minute < 0 ) || (minute > 59 )) { return 5 }
        if ((second < 0 ) || (second >= 60 )) { return 6 }
        if ((pressure < 0 ) || (pressure > 5000)) { return 12 }
        if ((temperature <= -273) || (temperature > 6000)) { return 13 }
        if ((delta_ut1 <= -1 ) || (delta_ut1 >= 1 )) { return 17 }
        if ((hour == 24 ) && (minute > 0 )) { return 5 }
        if ((hour == 24 ) && (second > 0 )) { return 6 }
        if (abs(delta_t) > 8000 ) { return 7 }
        if (abs(timezone) > 18 ) { return 8 }
        if (abs(longitude) > 180 ) { return 9 }
        if (abs(latitude) > 90 ) { return 10 }
        if (abs(atmos_refract) > 5 ) { return 16 }
        if ( elevation < -6500000){ return 11 }
        if (abs(slope) > 360) { return 14 }
        if (abs(azm_rotation) > 360) { return 15 }
        return 0
    }
    
    //Calculate the Julian day
    func julian_day(var year : Int, var month : Int, var day : Int, var hour : Int, var minute : Int, var second : Double, var dut1 : Double, var tz : Double) -> Double {
        
        let sec_dut1 : Double = (second + dut1)/60.0
        let min_sec_dut1 : Double = (Double(minute) + sec_dut1)/60.0
        var day_decimal : Double = Double(day) + (Double(hour) - tz + min_sec_dut1)/24.0
        
        if month < 3 {
            month += 12
            year -= 1
        }
        var julian_day : Double = floor(365.25*(Double(year)+4716.0)) + floor(30.6001*(Double(month)+1)) + day_decimal - 1524.5
        if (julian_day > 2299160.0) {
            let a = floor(Double(year/100))
            julian_day += (2 - a + floor(a/4))
        }

        return julian_day;
    }
    
    func julian_century(jd : Double) -> Double
    {
        return (jd - 2451545.0)/36525.0
    }
    
    func julian_ephemeris_day(jd : Double, delta_t : Double) -> Double
    {
        return jd + (delta_t/86400.0)
    }
    
    func julian_ephemeris_century(jde : Double) -> Double
    {
        return (jde - 2451545.0)/36525.0
    }
    
    func julian_ephemeris_millennium(jce : Double) -> Double
    {
        return (jce/10.0)
    }
    
    func earth_periodic_term_summation(terms : [[Double]], jme : Double) -> Double
    {
        var sum : Double = 0.0
        for term : [Double] in terms{
            sum += term[TERM_A] * cos(term[TERM_B]+term[TERM_C]*jme)
        }
        return sum
    }
    
    func earth_values(term_sum : [Double], jme : Double) -> Double
    {
        var sum : Double = 0
        for i in 0...term_sum.count - 1
        {
            var power_term : Double = pow(jme,Double(i))
            sum += (term_sum[i] * power_term)
        }
        sum /= 1.0e8
        return sum
    }
    
    
    func earth_heliocentric_longitude(jme : Double) ->Double
    {
        var sum : [Double] = [Double]()
        
        for i in 0 ... L_TERMS.count - 1
        {
            sum.append(earth_periodic_term_summation(L_TERMS[i], jme: jme))
        }
        return limit_degrees(rad2deg(earth_values(sum, jme: jme)))
    }
    
    
    func earth_heliocentric_latitude(jme : Double) ->Double
    {
        var sum : [Double] = [Double]()
        
        for i in 0 ... B_TERMS.count - 1
        {
            sum.append(earth_periodic_term_summation(B_TERMS[i], jme: jme))
        }
        return limit_degrees(rad2deg(earth_values(sum, jme: jme)))
    }
    
    
    func earth_radius_vector(jme : Double) -> Double
    {
        var sum : [Double] = [Double]()
        
        for i in 0 ... R_TERMS.count - 1
        {
            sum.append(earth_periodic_term_summation(R_TERMS[i], jme: jme))
        }
        return earth_values(sum, jme: jme)
    }
    
    func geocentric_longitude(l : Double) -> Double
    {
        var theta : Double = l + 180.0
        if theta >= 360.0 { theta -= 360.0 }
        return theta
    }
    
    func geocentric_latitude(b : Double) -> Double
    {
        return -b
    }
    
    func mean_elongation_moon_sun(jce : Double) -> Double
    {
        return third_order_polynomial(1.0/189474.0, b: -0.0019142, c: 445267.11148, d: 297.85036, x: jce)
    }
    
    func mean_anomaly_sun(jce : Double) -> Double
    {
        return third_order_polynomial(-1.0/300000.0, b: -0.0001603, c: 35999.05034, d: 357.52772, x: jce)
    }
    
    func mean_anomaly_moon(jce : Double) -> Double
    {
        return third_order_polynomial(1.0/56250.0, b: 0.0086972, c: 477198.867398, d: 134.96298, x: jce)
    }
    
    func argument_latitude_moon(jce : Double) -> Double
    {
        return third_order_polynomial(1.0/327270.0, b: -0.0036825, c: 483202.017538, d: 93.27191, x: jce)
    }
    
    func ascending_longitude_moon(jce : Double) -> Double
    {
        return third_order_polynomial(1.0/450000.0, b: 0.0020708, c: -1934.136261, d: 125.04452, x: jce)
    }
    
    func xy_term_summation(i : Int, x : [Double]) -> Double
    {
        var sum : Double = 0
        for j in 0 ... Y_TERMS[i].count - 1
        {
            sum += x[j] * Double(Y_TERMS[i][j])
        }
        return sum
    }
    
    func nutation_longitude_and_obliquity(jce : Double, x : [Double]) -> (del_psi : Double, del_epsilon : Double)
    {
        var xy_term_sum : Double = 0
        var sum_psi : Double = 0
        var sum_epsilon : Double = 0
        
        for i in 0 ... Y_TERMS.count - 1
        {
            xy_term_sum = deg2rad(xy_term_summation(i, x: x))
            sum_psi += PE_TERMS[i][TERM_PSI_A] + jce*PE_TERMS[i][TERM_PSI_B]*sin(xy_term_sum)
            sum_epsilon += PE_TERMS[i][TERM_EPS_C] + jce*PE_TERMS[i][TERM_EPS_D]*cos(xy_term_sum)
        }
        
        return (sum_psi / 36000000.0, sum_epsilon / 36000000.0)
    }
    
    func ecliptic_mean_obliquity(jme : Double) -> Double
    {
        var u : Double = jme / 10.0
        
        return 84381.448 + u*(-4680.93 + u*(-1.55 + u*(1999.25 + u*(-51.38 + u*(-249.67 + u*( -39.05 + u*( 7.12 + u*( 27.87 + u*( 5.79 + u*2.45)))))))))
    }
    
    func ecliptic_true_obliquity(delta_epsilon : Double, epsilon0: Double) -> Double
    {
        return delta_epsilon + epsilon0/3600.0
    }
    
    func aberration_correction(r : Double) -> Double
    {
        return -20.4898 / (3600.0 * r)
    }
    
    func apparent_sun_longitude(theta : Double, delta_psi : Double, delta_tau : Double) -> Double
    {
        return theta + delta_psi + delta_tau
    }
    
    func greenwich_mean_sidereal_time (jd : Double, jc : Double) -> Double
    {
        return limit_degrees(280.46061837 + 360.98564736629 * (jd - 2451545.0) + jc*jc*(0.000387933 - jc/38710000.0))
    }
    
    func greenwich_sidereal_time (nu0 : Double, delta_psi : Double, epsilon : Double) -> Double
    {
        return nu0 + delta_psi*cos(deg2rad(epsilon))
    }
    
    func geocentric_right_ascension(lamda : Double, epsilon : Double, beta : Double) -> Double
    {
        var lamda_rad : Double = deg2rad(lamda)
        var epsilon_rad : Double = deg2rad(epsilon)
        return limit_degrees(rad2deg(atan2(sin(lamda_rad)*cos(epsilon_rad) - tan(deg2rad(beta))*sin(epsilon_rad), cos(lamda_rad))))
    }
    
    
    func geocentric_declination(beta : Double, epsilon : Double, lamda : Double) -> Double
    {
        var beta_rad : Double = deg2rad(beta)
        var epsilon_rad : Double = deg2rad(epsilon)
        return rad2deg(asin(sin(beta_rad)*cos(epsilon_rad) + cos(beta_rad)*sin(epsilon_rad)*sin(deg2rad(lamda))))
    }
    
    
    func observer_hour_angle(nu : Double, longitude : Double, alpha_deg : Double) -> Double
    {
        return limit_degrees(nu + longitude - alpha_deg)
    }
    
    
    func sun_equatorial_horizontal_parallax(r : Double) ->Double
    {
        return 8.794 / (3600.0 * r)
    }
    
    
    func right_ascension_parallax_and_topocentric_dec(latitude : Double, elevation : Double, xi : Double, h : Double, delta : Double) -> (delta_prime : Double, delta_alpha : Double)
    {
        var lat_rad : Double = deg2rad(latitude)
        var xi_rad : Double = deg2rad(xi)
        var h_rad : Double = deg2rad(h)
        var delta_rad : Double = deg2rad(delta)
        var u : Double = atan(0.99664719 * tan(lat_rad))
        var y : Double = 0.99664719 * sin(u) + elevation*sin(lat_rad)/6378140.0
        var x : Double = cos(u) + elevation*cos(lat_rad)/6378140.0
        var delta_alpha_rad : Double = atan2( Double(-x * sin(xi_rad) * sin(h_rad)), Double(cos(delta_rad) - x * sin(xi_rad) * cos(h_rad)))
        
        var delta_prime : Double = rad2deg(atan2(Double((sin(delta_rad) - y * sin(xi_rad)) * cos(delta_alpha_rad)), Double(cos(delta_rad) - x * sin(xi_rad) * cos(h_rad))))
        var delta_alpha : Double = rad2deg(delta_alpha_rad)
        
        return (delta_prime, delta_alpha)
    }
    
    
    func topocentric_right_ascension(alpha_deg : Double, delta_alpha : Double) -> Double
    {
        return alpha_deg + delta_alpha
    }
    
    
    func topocentric_local_hour_angle(h : Double, delta_alpha : Double) -> Double
    {
        return h - delta_alpha
    }
    
    func topocentric_elevation_angle(latitude : Double, delta_prime : Double, h_prime : Double) -> Double
    {
        var lat_rad : Double = deg2rad(latitude)
        var delta_prime_rad : Double = deg2rad(delta_prime)
        return rad2deg(asin(sin(lat_rad)*sin(delta_prime_rad) + cos(lat_rad)*cos(delta_prime_rad) * cos(deg2rad(h_prime))))
    }
    
    func atmospheric_refraction_correction(pressure : Double, temperature : Double, atmos_refract : Double, e0 : Double)  -> Double
    {
        var del_e : Double = 0
        if (e0 >= -1*(sun_radius + atmos_refract)){
            del_e = (pressure / 1010.0) * (283.0 / (273.0 + temperature)) * 1.02 / (60.0 * tan(deg2rad(e0 + 10.3/(e0 + 5.11))))
        }
        return del_e
    }
    
    
    func topocentric_elevation_angle_corrected(e0 : Double, delta_e : Double) -> Double
    {
        return e0 + delta_e
    }
    
    
    func topocentric_zenith_angle(e : Double) -> Double
    {
        return 90.0 - e
    }
    
    
    func topocentric_azimuth_angle_astro(h_prime : Double, latitude : Double, delta_prime : Double) -> Double
    {
        var h_prime_rad  : Double = deg2rad(h_prime)
        var lat_rad  : Double = deg2rad(latitude)
        return limit_degrees(rad2deg(atan2(sin(h_prime_rad), cos(h_prime_rad)*sin(lat_rad) - tan(deg2rad(delta_prime))*cos(lat_rad))))
    }
    
    func topocentric_azimuth_angle(azimuth_astro : Double) -> Double
    {
        return limit_degrees(azimuth_astro + 180.0)
    }
    
    
    func surface_incidence_angle(zenith : Double, azimuth_astro : Double, azm_rotation : Double, slope : Double) -> Double
    {
        var zenith_rad : Double = deg2rad(zenith)
        var slope_rad : Double = deg2rad(slope)
        return rad2deg(acos(cos(zenith_rad)*cos(slope_rad) + sin(slope_rad )*sin(zenith_rad) * cos(deg2rad(azimuth_astro - azm_rotation))))
    }
    
    func sun_mean_longitude(jme : Double) -> Double
    {
        return limit_degrees(280.4664567 + jme*(360007.6982779 + jme*(0.03032028 + jme*(1/49931.0 + jme*(-1/15300.0 + jme*(-1/2000000.0))))))
    }
    
    func eot(m : Double, alpha : Double, del_psi : Double, epsilon : Double) -> Double
    {
        return limit_minutes(4.0*(m - 0.0057183 - alpha + del_psi*cos(deg2rad(epsilon))))
    }
    
    func approx_sun_transit_time(alpha_zero : Double, longitude : Double, nu : Double) -> Double
    {
        return (alpha_zero - longitude - nu) / 360.0
    }
    
    func sun_hour_angle_at_rise_set(latitude : Double, delta_zero : Double, h0_prime : Double) -> Double
    {
        var h0 : Double = -99999
        var latitude_rad : Double = deg2rad(latitude)
        var delta_zero_rad : Double = deg2rad(delta_zero)
        var argument : Double = (sin(deg2rad(h0_prime)) - sin(latitude_rad)*sin(delta_zero_rad)) / (cos(latitude_rad)*cos(delta_zero_rad))
        
        if (abs(argument) <= 1)
        {
            h0 = limit_degrees180(rad2deg(acos(argument)))
        }
        
        return h0
    }
    
    func approx_sun_rise_and_set(sun_transit : Double , h0 : Double) -> (sunrise : Double, sunset : Double, transit : Double)
    {
        var h0_dfrac : Double = h0/360.0
        var sunrise : Double = limit_zero2one(sun_transit - h0_dfrac);
        var sunset : Double = limit_zero2one(sun_transit + h0_dfrac);
        var transit : Double = limit_zero2one(sun_transit)
        
        return (sunrise, sunset, transit)
    }
    
    
    func rts_alpha_delta_prime(ad : [Double], n : Double) -> Double
    {
        var a  : Double = ad[JD_ZERO] - ad[JD_MINUS]
        var b : Double = ad[JD_PLUS] - ad[JD_ZERO]
        
        if abs(a) >= 2.0 { a = limit_zero2one(a) }
        if abs(b) >= 2.0 { b = limit_zero2one(b) }
        
        return ad[1] + n * (a + b + (b-a)*n)/2.0;
    }
    
    func rts_sun_altitude(latitude : Double, delta_prime : Double, h_prime : Double) -> Double
    {
        var latitude_rad : Double = deg2rad(latitude)
        var delta_prime_rad : Double = deg2rad(delta_prime)
        return rad2deg(asin(sin(latitude_rad)*sin(delta_prime_rad) + cos(latitude_rad)*cos(delta_prime_rad)*cos(deg2rad(h_prime))))
    }
    
    func sun_rise_and_set(m_rts : [Double], h_rts : [Double], delta_prime : [Double], latitude : Double, h_prime : [Double], h0_prime : Double, sun : Int) -> Double
    {
        return m_rts[sun] + (h_rts[sun] - h0_prime) / (360.0*cos(deg2rad(delta_prime[sun]))*cos(deg2rad(latitude))*sin(deg2rad(h_prime[sun])))
    }
    
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Calculate required SPA parameters to get the right ascension (alpha) and declination (delta)
    // Note: JD must be already calculated and in structure
    ////////////////////////////////////////////////////////////////////////////////////////////////
    func calculate_geocentric_sun_right_ascension_and_declination()
    {
        var x : [Double] = [Double](count: TERM_X_COUNT,repeatedValue: 0.0)
        jc = julian_century(jd)
        jde = julian_ephemeris_day(jd, delta_t: delta_t)
        jce = julian_ephemeris_century(jde)
        jme = julian_ephemeris_millennium(jce)
        l = earth_heliocentric_longitude(jme)
        b = earth_heliocentric_latitude(jme)
        r = earth_radius_vector(jme)
        theta = geocentric_longitude(l)
        beta = geocentric_latitude(b)
        
        x0 = mean_elongation_moon_sun(jce)
        x[TERM_X0] = x0
        
        x1 = mean_anomaly_sun(jce)
        x[TERM_X1] = x1
        
        x2 = mean_anomaly_moon(jce)
        x[TERM_X2] = x2
        
        x3 = argument_latitude_moon(jce)
        x[TERM_X3] = x3
            
        x4 = ascending_longitude_moon(jce)
        x[TERM_X4] = x4
        
        var result : (del_psi : Double, del_epsilon : Double) = nutation_longitude_and_obliquity(jce, x: x)
        del_psi = result.del_psi
        del_epsilon = result.del_epsilon
            
        epsilon0 = ecliptic_mean_obliquity(jme)
        epsilon = ecliptic_true_obliquity(del_epsilon, epsilon0: epsilon0)
        del_tau = aberration_correction(r)
        lamda = apparent_sun_longitude(theta, delta_psi: del_psi, delta_tau: del_tau)
        nu0 = greenwich_mean_sidereal_time (jd, jc: jc)
        nu = greenwich_sidereal_time (nu0, delta_psi: del_psi, epsilon: epsilon)
        alpha = geocentric_right_ascension(lamda, epsilon: epsilon, beta: beta)
        delta = geocentric_declination(beta, epsilon: epsilon, lamda: lamda)
    }
    
    
    ////////////////////////////////////////////////////////////////////////
    // Calculate Equation of Time (EOT) and Sun Rise, Transit, & Set (RTS)
    ////////////////////////////////////////////////////////////////////////
    func calculate_eot_and_sun_rise_transit_set()
    {
        var m : Double
        var h0 : Double
        var n : Double
        var nu_local : Double //Used to store a local copy of nu after the first calculate_geocentric_sun_right_ascension_and_declination
        var alpha : [Double] = [Double](count : JD_COUNT,repeatedValue : 0.0)
        var delta : [Double] = [Double](count : JD_COUNT,repeatedValue : 0.0)
        
        var m_rts : [Double] = [Double](count : SUN_COUNT,repeatedValue : 0.0)
        var nu_rts : [Double] = [Double](count : SUN_COUNT,repeatedValue : 0.0)
        var h_rts : [Double] = [Double](count : SUN_COUNT,repeatedValue : 0.0)
        var alpha_prime : [Double] = [Double](count : SUN_COUNT,repeatedValue : 0.0)
        var delta_prime : [Double] = [Double](count : SUN_COUNT,repeatedValue : 0.0)
        var h_prime : [Double] = [Double](count : SUN_COUNT,repeatedValue : 0.0)
        var h0_prime : Double = -1*(sun_radius + atmos_refract)

        var i : Int;

        m = sun_mean_longitude(jme);
        eot = eot(m, alpha: self.alpha, del_psi: del_psi, epsilon: epsilon)
        
        //hour = 0
        //minute = 0
        //second = 0.0
        //delta_ut1 = 0.0
        
        var jd_prev = jd
        jd = julian_day (year, month: month, day: day, hour: 0, minute: 0, second: 0, dut1: 0, tz: 0) // Calculate the julian day at midnight in Grenwich
        calculate_geocentric_sun_right_ascension_and_declination()
        nu_local = nu
        
        delta_t = 0
        jd--
        
        for (i = 0; i < JD_COUNT; i++)
        {
            calculate_geocentric_sun_right_ascension_and_declination()
            alpha[i] = self.alpha
            delta[i] = self.delta
            jd++
        }
        
        jd = jd_prev
        
        m_rts[SUN_TRANSIT] = approx_sun_transit_time(alpha[JD_ZERO], longitude: longitude, nu: nu_local)
        h0 = sun_hour_angle_at_rise_set(latitude, delta_zero: delta[JD_ZERO], h0_prime: h0_prime);
        if (h0 >= 0) {
            var result : (sunrise : Double, sunset : Double, transit : Double) = approx_sun_rise_and_set(m_rts[SUN_TRANSIT], h0: h0)
            
            m_rts[SUN_RISE] = result.sunrise
            m_rts[SUN_TRANSIT] = result.transit
            m_rts[SUN_SET] = result.sunset
            
            for (i = 0; i < SUN_COUNT; i++)
            {
                nu_rts[i] = nu_local + 360.985647*m_rts[i]
                n = m_rts[i] + delta_t/86400.0
                alpha_prime[i] = rts_alpha_delta_prime(alpha, n: n)
                delta_prime[i] = rts_alpha_delta_prime(delta, n: n);
                h_prime[i] = limit_degrees180pm(nu_rts[i] + longitude - alpha_prime[i]);
                h_rts[i] = rts_sun_altitude(latitude, delta_prime: delta_prime[i], h_prime: h_prime[i]);
            }
            srha = h_prime[SUN_RISE];
            ssha = h_prime[SUN_SET];
            sta = h_rts[SUN_TRANSIT];
            suntransit = dayfrac_to_local_hr(m_rts[SUN_TRANSIT] - h_prime[SUN_TRANSIT] / 360.0, timezone: timezone);
            sunrise = dayfrac_to_local_hr(sun_rise_and_set(m_rts, h_rts: h_rts, delta_prime: delta_prime, latitude: latitude, h_prime: h_prime, h0_prime: h0_prime, sun: SUN_RISE), timezone: timezone);
            sunset = dayfrac_to_local_hr(sun_rise_and_set(m_rts, h_rts: h_rts, delta_prime: delta_prime, latitude: latitude, h_prime: h_prime, h0_prime: h0_prime, sun: SUN_SET), timezone: timezone);
        }
        else
        {
            srha = -99999
            ssha = -99999
            sta = -99999
            suntransit = -99999
            sunrise = -99999
            sunset = -99999
        }
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////
    // Calculate all SPA parameters and put into structure
    // Note: All inputs values (listed in header file) must already be in structure
    ///////////////////////////////////////////////////////////////////////////////////////////
    func spa_calculate() -> Int
    {
        var result : Int = validate_inputs()
        if (result == 0)
        {
            jd = julian_day (year, month: month, day: day, hour: hour, minute: minute, second: second, dut1: delta_ut1, tz: timezone)
            calculate_geocentric_sun_right_ascension_and_declination()
            h = observer_hour_angle(nu, longitude: longitude, alpha_deg: alpha)
            xi = sun_equatorial_horizontal_parallax(r)
            var rapt : (delta_prime : Double, delta_alpha : Double) = right_ascension_parallax_and_topocentric_dec(latitude, elevation: elevation, xi: xi, h: h, delta: delta)
            del_alpha = rapt.delta_alpha
            delta_prime = rapt.delta_prime
            
            alpha_prime = topocentric_right_ascension(alpha, delta_alpha: del_alpha)
            
            h_prime = topocentric_local_hour_angle(h, delta_alpha: del_alpha)
            e0 = topocentric_elevation_angle(latitude, delta_prime: delta_prime, h_prime: h_prime)
            del_e = atmospheric_refraction_correction(pressure, temperature: temperature, atmos_refract: atmos_refract, e0: e0)
            e = topocentric_elevation_angle_corrected(e0, delta_e: del_e)
            zenith = topocentric_zenith_angle(e)
            azimuth_astro = topocentric_azimuth_angle_astro(h_prime, latitude: latitude, delta_prime: delta_prime)
            azimuth = topocentric_azimuth_angle(azimuth_astro)
            incidence = surface_incidence_angle(zenith, azimuth_astro: azimuth_astro, azm_rotation: azm_rotation, slope: slope)
            calculate_eot_and_sun_rise_transit_set()
        }
        return result
    }
    
    func get_sunrise_tuple() -> (hour : Int, minute: Int, second : Int)
    {
        var hour : Int = Int(sunrise)
        var min : Double = (60.0 * (sunrise - floor(sunrise)))
        var sec : Double = (60.0 * (min - floor(min)))
        
        return (hour, Int(min), Int(sec))
    }
    
    func get_sunset_tuple() -> (hour : Int, minute: Int, second : Int)
    {
        var hour : Int = Int(sunset)
        var min : Double = (60.0 * (sunset - floor(sunset)))
        var sec : Double = (60.0 * (min - floor(min)))
        
        return (hour, Int(min), Int(sec))
    }
    
    func get_suntransit_tuple() -> (hour : Int, minute: Int, second : Int)
    {
        var hour : Int = Int(suntransit)
        var min : Double = (60.0 * (suntransit - floor(suntransit)))
        var sec : Double = (60.0 * (min - floor(min)))
        
        return (hour, Int(min), Int(sec))
    }
    
    //This class method will pop up a UIAlertView with the next Rise, Transit, and Set for the specified location & altitude
    class func showRTSAlertView(_name : String, _latitude : Double, _longitude : Double, _altitude : Double)
    {
        let scalc = SolarCalculator()
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay | NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitMinute | NSCalendarUnit.CalendarUnitSecond, fromDate: date)
        
        //Todays Rise & Set
        scalc.timezone = Double(NSTimeZone.systemTimeZone().secondsFromGMT)/3600.0
        let tzstring = NSTimeZone.systemTimeZone().abbreviation
        scalc.year = components.year
        scalc.month = components.month
        scalc.day = components.day
        
        scalc.longitude = _longitude
        scalc.latitude = _latitude
        scalc.elevation = _altitude
        
        
        scalc.spa_calculate()
        let td_rise = scalc.get_sunrise_tuple()
        let td_set = scalc.get_sunset_tuple()
        let td_transit = scalc.get_suntransit_tuple()
        
        let td_rise_string = NSString(format: "%04d-%02d-%02d %02d:%02d:%02d \(tzstring!)", scalc.year, scalc.month, scalc.day, td_rise.hour,td_rise.minute,td_rise.second)
        let td_transit_string = NSString(format: "%04d-%02d-%02d %02d:%02d:%02d \(tzstring!)", scalc.year, scalc.month, scalc.day,  td_transit.hour,td_transit.minute,td_transit.second)
        let td_set_string = NSString(format: "%04d-%02d-%02d %02d:%02d:%02d \(tzstring!)",  scalc.year, scalc.month, scalc.day, td_set.hour,td_set.minute,td_set.second)
        
        //Tomorrows Rise & Set
        scalc.day += 1
        
        scalc.spa_calculate()
        let tm_rise = scalc.get_sunrise_tuple()
        let tm_set = scalc.get_sunset_tuple()
        let tm_transit = scalc.get_suntransit_tuple()
        
        let tm_rise_string = NSString(format: "%04d-%02d-%02d %02d:%02d:%02d \(tzstring!)",  scalc.year, scalc.month, scalc.day, tm_rise.hour,tm_rise.minute,tm_rise.second)
        let tm_transit_string = NSString(format: "%04d-%02d-%02d %02d:%02d:%02d \(tzstring!)", scalc.year, scalc.month, scalc.day,  tm_transit.hour,tm_transit.minute,tm_transit.second)
        let tm_set_string = NSString(format: "%04d-%02d-%02d %02d:%02d:%02d \(tzstring!)", scalc.year, scalc.month, scalc.day,  tm_set.hour,tm_set.minute,tm_set.second)
        
        var rise_string = ""
        var set_string = ""
        var transit_string = ""
        
        
        let rts_components = NSDateComponents()
        rts_components.year = scalc.year
        rts_components.month = scalc.month
        rts_components.day = scalc.day-1
        rts_components.hour = td_rise.hour
        rts_components.minute = td_rise.minute
        rts_components.second = td_rise.second
        let today_rise = calendar.dateFromComponents(rts_components)
        
        rts_components.hour = td_transit.hour
        rts_components.minute = td_transit.minute
        rts_components.second = td_transit.second
        let today_transit = calendar.dateFromComponents(rts_components)
        
        rts_components.hour = td_set.hour
        rts_components.minute = td_set.minute
        rts_components.second = td_set.second
        let today_set = calendar.dateFromComponents(rts_components)
        
        if today_rise?.timeIntervalSinceNow <= 0 { rise_string = tm_rise_string as String}
        else { rise_string = td_rise_string as String}
        
        if today_set?.timeIntervalSinceNow <= 0 {  set_string = tm_set_string as String}
        else { set_string = td_set_string as String}
        
        if today_transit?.timeIntervalSinceNow <= 0 {  transit_string = tm_transit_string as String}
        else { transit_string = td_transit_string as String}
        
        
        let alert = UIAlertView(title: "Solar Times for \(_name)", message: "Sunrise: \(rise_string)\nTransit: \(transit_string)\nSunset: \(set_string)", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "OK")
        alert.show()
    }
}