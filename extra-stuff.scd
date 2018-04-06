/*
there is a different messaging style which is more low level without using SuperCollider language objects, instead the server command protocol (implemented in Open Sound Control) is used directly
*/

~server = Server("remote", NetAddr("192.168.1.101", 57110))

SynthDef('pulsing', {|freq, mod, rate, amp, dur, pan|
	var sig;
	sig = PMOsc.ar(freq, mod, LFNoise2.kr(pi**pi).range(1, 10),
		mul: LFPulse.kr(rate, width: dur).range(0, 1));
	Out.ar(0, Pan2.ar(sig * amp, pan))
}).add.send(~server)

s.addr


s.sendMsg("/s_new", "pulsing", ~s1 = s.nextNodeID, 1, 1, "freq", 7001.0, "mod", 201.0, "rate", 4, "amp", 0.0, "dur", 0.3, "pan", 0)

s.sendMsg("/s_new", "pulsing", ~s2 = s.nextNodeID, 1, 1, "freq", 301.0, "mod", 4001.0, "rate", 4, "amp", 0.2, "dur", 0.3, "pan", 0)


s.sendMsg("/n_set", ~s1, "freq", 2001)

s.sendMsg("/n_set", ~s2, "dur", 0.1)

s.sendMsg("/n_free", ~s1)

s.sendMsg("/n_query", ~s1)


s.queryAllNodes




/*
SYNTHESIS
*/


// time stretching

(
SynthDef(\warpSample, {| buffer, warp, fscale, wsize, dens, ratio, amp |
	var pointer;
	pointer = LFSaw.kr(warp/BufDur.kr(buffer), 1).range(0, 1);
	Out.ar(0, Pan2.ar(Warp1.ar(1, buffer, pointer, fscale, wsize, -1, dens, ratio )) * amp)
}).add
)

~synth1.set(\warp, 0.1, \fscale, 1)

~synth1 = Synth(\warpSample, [\buffer, ~sample, \warp, 0.1, \fscale, 1.0, \wsize, 0.1,
	\dens, 6, \ratio, 0.02, \amp, 0.2
])

~synth2 = Synth(\warpSample, [\buffer, ~sample, \warp, 0.05, \fscale, 2.0, \wsize, 0.1,
	\dens, 6, \ratio, 0.02, \amp, 0.4
])

~synth3 = Synth(\warpSample, [\buffer, ~sample, \warp, 0.2, \fscale, 0.5, \wsize, 0.1,
	\dens, 6, \ratio, 0.02, \amp, 0.2
])

~synth4 = Synth(\warpSample, [\buffer, ~sample, \warp, 0.01, \fscale, 1.0, \wsize, 0.1,
	\dens, 3, \ratio, 0.0, \amp, 0.2
])

(
~synth1.free;
~synth2.free;
~synth3.free;
~synth4.free;
)



(


SynthDef(\warpSample, {| buffer, warp, fscale, pointer, wsize, dens, ratio |
	Out.ar(0, Pan2.ar(Warp1.ar(1, buffer, pointer, 1.0, wsize, -1, dens, ratio )))
}).add
)



~synth1 = Synth(\warpSample, [\buffer, ~sample, \fscale, 1.0, \wsize, 0.1,
	\dens, 6, \ratio, 0.02, \pointer, 1.0
])

~synth1.free

~win = Window("scratch", Rect(20, 20, 400, 100)).front;
Slider(~win, Rect(10, 10, 360, 60))
	.action_({|slider|
	     ~synth1.set(\pointer, slider.value)
	});





/*
control warping with a sine oscillator
*/

(
SynthDef(\warpSample, {| buffer, fscale, wsize, dens, ratio |
	var pointer;
	pointer = LFSaw.kr(SinOsc.kr(0.05, pi).range(0.01, 1.0)/BufDur.kr(buffer), 1).range(0, 1);
	Out.ar(0, Pan2.ar(Warp1.ar(1, buffer, pointer, fscale, wsize, -1, dens, ratio )))
}).add
)



~synth = Synth(\warpSample, [\buffer, ~sample, \fscale, 1.0, \wsize, 0.1,
	\dens, 6, \ratio, 0.02
])

~synth.free










~buffer = Buffer.alloc(s, s.sampleRate * 2, 1);


