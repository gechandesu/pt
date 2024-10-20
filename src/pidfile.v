module main

import os
import log

fn read_pidfile(path string) int {
	log.debug('Read PID file: ${path}')
	pid := os.read_file(os.norm_path(path)) or {
		log.error('Unable to read PID file: ${err}')
		exit(1)
	}
	return pid.i32()
}

fn write_pidfile(path string, pid int) {
	log.debug("Write PID file '${path}' for process ${pid}")
	filepath := os.norm_path(path)
	os.mkdir_all(os.dir(filepath)) or {
		log.error('Cannot create dirs ${filepath}')
		exit(1)
	}
	os.write_file(filepath, pid.str()) or {
		log.error('Cannot write PID file: ${err}')
		exit(1)
	}
}

const piddir = $d('pt_piddir', 'pt')

@[params]
struct PidfileParams {
	rundir string
	entry  string // entry.name
	path   string // entry.pidfile
}

fn get_pidfile_path(params PidfileParams) string {
	if params.path != '' {
		return params.path
	}
	return os.join_path(params.rundir, piddir, params.entry + '.pid')
}

fn get_pidfiles(rundir string) []string {
	return os.glob(os.join_path(rundir, piddir, '*.pid')) or { []string{} }
}
