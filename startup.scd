/*
This is an ansible generated startup file.
Modifications will be overwritten on next run,
but a backup copy will exist in the same dir as this file
*/
(
//Server.killAll;
//Server.supernova;
s.reboot {
	// server options are only updated on reboot
	// configure the sound server: here you could add hardware specific options
	// see http://doc.sccode.org/Classes/ServerOptions.html
	s.options.numBuffers = 2048 * 256; // increase this if you need to load more samples
	s.options.memSize = 8192 * 64; // increase this if you get "alloc failed" messages
	s.options.numWireBufs = 256; // increase this if you get "exceeded number of interconnect buffers" messages
	s.options.maxNodes = 1024*512; // increase this if you are getting drop outs and the message "too many nodes"
	s.options.numOutputBusChannels = 36; // set this to your hardware output channel size, if necessary
	s.options.numInputBusChannels = 0; // set this to your hardware input channel size, if necessary
    s.options.maxLogins = 3; // optional, required to enable feedforward VU meter
	// boot the server and start SuperDirt
	s.waitForBoot {
		~dirt = SuperDirt(2, s); // two output channels, increase if you want to pan across more channels
        //loadRelative("ansible_tidal_synthdefs/*.scd");
		~dirt.doNotReadYet = false; //lazy sample loading
		~dirt.loadSoundFiles;   // load samples (path containing a wildcard can be passed in)
		// for example: ~dirt.loadSoundFiles("/Users/myUserName/Dirt/samples/*");
    		~dirt.loadSoundFiles("/home/endo/Studio/Sampling/tidal-samples/*");


		~dirt.start(57122, [ 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20,  22, 24, 26, 28, 30, 32, 34 ] );   // start listening on port 57120, create 18 stereo busses

        // optional, enable feedforward vu meter
        //~dirt.startSendRMS;

        // midi
        (
            MIDIClient.init;

            ~midithroughport0 = MIDIOut.newByName("Midi Through", "Midi Through Port-0");
            ~midithroughport0.latency = 0;
            ~dirt.soundLibrary.addMIDI(\midi0, ~midithroughport0);

        );

		// optional, needed for convenient access from sclang:
		(
			~b1 = ~dirt.orbits[0];
			~b2 = ~dirt.orbits[1];
			~b3 = ~dirt.orbits[2];
			~b4 = ~dirt.orbits[3];
			~b5 = ~dirt.orbits[4];
			~b6 = ~dirt.orbits[5];
			~l1 = ~dirt.orbits[6];
			~l2 = ~dirt.orbits[7];
			~l3 = ~dirt.orbits[8];
			~l4 = ~dirt.orbits[9];
			~l5 = ~dirt.orbits[10];
			~l6 = ~dirt.orbits[11];
			~a1 = ~dirt.orbits[12];
			~a2 = ~dirt.orbits[13];
			~a3 = ~dirt.orbits[14];
			~a4 = ~dirt.orbits[15];
			~a5 = ~dirt.orbits[16];
			~a6 = ~dirt.orbits[17];
		);

        // define global effects for mutable instruments effects
        /*~dirt.orbits.do { |x|
            var clouds = GlobalDirtEffect(\global_mi_clouds, [\cloudspitch, \cloudspos, \cloudssize, \cloudsdens, \cloudstex, \cloudswet, \cloudsgain, \cloudsspread, \cloudsrvb, \cloudsfb, \cloudsfreeze, \cloudsmode, \cloudslofi]);
            var verb = GlobalDirtEffect(\global_mi_verb, [\verbwet, \verbtime, \verbdamp, \verbhp, \verbfreeze, \verbdiff, \verbgain]);
            x.globalEffects = x.globalEffects
              .addFirst(clouds)
              .addFirst(verb);
            x.initNodeTree;
        };*/

		~busses = ~dirt.orbits.do { |each|
				var bus = Bus.audio(each.server, each.numChannels);
			each.outBus( bus );
				bus
		};

			Ndef(\x, {
				var level = 2;
				var distortion = 10;
				var reverbFeedback = 0.1;
				~allBuses = ~busses.collect { |each| InBus.ar(each.outBus, each.numChannels) };
				~mix = ~allBuses.collect { |x|
					var d = { 0.01.rand } ! x.size;
					DelayN.ar(x, d, d)
				};
				~loop = LocalIn.ar(~dirt.numChannels);
				5.do { ~loop = AllpassL.ar(~loop, 0.15, { ExpRand(0.03, 0.15) } ! 2, 3) };
				~mix = ~loop * reverbFeedback + ~mix;
				~mix = LeakDC.ar(~mix);
				LocalOut.ar(~mix);
				~mix = Compander.ar(~mix,~mix, 0.3, slopeBelow:1, slopeAbove:0.5, clampTime:0.01, relaxTime:0.01);
				~mix = (~mix * distortion).tanh * (level / distortion.max(1));
				~mix
			}).play;



	};

	s.latency = 0.5; // increase this if you get "late" messages

	//s.sync; // optionally: wait for samples to be read
     // s.sync;
	};





	);


