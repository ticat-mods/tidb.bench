# -*- coding: utf-8 -*-

import copy
import sys
sys.path.append('../../helper/python.helper')

from my import my_exe
from strs import colorize

def _bench_result_format_one(info, verb, indent):
	indent = ' ' * indent
	id, meta, tags, sections, kvs = info

	header_lines = []
	header_lines.append('record-id: %s' % id)
	header_lines.append('workload:  %s' % meta[4])
	header_lines.append('begin:     %s' % meta[1])
	if verb > 0:
		header_lines.append('end:       %s' % meta[2])
	if verb > 3:
		header_lines.append('run-host:  %s ' % meta[3])
		header_lines.append('bench-id:  %s ' % meta[0])

	tags_lines = []
	if len(tags) != 0:
		tags_lines.append('[tags]')
		for tag in tags:
			tags_lines.append('%s%s' % (indent, tag))

	sections_lines = {}
	for i in range(0, len(sections)):
		pairs = kvs[i]
		if len(pairs) == 0:
			continue
		section = sections[i]
		section_lines = []
		section_lines.append('[%s]' % section)
		for k, v in pairs:
			section_lines.append('%s%s: %s' % (indent, k, v))
		sections_lines[section] = section_lines
	return (header_lines, tags_lines, sections, sections_lines)

def _bench_result_display_one(header_lines, tags_lines, sections, sections_lines):
	def print_line(line):
		for c in line:
			if c != ' ' and c != '|':
				print(line)
				return
	for line in header_lines:
		print_line(line)
	for line in tags_lines:
		print_line(line)
	for section in sections:
		for line in sections_lines[section]:
			print_line(line)

def _bench_result_v_align(ids, runs_lines):
	header_max = 0
	tags_max = 0
	sections_all = []
	sections_max = {}

	for id in ids:
		lines = runs_lines[id]
		header_lines, tags_lines, sections, sections_lines = lines
		if len(header_lines) > header_max:
			header_max = len(header_lines)
		if len(tags_lines) > tags_max:
			tags_max = len(tags_lines)
		for section in sections:
			if section not in sections_all:
				sections_all.append(section)
			section_lines_len = len(sections_lines[section])
			if section not in sections_max or sections_max[section] < section_lines_len:
				sections_max[section] = section_lines_len

	for id in ids:
		lines = runs_lines[id]
		header_lines, tags_lines, sections, sections_lines = lines
		while len(header_lines) < header_max:
			header_lines.append('')
		while len(tags_lines) < tags_max:
			tags_lines.append('')
		for section in sections_all:
			if section not in sections_lines:
				sections_lines[section] = []
			section_lines = sections_lines[section]
			while len(section_lines) < sections_max[section]:
				section_lines.append('')
			sections_lines[section] = section_lines
		runs_lines[id] = (header_lines, tags_lines, sections_all, sections_lines)

	return runs_lines, sections_all

class BenchResultMerging:
	def __init__(self):
		self.reset()

	def reset(self):
		self.header_lines = []
		self.tags_lines = []
		self.sections_lines = {}

	def merge(self, ids, runs_lines, indent):
		indent = ' ' * indent
		indent = indent + '|' + indent

		def _merge(dest, lines):
			if len(dest) == 0:
				for i in range(0, len(lines)):
					dest.append(lines[i])
			else:
				for i in range(0, len(lines)):
					dest[i] += indent + lines[i]
			return dest

		for id in ids:
			header_lines, tags_lines, sections, sections_lines = runs_lines[id]
			self.header_lines = _merge(self.header_lines, header_lines)
			self.tags_lines = _merge(self.tags_lines, tags_lines)
			for section in sections:
				section_lines = sections_lines[section]
				if section not in self.sections_lines:
					self.sections_lines[section] = copy.deepcopy(section_lines)
				else:
					self.sections_lines[section] = _merge(self.sections_lines[section], section_lines)

