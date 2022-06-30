# -*- coding: utf-8 -*-

import sys
sys.path.append('../../helper/python.helper')
sys.path.append('.')
sys.path.append('./select')

from ticat import Env
from my import my_exe
from select_ids import bench_result_select
from select_ids import bench_result_merge_ids
from display_ids import bench_result_display
from display_ids import DataTransformers

def bench_result():
	env = Env()

	verb = int(env.must_get('bench.result.display.verb'))

	agg_method = env.get_ex('bench.result.display.agg', '')
	data_transformer, ok = DataTransformers.normalize_name(agg_method)
	if not ok:
		print('[:(] value of \'aggregate-by-tag\' is \'%s\', not in %s' % (agg_method, str(DataTransformers.names())))
		sys.exit(1)

	order_list = env.get_ex('bench.result.display.order-list', '').split(',')

	color = env.must_get('display.color') == 'true'
	width = int(env.must_get('display.width.max'))

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	pp = env.get_ex('bench.meta.pwd', '')
	db = env.must_get('bench.meta.db-name')

	my_exe(host, port, user, pp, '', "CREATE DATABASE IF NOT EXISTS %s" % db, 'tab')
	tables = my_exe(host, port, user, pp, db, "SHOW TABLES", 'tab')
	if 'bench_meta' not in tables:
		print('[:(] bench_meta table not found')
		sys.exit(1)

	ids = env.get_ex('bench.meta.result.ids', '')
	baseline_id = env.get_ex('bench.meta.result.baseline-id', '')

	if len(baseline_id) == 0 and len(ids) == 0:
		print('[:(] no matched bench results')
		return

	bench_result_display(host, port, user, pp, db, verb, ids, color, width, baseline_id, max_cnt = 0, data_transformer = data_transformer, order_list = order_list)

bench_result()
