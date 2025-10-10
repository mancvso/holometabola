:set -XOverloadedStrings
:set prompt ""
import Sound.Tidal.Context
import System.IO (hSetEncoding, stdout, utf8)
hSetEncoding stdout utf8

-- Targets (tus puertos 57131–57133)
:{
let dirt1 = superdirtTarget {oLatency = 0.05, oAddress = "127.0.0.1", oPort = 57131}
    dirt2 = superdirtTarget {oLatency = 0.05, oAddress = "127.0.0.1", oPort = 57132}
    dirt3 = superdirtTarget {oLatency = 0.05, oAddress = "127.0.0.1", oPort = 57133}
:}

-- Shapes que exigen la “marca” dirtN para rutear al target correspondiente
:{
let shape1 = OSC "/dirt/play" $ Named {requiredArgs = ["s","dirt1"]}
    shape2 = OSC "/dirt/play" $ Named {requiredArgs = ["s","dirt2"]}
    shape3 = OSC "/dirt/play" $ Named {requiredArgs = ["s","dirt3"]}
:}

-- Mapa OSC
let oscmap = [(dirt1, [shape1]), (dirt2, [shape2]), (dirt3, [shape3])]

-- Stream principal (usa un ctrl port que no choque con SC)
tidal <- startStream (defaultConfig {cVerbose = True, cFrameTimespan = 1/20, cCtrlPort = 57141}) oscmap

-- Definimos los parámetros de control requeridos por los shapes
-- (ojo: el nombre del parámetro debe ser EXACTAMENTE "dirt1|2|3")
let dirt1p = pI "dirt1"
    dirt2p = pI "dirt2"
    dirt3p = pI "dirt3"

-- Atajos útiles
:{
let hush         = streamHush tidal
    only         = (hush >>)
    p            = streamReplace tidal
    once         = streamOnce tidal
    asap         = streamOnce tidal
    nudgeAll     = streamNudgeAll tidal
    all          = streamAll tidal
    resetCycles  = streamResetCycles tidal
    setcps       = asap . cps
    xfade i      = transition tidal True (Sound.Tidal.Transition.xfadeIn 4) i
:}

-- Ruteo por grupos: BEATS (dirt1), LEADS (dirt2), AMBS (dirt3)
-- Cada slot fija orbit + marca dirtNp=1 para que sólo dispare el shape de su target
:{
-- BEATS @ 57131
let b1 = p 1  . (# orbit 0) . (# dirt1p 1)
    b2 = p 2  . (# orbit 1) . (# dirt1p 1)
    b3 = p 3  . (# orbit 2) . (# dirt1p 1)
    b4 = p 4  . (# orbit 3) . (# dirt1p 1)
    b5 = p 5  . (# orbit 4) . (# dirt1p 1)
    b6 = p 6  . (# orbit 5) . (# dirt1p 1)

-- LEADS @ 57132
    l1 = p 7  . (# orbit 0) . (# dirt2p 1)
    l2 = p 8  . (# orbit 1) . (# dirt2p 1)
    l3 = p 9  . (# orbit 2) . (# dirt2p 1)
    l4 = p 10 . (# orbit 3) . (# dirt2p 1)
    l5 = p 11 . (# orbit 4) . (# dirt2p 1)
    l6 = p 12 . (# orbit 5) . (# dirt2p 1)

-- AMBS @ 57133
    a1 = p 13 . (# orbit 0) . (# dirt3p 1)
    a2 = p 14 . (# orbit 1) . (# dirt3p 1)
    a3 = p 15 . (# orbit 2) . (# dirt3p 1)
    a4 = p 16 . (# orbit 3) . (# dirt3p 1)
    a5 = p 17 . (# orbit 4) . (# dirt3p 1)
    a6 = p 18 . (# orbit 5) . (# dirt3p 1)
:}

-- Extras opcionales (get/set)
:{
let getState = streamGet tidal
    setI = streamSetI tidal
    setF = streamSetF tidal
    setS = streamSetS tidal
    setR = streamSetR tidal
    setB = streamSetB tidal
:}

:set prompt "~/endo> "
:set prompt-cont ""
default (Pattern String, Integer, Double)
