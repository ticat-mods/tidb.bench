# -*- coding: utf-8 -*-

import sys
sys.path.append('../../../helper/python.helper')
sys.path.append('../../../helper/ticat.helper')
sys.path.append('.')

from ticat import Env
from strs import to_true
from my import my_exe
from select_ids import bench_result_update_ids_to_env

def bench_result_select_last():
	as_baseline = sys.argv[2].lower()
	as_baseline = as_baseline == 'baseline' or to_true(as_baseline)

	env = Env()

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	pp = env.get_ex('bench.meta.pwd', '')
	db = env.must_get('bench.meta.db-name')

	tables = my_exe(host, port, user, pp, db, "SHOW TABLES", 'tab')
	if 'bench_meta' not in tables:
		print('[:(] bench_meta table not found')
		return

	query = 'SELECT MAX(bench_id) as bench_id FROM bench_meta WHERE finished=1'
	bench_ids = my_exe(host, port, user, pp, db, query, 'tab')
	if len(bench_ids) == 0:
		print('[:(] no bench result found')
		return

	query = 'SELECT id FROM bench_meta WHERE bench_id="%s"' % bench_ids[0]
	ids = my_exe(host, port, user, pp, db, query, 'tab')
	if len(ids) == 0:
		print('[:(] no bench result found')
		return

	ok = bench_result_update_ids_to_env(env, ids, as_baseline)
	if not ok:
		sys.exit(-1)

bench_result_select_last()
