/*
Collaborative Network Music (workshop) led by Alo Allik (alo@tehis.net)
and Anna Xambó (axambo@qmul.ac.uk).
April 7-8, 2018.
Organized by Music Hackspace.
Sponsored by Rewire 2018. The Hague, The Netherlands.



INTRODUCTION
----------------------------------------------------------




Download: https://supercollider.github.io
The files are available at: http://192.168.1.100/rewire/network.zip


SuperCollider basics:

- there are 3 components to SuperCollider:
	synthesis server - a separate application that makes the sound
	unit generator plugins - sound synthesis units (e.g. SinOsc)
	language - programming language to control synthesis

- when you open the SuperCollider IDE there are 2 windows:
	post - where the application posts feedback e.g. errors, info, status etc.
	editor window

to make a new window use cmd-N or choose File->New from the menu

..and to get help use cmd-D to launch the searchable help system

to execute code, highlight it and press cmd-ENTER (varies by platform)

to stop all local server processes cmd-.







FIRST NETWORK MUSIC EXAMPLES
----------------------------------------------------------
*/



(
~server = Server(
	"remote",
	NetAddr(
		// "192.168.1.102",
		"192.168.2.3",
		57110
	)
)
)


SynthDef('crackle', {arg param;
	Out.ar(0, Crackle.ar(param))
}).add.send(~server);

~localcrackle = Synth('crackle', ['param', 1.5])

~remotecrackle = Synth('crackle', ['param', 1.0], ~server)


~remotecrackle.set('param', 1.999)


~localcrackle.set('param', 0.8)

~remotecrackle.free


SynthDef('tone', {arg freq, amp, dur;
	var sig, env;
	env = Line.kr(1, 0, dur);
	FreeSelfWhenDone.kr(env);
	sig = LFSaw.ar(freq) * env;
	Out.ar(0, sig)
}).send(~server)

Synth('tone', ['freq', 101, 'amp', 0.2, 'dur', 1.0], ~server)

Tdef('tones', {
	loop({
		Synth('tone', ['freq', 201.rand, 'amp', 0.5, 'dur', rrand(0.4, 1.0)], ~server);
		[0.25, 0.5, 0.375].choose.wait
	})
}).play

Tdef('tones').clear






/*
DAY 1 SESSION 1: SUPERCOLLIDER BASICS
----------------------------------------------------------
*/




/* NETWORK

you can also send messages to another client
if the client knows how to receive it

for example, you can send chat messages
*/

"ipconfig getifaddr en0".unixCmd // <-- execute this to see your address in the post window


~client = NetAddr("192.168.2.3", 57120)

~client.sendMsg("/chat", "alo", "hello let's make some noise :)")

OSCdef('chat', {arg message;
	Post << "#" << message[1] << ": " << message[2] << Char.nl
}, "/chat")







/*
or if you have a window for your collaborators' code
it can be automatically posted there, so the same bit of code can be modified collaboratively
*/



// open send-me-code.scd
~codedoc = Document.allDocuments.select({arg doc; doc.name == "send-me-code.scd"}).first

// activate a receiver that posts the code in the send-me-code.scd file
OSCdef('code', {arg message;
	~codedoc.string = " /*from " ++ message[1] ++ "*/ " ++ Char.nl.asString ++ message[2] ++ Char.nl.asString;
	~codedoc.front;
}, "/code")


// to send code to others to edit, create a SynthDef
~mycode = SynthDef('tone', {arg freq, amp, dur;
	var sig;
	sig = LFSaw.ar(freq, mul: amp) * Line.kr(1, 0, dur, doneAction: Done.freeSelf);
	Out.ar(0, sig)
}).asCompileString

// and send it, including the type of message, your nickname, and the contents
~client.sendMsg("/code", "alo", ~mycode)









/*
you can also make the code execute automatically in another client
if you wrap it in a string and send it and hope that they trust you to
receive it
*/

~mycode = "Tdef('loop', {
	100.do({
		SynthDef('racket', {
			Out.ar(0, PMOsc.ar(rrand(30, 60), rrand(100, 200), 10.rand)
				* Line.kr(0.3.rand, 0, rrand(0.3, 1.0), doneAction: Done.freeSelf))
		}).play;
		rrand(0.2, 0.6).wait;
	})
}).play";

~client.sendMsg("/run", ~mycode)


// this is how you would receive it
OSCdef('run', { arg message;
	message[1].asString.compile.()
}, '/run')








// SYNTHESIS

~server = Server("rewire", NetAddr("192.168.2.3", 57110))

// simple synth with a sinewave
SynthDef('sine', {arg freq, amp, dur;
	var sig;
	sig = SinOsc.ar(freq) * EnvGen.kr(Env.perc, 1, amp, timeScale: dur, doneAction: Done.freeSelf);
	Out.ar(0, sig)
}).add.send(~server)

// play it
Synth('sine', ['freq', 241, 'amp', 0.4, 'dur', 1.0 ], ~server)

// or you can have a 100 :)
100.do({
	Synth('sine', ['freq', 2000.rand, 'amp', 1/100, 'dur', 1.0 ], ~server);
})












// you can modulate any parameter with another ugen
SynthDef('modulate', {arg freq, amp, dur;
	var sig;
	sig = SinOsc.ar(freq, SinOsc.kr(freq), SinOsc.kr(freq*0.1)) * EnvGen.kr(Env.perc, 1, amp, timeScale: dur, doneAction: Done.freeSelf);
	Out.ar(0, sig)
}).add.send(~server)

