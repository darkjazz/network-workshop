// Collaborative Network Music (workshop) led by Alo Allik (alo@tehis.net) and Anna Xambó (axambo@qmul.ac.uk).
// April 7-8, 2018.
// Organized by Music Hackspace.
// Sponsored by Rewire 2018. The Hague, The Netherlands.

// MACHINE LISTENING

// we can use machine listening ugens to capture information
// from audio, like pitch, and use it for synthesis

~buf = Buffer.read(s, "/Users/alo/snd/Kimpala.aiff")

SynthDef('pitch', {|buf|
	var input, pitch, freq, hasFreq;
	// input = SoundIn.ar([0]);
	input = PlayBuf.ar(2, buf, BufRateScale.kr(buf), loop: 1);
	#freq, hasFreq = Pitch.kr(input.sum);
	Out.ar(0, VarSaw.ar(freq, 0, 0.2, 0.3).dup)
}).add;

~synth = Synth('pitch', ['buf', ~buf])

~synth.free

// we can also track onsets in the live audio stream
SynthDef('onsets', {|gate, freq, buf, iamp|
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

~synth.set('iamp', 0.0, 'gate', 3.0)

~synth.free

// and then we can combine the two and send it back to the client
SynthDef('pitch', {|buf|
	var input, pitch, freq, hasFreq, fft, trig, pch;
	// input = SoundIn.ar([0]);
	input = PlayBuf.ar(2, buf, BufRateScale.kr(buf), loop: 1);
	fft = FFT(LocalBuf(1024), input.sum);
	trig = Onsets.kr(fft, 0.6);
	#freq, hasFreq = Pitch.kr(input.sum);
	pch = Latch.kr(freq, trig);
	SendReply.kr(trig, '/pitch', freq);
	Out.ar(0, SinOsc.ar(freq, 0, 0.3))
}).add;

~synth = Synth('pitch', ['buf', ~buf])

~synth.free

OSCdef('listen', {|ms|
	ms.postln
}, '/pitch', s.addr)

OSCdef('listen').clear

// this is a more advanced technique using changes in frequency bands to control
// synthesis parameters of the audio input, including pitch shift and reverb
(
SynthDef('timbre', {|buf|
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
}).add
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
}).add
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
}).add
)

~synth = Synth('bpm', ['buffer', ~buf, 'start', ~buf.sampleRate * 40])

~synth.free

OSCdef('listen', {|ms|
	Post << "Current BPM: " << (ms[3] * 60).round(0.1) << Char.nl
}, '/beats', s.addr)

OSCdef('listen').clear


~mylist = [1, 2, 3]

~mylist.collect({|num| num + 1 })