def _bench_result_merge_aligned(ids, runs_lines, sections_all, merging, color, width, indent):
	def h_padding(lines, prefix_len):
		header_lines, tags_lines, sections, sections_lines = lines
		line_max = 0
		for line in header_lines:
			if len(line) > line_max:
				line_max = len(line)
		for line in tags_lines:
			if len(line) > line_max:
				line_max = len(line)
		for section in sections:
			section_lines = sections_lines[section]
			for line in section_lines:
				if len(line) > line_max:
					line_max = len(line)
		if prefix_len + line_max > width:
			return (header_lines, tags_lines, sections, sections_lines), line_max, False
		for j in range(0, len(header_lines)):
			header_lines[j] = header_lines[j] + ' ' * (line_max - len(header_lines[j]))
		for j in range(0, len(tags_lines)):
			tags_lines[j] = tags_lines[j] + ' ' * (line_max - len(tags_lines[j]))
		for section in sections:
			section_lines = sections_lines[section]
			for j in range(0, len(section_lines)):
				section_lines[j] = section_lines[j] + ' ' * (line_max - len(section_lines[j]))
			sections_lines[section] = section_lines
		return (header_lines, tags_lines, sections, sections_lines), line_max, True

	prefix_len = 0
	for i in range(0, len(ids)):
		id = ids[i]
		lines = runs_lines[id]
		runs_lines[id], line_max, ok = h_padding(lines, prefix_len)
		if i > 0 and not ok:
			ids = ids[:i]
			break
		prefix_len += line_max + (indent * 2 + 1)

	def colorize_line(line, c1, c2, c3, c4):
		if len(line) == 0:
			return line
		if line[0] == '[':
			line = colorize(c1, line)
		else:
			n = line.find(':')
			if n < 0:
				line = colorize(c2, line)
			else:
				if line[0] != ' ':
					line = colorize(c3, line[:n+1]) + colorize(c2, line[n+1:])
				else:
					line = colorize(c4, line[:n+1]) + line[n+1:]
		return line

	def colorize_lines(lines, c1, c2, c3, c4):
		if not color:
			return lines
		for i in range(0, len(lines)):
			lines[i] = colorize_line(lines[i], c1, c2, c3, c4)
		return lines

	for id in ids:
		header_lines, tags_lines, sections, sections_lines = runs_lines[id]
		header_lines = colorize_lines(header_lines, 0, 86, 214, 0)
		tags_lines = colorize_lines(tags_lines, 27, 91, 0, 0)
		for section in sections_all:
			section_lines = sections_lines[section]
			sections_lines[section] = colorize_lines(section_lines, 27, 0, 0, 130)
		runs_lines[id] = (header_lines, tags_lines, sections, sections_lines)

	merging.merge(ids, runs_lines, indent)
	return len(ids), prefix_len - indent * 2 + 1

# TODO: support multiply client's data aggregation
def bench_result_display(host, port, user, db, verb, ids_str, color, width):
	def _bench_result_kvs_to_section(kvs):
		names = []
		lists = []
		name = ''
		for n, k, v in kvs:
			if name != n:
				name = n
				names.append(name)
				lists.append([])
			lists[-1].append((k, v))
		return (names, lists)

	ids = []
	infos = {}
	runs_lines = {}
	for id in ids_str.split(','):
		query = 'SELECT bench_id, run_id, end_ts, run_host, workload FROM bench_meta WHERE id=\"%s\"' % id
		meta = my_exe(host, port, user, db, query, 'tab')
		if len(meta) == 0:
			break
		meta = meta[0]
		query = 'SELECT tag FROM bench_tags WHERE id=\"%s\" ORDER BY display_order' % id
		tags = my_exe(host, port, user, db, query, 'tab')
		query = 'SELECT section, name, val FROM bench_data WHERE id=\"%s\" AND verb_level<=\"%s\" ORDER BY display_order' % (id, verb)
		kvs = my_exe(host, port, user, db, query, 'tab')
		sections, kvs = _bench_result_kvs_to_section(kvs)
		if len(sections) != 0:
			ids.append(id)
			info = (id, meta, tags, sections, kvs)
			infos[id] = info
			runs_lines[id] = _bench_result_format_one(info, verb, 4)

	runs_lines, sections_all = _bench_result_v_align(ids, runs_lines)

	while len(ids) > 0:
		merging = BenchResultMerging()
		merged_cnt, line_max = _bench_result_merge_aligned(ids, runs_lines, sections_all, merging, color, width, 3)
		_bench_result_display_one(merging.header_lines, merging.tags_lines, sections_all, merging.sections_lines)
		ids = ids[merged_cnt:]
		if len(ids) > 0:
			print('-' * width)

if __name__ == '__main__':
	if len(sys.argv) != 9:
		print('usage: display_ids.py host port user db verb colorize display-width session-id-list')
		sys.exit(1)
	host = sys.argv[1]
	port = sys.argv[2]
	user = sys.argv[3]
	db = sys.argv[4]
	verb = int(sys.argv[5])
	color = sys.argv[6].lower() == 'true'
	width = int(sys.argv[7])
	ids = sys.argv[8]
	bench_result_display(host, port, user, db, verb, ids, color, width)
