# -*- coding: utf-8 -*-

import copy
import sys
sys.path.append('../helper/python.helper')
sys.path.append('./result')

from ticat import Env
from select_ids import bench_result_select
from display_ids import bench_result_display

def bench_result():
	workload = sys.argv[2]
	tags = sys.argv[3]
	verb = int(sys.argv[4])
	record_ids = sys.argv[5]
	bench_id = sys.argv[6]

	vertical = sys.argv[7].lower()
	vertical = (vertical == 'vertical') or (vertical == 'v') or (vertical == 'true')

	env = Env()

	color = env.must_get('display.color') == 'true'
	width = int(env.must_get('display.width.max'))

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	db = env.must_get('bench.meta.db-name')

	if len(bench_id) == 0 and len(record_ids) == 0 and len(tags) == 0 and len(workload) == 0:
		print('[:(] all args are empty, skipped')
		return

	ids = bench_result_select(host, port, user, db, bench_id, record_ids, tags, workload)
	bench_result_display(host, port, user, db, verb, ','.join(ids), color, width)

bench_result()