/*
SuperCollider CPU Monitoring for TidalCycles Orbits
Monitors individual orbit CPU usage via voice counting
*/

(
// CPU monitoring state with per-orbit voice tracking
~cpuMonitor = (
    baseline: nil,
    orbitVoices: Array.fill(18, { 0 }), // Track active voices per orbit
    orbitCPUHistory: Array.fill(18, { List.new }), // CPU history per orbit
    monitorTask: nil,
    sampleInterval: 0.5,

    // Initialize baseline CPU measurement
    setBaseline: {
        ~cpuMonitor.baseline = s.avgCPU;
        "CPU baseline set: % %%".format(~cpuMonitor.baseline.round(0.01)).postln;
    },

    // Update voice count for an orbit (called on synth creation)
    updateOrbitVoices: {
        ~dirt.orbits.do { |orbit, i|
            var nodeCount = 0;
            var currentVoices;

            // Get current voice count safely
            currentVoices = ~cpuMonitor.orbitVoices.at(i);

            // Approximate voice count using exponential decay model
            // This is a heuristic since we can't get real-time node counts synchronously
            nodeCount = (currentVoices * 0.85).asInteger;

            ~cpuMonitor.orbitVoices.put(i, nodeCount);
        };
    },

    // Calculate estimated CPU per orbit based on voice distribution
    getOrbitCPUEstimate: { |orbitIndex|
        var totalVoices = ~cpuMonitor.orbitVoices.sum;
        var orbitVoices = ~cpuMonitor.orbitVoices.at(orbitIndex);
        var totalCPU = s.avgCPU;
        var estimatedCPU = 0;

        if(totalVoices > 0, {
            // Proportional CPU allocation based on voice count
            estimatedCPU = (orbitVoices / totalVoices) * totalCPU;
        });

        estimatedCPU
    },

    // Monitor all orbits and print statistics
    startMonitoring: { |interval|
        interval = interval ?? ~cpuMonitor.sampleInterval;

        ~cpuMonitor.monitorTask = Task({
            inf.do {
                var totalCPU = s.avgCPU;
                var peakCPU = s.peakCPU;
                var baseline = ~cpuMonitor.baseline ? 0;
                var totalVoices = 0;

                // Update voice counts
                ~cpuMonitor[\updateOrbitVoices].value;
                totalVoices = ~cpuMonitor.orbitVoices.sum;

                "\n=== SuperCollider CPU Monitor ===".postln;
                "Total CPU: % %% (Peak: % %%)".format(
                    totalCPU.round(0.01),
                    peakCPU.round(0.01)
                ).postln;
                "Baseline: % %%".format(baseline.round(0.01)).postln;

                if(baseline > 0, {
                    var delta = totalCPU - baseline;
                    var deltaPercent = (delta / baseline * 100).round(0.1);
                    "Delta: % %% (%%)".format(
                        delta.round(0.01),
                        if(deltaPercent >= 0, { "+" ++ deltaPercent }, { deltaPercent })
                    ).postln;
                });

                "Total Active Voices: %".format(totalVoices).postln;
                "".postln;
                "Per-Orbit CPU Estimates:".postln;

                // Display per-orbit statistics
                ~dirt.orbits.do { |orbit, i|
                    var name, voices, estimatedCPU, cpuPercent;

                    // Determine orbit name
                    name = switch(i,
                        0, { "b1" }, 1, { "b2" }, 2, { "b3" },
                        3, { "b4" }, 4, { "b5" }, 5, { "b6" },
                        6, { "l1" }, 7, { "l2" }, 8, { "l3" },
                        9, { "l4" }, 10, { "l5" }, 11, { "l6" },
                        12, { "a1" }, 13, { "a2" }, 14, { "a3" },
                        15, { "a4" }, 16, { "a5" }, 17, { "a6" },
                        { "orbit" ++ i }
                    );

                    voices = ~cpuMonitor.orbitVoices.at(i);
                    estimatedCPU = ~cpuMonitor[\getOrbitCPUEstimate].value(i);
                    cpuPercent = if(totalCPU > 0, {
                        (estimatedCPU / totalCPU * 100).round(0.1)
                    }, { 0 });

                    if(voices > 0, {
                        "  % - % voices, ~% %% (% %% of total)".format(
                            name,
                            voices,
                            estimatedCPU.round(0.01),
                            cpuPercent
                        ).postln;
                    }, {
                        "  % - idle".format(name).postln;
                    });
                };

                "================================\n".postln;

                interval.wait;
            }
        }).start;

        "CPU monitoring started (interval: %s)".format(interval).postln;
    },

    // Stop monitoring
    stopMonitoring: {
        if(~cpuMonitor.monitorTask.notNil, {
            ~cpuMonitor.monitorTask.stop;
            ~cpuMonitor.monitorTask = nil;
            "CPU monitoring stopped".postln;
        });
    },

    // Advanced: Install OSCFunc to track actual synth creation per orbit
    installSynthTracking: {
        // Listen for /n_go messages (synth started)
        ~cpuMonitor.synthTracker = OSCFunc({ |msg|
            var nodeID = msg[1];
            var parentID = msg[2];

            // Find which orbit this belongs to
            ~dirt.orbits.do { |orbit, i|
                var groupID = if(orbit.group.isKindOf(Group), {
                    orbit.group.nodeID
                }, {
                    orbit.group.asInteger
                });
                var currentVoices;

                if(groupID == parentID, {
                    currentVoices = ~cpuMonitor.orbitVoices.at(i);
                    ~cpuMonitor.orbitVoices.put(i, currentVoices + 1);
                });
            };
        }, '/n_go', s.addr);

        // Listen for /n_end messages (synth stopped)
        ~cpuMonitor.synthEndTracker = OSCFunc({ |msg|
            var nodeID = msg[1];
            var parentID = msg[2];

            // Find which orbit this belongs to
            ~dirt.orbits.do { |orbit, i|
                var groupID = if(orbit.group.isKindOf(Group), {
                    orbit.group.nodeID
                }, {
                    orbit.group.asInteger
                });
                var currentVoices;

                if(groupID == parentID, {
                    currentVoices = ~cpuMonitor.orbitVoices.at(i);
                    ~cpuMonitor.orbitVoices.put(i, max(0, currentVoices - 1));
                });
            };
        }, '/n_end', s.addr);

        "Advanced synth tracking enabled".postln;
    },

    // Show detailed node tree
    showNodeTree: {
        "\n=== SuperCollider Node Tree ===".postln;
        s.queryAllNodes;
        "================================\n".postln;
    },

    // Get detailed statistics snapshot
    getDetailedStats: {
        var stats = (
            totalCPU: s.avgCPU,
            peakCPU: s.peakCPU,
            numUGens: s.numUGens,
            numSynths: s.numSynths,
            numGroups: s.numGroups,
            baseline: ~cpuMonitor.baseline,
            deltaPercent: if(~cpuMonitor.baseline.notNil && ~cpuMonitor.baseline > 0, {
                ((s.avgCPU - ~cpuMonitor.baseline) / ~cpuMonitor.baseline * 100).round(0.1)
            }, { 0 }),
            orbitStats: []
        );

        // Add per-orbit stats
        ~dirt.orbits.do { |orbit, i|
            var voices = ~cpuMonitor.orbitVoices.at(i);
            if(voices > 0, {
                stats.orbitStats = stats.orbitStats.add((
                    index: i,
                    voices: voices,
                    estimatedCPU: ~cpuMonitor[\getOrbitCPUEstimate].value(i)
                ));
            });
        };

        stats
    }
);

// Convenience shortcuts
~setCPUBaseline = { ~cpuMonitor[\setBaseline].value };
~startCPUMonitor = { |interval| ~cpuMonitor[\startMonitoring].value(interval) };
~stopCPUMonitor = { ~cpuMonitor[\stopMonitoring].value };
~showCPUStats = { ~cpuMonitor[\getDetailedStats].value.postln };
~showNodes = { ~cpuMonitor[\showNodeTree].value };
~enableAdvancedTracking = { ~cpuMonitor[\installSynthTracking].value };

"\n=== CPU Monitor Initialized ===".postln;
"Commands:".postln;
"  ~setCPUBaseline()           - Set current CPU as baseline".postln;
"  ~startCPUMonitor()          - Start continuous monitoring".postln;
"  ~startCPUMonitor(1.0)       - Start with custom interval (seconds)".postln;
"  ~stopCPUMonitor()           - Stop monitoring".postln;
"  ~showCPUStats()             - Show current statistics snapshot".postln;
"  ~showNodes()                - Show detailed node tree".postln;
"  ~enableAdvancedTracking()   - Enable precise synth tracking (experimental)".postln;
"  s.avgCPU                    - Current average CPU %%".postln;
"  s.peakCPU                   - Peak CPU %%".postln;
"================================\n".postln;
)

