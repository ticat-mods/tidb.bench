# -*- coding: utf-8 -*-

import sys
sys.path.append('../helper/python.helper')
sys.path.append('./result')
sys.path.append('./result/select')

from ticat import Env
from my import my_exe
from select_ids import bench_result_select
from select_ids import bench_result_merge_ids
from display_ids import bench_result_display

def bench_result():
	workload = sys.argv[2]
	tags = sys.argv[3]
	verb = int(sys.argv[4])
	record_ids = sys.argv[5]
	bench_id = sys.argv[6]
	max_cnt = int(sys.argv[7])
	has_filter = len(bench_id) != 0 or len(record_ids) != 0 or len(tags) != 0 or len(workload) != 0

	env = Env()

	color = env.must_get('display.color') == 'true'
	width = int(env.must_get('display.width.max'))
	ids_old = env.get_ex('bench.meta.result.ids', '')

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	pp = env.get_ex('bench.meta.pwd', '')
	db = env.must_get('bench.meta.db-name')

	if not has_filter and len(ids_old) == 0:
		max_cnt = 1024

	my_exe(host, port, user, pp, '', "CREATE DATABASE IF NOT EXISTS %s" % db, 'tab')
	tables = my_exe(host, port, user, pp, db, "SHOW TABLES", 'tab')
	if 'bench_meta' not in tables:
		print('[:(] bench_meta table not found')
		return

	ids = []
	if has_filter:
		ids = bench_result_select(host, port, user, pp, db, bench_id, record_ids, tags, workload, max_cnt)
	ids = bench_result_merge_ids(ids_old, ids)
	baseline_id = env.get_ex('bench.meta.result.baseline-id', '')

	if len(baseline_id) == 0 and len(ids) == 0:
		if has_filter:
			print('[:(] no matched bench results')
			return
		else:
			ids = bench_result_select(host, port, user, pp, db, bench_id, record_ids, tags, workload, max_cnt)
	bench_result_display(host, port, user, pp, db, verb, ','.join(ids), color, width, baseline_id)

bench_result()
