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
from display_ids import DataTransformers

def bench_result():
	env = Env()

	workload = env.get_ex('bench.result.filter.workload', '')
	tags = env.get_ex('bench.result.filter.tag', '')
	verb = int(env.must_get('bench.result.display.verb'))
	record_ids = env.get_ex('bench.result.filter.record-ids', '')
	bench_id = env.get_ex('bench.result.filter.session', '')
	max_cnt = int(env.must_get('bench.result.display.max'))
	has_filter = len(bench_id) != 0 or len(record_ids) != 0 or len(tags) != 0 or len(workload) != 0

	agg_method = env.get_ex('bench.result.display.agg', '')
	data_transformer, ok = DataTransformers.normalize_name(agg_method)
	if not ok:
		print('[:(] value of \'aggregate-by-tag\' is \'%s\', not in %s' % (agg_method, str(DataTransformers.names())))
		sys.exit(1)

	order_list = env.get_ex('bench.result.display.order-list', '').split(',')

	color = env.must_get('display.color') == 'true'
	width = int(env.must_get('display.width.max'))
	ids_old = env.get_ex('bench.meta.result.ids', '')

	# Mix-use is convenient but confusing, disable it
	if len(ids_old) != 0 and has_filter:
		print('[:(] after `bench.result.select.*`, `bench.result` can not have filters, exit')
		sys.exit(1)

	host = env.must_get('bench.meta.host')
	port = env.must_get('bench.meta.port')
	user = env.must_get('bench.meta.user')
	pp = env.get_ex('bench.meta.pwd', '')
	db = env.must_get('bench.meta.db-name')

	if not has_filter and len(ids_old) == 0:
		max_cnt = 1024

	my_exe(host, port, user, pp, '', "CREATE DATABASE IF NOT EXISTS %s" % db, 'tab')
	tables = my_exe(host, port, user, pp, db, "SHOW TABLES", 'tab')
	if 'bench_meta' not in tables:
		print('[:(] bench_meta table not found')
		sys.exit(1)

	# This was disabled
	ids = []
	if has_filter:
		ids = bench_result_select(host, port, user, pp, db, bench_id, record_ids, tags, workload, max_cnt)
	ids = bench_result_merge_ids(ids_old, ids)

	baseline_id = env.get_ex('bench.meta.result.baseline-id', '')

	if len(baseline_id) == 0 and len(ids) == 0:
		if has_filter:
			print('[:(] no matched bench results')
			return
		else:
			ids = bench_result_select(host, port, user, pp, db, bench_id, record_ids, tags, workload, max_cnt)
			if len(ids) == 0:
				print('[:(] no bench results')
				return

	bench_result_display(host, port, user, pp, db, verb, ','.join(ids), color, width, baseline_id, data_transformer = data_transformer, order_list = order_list)

bench_result()
