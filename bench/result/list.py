# -*- coding: utf-8 -*-

import copy
import sys
sys.path.append('../../helper/python.helper')

from ticat import Env
from my import my_exe
from strs import colorize

def bench_result_list():
	limit = int(sys.argv[2])
	env = Env()

	color = env.must_get('display.color') == 'true'
	width = int(env.must_get('display.width.max'))

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	db = env.must_get('bench.meta.db-name')

	sub_query = 'SELECT DISTINCT(bench_id) FROM bench_meta WHERE finished=1 ORDER BY bench_id DESC LIMIT %s' % limit
	query = '''
		SELECT
			bench_id,
			id as record_id,
			run_id as begin,
			workload
		FROM bench_meta WHERE bench_id IN (%s)
		ORDER BY bench_id DESC
	''' % sub_query
	rows = my_exe(host, port, user, db, query, 'tab')
	rows.sort(key = lambda row: row[0])

	def normalize_tags(tags):
		result = []
		for tag in tags:
			result.append(tag[0])
		return result

	def normalize_kvs(kvs):
		first_section = ''
		cols = []
		for section, name, val in kvs:
			if len(first_section) == 0:
				first_section = section
			elif section != first_section:
				continue
			cols.append((name, val))
		return first_section, cols

	benchs = {}
	bench_ids = []
	for bench_id, record_id, begin, workload in rows:
		bench = []
		if bench_id in benchs:
			bench = benchs[bench_id]
		else:
			bench_ids.append(bench_id)
		query = 'SELECT tag FROM bench_tags WHERE id=\"%s\" ORDER BY display_order' % record_id
		tags = my_exe(host, port, user, db, query, 'tab')
		query = 'SELECT section, name, val FROM bench_data WHERE id=\"%s\" AND verb_level=0 ORDER BY display_order' % record_id
		kvs = my_exe(host, port, user, db, query, 'tab')
		section, kvs = normalize_kvs(kvs)
		bench.append((record_id, begin, workload, normalize_tags(tags), section, kvs))
		benchs[bench_id] = bench

	for bench_id in bench_ids:
		runs = benchs[bench_id]
		runs.sort(key = lambda run: run[0])

	indent = ' ' * 4

	def format_kvs(kvs, limit):
		cols = []
		curr_len = 0
		for name, val in kvs:
			next_len = len(name + '=' + val)
			if curr_len + next_len >= limit:
				cols.append('...')
				break
			if color:
				cols.append(colorize(0, name) + colorize(130, '=') + colorize(76, val))
			else:
				cols.append(name + '=' + val)
			curr_len += next_len + 1
		return ' '.join(cols)

	def print_line(line, c1, c2):
		if color:
			n = line.find(':')
			if n >= 0:
				line = colorize(c1, line[:n+1]) + colorize(c2, line[n+1:])
		print(line)

	for bench_id in bench_ids:
		runs = benchs[bench_id]
		print_line('[bench-id]: ' + bench_id, 202, 202)
		for record_id, begin, workload, tags, section, kvs in runs:
			print_line(indent + 'record-id: ' + record_id, 214, 214)
			print_line(indent * 2 + 'workload: ' + workload, 27, 0)
			#print_header(indent + 'begin: ' + begin)
			if len(tags) > 0:
				print_line(indent * 2 + 'tags: ' + ' '.join(tags), 27, 8)
			if len(kvs) > 0:
				prefix = indent * 2 + section + ': '
				print_line(prefix + format_kvs(kvs, width-len(prefix)), 27, 0)

bench_result_list()
