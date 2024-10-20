module main

import os
import log
import maps
import toml { Any }

pub struct Entry {
mut:
	name string
	pid  int @[json: '-']
pub mut:
	exec        []string
	env         map[string]string
	pidfile     string
	workdir     string
	labels      []string
	description string
}

pub struct Config {
pub mut:
	rundir  string
	include []string
	entries map[string]Entry
}

pub fn (mut c Config) from_toml(any Any) {
	all := any.as_map()
	c.rundir = all.value('rundir').default_to(runtime_dir).string()
	c.include = all.value('include').default_to([]Any{}).array().as_strings()
	entries := all['entry'] or { Any(map[string]Any{}) }.as_map()
	for k, v in entries {
		entry := {
			k: Entry{
				name:        k
				exec:        v.as_map().value('exec').default_to([]Any{}).array().as_strings()
				env:         v.as_map().value('env').default_to(map[string]Any{}).as_map().as_strings()
				pidfile:     v.as_map().value('pidfile').default_to('').string()
				workdir:     v.as_map().value('workdir').default_to('').string()
				labels:      v.as_map().value('labels').default_to([]Any{}).array().as_strings()
				description: v.as_map().value('description').default_to('').string()
			}
		}
		maps.merge_in_place(mut c.entries, entry)
	}
}

const runtime_dir = get_runtime_dir()

fn get_runtime_dir() string {
	return os.getenv_opt('XDG_RUNTIME_DIR') or {
		if os.geteuid() == 0 {
			if os.exists('/run') {
				return '/run'
			} else {
				return '/var/run'
			}
		}
		dir := os.temp_dir()
		log.warn('XDG_RUNTIME_DIR is unset, fallback to ${dir} for PID-files')
		return dir
	}
}

fn load_config(config_path string) Config {
	filepath := os.abs_path(os.expand_tilde_to_home(os.norm_path(config_path)))
	mut conf := Config{}
	return load_config_recursively(mut conf, 0, filepath)
}

const max_recursion_depth = $d('pt_max_recursion_depth', 10)

fn load_config_recursively(mut conf Config, recursion_depth int, file string) Config {
	mut recursion := recursion_depth + 1
	if recursion > max_recursion_depth {
		log.warn('Max recursion depth reached, ${file} is not loaded')
		return conf
	}
	log.debug('Loading config file ${file}')
	text := os.read_file(file) or {
		log.error('Unable to read file ${file}: ${err}')
		exit(1)
	}
	loaded := toml.decode[Config](text) or {
		log.error('Unable to parse config file ${file}: ${err}')
		exit(1)
	}
	if recursion == 1 {
		conf.rundir = loaded.rundir // disallow rundir overriding
	}
	conf.include = loaded.include
	maps.merge_in_place(mut conf.entries, loaded.entries)
	if conf.include.len != 0 {
		mut matched_files := []string{}
		old_cwd := os.getwd()
		os.chdir(os.dir(file)) or {}
		for glob in conf.include {
			matched_files << os.glob(os.expand_tilde_to_home(glob)) or { [] }
		}
		for filepath in matched_files {
			if os.is_dir(filepath) {
				continue
			}
			conf = load_config_recursively(mut conf, recursion, os.abs_path(filepath))
		}
		os.chdir(old_cwd) or {}
	}
	return conf
}
