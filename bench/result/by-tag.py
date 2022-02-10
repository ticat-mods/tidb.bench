# -*- coding: utf-8 -*-

import sys
sys.path.append('../../helper/python.helper')
sys.path.append('.')
sys.path.append('./select')

from ticat import Env
from select_ids import bench_result_select
from display_ids import bench_result_display

def bench_result_by_tag():
	tags = sys.argv[2]

	if len(tags) == 0:
		print('[:(] arg \'tag\' is empty, skipped')
		return

	verb = int(sys.argv[3])

	env = Env()

	color = env.must_get('display.color') == 'true'
	width = int(env.must_get('display.width.max'))

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	db = env.must_get('bench.meta.db-name')

	ids = bench_result_select(host, port, user, db, '', '', tags, '')
	bench_result_display(host, port, user, db, verb, ','.join(ids), color, width)

bench_result_by_tag()
