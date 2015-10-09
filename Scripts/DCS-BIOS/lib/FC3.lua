local defineString = BIOS.util.defineString
local defineIntegerFromGetter = BIOS.util.defineIntegerFromGetter

local _altitude = " ALT"
local _altitudeR = "RALT"
local _verticalVelocity = " VVI"
local _indicatedAirspeed = " IAS"
local _trueAirspeed = " TAS"
local _machNumber = "MACH"
local _fuel = "FUEL"
local _pilot = ""

BIOS.protocol.beginModule("FC3", 0x2600)
BIOS.protocol.setExportModuleAircrafts(BIOS.FLAMING_CLIFFS_AIRCRAFT)

--[[
LoGetAngleOfAttack() -- (args - 0, results - 1 (rad))
LoGetAccelerationUnits() -- (args - 0, results - table {x = Nx,y = NY,z = NZ} 1 (G))
LoGetADIPitchBankYaw()   -- (args - 0, results - 3 (rad))
LoGetMagneticYaw()       -- (args - 0, results - 1 (rad)
LoGetGlideDeviation()    -- (args - 0,results - 1)( -1 < result < 1)
LoGetSideDeviation()     -- (args - 0,results - 1)( -1 < result < 1)
LoGetSlipBallPosition()  -- (args - 0,results - 1)( -1 < result < 1)
LoGetBasicAtmospherePressure() -- (args - 0,results - 1) (mm hg)
]]--

moduleBeingDefined.exportHooks[#moduleBeingDefined.exportHooks+1] = function()
  local pilot = LoGetPilotName()                -- (args - 0, results - 1 (text string))
  local alt = LoGetAltitudeAboveSeaLevel()      -- (args - 0, results - 1 (meters))
  local altR = LoGetAltitudeAboveGroundLevel()  -- (args - 0, results - 1 (meters))
  local vvi = LoGetVerticalVelocity()           -- (args - 0, results - 1( m/s))
  local ias = LoGetIndicatedAirSpeed()          -- (args - 0, results - 1 (m/s))
  local tas = LoGetTrueAirSpeed()               -- (args - 0, results - 1 (m/s))
  local mach = LoGetMachNumber()                -- (args - 0, results - 1)
  local eng = LoGetEngineInfo()
  local fuel = eng.fuel_internal + eng.fuel_external

  if ( mach < 0.5 ) then mach = 0.5 end

  local self = LoGetSelfData()
  local plane = self.Name

  _pilot = string.format("%16s", pilot)
  -- US planes (knots and feets)
  if plane == "A-10A" or plane == "F-15C" or plane == "MiG-29G" then
    ias = ias * 1.94384449  -- knots
    tas = tas * 1.94384449  -- knots
    alt = alt * 3.2808399   -- feets
    altR = altR * 3.2808399 -- feets
    vvi = vvi * 196.850394  -- feets per minute
    fuel = fuel * 2.20462262 -- pounds
    
    _indicatedAirspeed = string.format("%4d", ias)
    -- altitude over 10000 feets is shown in hundreds
    if alt < 10000 then _altitude = string.format("%4d", alt)
    else _altitude = string.format("%4d", alt / 100) end
    -- vertical velocity is cut to 6000 fpm as on instruments
    if vvi > 6000 then vvi = 6000
    elseif vvi < -6000 then vvi = -6000 end
    _verticalVelocity = string.format(" %4.1f", vvi/1000)
   
    -- only A-10A has radar altimeter
    if plane == "A-10A" or plane == "MiG-29G" then
      -- radar altimeter is working to 5000 feets then baro
      if altR < 5000 then _altitudeR = string.format("%4d", altR)
      else _altitudeR = _altitude end
    elseif plane == "F-15C" then
      -- F-15C has TAS,GS and mach number (I don't want to calculete GS right now)
      _trueAirspeed = string.format("%4d", tas)
      _machNumber = string.format("%.2f", mach)
    end
    if plane == "MiG-29G" then
      _machNumber = string.format("%.2f", mach)
    end
    
    -- we want fuel in hundreds
    fuel = fuel / 100
    _fuel = string.format("%3.1f", math.floor(fuel));
  -- RU planes
  elseif plane == "MiG-29A" or plane == "MiG-29S" or
         plane == "Su-25" or plane == "Su-25T" or
         plane == "Su-27" or plane == "Su-33" then
    ias = ias * 3.6 -- km/h
    tas = tas * 3.6

    -- tens like on hud
    ias = math.floor(ias / 10) * 10
    tas = math.floor(tas / 10) * 10
    _indicatedAirspeed = string.format("%4d", ias)
    
    if plane ~= "Su-27" or plane ~= "MiG-29A" or plane ~= "MiG-29S" then
      -- tas from 400 like on instrument
      if( tas < 400 ) then tas = 400 end
      _trueAirspeed = string.format("%4d", tas)
    elseif plane ~= "Su-25T" then
      -- Su-25T does not have mach meter
      _machNumber = string.format("%.2f", mach)
    end

    -- tens like on hud
    alt = math.floor(alt / 10) * 10
    _altitude = string.format("%4d", alt)
    if altR < 1500 then _altitudeR = string.format("%4d", altR)
    else _altitudeR = _altitude end
    _verticalVelocity = string.format("%4d", vvi)
    _fuel = string.format("%3.1f", fuel/100)
  end
end

defineString("_PILOTNAME", function() return _pilot .. string.char(0) end, 16, "String", "Pilot Name")
defineString("_ALTITUDE", function() return _altitude .. string.char(0) end, 4, "String", "Altitude above Sea Level")
defineString("_ALTITUDE_RADAR", function() return _altitudeR .. string.char(0) end, 4, "String", "Altitude above Ground")
defineString("_VERTICAL_VELOCITY", function() return _verticalVelocity .. string.char(0) end, 4, "String", "Vertical Velocity")
defineString("_INDICATED_AIRSPEED", function() return _indicatedAirspeed .. string.char(0) end, 4, "String", "Indicated Airspeed")
defineString("_TRUE_AIRSPEED", function() return _trueAirspeed .. string.char(0) end, 4, "String", "True Airspeed")
defineString("_MACHNUMBER", function() return _machNumber .. string.char(0) end, 4, "String", "Mach Number")
defineString("_FUELALL", function() return _fuel .. string.char(0) end, 4, "String", "Fuel Remaining")

BIOS.protocol.endModule()