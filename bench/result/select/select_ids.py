# -*- coding: utf-8 -*-

import sys
sys.path.append('../../helper/python.helper')

from my import my_exe

def bench_result_select(host, port, user, db, bench_id, record_ids, tags, workload):
	def query_by_tags(tags):
		assert(len(tags) > 0)
		for i in range(1, len(tags)):
			tags[i] = tags[i].strip()

		query = 'SELECT DISTINCT t1.id as id from bench_tags AS t1'
		join = ''
		where = ' WHERE t1.tag="%s"' % tags[0]
		for i in range(1, len(tags)):
			table = 't' + str(i + 1)
			join += ' INNER JOIN bench_tags AS %s ON t1.id=%s.id' % (table, table)
			where += ' AND %s.tag="%s"' % (table, tags[i])
		return query + join + where

	where = ''

	if len(bench_id) != 0:
		where += 'bench_id=\"%s\"' % bench_id

	if len(workload) != 0:
		if len(where) != 0:
			where += ' AND '
		where += 'workload=\"%s\"' % workload

	if len(record_ids) != 0:
		array = []
		for it in record_ids.split(','):
			it = it.strip()
			if len(it) != 0:
				array.append('\"' + it + '\"')
		if len(array) != 0:
			if len(where) != 0:
				where += ' AND '
			where += 'id IN (%s)' % ', '.join(array)
	if len(tags) != 0:
		if len(where) != 0:
			where += ' AND '
		where += 'id IN (%s)' % query_by_tags(tags.strip().split(','))

	if len(where) > 0:
		where = ' WHERE ' + where
	query = 'SELECT id FROM bench_meta' + where
	return my_exe(host, port, user, db, query, 'tab')

def bench_result_merge_ids(ids_old_str, ids):
	if len(ids_old_str) == 0:
		return ids
	ids_old = ids_old_str.split(',')
	for id in ids:
		if id not in ids_old:
			ids_old.append(id)
	return ids_old

def bench_result_update_ids_to_env(env, ids, as_baseline):
	if len(ids) == 0:
		return True

	if as_baseline:
		key = 'bench.meta.result.baseline-id'
		if len(ids) > 1:
			print('[:(] select more than one id as baseline, skipped')
			return False
	else:
		key = 'bench.meta.result.ids'

	ids_old = env.get_ex(key, '')
	if as_baseline and len(ids_old) != 0:
		print('[:(] has previous selected baseline, skipped')
		return False

	ids = bench_result_merge_ids(ids_old, ids)
	ids_str = ','.join(ids)
	env.set(key, ids_str)
	env.flush()
	print(key + '=' + ids_str)
	return True
