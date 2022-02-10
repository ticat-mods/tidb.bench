# -*- coding: utf-8 -*-

import sys
sys.path.append('../../../helper/python.helper')
sys.path.append('.')

from ticat import Env
from select_ids import bench_result_select
from select_ids import bench_result_update_ids_to_env

def bench_result_select_by_tag():
	bench_id = sys.argv[2]

	if len(bench_id) == 0:
		print('[:(] arg \'bench-id\' is empty, skipped')
		return

	env = Env()

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	db = env.must_get('bench.meta.db-name')

	ids = bench_result_select(host, port, user, db, bench_id, '', '', '')
	bench_result_update_ids_to_env(env, ids)

bench_result_select_by_tag()
