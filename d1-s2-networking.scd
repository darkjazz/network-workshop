// Collaborative Network Music (workshop) led by Alo Allik (alo@tehis.net) and Anna Xambó (axambo@qmul.ac.uk).
// April 7-8, 2018.
// Organized by Music Hackspace.
// Sponsored by Rewire 2018. The Hague, The Netherlands.


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

~sample = Buffer.alloc(s, 44100)

~remotesample = Buffer.alloc(~server, 44100)


SynthDef('record', {arg buffer;
	var input, rec;
	input = SoundIn.ar(0);
	rec = RecordBuf.ar(input, buffer, loop: 0, doneAction: Done.freeSelf);
}).add.send(~server);

Synth('record', ['buffer', ~sample])


SynthDef('loop-sample', {arg buffer, amp, rate;
	var sig;
	sig = PlayBuf.ar(1, buffer, rate, loop: 1) * amp;
	Out.ar(0, sig)
}).add.send(~server)


~looper = Synth('loop-sample', ['buffer', ~sample, 'amp', 0.4, 'rate', 1])

~looper.set('rate', -1.0)

~looper.free

//
// // then you can send it to someone else's computer and play it
//
// ~sample.loadToFloatArray(action: {arg array;
// 	~samplearray = array
// });
//


// make a directory for your recordings
"mkdir ~/Desktop/rewire-sounds".unixCmd

// wav or aiff
~sample.write("~/Desktop/rewire-sounds".absolutePath +/+ "sample1.aiff", "aiff", "int24")







// UPLOAD SOUNDS TO FREESOUND


// NETWORKING ACTIVITIES

// MIRLCRep library: Repurposing sounds from Freesound.org
// This library is under development, apologies for the bugs!


// make a directory for MIRLC on your Desktop
"mkdir ~/Desktop/MIRLC".unixCmd

// instantiation
~a = MIRLCRep.new
~b = MIRLCRep.new


// GET SOUNDS BY TEXT

// getsound(id=31362, size=1)
~a.id(323399)
~a.id(19246)
~a.id(19247)
~b.id(19248)
~b.id(192468)

// random(size=1)
~a.random
~a.random(2)
~a.random(3)
~b.random

// tag(tag="noise", size=1)
~a.tag("nail", 3)
~a.tag("chimes", 2)
~a.tag("noise", 2)
~a.tag("hammer", 2)
~b.tag("grain", 2)
~b.tag("humming", 3)


// GET SOUNDS BY CONTENT & GET SOUNDS BY CONTENT WITH FILTER

// content(size=1, feature = 'dur', fvalue = 1, fx = 'conf', fxvalue = 'hi')
~a.content // sounds of 1 sec of duration
~a.content(1, 'dur', 10) // sounds of 10 sec of duration
~a.content(1, 'dur', 1, 'key', 'A')
~a.content(1, 'dur', 4, 'scale', 'minor')
~a.content(1, 'dur', 1, 'conf', 'lo')
~a.content(2, 'pitch', 100, 'conf', 'lo')
~a.content(1, 'key', 'Asharp')
~a.content(5, '.lowlevel.spectral_complexity.mean:',1, 'conf', '[0 TO 0.3]') // Using directly Essentia's format
~b.content(1, 'bpm', 120)


// GET SIMILAR SOUNDS BY EXAMPLE

// similar(targetnumsnd=0, size=1)

~a.similar
~a.similar(0)
~a.similar(0, 2)
~b.similar(1)


// GET SIMILAR SOUNDS BY FILTER

// filter (targetnumsnd=0, size=1, fx = 'conf', fxvalue = 'hi')

~a.content(1, 'dur', 4, 'scale', 'minor')
~a.filter(1, 1,'conf','lo')
~a.filter(1, 1,'conf','hi')
~a.filter(2, 1,'conf','hi')

~b.content(1, 'dur', 2)
~b.filter(1, 1,'mfcc0','neg')
~b.filter(1, 1,'mfcc1','1720')
~b.filter(1, 1,'mfcc1','2040')


// ANALYZE SOUNDS BY CONTENT

~a.random(1)
~a.whatpitch
~a.content(1, 'pitch', 660)
~a.similar

~a.random(1)
~a.whatbpm
~a.content(1, 'bpm', 116)
~a.similar
~a.whatpitch
~a.content(1,'pitch', 220)


~a.analyze; // full list as it comes from the Freesound quark


// PLAYING WITH SOUNDS

~a.sequence
~a.parallel

~a.solo(4)

~a.mute(2)

~a.muteall

~a.stop

~a.play



// VISUALIZING SOUNDS

~a.plotserver // it plots all the sounds that are playing, no matter the instace
~a.printpool
~a.scope
~b.printpool
~a.printall

// Another example

~c = MIRLCRep.new
~c.content(1, 'dur', 1)
~c.content(1, 'dur', 2)
~c.content(1, 'dur', 4)
~c.content(1, 'dur', 8)

~c.sequence
~c.parallel


(

r = Routine({
    var delta;
    loop {
        delta = rrand(1, 3) * 0.5;
         if ( [false, true].choose,
			{ ~c.sequence; },
			{ ~c.parallel; }
		 );
        delta.yield;
    }
});
)
r.play


// Activities to explore with what we have learned!

// Pairs or small groups exchange

// Everyone controls central server




// Plan for performance
