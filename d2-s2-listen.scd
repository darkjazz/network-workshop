// Collaborative Network Music (workshop) led by Alo Allik (alo@tehis.net) and Anna Xambó (axambo@qmul.ac.uk).
// April 7-8, 2018.
// Organized by Music Hackspace.
// Sponsored by Rewire 2018. The Hague, The Netherlands.


/*
TRIGGERING

Triggers can be used to start various processes. In a SynthDef, a trigger can be any signal that changes from non-positive to positive
*/


/* a trigger at regular intervals, that activates the amplitude envelope and a random number generator at the same time
*/
SynthDef('impulse', {arg rate, amp;
	var trig, sig, freq;
	trig = Impulse.kr(rate);
	freq = TRand.kr(200, 400, trig);
	sig = SinOsc.ar(freq) * EnvGen.kr(Env.perc, trig, levelScale: amp, timeScale: 1.0/rate);
	Out.ar(0, sig)
}).add.send(~server);

~synth = Synth('impulse', ['rate', 2, 'amp', 0.4])

~synth.set('rate', 3)

~synth.free










// a trigger at irregular intervals
SynthDef('dust', {arg rate, amp;
	var trig, sig, freq;
	trig = Dust.kr(rate);
	freq = TRand.kr(200, 400, trig);
	sig = SinOsc.ar(freq) * EnvGen.kr(Env.perc, trig, levelScale: amp, timeScale: 1.0/rate);
	Out.ar(0, sig)
}).add.send(~server)

~synth = Synth('dust', ['rate', 2, 'amp', 0.4])

~synth.set('rate', 3)

~synth.free

















// or you can trigger whenever you want

SynthDef('trig', {arg bus, amp;
	var trig, sig, freq, dur;
	trig = InTrig.kr(bus);
	freq = TRand.kr(200, 400, trig);
	dur = TRand.kr(0.5, 2.0, trig);
	sig = SinOsc.ar(freq) * EnvGen.kr(Env.perc, trig, levelScale: amp, timeScale: dur);
	Out.ar(0, sig)
}).add.send(~server)

~bus = Bus.control(s)

~synth = Synth('trig', ['bus', ~bus, 'amp', 0.4])

~bus.set(1.0)

~synth.free

s.freeAll













// trigger a buffer

SynthDef('buftrig', {arg buffer, bus, amp;
	var trig, sig;
	trig = InTrig.kr(bus);
	sig = PlayBuf.ar(1, buffer, trigger: trig) * amp;
	Out.ar(0, sig)
}).add.send(~server);



~synth = Synth('buftrig', ['buffer', ~sample, 'bus', ~bus, 'amp', 0.4])

~synth.set('amp', 1.0)

~bus.set(1.0);

~synth.free



/* you can use the trigger in a Pbind pattern
in this example to trigger a sample every time there is a rest
using Pfunc which evaluates a function on every time step of the pattern
the function checks if the duration value is Rest and only in that case sets the trigger
*/

~seq = Pbind(
	// 'server', Prand([s, ~server], inf),
	'instrument', 'sine',
	'freq', Pseq(Scale.minor.ratios * 201, inf),
	'amp', Pwhite(0.4, 0.8),
	'dur', Prand([1, 2, 3, 4, Rest(1)], inf),
	'checkdur', Pfunc({arg event;
		if (event.dur.isKindOf(Rest))
		{
			~bus.set(1.0)
		};
		0 // you have to return a value
	}),
	'delta', 0.5
).play


~seq.stop







// MACHINE LISTENING

// we can use machine listening ugens to capture information
// from audio, like pitch, and use it for synthesis


// SoundIn

// directly reading from the input of computer/soundcard...

// avoid feedback using headphones
x = { SoundIn.ar(0) }.play; // mono
x.free

x = { SoundIn.ar([0,1]) }.play; // stereo
x.free

x = { SoundIn.ar(0)!2 }.play; // stereo or 2 mono?
x.free

x = {SoundIn.ar(0).poll(label:\audioIn)}.play;
x.free


(
x = {
var in;
in = SoundIn.ar(0).poll(label:\audioIn);
Amplitude.kr(in).poll(label:\amp); // input amplitude
}.play;
)
x.free

// plot the amplitude
x = { Amplitude.kr(SoundIn.ar(0)); }.scope;
x.free

//	plugging the SoundIn as the amplitude of a UG e.g. pulse width modulation  - use headphones to prevent feedback.
x = { Pulse.ar(440, 0.1, Amplitude.kr(SoundIn.ar(0)))!2 }.scope
x.free
x = { Pulse.ar(90, 0.5, Amplitude.kr(SoundIn.ar(0)))!2 }.scope	// square wave
x.free

(
// use input amplitude to control SinOsc frequency - use headphones to prevent feedback.
x = {
    SinOsc.ar(
            Amplitude.kr(
                        SoundIn.ar(0),
                        0.01,
                        0.01,
                        1200,
                        400
            ),
            0, 0.3)
}.play;
)
x.free
// Pitch

(
// we can track the pitch with a pitch follower, two values are returned: freq and hasFreq
x = {
	var in, amp, freq, hasFreq, out;
	in = SoundIn.ar(0).poll(label:\audioIn);
	amp = Amplitude.ar(in).poll(label:\amp);
	#freq, hasFreq = Pitch.kr(in).poll(label:\pitch);
	freq.poll(label:\freq);
	hasFreq.poll(label:\freq);
}.play

)
x.free



