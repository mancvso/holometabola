/*
This is an ansible generated startup file.
Modifications will be overwritten on next run,
but a backup copy will exist in the same dir as this file
*/
(

// Three SC servers
~server1 = Server.new("beats", NetAddr("127.0.0.1", 57121), s.options, 0);
~server2 = Server.new("leads", NetAddr("127.0.0.1", 57122), s.options, 0);
~server3 = Server.new("ambs", NetAddr("127.0.0.1", 57123), s.options, 0);

// Boot all three servers
[~server1, ~server2, ~server3].do { |server|
//Server.killAll;
//Server.supernova;
server.reboot {
	// server options are only updated on reboot
	// configure the sound server: here you could add hardware specific options
	// see http://doc.sccode.org/Classes/ServerOptions.html
	server.options.numBuffers = 2048 * 256; // increase this if you need to load more samples
	server.options.memSize = 8192 * 64; // increase this if you get "alloc failed" messages
	server.options.numWireBufs = 256; // increase this if you get "exceeded number of interconnect buffers" messages
	server.options.maxNodes = 1024*512; // increase this if you are getting drop outs and the message "too many nodes"
	server.options.numOutputBusChannels = 36; // set this to your hardware output channel size, if necessary
	server.options.numInputBusChannels = 0; // set this to your hardware input channel size, if necessary
    server.options.maxLogins = 3; // optional, required to enable feedforward VU meter
	// boot the server and start SuperDirt
	server.waitForBoot {
		~dirt = SuperDirt(2, server); // two output channels, increase if you want to pan across more channels
        //loadRelative("ansible_tidal_synthdefs/*.scd");
		~dirt.doNotReadYet = false; //lazy sample loading
		~dirt.loadSoundFiles;   // load samples (path containing a wildcard can be passed in)
		// for example: ~dirt.loadSoundFiles("/Users/myUserName/Dirt/samples/*");
    		~dirt.loadSoundFiles("/home/endo/Studio/Sampling/tidal-samples/*");


		~dirt.start(s.addr.port + 100, [ 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20,  22, 24, 26, 28, 30, 32, 34 ] );   // start listening on port 57120, create 18 stereo busses

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
}
	);
