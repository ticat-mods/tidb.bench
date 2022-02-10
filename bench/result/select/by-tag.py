# -*- coding: utf-8 -*-

import sys
sys.path.append('../../../helper/python.helper')
sys.path.append('.')

from ticat import Env
from select_ids import bench_result_select
from select_ids import bench_result_update_ids_to_env

def bench_result_select_by_tag():
	tags = sys.argv[2]

	if len(tags) == 0:
		print('[:(] arg \'tag\' is empty, skipped')
		return

	env = Env()

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	db = env.must_get('bench.meta.db-name')

	ids = bench_result_select(host, port, user, db, '', '', tags, '')
	bench_result_update_ids_to_env(env, ids)

bench_result_select_by_tag()
