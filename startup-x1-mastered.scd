/*
This is an ansible generated startup file.
Modifications will be overwritten on next run,
but a backup copy will exist in the same dir as this file
*/
//Server.supernova;
Server.scsynth;
Server.killAll;




(
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

		~busses = ~dirt.orbits.collect { |each|
    var bus = Bus.audio(each.server, each.numChannels);
    each.outBus(bus);
    bus
};


		// -----------------------------

// Stop existing Ndef
Ndef(\x).stop;

// BEATS GROUP - Orbits [0-5] - Original style with minimal distortion
Ndef(\beats, {
    var level = 0.9;
    var distortion = 0.1;
    var reverbFeedback = 0.02;
    var beatsBuses, beatsMix, beatsLoop;

    // Collect beats orbits [0-5]
    beatsBuses = ~busses[0..5].collect { |bus| InBus.ar(bus, 2) };
    beatsMix = Mix.ar(beatsBuses);

    // Add small delays for width
    beatsMix = [
        DelayN.ar(beatsMix[0], 0.01, 0.003.rand),
        DelayN.ar(beatsMix[1], 0.01, 0.007.rand)
    ];

    // Shorter reverb for beats
    beatsLoop = InBus.ar(2);
    3.do {
        beatsLoop = AllpassL.ar(beatsLoop, 0.08, [0.03, 0.05], 1.5)
    };
    beatsMix = (beatsLoop * reverbFeedback) + beatsMix;

    beatsMix = LeakDC.ar(beatsMix);
    LocalOut.ar(beatsMix);

    // Tighter compression for punchy beats
    beatsMix = Compander.ar(beatsMix, beatsMix, 0.25,
                           slopeBelow:1, slopeAbove:0.4,
                           clampTime:0.005, relaxTime:0.05);

    // Minimal saturation
    beatsMix = (beatsMix * distortion).tanh * (level / max(distortion, 0.7));
    beatsMix
}).play;

// LEADS GROUP - Orbits [6-11] - Clean mastering
Ndef(\leads, {
    var level = 0.95;
    var leadsBuses, leadsMix;

    // Collect leads orbits [6-11]
    leadsBuses = ~busses[6..11].collect { |bus| InBus.ar(bus, 2) };
    leadsMix = Mix.ar(leadsBuses);

    // Slight spread for width
    leadsMix = [
        DelayN.ar(leadsMix[0], 0.01, 0.005.rand),
        DelayN.ar(leadsMix[1], 0.01, 0.011.rand)
    ];

    leadsMix = LeakDC.ar(leadsMix);

    // Very gentle compression - transparent
    leadsMix = Compander.ar(leadsMix, leadsMix, 0.6,
                           slopeBelow:1, slopeAbove:0.8,
                           clampTime:0.01, relaxTime:0.15);

    // No saturation - completely clean
    leadsMix * level
}).play;

// AMBIENTS GROUP - Orbits [12-17] - Clearer than beats, less muddy
Ndef(\ambients, {
    var level = 0.8;
    var distortion = 0.3;
    var reverbFeedback = 0.08;
    var ambientsBuses, ambientsMix, ambientsLoop;

    // Collect ambients orbits [12-17]
    ambientsBuses = ~busses[12..17].collect { |bus| InBus.ar(bus, 2) };
    ambientsMix = Mix.ar(ambientsBuses);

    // Wider spread for ambient width
    ambientsMix = [
        DelayN.ar(ambientsMix[0], 0.02, 0.015.rand),
        DelayN.ar(ambientsMix[1], 0.02, 0.025.rand)
    ];

    // Clearer reverb - longer but less dense
    ambientsLoop = LocalIn.ar(2);
    4.do {
        ambientsLoop = AllpassL.ar(ambientsLoop, 0.25, [0.1, 0.15], 4)
    };

    // High-pass the reverb return to reduce muddiness
    ambientsLoop = HPF.ar(ambientsLoop, 80);

    ambientsMix = (ambientsLoop * reverbFeedback) + ambientsMix;
    ambientsMix = LeakDC.ar(ambientsMix);
    LocalOut.ar(ambientsMix);

    // Gentle compression with slower attack for ambient swells
    ambientsMix = Compander.ar(ambientsMix, ambientsMix, 0.4,
                              slopeBelow:1, slopeAbove:0.6,
                              clampTime:0.02, relaxTime:0.3);

    // Very light saturation for warmth without muddiness
    ambientsMix = (ambientsMix * distortion).tanh * (level / max(distortion, 0.5));
    ambientsMix
}).play;

// FINAL MASTER BUS - Combines all three groups
Ndef(\master, {
    var masterLevel, beatsSignal, leadsSignal, ambientsSignal, finalMix;

    masterLevel = 0.95;
    beatsSignal = \beats.ar([0, 0]);
    leadsSignal = \leads.ar([0, 0]);
    ambientsSignal = \ambients.ar([0, 0]);

    finalMix = beatsSignal + leadsSignal + ambientsSignal;

    // Final master limiting to prevent any clipping
    finalMix = Limiter.ar(finalMix, masterLevel, 0.01);
    finalMix
}).play;


		// -----------------------------



	};

	s.latency = 0.5; // increase this if you get "late" messages

	//s.sync; // optionally: wait for samples to be read
     // s.sync;
	};

	);
