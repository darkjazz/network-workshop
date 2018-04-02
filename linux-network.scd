~s_port = 57110
~rpi = Server("pi", NetAddr("192.168.1.101", ~s_port))
~anrita = Server("anrita", NetAddr("192.168.1.100", ~s_port))


SynthDef("dusty", {|freq, amp, pulse|
	var sig;
	sig = Dust2.ar(freq, LFPulse.kr(pulse, 0, 0.5, 0.5, 0.5));
	Out.ar(0, Pan2.ar(sig, LFNoise0.kr(pulse), amp))
}).send(~rpi)


SynthDef("sawy", {|freq, amp, pulse|
	var sig;
	sig = LFSaw.ar(Select.kr(TIRand.kr(0, 2, Impulse.kr(pulse), [freq, freq/2, freq*1.5]), 0, LFPulse.kr(pulse, 0, 0.5, 0.5, 0.5));
	Out.ar(0, Pan2.ar(sig, LFNoise0.kr(pulse), amp))
}).send(~rpi)

~synth = Synth("dusty", ['freq', 100, 'amp', 0.1, 'pulse', 2.0], ~rpi)

~synth.set('amp', 1.0, 'freq', 2001, 'pulse', 2.0)

~synth.freeL


~anrita = Server("anrita", NetAddr("192.168.1.100", ~s_port))

SynthDef("sawy", {|freq, amp, pulse|
	var sig;
	sig = LFSaw.ar(Select.kr(TIRand.kr(0, 2, Impulse.kr(pulse)), [freq, freq*6/5, freq*1.5]), 0, LFPulse.kr(pulse, 0, 0.5, 0.5, 0.5));
	Out.ar(0, Pan2.ar(sig, LFNoise0.kr(pulse), amp))
}).send(~anrita)



~syn_an_1 = Synth("sawy", ['freq', 100, 'amp', 0.1, 'pulse', 3.0], ~anrita)

~syn_an_2 = Synth("sawy", ['freq', 50, 'amp', 0.1, 'pulse', 3.0], ~anrita)


~syn_an_1.free

~syn_an_2.free