Synth('modulate', ['freq', 241, 'amp', 0.4, 'dur', 1.0 ], ~server)
















// you can use filters
SynthDef('filter', {arg freq, amp, dur;
	var sig;
	sig = BPF.ar(WhiteNoise.ar, freq, 1.0/SinOsc.kr(2).range(freq/4, freq*4), 10) * EnvGen.kr(Env.perc, 1, amp, timeScale: dur, doneAction: Done.freeSelf);
	Out.ar(0, sig)
}).add.send(~server)

Synth('filter', ['freq', 241, 'amp', 2.0, 'dur', 2.0 ], ~server)














// you can record a sound

~sample = Buffer.alloc(s, 44100 * 2)

~remotesample = Buffer.alloc(~server, 44100)


SynthDef('record', {arg buffer;
	var input, rec;
	input = SoundIn.ar(0);
	rec = RecordBuf.ar(input, buffer, loop: 0, doneAction: Done.freeSelf);
}).add.send(~server);

Synth('record', ['buffer', ~remotesample], ~server)


SynthDef('loop-sample', {arg buffer, amp, rate;
	var sig;
	sig = PlayBuf.ar(1, buffer, rate, loop: 1) * amp;
	Out.ar(0, sig)
}).add.send(~server)


~looper = Synth('loop-sample', ['buffer', ~sample, 'amp', 0.4, 'rate', 1], ~server)

~looper.set('rate', 0.5)

~looper.free


// then you can send it to someone else's computer and play it

~sample.loadToFloatArray(action: {arg array;
	~samplearray = array
});












// SEQUENCING WITH SCHEDULERS AND LOOPS

~freqs = Scale.minor.ratios * 301;
Tdef('myloop', {
	loop({
		Synth('sine', ['freq', ~freqs.choose, 'amp', 0.2.rand, 'dur', 1 ], ~server);
		1.wait; // <---- VERY IMPORTANT!!!!
	})
}).play

// you can change it while it runs

Tdef('myloop', {
	loop({
		Synth('sine', ['freq', ~freqs.choose, 'amp', 0.2, 'dur', 0.4 ]);
		0.1.wait;
	})
})

// now clear it up so it doesn't run indefinitely
Tdef('myloop').clear


// SEQUENCING WITH PATTERNS

// there is this magical object called Pbind...
~bind = Pbind().play
~bind.stop

SynthDef('sine', {arg freq, amp, dur;
	var sig;
	sig = SinOsc.ar(freq) * EnvGen.kr(Env.perc, 1, amp, timeScale: dur, doneAction: Done.freeSelf);
	Out.ar(0, sig)
}).add.send(~server)

~seq = Pbind(
	'server', Prand([s, ~server], inf),
	'instrument', 'sine',
	'freq', Pseq(Scale.minor.ratios * 201, inf),
	'amp', Pwhite(0.4, 0.8),
	'dur', Prand([1, 2, 3, 4], inf),
	'delta', 0.5
).play

~seq.stop


SynthDef('slide', {arg freq, amp, dur;
	var sig;
	sig = SinOsc.ar(XLine.kr(freq, freq*2, dur)) * EnvGen.kr(Env.perc, 1, amp, timeScale: dur, doneAction: Done.freeSelf);
	Out.ar(0, sig)
}).add.send(~server)


~seq = Pseq([
	Pbind(
		'server', Prand([s, ~server], inf),
		'instrument', 'sine',
		'freq', Pseq(Scale.minor.ratios * 201, 2),
		'amp', Pwhite(0.4, 0.8),
		'dur', Prand([1, 2, 3, 4], inf),
		'delta', 0.5
	),
	Pbind(
		'server', Pstutter(2, Pseq([s, ~server], 2)),
		'instrument', Pseq(['sine', 'slide'], 8),
		'freq', Pseq(Scale.minor.ratios.reverse * 401, 2),
		'amp', 0.5,
		'dur', 0.7,
		'delta', 0.25
	)
], inf).play


~seq.stop






~neopkwaii = Server("neopkwaii", NetAddr("192.168.1.101", 57110))

SynthDef('pulsing', {|freq, mod, rate, amp, dur, pan|
	var sig;
	sig = PMOsc.ar(freq, mod, LFNoise2.kr(pi**pi).range(1, 10),
		mul: LFPulse.kr(rate, width: dur).range(0, 1));
	Out.ar(0, Pan2.ar(sig * amp, pan))
}).send(~neopkwaii)

s.addr

s.sendMsg("/s_new", "pulsing", ~s1 = s.nextNodeID, 1, 1, "freq", 7001.0, "mod", 201.0, "rate", 4, "amp", 0.2, "dur", 0.3, "pan", 0)

s.sendMsg("/s_new", "pulsing", ~s2 = s.nextNodeID, 1, 1, "freq", 301.0, "mod", 4001.0, "rate", 4, "amp", 0.2, "dur", 0.3, "pan", 0)


s.sendMsg("/n_set", ~s1, "freq", 2001)

s.sendMsg("/n_set", ~s2, "dur", 0.1)


s.sendMsg("/n_free", ~s1)



s.sendMsg("/n_query", ~s1)


s.queryAllNodes