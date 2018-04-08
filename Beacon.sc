// New version for TEI 2018, optimized & refactored for stereo

Beacon {

	classvar <>server, <>buf;
	var directory, filenames, buffer, buffer2, buffer2fake;
	var iter, j, k;
	classvar <numspeakers, spkbufnums, offsetspknum, inputchannel, ispk, <pairs, <evenodds, <circular;

	*new { |numnodes = 2, offset = 0, audioinbus = 0|
		^super.new.init(numnodes, offset, audioinbus);
	}

		init { |numnodes, offset, audioinbus|

		server = Server.local;
		//Server.default = server;
		server.boot;

		// Change numspeakers depending on setup
		numspeakers = numnodes;
		// Change offset speaker number depending on where the first speaker starts from the audio interface
		offsetspknum = offset;
		// Change audio in channel depending on setup
		inputchannel = audioinbus;

		//this.mapSpeakersStereo(numspeakers, offsetspknum);
		//this.mapSpeakersPairs(numspeakers, offsetspknum);

		pairs = List.new;
		4.do{ pairs.add(List.new)}; // for 16 speakers, it should loop 8 times

		evenodds = List.new;
		2.do{ evenodds.add(List.new) }; // for 16 speakers, it should loop 8 times

		switch (numspeakers,
			2, {// depecrated
				pairs[0] = [0+offsetspknum, 1+offsetspknum];
				pairs[1] = [0+offsetspknum, 1+offsetspknum];
				pairs[2] = [0+offsetspknum, 1+offsetspknum]; pairs[3] = [0+offsetspknum, 1+offsetspknum];
				evenodds[0] = [0+offsetspknum]; evenodds[1] = [1+offsetspknum];
			},
			4, {
				pairs[0] = [0+offsetspknum, 3+offsetspknum]; pairs[1] = [1+offsetspknum, 2+offsetspknum]; pairs[2] = [0+offsetspknum, 3+offsetspknum]; pairs[3] = [1+offsetspknum, 2+offsetspknum];
				evenodds[0] = [0+offsetspknum, 2+offsetspknum]; evenodds[1] = [1+offsetspknum, 3+offsetspknum];
			},
			8, {
				pairs[0] = [0+offsetspknum, 7+offsetspknum]; pairs[1] = [1+offsetspknum, 6+offsetspknum]; pairs[2] = [2+offsetspknum, 5+offsetspknum]; pairs[3] = [3+offsetspknum, 4+offsetspknum];
				evenodds[0] = [0+offsetspknum, 2+offsetspknum, 4+offsetspknum, 6+offsetspknum]; evenodds[1] = [1+offsetspknum, 3+offsetspknum, 5+offsetspknum, 7+offsetspknum];
			}
		);

		server.waitForBoot {

	    buffer = Buffer.alloc(server, 512);
		buffer2 = Buffer.alloc(server, 44100 * 2, numspeakers);
		buffer2fake = Buffer.read(server, "/Users/annaxambo/Documents/__Postdoc\ Projects__/Ongoing/TEI\ Beacon\ performance/Piece\ process\ TEI18/Sounds/Lavelier-recording-mono.wav");

			// en un synthdef fer que l'out.ar vagi a 2 busos
			// amb un altre synthdef capturar aquell bus amb In
			// explorar TRand + onsets i passar-ho com a frequencia

		SynthDef('kickdrum', { | amp = 1, freq = 60, da = 0, bypassfx = 0, rate = 0.1 | // freq: 60-80; rate: 0.1-8
				var oscout, osc1, env1;
				var sig, chain, onsets;
				var out, effect;
				if (inputchannel == -1, {
					sig = PlayBuf.ar(1, buffer2fake, BufRateScale.kr(buffer2fake) * rate, loop: 1);
				},
				{
					sig = SoundIn.ar(inputchannel);
					//amp = Amplitude.kr(SoundIn.ar(inputchannel));
				}
				);
				chain = FFT(buffer, sig);
				onsets = Onsets.kr(chain, 0.2, \rcomplex);
				osc1 = SinOsc.ar(freq);
				env1 = EnvGen.kr(Env.perc(0.002, 0.3, 1, -2), onsets, doneAction: da);

				// Stereo case
				out = 0;
				oscout = Pan2.ar(osc1*env1) * amp;
/*				if (bypassfx == 0, {
					Out.ar(60, oscout);
				},
				{
					Out.ar(out, oscout);
				}
				);*/
				Out.ar(60, oscout);
		}).add;


		SynthDef('audioin', { | amp = 0.7, feedback = 0.5, gate = 1 |
				var out, oscout1, sig, left, right, effect, env;
				if (inputchannel == -1, {
					sig = PlayBuf.ar(1, buffer2fake, BufRateScale.kr(buffer2fake), loop: 1);
				},
				{
					sig = SoundIn.ar(inputchannel);
				}
				);

				// Stereo case
				env = EnvGen.kr(Env.asr(20.0,2.0,20.0, 'sine'), gate, doneAction: 2);
				left = sig;
				right = sig;
				effect = PingPong.ar(buffer2.bufnum, [ sig, sig ], 0.4, feedback, 0);
				out = 0;
				oscout1 =Pan2.ar(effect) * amp * env;
				Out.ar(out, oscout1);

		}).add;

		SynthDef('pureaudioin', { | amp = 0.7, gate = 1 |
				var out, oscout, sig, left, right, effect, env;
				if (inputchannel == -1, {
					sig = PlayBuf.ar(1, buffer2fake, BufRateScale.kr(buffer2fake), loop: 1);
				},
				{
					sig = SoundIn.ar(inputchannel);
				}
				);

				// Stereo case
				env = EnvGen.kr(Env.asr(20.0,2.0,20.0, 'sine'), gate, doneAction: 2);
				out = 0;
				oscout =Pan2.ar(sig) * amp * env;
				Out.ar(out, oscout);
		}).add;

		SynthDef('noisegrain', { | chain, onsets, gate = 0, freq = 440, doneAction = 0, osc1, env1, oscout1, amp = 0.3 |
				var out, sig;
				if (inputchannel == -1, {
					sig = PlayBuf.ar(1, buffer2fake, BufRateScale.kr(buffer2fake), loop: 1);
				},
				{
					sig = SoundIn.ar(inputchannel);
				}
				);
				chain = FFT(buffer, sig);
				onsets = Onsets.kr(chain, 0.2, \rcomplex);
				osc1 = Pulse.ar(90, 0.3, Amplitude.kr(sig));
				env1 = EnvGen.kr(Env.perc, onsets, doneAction: doneAction);

				// Stereo case
				oscout1 =Pan2.ar(osc1*env1) * amp;
				out = 0;
				Out.ar(out, oscout1);

		}).add;


			// Playbuf with trigger (rhythmical) + RLPF mod by freq
			SynthDef(\beacon_PlayBuf_rhythmic, { | amp = 1, rate = 1, freq = 600, trigvalue = 1, bufnum = 0, gate = 1|
				var oscout, loop, da;
				var sig, env, out, trig;
				loop = 1;
				da = 2;
				trig = Impulse.kr(trigvalue);
				env = EnvGen.kr(Env.asr(20.0,2.0,20.0, 'sine'), gate, doneAction:2);
				sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * rate, trigger: trig, doneAction:da, loop: loop);
				sig = RLPF.ar(sig, freq);

				// Stereo case
				out = 0;
				oscout = Pan2.ar(sig * env) * amp;
				//Out.ar(out, oscout);
				Out.ar(31, oscout);

			}).add;


			// Playbuf normal + RLPF mod by freq
			SynthDef(\beacon_PlayBuf_LPF, { | amp = 1, rate = 1, freq = 400, bufnum = 0, gate = 1, bypassfx = 0 | // freq: 400-800
				var oscout, loop, da;
				var sig, env, out;
				loop = 1;
				da = 2;
				env = EnvGen.kr(Env.asr(20.0,2.0,20.0, 'sine'), gate, doneAction:2);
				sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * rate, doneAction:da, loop: loop);

				sig = RLPF.ar(sig, freq);

				// Stereo case
				out = 0;
				oscout = Pan2.ar(sig * env) * amp;
/*				if (bypassfx == 0, {
					Out.ar(11, oscout);
				},
				{
					Out.ar(out, oscout);
				}
				);*/
				Out.ar(11, oscout);

			}).add;

			// Playbuf normal + RLPF mod by freq
			SynthDef(\beacon_PlayBuf_LPF_p2, { | amp = 1, rate = 1, freq = 400, bufnum = 0, gate = 1, bypassfx = 0 | // freq: 400-800
				var oscout, loop, da;
				var sig, env, out;
				loop = 1;
				da = 2;
				env = EnvGen.kr(Env.asr(20.0,2.0,20.0, 'sine'), gate, doneAction:2);
				sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * rate, doneAction:da, loop: loop);

				sig = RLPF.ar(sig, freq);

				// Stereo case
				out = 0;
				oscout = Pan2.ar(sig * env) * amp;
/*				if (bypassfx == 0, {
					Out.ar(11, oscout);
				},
				{
					Out.ar(out, oscout);
				}
				);*/
				Out.ar(21, oscout);

			}).add;


			// Playbuf normal + HPF mod by freq
			SynthDef(\beacon_PlayBuf_HPF, { | amp = 1, rate = 1, freq = 300, bufnum = 0, gate = 1, bypassfx = 0 |
				var oscout, loop, da;
				var sig, env, out;
				 loop = 1;
				da = 2;
				env = EnvGen.kr(Env.asr(20.0,2.0,20.0, 'sine'), gate, doneAction:2);
				sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * rate, doneAction:da, loop: loop);
				sig = HPF.ar(sig, freq);

				// Stereo case
				out = 0;
				oscout = Pan2.ar(sig * env) * amp;
/*				if (bypassfx == 0, {
					Out.ar(12, oscout);
				},
				{
					Out.ar(out, oscout);
				}
				);*/
				Out.ar(23, oscout);
			}).add;


			// Playbuf normal + BPF mod by freq
			SynthDef(\beacon_PlayBuf_BPF, { | amp = 1, rate = 1, freq = 1200, bufnum = 0, gate = 1, bypassfx = 0 |
				var oscout, loop, da;
				var sig, env, out;
				 loop = 1;
				da = 2;
				env = EnvGen.kr(Env.asr(20.0,2.0,20.0, 'sine'), gate, doneAction:2);
				sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * rate, doneAction:da, loop: loop);
				sig = BPF.ar(sig, freq);

				// Stereo case
				out = 0;
				oscout = Pan2.ar(sig * env) * amp;
/*				if (bypassfx == 0, {
					Out.ar(13, oscout);
				},
				{
					Out.ar(out, oscout);
				}
				);*/
				Out.ar(13, oscout);
			}).add;


			// Random mode: random speaker at a trigger that equals to the end of the buffer
			SynthDef(\beacon_PlayBuf_random_speaker, { | amp = 1, rate = 1, gate = 1, bufnum = 0, freq = 440, trigger = 1, freqonsets = 0.2 |
				var oscout, loop, da, in;
				var sig, env, out, trig, lo, hi, min, max, chain, onsets, mod;
				loop = 1;
				da = 2;

				if (inputchannel == -1, {
					in = PlayBuf.ar(1, buffer2fake, BufRateScale.kr(buffer2fake), loop: 1);
				},
				{
					in = SoundIn.ar(inputchannel);
				}
				);

				min = 0 + offsetspknum;
				max = numspeakers + offsetspknum;
				lo = \lo.kr(min);
				hi = \hi.kr(max)-1;
				trig = Impulse.kr(BufDur.kr(bufnum).reciprocal);
				//trig.poll(label: \trig);

				env = EnvGen.kr(Env.asr(20.0,2.0,20.0, 'sine'), gate, doneAction:2);
				sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * rate, trigger: trigger, doneAction: da, loop: loop);
				sig = RLPF.ar(sig, freq);

				if ( numspeakers >2, {
					out = TRand.kr(lo, hi, trig);
					oscout = sig * env * amp;
					Out.ar(out, oscout);
				},
				{
					//some MIRLC!
					chain = FFT(buffer, in);
					onsets = Onsets.kr(chain, freqonsets, \rcomplex);
					//onsets.poll(label: \onsets);
					mod = TRand.kr(lo, hi, onsets); // [values between -1 and 1]
					//lo.poll(label: \lo);
					//hi.poll(label: \hi);
					//mod.poll;
					out = 0;
					oscout = Pan2.ar(sig * env, mod) * amp;
					//Out.ar(out, oscout);
					Out.ar(41, oscout );
				}
				);

			}).add;


