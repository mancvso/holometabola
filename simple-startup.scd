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




	};

	s.latency = 0.5; // increase this if you get "late" messages

	//s.sync; // optionally: wait for samples to be read
     // s.sync;
	};

);
// Quick start:
// ~setCPUBaseline();
// ~enableAdvancedTracking();
// ~showCPUGUI();