module main

import os
import log
import cli { Command, Flag }
import x.json2 as json

const default_config_file = $d('pt_default_config_file', '~/.ptrc')

fn init(cmd Command) Config {
	debug := cmd.flags.get_bool('debug') or { false }
	config := cmd.flags.get_string('config') or { default_config_file }
	if debug {
		log.set_level(.debug)
	}
	return load_config(config)
}

fn root_command(cmd Command) ! {
	println(cmd.help_message())
}

fn ls_command(cmd Command) ! {
	conf := init(cmd)
	output := cmd.flags.get_string('output')!
	match output {
		'json' {
			mut entries := []Entry{}
			for _, val in conf.entries {
				entries << val
			}
			println(json.encode[[]Entry](entries))
		}
		'brief' {
			for key, _ in conf.entries {
				println(key)
			}
		}
		else {
			for key, val in conf.entries {
				println('${key:-24}${val.description:01}')
			}
		}
	}
}

fn start_command(cmd Command) ! {
	conf := init(cmd)
	em := EntryManager.new(conf)
	labels := cmd.flags.get_strings('label') or { []string{} }
	mut code := 0
	if labels.len > 0 {
		if cmd.args.len > 0 {
			log.warn('Positional arguments are ignored: ${cmd.args}')
		}
		for entry in em.by_labels(labels) {
			em.run(entry) or {
				log.error(err.str())
				code = 1
			}
		}
	} else if cmd.args.len > 0 {
		for arg in cmd.args {
			entry := em.by_name(arg) or {
				log.error(err.str())
				code = 1
				continue
			}
			em.run(entry) or {
				log.error(err.str())
				code = 1
				continue
			}
		}
	}
	exit(code)
}

fn ps_command(cmd Command) ! {
	conf := init(cmd)
	em := EntryManager.new(conf)
	entries := em.processes()
	println('PID         NAME')
	for entry in entries {
		println('${entry.pid:-12}${entry.name}')
	}
}

fn signal_command(cmd Command) ! {
	conf := init(cmd)
	em := EntryManager.new(conf)
	if cmd.args.len < 2 {
		println(cmd.help_message())
	}
	sig := signal_from_string(cmd.args[0]) or {
		log.error(err.str())
		exit(2)
	}
	for entry in cmd.args[1..] {
		em.signal(entry, sig) or {
			log.error(err.str())
			exit(1)
		}
	}
}

fn labels_command(cmd Command) ! {
	conf := init(cmd)
	em := EntryManager.new(conf)
	for label in em.labels().sorted() {
		println(label)
	}
}

fn stop_command(cmd Command) ! {
	conf := init(cmd)
	em := EntryManager.new(conf)
	for entry in cmd.args {
		em.signal(entry, .term) or {
			log.error(err.str())
			exit(1)
		}
	}
}

fn main() {
	mut app := Command{
		name:          'pt'
		execute:       root_command
		version:       $d('pt_version', '0.0.0')
		sort_commands: true
		defaults:      struct {
			man: false
		}
		flags:         [
			Flag{
				flag:          .string
				name:          'config'
				abbrev:        'c'
				description:   'Config file path.'
				global:        true
				default_value: [default_config_file]
			},
			Flag{
				flag:        .bool
				name:        'debug'
				description: 'Enable debug logs.'
				global:      true
			},
		]
		commands:      [
			Command{
				name:        'ls'
				execute:     ls_command
				description: 'List defined command entries.'
				flags:       [
					Flag{
						flag:        .string
						name:        'output'
						abbrev:      'o'
						description: 'Set output format [text, json, brief].'
					},
				]
			},
			Command{
				name:        'start'
				usage:       '[<entry>]...'
				execute:     start_command
				description: 'Start entries by name or label.'
				flags:       [
					Flag{
						flag:        .string_array
						name:        'label'
						abbrev:      'l'
						description: 'Select entries by label. Can be multiple.'
					},
				]
			},
			Command{
				name:        'ps'
				execute:     ps_command
				description: 'Print running entries list.'
			},
			Command{
				name:        'signal'
				usage:       '<SIGNAL> <entry> [<entry>]...'
				execute:     signal_command
				description: 'Send OS signal to running entry.'
			},
			Command{
				name:        'labels'
				execute:     labels_command
				description: 'List all entry labels.'
			},
			Command{
				name:        'stop'
				usage:       '[<entry>]...'
				execute:     stop_command
				description: 'Stop entries.'
			},
		]
	}
	app.setup()
	app.parse(os.args)
}
