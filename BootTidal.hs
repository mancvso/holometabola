:set -XOverloadedStrings
:set prompt ""

import Sound.Tidal.Context

import System.IO (hSetEncoding, stdout, utf8)
hSetEncoding stdout utf8

:{
let dirt1 = superdirtTarget {oLatency = 0.05, oAddress = "127.0.0.1", oPort = 57131}
    dirt2 = superdirtTarget {oLatency = 0.05, oAddress = "127.0.0.1", oPort = 57132}
    dirt3 = superdirtTarget {oLatency = 0.05, oAddress = "127.0.0.1", oPort = 57133}
:}

:{
let shape1 = OSC "/dirt/play" $ Named {requiredArgs = ["s", "dirt1"]}
    shape2 = OSC "/dirt/play" $ Named {requiredArgs = ["s", "dirt2"]}
    shape3 = OSC "/dirt/play" $ Named {requiredArgs = ["s", "dirt3"]}
:}

let oscmap = [(dirt1, [shape1]), (dirt2, [shape2]), (dirt3, [shape3])]

tidal <- startStream (defaultConfig {cVerbose = True, cFrameTimespan = 1/20, cCtrlPort = 57141}) oscmap

:{
let only = (hush >>)
    hush = streamHush tidal
    p = streamReplace tidal
    b1 = p "b1" . (|< (orbit 0 |< pI "dirt1" 0))
    b2 = p "b2" . (|< (orbit 1 |< pI "dirt1" 0))
    b3 = p "b3" . (|< (orbit 2 |< pI "dirt1" 0))
    b4 = p "b4" . (|< (orbit 3 |< pI "dirt1" 0))
    b5 = p "b5" . (|< (orbit 4 |< pI "dirt1" 0))
    b6 = p "b6" . (|< (orbit 5 |< pI "dirt1" 0))
    -- etc
    l1 = p "l1" . (|< (orbit 0 |< pI "dirt2" 0))
    l2 = p "l2" . (|< (orbit 1 |< pI "dirt2" 0))
    l3 = p "l3" . (|< (orbit 2 |< pI "dirt2" 0))
    l4 = p "l4" . (|< (orbit 3 |< pI "dirt2" 0))
    l5 = p "l5" . (|< (orbit 4 |< pI "dirt2" 0))
    l6 = p "l6" . (|< (orbit 5 |< pI "dirt2" 0))
    -- etc
    a1 = p "a1" . (|< (orbit 0 |< pI "dirt3" 0))
    a2 = p "a2" . (|< (orbit 1 |< pI "dirt3" 0))
    a3 = p "a3" . (|< (orbit 2 |< pI "dirt3" 0))
    a4 = p "a4" . (|< (orbit 3 |< pI "dirt3" 0))
    a5 = p "a5" . (|< (orbit 4 |< pI "dirt3" 0))
    a6 = p "a6" . (|< (orbit 5 |< pI "dirt3" 0))
    -- etc
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