SynthDef(\record, {|buffer|
	var input;
	input = SoundIn.ar([0]);
	RecordBuf.ar(input, buffer, loop: 0, doneAction: 2);
}).add;


Synth(\record, [\buffer, ~buffer])

// we can then make it a bit more interesting
(
SynthDef(\shiftSample, {|buffer, rate, winsize, shift, roomsize, revtime|
	var sig;
	sig = PlayBuf.ar(1, buffer, rate, loop: 1);
	sig = GVerb.ar(sig, roomsize, revtime);
	sig = PitchShift.ar(sig, winsize, shift);
	Out.ar(0, sig)
}).add
)



~synth = Synth(\shiftSample, [\buffer, ~buffer, \rate, 1.0, \winsize, 0.1, \shift, 1.0, \roomsize, 100, \revtime, 4])

~synth.set(\rate, 1.0, \shift, 1.0)

~synth.set(\roomsize, 50, \revtime, 2)

~synth.free

~buffer.write("/Users/alo/snd/lonams4.aiff")














// BASIC SEQUENCING

SynthDef('mod', {arg freq, rate, amp, pan, dur;
	Out.ar(0, Pan2.ar(
		LFSaw.ar(
			LFNoise1.kr(rate).range(freq/2, freq*2),
			mul:amp),
		0) * EnvGen.kr(Env.perc, timeScale: dur, doneAction: 2)
	)
}).add;

Routine


~player = Pbind(
	'instrument', 'mod',
	'freq', Prand(Array.geom(12, 211, 2**(1/12)), inf),
	'rate', Pwhite(1, 8, inf),
	'amp', 0.5, 'pan', Prand([-1, 1], inf),
	'dur', Pseq([0.5, 1.0, 2.0], inf),
	'delta', 0.125,
	'type', Pseq([\note, \rest, \rest, \note, \rest, \rest, \rest, \rest], inf)
).play

~player.stop




// MORE ADVANCED DRUMMING SEQUENCE
// DJEMBE RHYTHM PATTERN DJAKANDI

(
// define rhythm patterns as 2D array
~seq = [
	[ 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0 ],
	[ 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
	[ 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0 ],
	[ 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0 ],
	[ 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
	[ 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0 ],
	[ 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
	[ 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0 ],
	[ 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0 ]
];
)



(
// mass generate SynthDefs to save typing
~ugens = [LFNoise2, LFSaw, LFPulse, SinOsc, VarSaw, LFNoise0, LFTri, SinOsc, SinOsc, VarSaw];

//~ugens = PinkNoise.dup(11);

~defs = ~ugens.collect({|ugen, i|
	SynthDef((ugen.name.asString.toLower ++ i.asString).asSymbol, {arg freq, amp, dur, pan;
		Out.ar(0, Pan2.ar(ugen.ar(freq, mul: amp), pan)
			* EnvGen.kr(Env.perc, timeScale: dur, doneAction: 2)
		)
	})
})

)

~defs.do({arg def; def.add })

~defs.do(_.add);

~bpm = 120;
~bps = ~bpm / 60;
~delta = ~bps.reciprocal / 4

(
~freqs = Array.geom(11, 121.0, 2**(1/5));
// ~seq = Array.fill(10, { Array.fill(64, { [1, 0].wchoose([0.05, 0.95]) }) });
~binds = ~ugens.collect({|ugen, i|
	Pbind(
		'instrument', ~defs[i].name,// (ugen.name.asString.toLower ++ i.asString).asSymbol,
		'freq', ~freqs[i],
		'amp', Pwhite(0.2, 0.5, inf),
		'dur', Pbrown(0.05, 0.3, 0.06, inf),
		'delta', Pfunc({ ~delta }),
		'type', Pseq(~seq[i].replace(0, \rest).replace(1, \note), inf),
		'pan', Pwhite(-1.0, 1.0, inf)
	)
})
)

Pdef('rhythm', Ppar(~binds)).quant(24)

Pdef('rhythm').play

Pdef('rhythm').stop


// add some reverb
~rev = SynthDef('reverb', {arg revamp=0.1, revtime=0.5;
	var sig;
	sig = In.ar(0, 2);
	ReplaceOut.ar(0, GVerb.ar(sig, 30, revtime, earlyreflevel: revamp))
}).play

~rev.free

~rev.set('revamp', 0.1, 'revtime', 0.9)
