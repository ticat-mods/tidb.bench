# -*- coding: utf-8 -*-

import sys
sys.path.append('../../../helper/python.helper')
sys.path.append('../../../helper/ticat.helper')
sys.path.append('.')

from ticat import Env
from my import my_exe
from select_ids import bench_result_update_ids_to_env

def bench_result_select_last():
	env = Env()

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	db = env.must_get('bench.meta.db-name')

	query = 'SELECT MAX(bench_id) as bench_id FROM bench_meta WHERE finished=1'
	bench_ids = my_exe(host, port, user, db, query, 'tab')
	if len(bench_ids) == 0:
		print('[:(] no bench result found')
		return

	query = 'SELECT id FROM bench_meta WHERE bench_id="%s"' % bench_ids[0]
	ids = my_exe(host, port, user, db, query, 'tab')
	if len(ids) == 0:
		print('[:(] no bench result found')
		return

	bench_result_update_ids_to_env(env, ids)

bench_result_select_last()
