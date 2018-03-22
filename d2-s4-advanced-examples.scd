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
