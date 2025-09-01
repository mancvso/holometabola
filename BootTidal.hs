:set -XOverloadedStrings
:set prompt ""

import Sound.Tidal.Context

import System.IO (hSetEncoding, stdout, utf8)
hSetEncoding stdout utf8

:{
let dirt1 = superdirtTarget { oLatency = 0.05, oAddress = "127.0.0.1", oPort = 57122 }
:}

:{
let shape1 = OSC "/dirt/play" $ Named { requiredArgs = ["s", "dirt1"] }
:}

let oscmap = [ (dirt1, [shape1] ) ]

tidal <- startStream ( defaultConfig { cVerbose = True, cFrameTimespan = 1/20 } ) oscmap

:{
let only = (hush >>)
    hush = streamHush tidal
    list = streamList tidal
    mute = streamMute tidal
    unmute = streamUnmute tidal
    unmuteAll = streamUnmuteAll tidal
    unsoloAll = streamUnsoloAll tidal
    solo = streamSolo tidal
    unsolo = streamUnsolo tidal
    once = streamOnce tidal
    first = streamFirst tidal
    asap = once
    nudgeAll = streamNudgeAll tidal
    all = streamAll tidal
    resetCycles = streamResetCycles tidal
    setCycle = streamSetCycle tidal
    setcps = asap . cps
    p = streamReplace tidal
    b1 = p "b1" . (|< (orbit 0 |< pI "dirt1" 0))
    b2 = p "b2" . (|< (orbit 1 |< pI "dirt1" 0))
    b3 = p "b3" . (|< (orbit 2 |< pI "dirt1" 0))
    b4 = p "b4" . (|< (orbit 3 |< pI "dirt1" 0))
    b5 = p "b5" . (|< (orbit 4 |< pI "dirt1" 0))
    b6 = p "b6" . (|< (orbit 5 |< pI "dirt1" 0))
    -- etc
    l1 = p "l1" . (|< (orbit 6 |< pI "dirt1" 0))
    l2 = p "l2" . (|< (orbit 7 |< pI "dirt1" 0))
    l3 = p "l3" . (|< (orbit 8 |< pI "dirt1" 0))
    l4 = p "l4" . (|< (orbit 9 |< pI "dirt1" 0))
    l5 = p "l5" . (|< (orbit 10 |< pI "dirt1" 0))
    l6 = p "l6" . (|< (orbit 11 |< pI "dirt1" 0))
    -- etc
    a1 = p "a1" . (|< (orbit 12 |< pI "dirt1" 0))
    a2 = p "a2" . (|< (orbit 13 |< pI "dirt1" 0))
    a3 = p "a3" . (|< (orbit 14 |< pI "dirt1" 0))
    a4 = p "a4" . (|< (orbit 15 |< pI "dirt1" 0))
    a5 = p "a5" . (|< (orbit 16 |< pI "dirt1" 0))
    a6 = p "a6" . (|< (orbit 17 |< pI "dirt1" 0))
    -- etc
:}

:{
let soloBeats = unsoloAll >> solo b1 >> solo b2 >> solo b3 >> solo b4 >> solo b5 >> solo b6
:}

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
