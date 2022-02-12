# -*- coding: utf-8 -*-

import sys
sys.path.append('../../helper/python.helper')
sys.path.append('./select')

from ticat import Env
from my import my_exe
from strs import colorize
from select_ids import bench_result_select

def bench_result_list():
	workload = sys.argv[2]
	tags = sys.argv[3]
	record_ids = sys.argv[4]
	bench_id = sys.argv[5]
	max_cnt = int(sys.argv[6])

	env = Env()

	color = env.must_get('display.color') == 'true'
	width = int(env.must_get('display.width.max')) - 2

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	db = env.must_get('bench.meta.db-name')

	tables = my_exe(host, port, user, db, "SHOW TABLES", 'tab')
	if 'bench_meta' not in tables:
		print('[:(] bench_meta table not found')
		return

	ids = bench_result_select(host, port, user, db, bench_id, record_ids, tags, workload, max_cnt)
	matching_id_str = ''
	if len(ids) != 0:
		matching_id_str = ' AND id in(%s)' % ','.join(ids)

	sub_query = 'SELECT DISTINCT(bench_id) FROM bench_meta WHERE finished=1 ORDER BY bench_id DESC'
	if max_cnt > 0:
		sub_query += ' LIMIT %d' % max_cnt
	query = '''
		SELECT
			bench_id,
			id as record_id,
			run_id as begin,
			workload
		FROM
			bench_meta
		WHERE
			bench_id IN (%s)%s
		ORDER BY bench_id DESC
	''' % (sub_query, matching_id_str)
	rows = my_exe(host, port, user, db, query, 'tab')
	rows.sort(key = lambda row: row[0])

	class RunInfo:
		def __init__(self, id, begin, workload):
			self.id = id
			self.begin = begin
			self.workload = workload
			self.tags = []
			self.first_section = ''
			self.kvs = []

		def add_tag(self, tag):
			self.tags.append(tag)

		def add_kv(self, section, k, v):
			if len(self.first_section) == 0:
				self.first_section = section
			elif section != self.first_section:
				return
			self.kvs.append((k, v))

	class Bench:
		def __init__(self, bench_id):
			self.bench_id = bench_id
			self.record_ids = []
			self.runs = {}

		def add(self, record_id, begin, workload):
			if record_id in self.runs:
				return False
			self.runs[record_id] = RunInfo(record_id, begin, workload)
			self.record_ids.append(record_id)
			return True

		def get(self, record_id):
			return self.runs[record_id]

		def sort_runs(self):
			self.record_ids.sort()

	benchs = {}
	bench_ids = []
	record_ids = set()
	for bench_id, record_id, begin, workload in rows:
		if bench_id in benchs:
			bench = benchs[bench_id]
		else:
			bench = Bench(bench_id)
			benchs[bench_id] = bench
			bench_ids.append(bench_id)
		bench.add(record_id, begin, workload)
		record_ids.add(record_id)

	for bench_id in bench_ids:
		benchs[bench_id].sort_runs()

	record_ids_str = ','.join(record_ids)

	query = '''
		SELECT
			m.bench_id,
			m.id,
			t.tag
		FROM
			bench_tags AS t
		LEFT JOIN
			bench_meta AS m
		ON
			t.id = m.id
		WHERE
			t.id IN (%s)
		ORDER BY
			t.display_order
		''' % record_ids_str
	tags = my_exe(host, port, user, db, query, 'tab')
	for bench_id, record_id, tag in tags:
		benchs[bench_id].get(record_id).add_tag(tag)

	query = '''
		SELECT
			m.bench_id,
			d.id,
			d.section,
			d.name,
			d.val
		FROM
			bench_data AS d
		LEFT JOIN
			bench_meta AS m
		ON
			d.id = m.id
		WHERE
			d.id IN (%s)
		AND
			d.verb_level<=1
		ORDER BY d.display_order
	''' % record_ids_str
	kvs = my_exe(host, port, user, db, query, 'tab')
	for bench_id, record_id, section, k, v in kvs:
		benchs[bench_id].get(record_id).add_kv(section, k, v)

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
		bench = benchs[bench_id]
		print_line('[bench-id]: ' + bench_id, 202, 202)
		for id in bench.record_ids:
			run = bench.runs[id]
			print_line(indent + 'record-id: ' + run.id, 214, 214)
			print_line(indent * 2 + 'workload: ' + run.workload, 27, 0)
			#print_header(indent + 'begin: ' + run.begin)
			if len(run.tags) > 0:
				print_line(indent * 2 + 'tags: ' + ' '.join(run.tags), 27, 8)
			if len(run.kvs) > 0:
				prefix = indent * 2 + run.first_section + ': '
				print_line(prefix + format_kvs(run.kvs, width-len(prefix)), 27, 0)

bench_result_list()
