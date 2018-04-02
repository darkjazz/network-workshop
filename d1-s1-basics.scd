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


~server = Server(
	"remote",
	NetAddr(
		"192.168.1.102",
		57110
	)
)


SynthDef('crackle', {arg param;
	Out.ar(0, Crackle.ar(param))
}).send(~server);


~crackle = Synth('crackle', ['param', 1.0], ~server)

~crackle.set('param', 1.97)

~crackle.free


SynthDef('tone', {arg freq, amp, dur;
	var sig;
	sig = LFSaw.ar(freq, mul: amp) * Line.kr(1, 0, dur, doneAction: 2);
	Out.ar(0, sig)
}).send(~server)

Pbind(
	'instrument', 'tone',
	'server', Prand([~server, s], 7),
	'freq', Pseq(Scale.minor.ratios * 101),
	'amp', 0.3,
	'dur', 0.4
).play





/*
DAY 1 SESSION 1: SUPERCOLLIDER BASICS
----------------------------------------------------------
*/




/* NETWORK
YOU CAN ALSO SEND MESSAGES TO ANOTHER CLIENT
IF THE CLIENT KNOWS HOW TO RECEIVE IT
YOU CAN CHAT MESSAGES
*/

~client = NetAddr("192.168.1.102", 57120)

~client.sendMsg("/chat", "alo", "hello let's make some noise :)")

OSCdef('chat', {arg message;
	Post << "#" << message[1] << ": " << message[2] << Char.nl
}, "/chat")



/*
OR IF YOU HAVE A WINDOW FOR YOUR COLLABORATORS CODE
IT CAN BE AUTOMATICALLY POSTED IN THERE
*/

~codedoc = Document.allDocuments.select({arg doc; doc.name == "send-me-code.scd"}).first

OSCdef('code', {arg message;
	~codedoc.string = " /*from " ++ message[1] ++ "*/ " ++ Char.nl.asString ++ message[2] ++ Char.nl.asString;
	~codedoc.front;
}, "/code")



~mycode = SynthDef('tone', {arg freq, amp, dur;
	var sig;
	sig = LFSaw.ar(freq, mul: amp) * Line.kr(1, 0, dur, doneAction: 2);
	Out.ar(0, sig)
}).asCompileString

~client.sendMsg("/chat", "alo", ~mycode)


/*
OR EXECUTED
*/

~mycode = "Tdef('loop', {
	100.do({
		SynthDef('racket', {
			Out.ar(0, PMOsc.ar(rrand(30, 60), rrand(100, 200), 10.rand)
				* Line.kr(0.3.rand, 0, rrand(0.3, 1.0), doneAction: 2))
		}).play;
		rrand(0.2, 0.6).wait;
	})
}).play";

~client.sendMsg("/run", ~mycode)

OSCdef('run', { arg message;
	message[1].asString.compile.()
}, '/run')






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

// SYNTHESIS



// SEQUENCING
