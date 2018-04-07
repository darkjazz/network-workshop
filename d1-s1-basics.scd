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

to record the sound you are producing type "Server.default.record" and execute cmd-ENTER. To stop the recording press cmd-ENTER (varies by platform). Alternatively type "Server.default.makeGui" and press the record/stop buttons. The sounds are recorded in "~/Music/SuperCollider Recordings/" (varies by platform).



connect to eototo
password: iame0t0t0



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

~localcrackle.free


SynthDef('tone', {arg freq, amp, dur;
	var sig, env;
	env = Line.kr(1, 0, dur);
	FreeSelfWhenDone.kr(env);
	sig = SinOsc.ar(freq) * env;
	Out.ar(0, Pan2.ar(sig, SinOsc.kr(8)))
}).add.send(~server)

Synth('tone', ['freq', 201, 'amp', 0.2, 'dur', 1.0], ~server)

Tdef('tones', {
	loop({
		Synth('tone', ['freq', 501.rand, 'amp', 0.05, 'dur', rrand(0.4, 1.0)], ~server);
		[0.25, 0.5, 0.375].choose.wait
	})
}).play

Tdef('tones').clear






/*
DAY 1 SESSION 1: SUPERCOLLIDER BASICS
----------------------------------------------------------
*/

// data types: numbers, strings, symbols

1.class
1.0.class
pi
1+1
2.neg.sqrt
1/0

// strings
"text"
t = "what are you looking at, punk?"

t.do(_.postln)

// symbols
'symbol'
\symbol

t = 'what are you looking at, punk?'


// booleans can only be true or false, used for conditions in if statements
true
false

n = 15;
if (n.odd) { n.asString ++ " is an odd number" } { n.asString ++ " is an even number" }
if (n.isPrime) { n.asString ++ " is a prime number" } { n.asString ++ " is not a prime number" }

/* variables are sort of containers that hold values you can change
variables have to be defined with the reserved word var
*/
(
var whatever;
whatever = 'what are you looking at, punk?';
whatever.postln
)

whatever

(
var mynumber;
mynumber = 5.rand + 1;
mynumber.postln
)

mynumber

// global variables that persist begin with a ~
~whatever = 'what are you looking at, punk?';
~whatever


~mynumber = 5.rand + 1;
~mynumber.postln

// all lower case letters are defined variables in SuperCollider

a = 0.1
a
a = a.pow(2)
a

b = "this is not a string"
b

c = 2pi
c


// this an array, a collection of objects, in [ ]
l = [1, "what are you looking at, punk?", pi, 'symbol', 2.neg.sqrt]

// each object in an array has a simple address called an index, starting with 0
l[0]

// you can do all sorts of stuff with arrays
l.reverse
l.scramble
l.select({arg item; item.isKindOf(Number) })
l.do({arg item, index;
	Post << "The index of " << item << " is " << index << Char.nl
})








/* this is a function, a bunch of code enclosed in { } ready to be executed

functions have arguments :) not the Monty Python kind though

just variables that you can feed to the function, whatever the last line evaluates to is returned from the function
*/
f = {arg argument;
	"this is not an argument, this is " ++ argument
}

f.value("abuse")


~dice = {arg sides;
	(sides - 1).rand + 1
}

~dice.value(6)







/*
everything in SuperCollider is an Object and every object has variables and methods - functions that change these variables.
*/

Object.method(parameter1, parameter2,..)

Scale.at(\ionian)

SystemClock.sched(2.0, {arg time;
	Post << "SuperCollider has been running for " << time.floor << " seconds" << Char.nl;
	1.0
})

SystemClock.clear

/*
Most objects you have to be created first by using the special method 'new', which can be omitted

*/

~env = Env.new([0.01, 0.3, 1.0, 0.4], [0.2, 0.5, 0.3], 'exp')
// is the same as
~env = Env([0.01, 0.3, 1.0, 0.4], [0.2, 0.5, 0.3], 'exp')

~env.plot(500) // plot method, first argument: size in pixels


~tuning = Tuning.new('partch', pi, "partch pi tuning")
// is the same as
~tuning = Tuning('partch', pi, "partch pi tuning")

~tuning.name // name variable
~tuning.octaveRatio // octaveRatio variable
~tuning.tuning // tuning variable









/* NETWORK

you can also send messages to another client
if the client knows how to receive it

for example, you can send chat messages
*/

"ipconfig getifaddr en0".unixCmd // <-- execute this to see your address in the post window


~client = NetAddr("127.0.0.1", 57120)

~client.sendMsg("/chat", "alo", "hello! my ip is 192.168.2.3")

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

Tdef('loop', {
	100.do({
		SynthDef('racket', {
			Out.ar(0, PMOsc.ar(rrand(30, 60), rrand(100, 200), 10.rand)
				* Line.kr(0.06.rand, 0, rrand(0.3, 1.0), doneAction: Done.freeSelf))
		}).play;
		rrand(0.2, 0.6).wait;
	})
}).play

~mycode = "";

~client.sendMsg("/run", ~mycode)


// this is how you would receive it
OSCdef('run', { arg message;
	message[1].asString.compile.()
}, '/run')














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
		Synth('sine', ['freq', ~freqs.choose, 'amp', 0.2, 'dur', 0.4 ], [~server, s].choose);
		0.1.wait;
	})
});

// now clear it up so it doesn't run indefinitely
Tdef('myloop').clear













// SEQUENCING WITH PATTERNS

// there is this magical object called Pbind...
~bind = Pbind().play
~bind.stop

SynthDef('sine', {arg freq, amp, dur;
	var sig;
	sig = SinOsc.ar(freq) * EnvGen.kr(Env.perc, 1, amp, timeScale: dur, doneAction: Done.freeSelf);
	Out.ar(0, sig.dup)
}).add.send(~server)

~seq = Pbind(
	// 'server', Prand([s, ~server], inf),
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
	Out.ar(0, sig.dup)
}).add.send(~server)


// you can also sequence Pbinds
~seq = Pseq([
	Pbind(
		// 'server', Prand([s, ~server], inf),
		'instrument', 'sine',
		'freq', Pseq(Scale.minor.ratios * 201, 2),
		'amp', Pwhite(0.4, 0.8),
		'dur', Prand([1, 2, 3, 4], inf),
		'delta', 0.5
	),
	Pbind(
		// 'server', Pstutter(2, Pseq([s, ~server], 2)),
		'instrument', Pseq(['sine', 'slide'], 8),
		'freq', Pseq(Scale.minor.ratios.reverse * 401, 2),
		'amp', 0.5,
		'dur', 0.7,
		'delta', 0.25
	)
], inf).play


~seq.stop











// you can play Pbinds in parallel
~seq = Ppar([
	Pbind(
		// 'server', Prand([s, ~server], inf),
		'instrument', 'sine',
		'freq', Pseq(Scale.minor.ratios * 201, 2),
		'amp', Pwhite(0.4, 0.8),
		'dur', Prand([1, 2, 3, 4], inf),
		'delta', 0.5
	),
	Pbind(
		// 'server', Pstutter(2, Pseq([s, ~server], 2)),
		'instrument', Pseq(['sine', 'slide'], 8),
		'freq', Pseq(Scale.minor.ratios.reverse * 401, 2),
		'amp', 0.5,
		'dur', 0.7,
		'delta', 0.25
	)
], inf).play

~seq.stop

s.quit




