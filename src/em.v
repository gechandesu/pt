module main

import arrays
import os
import log

struct EntryManager {
	config Config
}

fn EntryManager.new(config Config) EntryManager {
	return EntryManager{
		config: config
	}
}

fn (em EntryManager) labels() []string {
	mut labels := []string{}
	for _, val in em.config.entries {
		labels << val.labels
	}
	return arrays.uniq(labels.sorted())
}

fn (em EntryManager) by_labels(labels []string) []Entry {
	log.debug('Lookup entries by labels: ${labels}')
	mut entries := []Entry{}
	for _, val in em.config.entries {
		mut found := true
		for label in labels {
			if label !in val.labels {
				found = false
			}
		}
		if found == true {
			entries << val
		}
	}
	return entries
}

fn (em EntryManager) by_name(name string) !Entry {
	log.debug('Lookup entry: ${name}')
	return em.config.entries[name] or { error('No such entry named ${name}') }
}

fn (em EntryManager) run(entry Entry) ! {
	is_running := em.is_running(entry.name) or { false }
	if is_running {
		log.warn("Entry '${entry.name}' is already running")
		return
	}
	log.debug('Starting up entry: ${entry.name}')
	log.debug('${entry}')
	mut process := os.new_process(entry.exec[0])
	process.set_args(entry.exec[1..])
	process.set_environment(entry.env)
	process.set_work_folder(if entry.workdir == '' { os.getwd() } else { os.abs_path(entry.workdir) })
	process.run()
	pidfile := get_pidfile_path(rundir: em.config.rundir, entry: entry.name, path: entry.pidfile)
	write_pidfile(pidfile, process.pid)
}

fn (em EntryManager) signal(name string, signal os.Signal) ! {
	entry := em.by_name(name) or { return err }
	pidfile := get_pidfile_path(rundir: em.config.rundir, entry: entry.name, path: entry.pidfile)
	pid := read_pidfile(pidfile)
	send_signal(pid, signal)
}

fn (em EntryManager) processes() []Entry {
	mut pidfiles := get_pidfiles(em.config.rundir)
	for _, entry in em.config.entries {
		if entry.pidfile != '' && entry.pidfile !in pidfiles {
			pidfiles << entry.pidfile
		}
	}
	mut running_entries := []Entry{}
	for pidfile in pidfiles {
		pid := read_pidfile(pidfile)
		if os.exists(os.join_path_single('/proc', pid.str())) {
			entry_name := os.file_name(pidfile).split('.')[0]
			mut entry := em.by_name(entry_name) or { Entry{} }
			if entry.name != '' {
				entry.pid = pid
				running_entries << entry
			}
		} else {
			os.rm(pidfile) or {} // FIXME
		}
	}
	return running_entries
}

fn (em EntryManager) is_running(name string) !bool {
	entry := em.by_name(name) or { return err }
	pidfile := get_pidfile_path(rundir: em.config.rundir, entry: entry.name, path: entry.pidfile)
	if os.exists(pidfile) {
		pid := read_pidfile(pidfile)
		if os.exists(os.join_path_single('/proc', pid.str())) {
			return true
		} else {
			os.rm(pidfile) or { return err }
			return false
		}
	} else {
		return false
	}
}
