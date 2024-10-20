module main

import os
import log

#include <signal.h>

fn send_signal(pid int, signal os.Signal) {
	log.debug('Send ${signal} to process ${pid}')
	C.kill(pid, int(signal))
}

fn signal_from_string(signal string) !os.Signal {
	sig := signal.to_lower().trim_string_left('sig')
	if sig.is_int() {
		return os.Signal.from(sig.int()) or { return error('Invalid signal ${sig}') }
	} else {
		return os.Signal.from_string(sig) or { return error('Invalid signal ${sig}') }
	}
}
