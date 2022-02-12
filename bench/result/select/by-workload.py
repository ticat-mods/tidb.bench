# -*- coding: utf-8 -*-

import sys
sys.path.append('../../../helper/python.helper')
sys.path.append('.')

from ticat import Env
from strs import to_true
from my import my_exe
from select_ids import bench_result_select
from select_ids import bench_result_update_ids_to_env

def bench_result_select_by_workload():
	workload = sys.argv[2]
	as_baseline = sys.argv[3].lower()
	as_baseline = as_baseline == 'baseline' or to_true(as_baseline)

	if len(workload) == 0:
		print("[:(] arg 'workload' is empty, skipped")
		sys.exit(-1)

	env = Env()

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	db = env.must_get('bench.meta.db-name')

	tables = my_exe(host, port, user, db, "SHOW TABLES", 'tab')
	if 'bench_meta' not in tables:
		print('[:(] bench_meta table not found')
		return

	ids = bench_result_select(host, port, user, db, '', '', '', workload)
	ok = bench_result_update_ids_to_env(env, ids, as_baseline)
	if not ok:
		sys.exit(-1)

bench_result_select_by_workload()
