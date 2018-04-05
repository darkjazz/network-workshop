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
