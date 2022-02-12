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
	has_filter = len(bench_id) != 0 or len(record_ids) != 0 or len(tags) != 0 or len(workload) != 0

	env = Env()

	color = env.must_get('display.color') == 'true'
	width = int(env.must_get('display.width.max'))
	ids_old = env.get_ex('bench.meta.result.ids', '')

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	db = env.must_get('bench.meta.db-name')

	if not has_filter and len(ids_old) == 0:
		print('[:(] all args are empty, will be too many contents to show, skipped')
		print("     - use args 'workload' 'tags' 'record-id' 'bench-id' to match results")
		print("     - or use another command 'bench.result.ls' to list all in simple mode")
		return

	tables = my_exe(host, port, user, db, "SHOW TABLES", 'tab')
	if 'bench_meta' not in tables:
		print('[:(] bench_meta table not found')
		return

	ids = []
	if has_filter:
		ids = bench_result_select(host, port, user, db, bench_id, record_ids, tags, workload)
	ids = bench_result_merge_ids(ids_old, ids)
	baseline_id = env.get_ex('bench.meta.result.baseline-id', '')

	if len(baseline_id) == 0 and len(ids) == 0:
		print('[:(] no matched bench results')
		return
	bench_result_display(host, port, user, db, verb, ','.join(ids), color, width, baseline_id)

bench_result()