/*			SynthDef(\beacon_PlayBuf_Saw, { | amp = 1, bufnum = 0, rate = 1,  gate = 1, modrate = 0.5, freq = 440|
				var oscout, out, da, loop, chain, in;
				var sig, env, mod, maxbufnum, offset;
				out = 0;
				da = 2;
				loop = 1;

				if (inputchannel == -1, {
					in = PlayBuf.ar(1, buffer2fake, BufRateScale.kr(buffer2fake), loop: 1);
				},
				{
					in = SoundIn.ar(inputchannel);
				}
				);

				maxbufnum =  numspeakers + offsetspknum - 1;
				env = EnvGen.kr(Env.asr(20.0,2.0,20.0, 'sine'), gate, doneAction:2);
				sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * rate, doneAction:da, loop: loop);
				sig = RLPF.ar(sig, freq);
				if ( numspeakers >2, {
					offset = offsetspknum + 0.5;
					mod = Saw.kr(freq: modrate, mul: maxbufnum, add: offset);
					out = mod;
					oscout = sig * env * amp;
					Out.ar(out, oscout);
				},
				{

					offset = offsetspknum + 0.5;
					mod = Saw.kr(freq: modrate, mul: maxbufnum, add: offset);
					out = mod;
					out.poll;
					oscout = sig * env * amp;
					//Out.ar(out, oscout);
					Out.ar(15, oscout);
					//out = 0;
					//oscout = Pan2.ar(sig * env ) * amp;
					//Out.ar(out, oscout);
				}
				);

			}).add;*/

			SynthDef(\beacon_PlayBuf_Saw_MIRLC, { | amp = 1, bufnum = 0, rate = 1, gate = 1, modrate = 100, freq = 440, freqonsets = 0.2 |

				var oscout, out, da, loop, in;
				var sig, env, mod, maxbufnum, offset, chain, onsets;
				da = 2;
				loop = 1;

				if (inputchannel == -1, {
					in = PlayBuf.ar(1, buffer2fake, BufRateScale.kr(buffer2fake), loop: 1);
				},
				{
					in = SoundIn.ar(inputchannel);
				}
				);

				maxbufnum =  numspeakers + offsetspknum - 1;
				offset = offsetspknum + 0.5;
				env = EnvGen.kr(Env.asr(20.0,2.0,20.0, 'sine'), gate, doneAction:2);
				sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * rate, doneAction:da, loop: loop);
				sig = RLPF.ar(sig, freq);
				if ( numspeakers >1, {
					// missing adaptation code from below
					mod = Saw.kr(freq: modrate, mul: maxbufnum, add: offset);
					out = mod;
					oscout = sig * env * amp;
					//Out.ar(out, oscout);
					Out.ar(43, oscout);
				},
				{
/*					//some MIRLC!
					chain = FFT(buffer, in);
					onsets = Onsets.kr(chain, freqonsets, \rcomplex);
					mod = TRand.kr(-1, 1, onsets); // [values between -1 and 1]
					out = 0;
					oscout = Pan2.ar(sig * env, mod) * amp;
					//Out.ar(out, oscout);
					Out.ar(15, oscout);*/
				}
				);

			}).add;

			SynthDef(\beacon_PlayBuf_Saw_MIRLC_p5, { | amp = 1, bufnum = 0, rate = 1, gate = 1, modrate = 100, freq = 440, freqonsets = 0.2 |

				var oscout, out, da, loop, in;
				var sig, env, mod, maxbufnum, offset, chain, onsets;
				da = 2;
				loop = 1;

				if (inputchannel == -1, {
					in = PlayBuf.ar(1, buffer2fake, BufRateScale.kr(buffer2fake), loop: 1);
				},
				{
					in = SoundIn.ar(inputchannel);
				}
				);

				maxbufnum =  numspeakers + offsetspknum - 1;
				offset = offsetspknum + 0.5;
				env = EnvGen.kr(Env.asr(20.0,2.0,20.0, 'sine'), gate, doneAction:2);
				sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * rate, doneAction:da, loop: loop);
				sig = RLPF.ar(sig, freq);
				if ( numspeakers >1, {
					// missing adaptation code from below
					mod = Saw.kr(freq: modrate, mul: maxbufnum, add: offset);
					out = mod;
					oscout = sig * env * amp;
					//Out.ar(out, oscout);
					Out.ar(51, oscout);
				},
				{
/*					//some MIRLC!
					chain = FFT(buffer, in);
					onsets = Onsets.kr(chain, freqonsets, \rcomplex);
					mod = TRand.kr(-1, 1, onsets); // [values between -1 and 1]
					out = 0;
					oscout = Pan2.ar(sig * env, mod) * amp;
					//Out.ar(out, oscout);
					Out.ar(15, oscout);*/
				}
				);

			}).add;

			// Reverberation from: "http://doc.sccode.org/Tutorials/Mark_Polishook_tutorial/17_Delays_reverbs.html" (James McCartney)
			SynthDef(\reverb, { arg out=0, in=0, amount=0.2; // amount: 0.01 - 0.2

				var s, z, y;
				// 10 voices of a random sine percussion sound :
				s = In.ar(in, 1);
				// reverb predelay time :
				z = DelayN.ar(s, 0.048);
				// 7 length modulated comb delays in parallel :
				y = Mix.ar(Array.fill(7,{ CombL.ar(z, 0.1, LFNoise1.kr(0.1.rand, 0.04, 0.05), 15) }));
				// two parallel chains of 4 allpass delays (8 total) :
				4.do({ y = AllpassN.ar(y, 0.050, [0.050.rand, 0.050.rand], 1) });
				// add original sound to reverb and play it :
				Out.ar(out, s+(amount*y)); // original sound (s) + reverb (y)
			}).add;

			// Change directory path depending on where the audio samples are
			directory = "/Users/annaxambo/Documents/__Postdoc\ Projects__/Ongoing/TEI\ Beacon\ performance/Piece\ process\ TEI18/Sounds/";

		// Files used in RSF17 & NIME17
			// part1, [0]: drone, used repeated times at different rates (slightly different)
			// they are accessed from SC client e.g. Beacon.buf[0]
		filenames = Dictionary.new;
			filenames = [
				"367489.wav", // part 1, drone
				"195969.wav", "367632.wav", "369242.wav", "368256.wav",
				"369240.wav",  // part 4
				"133048.wav", "336333.wav", "250760.wav", "92739.wav",
				"33781.wav", "331155.wav",  // part 4
				"333859.wav",
				"367538.wav", // part 4
				"105210.wav", "133033.wav", "244688.wav", "268077.wav",
				"380788.wav",
				"plumbing-mikkeller-aw-mono.wav", // part 3
				"motorsounds-lavelier-aw-rec-mono.wav", // part 2 (motor sound) & part 3
				"motorsounds-lavelier-aw-rec-loop-mono.wav" // part 2 (motor sound - shorter loop)
			];

		buf = Dictionary.new;
		filenames.size.do { |i|
			buf[i] = Buffer.read(server, directory +/+ filenames[i]);
		};
		};

	}

}	