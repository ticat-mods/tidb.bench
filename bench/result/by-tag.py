# -*- coding: utf-8 -*-

import sys
sys.path.append('../../helper/python.helper')
sys.path.append('.')
sys.path.append('./select')

from ticat import Env
from my import my_exe
from select_ids import bench_result_select
from display_ids import bench_result_display

def bench_result_by_tag():
	tags = sys.argv[2]

	if len(tags) == 0:
		print('[:(] arg \'tag\' is empty, skipped')
		return

	verb = int(sys.argv[3])
	max_cnt = int(sys.argv[4])

	env = Env()

	color = env.must_get('display.color') == 'true'
	width = int(env.must_get('display.width.max'))

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	db = env.must_get('bench.meta.db-name')

	tables = my_exe(host, port, user, db, "SHOW TABLES", 'tab')
	if 'bench_meta' not in tables:
		print('[:(] bench_meta table not found')
		return

	ids = bench_result_select(host, port, user, db, '', '', tags, '', max_cnt)
	bench_result_display(host, port, user, db, verb, ','.join(ids), color, width)

bench_result_by_tag()