// Example usage:
~setCPUBaseline();           // Set baseline when idle
~enableAdvancedTracking();   // Optional: more accurate tracking
~startCPUMonitor(1.0);       // Start monitoring every 1 second

~cpuMonitor[\setBaseline].value;

~cpuMonitor[\startMonitoring].value(1.0);

~cpuMonitor[\installSynthTracking].value;

~cpuMonitor[\stopMonitoring].value;

~cpuMonitor[\getDetailedStats].value.postln;

/*
SuperCollider CPU Monitor with Visual GUI
Displays per-orbit CPU usage with meters and delta indicators
*/

/*
SuperCollider CPU Monitor with Visual GUI
Displays per-orbit CPU usage with meters and delta indicators
*/

(
~cpuGUI = (
    window: nil,
    orbitMeters: nil,
    orbitLabels: nil,
    orbitValues: nil,
    orbitDeltas: nil,
    totalMeter: nil,
    totalLabel: nil,
    baselineLabel: nil,
    footerLabel: nil,
    updateTask: nil,
    updateInterval: 0.1, // Fast GUI updates for smooth meters
    meterScale: 50, // Scale meters to show CPU up to this percentage

    // Color scheme
    colors: (
        background: Color.grey(0.15),
        meterBg: Color.grey(0.25),
        meterLow: Color.green(0.7),
        meterMed: Color.yellow(0.8),
        meterHigh: Color.red(0.7),
        text: Color.grey(0.9),
        deltaPositive: Color.red(0.8),
        deltaNegative: Color.green(0.8),
        deltaNeutral: Color.grey(0.6)
    ),

    // Get color based on CPU percentage
    getMeterColor: { |cpuPercent|
        case
            { cpuPercent < 30 } { ~cpuGUI.colors.meterLow }
            { cpuPercent < 60 } { ~cpuGUI.colors.meterMed }
            { true } { ~cpuGUI.colors.meterHigh }
    },

    // Create the GUI window
    create: {
        var win, layout, orbitNames, headerLayout, totalLayout;
        var orbitRows;

        // Orbit names
        orbitNames = ["b1", "b2", "b3", "b4", "b5", "b6",
                      "l1", "l2", "l3", "l4", "l5", "l6",
                      "a1", "a2", "a3", "a4", "a5", "a6"];

        // Initialize storage arrays
        ~cpuGUI.orbitMeters = Array.newClear(18);
        ~cpuGUI.orbitLabels = Array.newClear(18);
        ~cpuGUI.orbitValues = Array.newClear(18);
        ~cpuGUI.orbitDeltas = Array.newClear(18);

        // Create window
        win = Window("TidalCycles CPU Monitor", Rect(100, 100, 600, 850))
            .background_(~cpuGUI.colors.background)
            .front;

        layout = VLayout();

        // ====== HEADER SECTION ======
        headerLayout = VLayout(
            StaticText().string_("CPU MONITOR").font_(Font("Monospace", 20, true))
                .align_(\center).stringColor_(~cpuGUI.colors.text),
            nil // Spacer
        ).spacing_(5);

        // Total CPU meter
        totalLayout = HLayout(
            StaticText().string_("TOTAL:").font_(Font("Monospace", 12, true))
                .stringColor_(~cpuGUI.colors.text).fixedWidth_(80),
            ~cpuGUI.totalMeter = LevelIndicator()
                .style_(\led)
                .numSteps_(40)
                .warning_(0.6)
                .critical_(0.8)
                .background_(~cpuGUI.colors.meterBg)
                .value_(0),
            ~cpuGUI.totalLabel = StaticText().string_("0.0%")
                .font_(Font("Monospace", 12, true))
                .stringColor_(~cpuGUI.colors.text)
                .fixedWidth_(80)
                .align_(\right)
        ).spacing_(5);

        ~cpuGUI.baselineLabel = StaticText()
            .string_("Baseline: Not Set")
            .font_(Font("Monospace", 10))
            .stringColor_(~cpuGUI.colors.deltaNeutral)
            .align_(\center);

        headerLayout.add(totalLayout);
        headerLayout.add(~cpuGUI.baselineLabel);
        headerLayout.add(StaticText().string_("Meter Scale: 0-50% CPU")
            .font_(Font("Monospace", 9))
            .stringColor_(~cpuGUI.colors.deltaNeutral)
            .align_(\center));
        headerLayout.add(StaticText().string_("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            .align_(\center).stringColor_(~cpuGUI.colors.text));

        layout.add(headerLayout);

        // ====== ORBIT METERS SECTION ======
        orbitRows = VLayout().spacing_(3);

        18.do { |i|
            var row, name, meter, valueLabel, deltaLabel;

            name = orbitNames[i];

            row = HLayout(
                // Orbit name
                StaticText().string_(name)
                    .font_(Font("Monospace", 11, true))
                    .stringColor_(~cpuGUI.colors.text)
                    .fixedWidth_(40)
                    .align_(\right),

                // Meter bar - horizontal level indicator
                meter = LevelIndicator()
                    .style_(\led)
                    .numSteps_(30)
                    .warning_(0.6)
                    .critical_(0.8)
                    .background_(~cpuGUI.colors.meterBg)
                    .value_(0),

                // Current value
                valueLabel = StaticText().string_("0.0%")
                    .font_(Font("Monospace", 10))
                    .stringColor_(~cpuGUI.colors.text)
                    .fixedWidth_(60)
                    .align_(\right),

                // Delta indicator
                deltaLabel = StaticText().string_("--")
                    .font_(Font("Monospace", 10))
                    .stringColor_(~cpuGUI.colors.deltaNeutral)
                    .fixedWidth_(80)
                    .align_(\right)
            ).spacing_(5);

            // Store references
            ~cpuGUI.orbitMeters[i] = meter;
            ~cpuGUI.orbitLabels[i] = valueLabel;
            ~cpuGUI.orbitDeltas[i] = deltaLabel;
            ~cpuGUI.orbitValues[i] = 0;

            orbitRows.add(row);
        };

        layout.add(orbitRows);

        // ====== FOOTER SECTION ======
        layout.add(
            StaticText().string_("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                .align_(\center).stringColor_(~cpuGUI.colors.text)
        );

        ~cpuGUI.footerLabel = StaticText().string_("Voices: 0 | Peak: 0.0%")
            .font_(Font("Monospace", 10))
            .stringColor_(~cpuGUI.colors.text)
            .align_(\center);

        layout.add(~cpuGUI.footerLabel);

        win.layout = layout;
        ~cpuGUI.window = win;

        // Set close action
        win.onClose = {
            ~cpuGUI[\stopUpdating].value;
        };

        "CPU Monitor GUI created".postln;
    },

    // Update GUI with current CPU stats
    update: {
        var totalCPU, peakCPU, baseline, totalVoices;
        var delta, deltaPercent;

        if(~cpuGUI.window.isNil or: { ~cpuGUI.window.isClosed }, {
            ^nil; // Window closed, stop updating
        });

        // Get current CPU stats
        totalCPU = s.avgCPU;
        peakCPU = s.peakCPU;
        baseline = ~cpuMonitor.baseline ? 0;

        // Get total voices (don't decay, use actual counts)
        totalVoices = ~cpuMonitor.orbitVoices.sum;

        // Calculate delta
        delta = totalCPU - baseline;
        deltaPercent = if(baseline > 0, {
            (delta / baseline * 100)
        }, { 0 });

        // Update GUI on main thread
        {
            var meterScale = ~cpuGUI.meterScale;

            // Update total meter (scaled)
            ~cpuGUI.totalMeter.value_((totalCPU / meterScale).clip(0, 1));
            ~cpuGUI.totalMeter.peakLevel_((peakCPU / meterScale).clip(0, 1));
            ~cpuGUI.totalLabel.string_(totalCPU.round(0.1).asString ++ "%");

            // Update baseline label
            if(baseline > 0, {
                ~cpuGUI.baselineLabel.string_(
                    "Baseline: " ++ baseline.round(0.1) ++ "% | Delta: " ++
                    if(delta >= 0, { "+" }, { "" }) ++ delta.round(0.1) ++ "% (" ++
                    if(deltaPercent >= 0, { "+" }, { "" }) ++ deltaPercent.round(0.1) ++ "%)"
                );
                ~cpuGUI.baselineLabel.stringColor_(
                    if(delta > 5, {
                        ~cpuGUI.colors.deltaPositive
                    }, {
                        if(delta < -5, {
                            ~cpuGUI.colors.deltaNegative
                        }, {
                            ~cpuGUI.colors.deltaNeutral
                        })
                    })
                );
            });

            // Update footer
            ~cpuGUI.footerLabel.string_(
                "Voices: " ++ totalVoices ++ " | Peak: " ++ peakCPU.round(0.1) ++ "%"
            );

            // Update per-orbit meters
            18.do { |i|
                var voices, estimatedCPU, cpuPercent, previousCPU, cpuDelta;

                voices = ~cpuMonitor.orbitVoices.at(i);
                estimatedCPU = ~cpuMonitor[\getOrbitCPUEstimate].value(i);
                cpuPercent = if(totalCPU > 0, {
                    (estimatedCPU / totalCPU * 100).round(0.1)
                }, { 0 });

                // Calculate delta from previous reading
                previousCPU = ~cpuGUI.orbitValues[i];
                cpuDelta = estimatedCPU - previousCPU;
                ~cpuGUI.orbitValues[i] = estimatedCPU;

                // Update meter (scaled to meterScale for visibility)
                ~cpuGUI.orbitMeters[i].value_((estimatedCPU / meterScale).clip(0, 1));
                ~cpuGUI.orbitMeters[i].peakLevel_((estimatedCPU / meterScale * 1.1).clip(0, 1));

                // Update value label
                ~cpuGUI.orbitLabels[i].string_(estimatedCPU.round(0.01).asString ++ "%");

                // Update delta label
                if(voices > 0, {
                    ~cpuGUI.orbitDeltas[i].string_(
                        if(cpuDelta >= 0, { "▲ +" }, { "▼ " }) ++
                        cpuDelta.round(0.01) ++ "% (" ++ voices ++ "v)"
                    );
                    ~cpuGUI.orbitDeltas[i].stringColor_(
                        if(cpuDelta > 0.5, {
                            ~cpuGUI.colors.deltaPositive
                        }, {
                            if(cpuDelta < -0.5, {
                                ~cpuGUI.colors.deltaNegative
                            }, {
                                ~cpuGUI.colors.deltaNeutral
                            })
                        })
                    );
                }, {
                    ~cpuGUI.orbitDeltas[i].string_("idle");
                    ~cpuGUI.orbitDeltas[i].stringColor_(~cpuGUI.colors.deltaNeutral);
                });
            };

        }.defer; // Execute on GUI thread
    },

    // Start automatic updates
    startUpdating: { |interval|
        interval = interval ?? ~cpuGUI.updateInterval;

        ~cpuGUI[\stopUpdating].value; // Stop any existing task

        ~cpuGUI.updateTask = Task({
            inf.do {
                ~cpuGUI[\update].value;
                interval.wait;
            }
        }).start;

        "GUI updates started (interval: %s)".format(interval).postln;
    },

    // Stop automatic updates
    stopUpdating: {
        if(~cpuGUI.updateTask.notNil, {
            ~cpuGUI.updateTask.stop;
            ~cpuGUI.updateTask = nil;
        });
    },

    // Show/hide window
    show: {
        if(~cpuGUI.window.notNil, {
            ~cpuGUI.window.front;
        }, {
            "GUI not created yet. Call ~showCPUGUI() first".postln;
        });
    },

    close: {
        if(~cpuGUI.window.notNil, {
            ~cpuGUI[\stopUpdating].value;
            ~cpuGUI.window.close;
        });
    }
);

// Convenience shortcuts
~showCPUGUI = {
    // Ensure advanced tracking is enabled for accurate display
    if(~cpuMonitor.synthTracker.isNil, {
        "Enabling advanced synth tracking for accurate CPU monitoring...".postln;
        ~cpuMonitor[\installSynthTracking].value;
    });

    ~cpuGUI[\create].value;
    ~cpuGUI[\startUpdating].value(0.1); // Update every 100ms for smooth meters
};
~hideCPUGUI = { ~cpuGUI[\close].value };
~updateCPUGUI = { ~cpuGUI[\update].value };
~setMeterScale = { |scale|
    ~cpuGUI.meterScale = scale ? 50;
    "Meter scale set to 0-" ++ ~cpuGUI.meterScale ++ "%".postln;
};

"\n=== CPU Monitor GUI Available ===".postln;
"Commands:".postln;
"  ~setCPUBaseline()       - Set baseline (REQUIRED - do this first!)".postln;
"  ~showCPUGUI()           - Open visual CPU monitor (auto-enables tracking)".postln;
"  ~hideCPUGUI()           - Close monitor window".postln;
"  ~setMeterScale(100)     - Adjust meter scale (default: 50%)".postln;
"".postln;
"Quick Start:".postln;
"  1. ~setCPUBaseline()    - Set baseline when idle".postln;
"  2. ~showCPUGUI()        - Open monitor".postln;
"  3. Play patterns in TidalCycles and watch meters!".postln;
"".postln;
"Tips:".postln;
"  - If meters hit max, increase scale: ~setMeterScale(100)".postln;
"  - If meters are too small, decrease scale: ~setMeterScale(25)".postln;
"==================================\n".postln;
)


(
    // Ensure advanced tracking is enabled for accurate display
    if(~cpuMonitor.synthTracker.isNil, {
        "Enabling advanced synth tracking for accurate CPU monitoring...".postln;
        ~cpuMonitor[\installSynthTracking].value;
    });

    ~cpuGUI[\create].value;
    ~cpuGUI[\startUpdating].value(0.1); // Update every 100ms for smooth meters
);
// Quick start:
// ~setCPUBaseline();
// ~enableAdvancedTracking();
// ~showCPUGUI();