(
// RingModulated by a sinusoidal tone with half frequency by Andrea Valle
SynthDef.new(\RmOctaver, { var in, out = 0, freq, hasFreq;
    in = SoundIn.ar(0);
    # freq, hasFreq = Pitch.kr(in);
    Out.ar(out, SinOsc.ar(freq: freq*0.5)*in);
}).add.send(~server);
)

~synth = Synth(\RmOctaver);
~synth.free












// pitch following a sound file and controlling phase modulation

~buf = Buffer.read(s, "~/snd/Kimpala.aiff".absolutePath)

SynthDef('pitch', {arg buf;
	var input, pitch, freq, hasFreq;
	input = PlayBuf.ar(2, buf, BufRateScale.kr(buf), loop: 1);
	#freq, hasFreq = Pitch.kr(input.sum);
	Out.ar(0, PMOsc.ar(freq, freq, freq, 0.3).dup)
}).add;

~synth = Synth('pitch', ['buf', ~buf])

~synth.free




















// we can also track onsets in the live audio stream
SynthDef('onsets', {arg gate, freq, buf, iamp;
	var input, fft, trig;
	// input = SoundIn.ar([0]);
	input = PlayBuf.ar(2, buf, BufRateScale.kr(buf), loop: 1);
	fft = FFT(LocalBuf(1024), input.sum);
	trig = Onsets.kr(fft, gate);
	Out.ar(0, Pan2.ar(SinOsc.ar(TRand.kr(freq/2, freq*2, trig), 0, 0.3),
		TRand.kr(-1.0, 1.0, trig))
		* EnvGen.kr(Env.perc, trig, timeScale: 0.3) + (input * iamp))
}).add;

~synth = Synth('onsets', ['gate', 0.8, 'freq', 311, 'buf', ~buf])

~synth.set('iamp', 0.0, 'gate', 0.5)

~synth.free















// and then we can combine the two and send it back to the client
SynthDef('pitch', {arg buf;
	var input, pitch, freq, hasFreq, fft, trig, pch;
	// input = SoundIn.ar([0]);
	input = PlayBuf.ar(2, buf, BufRateScale.kr(buf), loop: 1);
	fft = FFT(LocalBuf(1024), input.sum);
	trig = Onsets.kr(fft, 0.6);
	#freq, hasFreq = Pitch.kr(input.sum);
	pch = Latch.kr(freq, trig);
	SendReply.kr(trig, '/pitch', freq);
	Out.ar(0, SinOsc.ar(freq, 0, 0.3))
}).add.send(~server);

~synth = Synth('pitch', ['buf', ~buf])

~synth.free

OSCdef('listen', {|ms|
	ms.postln
}, '/pitch', s.addr)

OSCdef('listen').clear














// this is a more advanced technique using changes in frequency bands to control
// synthesis parameters of the audio input, including pitch shift and reverb
(
SynthDef('timbre', {arg buf;
	var input, fft, trig, mfcc, shift, rev;
	input = SoundIn.ar([0, 1]);
	// input = PlayBuf.ar(2, buf, BufRateScale.kr(buf), loop: 1);
	fft = FFT(LocalBuf(1024), input.sum);
	// trig = Onsets.kr(fft, 0.6);
	mfcc = MFCC.kr(fft, 13);
	shift = PitchShift.ar(input, LinLin.kr(mfcc[[6, 7, 8, 9]].mean, -1.0, 1.0, 0.05, 2.0),
		LinLin.kr(mfcc[0], -1.0, 1.0, 0.25, 2.0)
	);
	rev = GVerb.ar(shift, 100, LinLin.kr(mfcc[[1, 2]].mean, -1.0, 1.0, 1.0, 4.0),
		drylevel: 1.0, earlyreflevel: LinLin.kr(mfcc[[3, 4, 5]].mean, -1.0, 1.0, 0.1, 0.7)
	);
	Out.ar(0, rev)
}).add.send(~server)
)


~synth = Synth('timbre', ['buf', ~buf])

~synth.free














// BPM tracking
(
SynthDef('bpm', {
	var input, fft, beat;
	input = SoundIn.ar([0]);
	fft = FFT(LocalBuf(1024), input);
	beat = BeatTrack.kr(fft);
	SendReply.kr(beat[0], '/beats', beat[3])
}).add.send(~server)
)

~synth = Synth('bpm')

~synth.free

OSCdef('listen', {|ms|
	Post << "Current BPM: " << (ms[3] * 60).round(0.1) << Char.nl
}, '/beats', s.addr)















// can also use a sound file
~buf = Buffer.read(s, "/Users/alo/snd/Afterlife.aiff")

(
SynthDef('bpm', {|buffer, start|
	var input, fft, beat;
	input = PlayBuf.ar(2, buffer, BufRateScale.kr(buffer), 1, start, loop:1) * 0.5;
	fft = FFT(LocalBuf(1024), input.sum);
	beat = BeatTrack.kr(fft);
	SendReply.kr(beat[0], '/beats', beat[3]);
	Out.ar(0, input)
}).add.send(~server)
)

~synth = Synth('bpm', ['buffer', ~buf, 'start', ~buf.sampleRate * 40])

~synth.free

OSCdef('listen', {|ms|
	Post << "Current BPM: " << (ms[3] * 60).round(0.1) << Char.nl
}, '/beats', s.addr)

OSCdef('listen').clear

