# -*- coding: utf-8 -*-

# TODO: support multiply client's data aggregation

import copy
import sys
sys.path.append('../../helper/python.helper')

from my import my_exe
from strs import to_false
from strs import to_true
from strs import colorize

def render_float_val(v):
	if v == 0:
		return '0'

	v = float(v)
	c = v
	n = 0
	while not (c >= 100 or c <= -100):
		c *= 10
		n += 1

	s = '%.*f' % (n, v)
	i = s.find('.')
	if i > 0:
		head = s[:i]
		tail = s[i+1:].rstrip('0')
		if len(tail) == 0:
			s = head
		else:
			s = head + '.' + tail
	return s

class Line:
	def __init__(self, line, gig = -1, better = -1, sym = ''):
		self.line = line
		self.colorized = line
		self.gig = gig
		self.better = better
		self.sym = sym

	def is_blank(self):
		for c in self.line:
			if c != ' ' and c != '|':
				return False
		return True

	def __len__(self):
		return len(self.line)

	def pad_to(self, to_width):
		self.line = self.line + ' ' * (to_width - len(self.line))

	def pad_tail(self, size):
		self.append(size * ' ')

	def append(self, s):
		self.line += s
		self.colorized += s

	def merge(self, line):
		self.line += line.line
		self.colorized += line.colorized

	def colorize(self, c1, c2, c3, c4):
		if len(self.line) == 0:
			return
		if self.line[0] == '[':
			self.colorized = colorize(c1, self.line)
			return
		n = self.line.find(':')
		if n < 0:
			self.colorized = colorize(c2, self.line)
			return
		head = self.line[:n+1]
		tail = self.line[n+1:]
		if self.line[0] != ' ':
			self.colorized = colorize(c3, head) + colorize(c2, tail)
			return
		if self.better < 0:
			self.colorized = colorize(c4, head) + tail
			return
		last_field_idx = self.line.rfind(self.sym)
		if self.better == 1:
			color_delta = 76 # green
		else:
			color_delta = 124 #red
		mid = self.line[n+1:last_field_idx]
		tail = self.line[last_field_idx:]
		self.colorized = colorize(c4, head) + mid + colorize(color_delta, tail)

	def display(self):
		if self.is_blank():
			return
		print(self.colorized)

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
					dest[i].append(indent)
					dest[i].merge(lines[i])
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

class Baseline:
	def __init__(self):
		self.sections = {}
		self.my_id = ''
		self.seen_ids = set()

	def uninited(self):
		return len(self.my_id) == 0

	def set_my_id(self, id):
		self.my_id = id
		self.seen_ids.add(id)

	def add(self, id, sections, kvs):
		self.seen_ids.add(id)
		if id != self.my_id:
			return
		for i in range(0, len(sections)):
			section = sections[i]
			for k, v, gig in kvs[i]:
				if section not in self.sections:
					self.sections[section] = {}
				self.sections[section][k] = (float(v), gig)

	def cmp(self, id, section, k, v):
		if self.uninited() or id == self.my_id:
			return '', False, -1
		if section not in self.sections:
			return '', False, -1
		kvs = self.sections[section]
		if k not in kvs:
			return '', False, -1

		baseline_v, gig = kvs[k]
		if gig < 0:
			return '', False, -1

		v = float(v)
		if str(baseline_v) == str(v):
			return '', False, -1

		if baseline_v == 0:
			if v > 0:
				return '+inf%', True, gig
			else:
				better = -1
				if gig == 0:
					better = 1
				elif gig == 1:
					better = 0
				return '+inf%', True, better

		# not the same direction
		if (baseline_v > 0 and v < 0) or (baseline_v < 0 and v > 0):
			return '>!<', True, -1

		percent = abs(abs(baseline_v - v) * 100 / baseline_v)
		if percent >= 100:
			percent = "%.0f" % percent
		else:
			percent = "%.2f" % percent
		if percent == '0.00':
			return '', False, -1

		if v >= 0:
			if baseline_v > 0:
				sym = '-'
				if v > baseline_v:
					sym = '+'
			else:
				sym = '+'
				if v > baseline_v:
					sym = '-'
		elif v < 0:
			sym = '+'
			if v > baseline_v:
				sym = '-'

		better = (gig == 1 and v > baseline_v) or (gig == 0 and v < baseline_v)
		return sym + percent + '%', True, better

	def should_show_baseline_mark(self, id):
		if id != self.my_id:
			return False
		return len(self.seen_ids) > 1

	@staticmethod
	def select_first_as_baseline(ids, infos):
		baseline = Baseline()
		if len(infos) == 0 or len(ids) == 0:
			return baseline
		baseline.set_my_id(ids[0])
		for id in infos:
			info = infos[id]
			baseline.add(info.id, info.sections, info.kvs)
		return baseline

class RunInfo:
	def __init__(self, id, meta, tags, sections, kvs):
		self.id = id
		self.meta = meta
		self.tags = tags
		self.sections = sections
		self.kvs = kvs

	def render(self, verb, baseline, indent):
		bench_id, begin, end, run_host, workload = self.meta

		id_line = 'record-id: %s' % self.id
		if baseline.should_show_baseline_mark(self.id):
			id_line += ' (baseline)'

		header_lines = []
		header_lines.append(Line(id_line))
		if len(workload) != 0:
			header_lines.append(Line('workload:  %s' % workload))
		if len(begin) != 0:
			header_lines.append(Line('begin:     %s' % begin))
		if verb > 1:
			if len(end) != 0:
				header_lines.append(Line('end:       %s' % end))
		if verb > 4:
			if len(run_host) != 0:
				header_lines.append(Line('run-host:  %s ' % run_host))
			if len(bench_id) != 0:
				header_lines.append(Line('session:   %s ' % bench_id))

		indent = ' ' * indent
		tags_lines = []
		if len(self.tags) != 0:
			tags_lines.append(Line('[Tags]'))
			for tag in self.tags:
				tags_lines.append(Line('%s%s' % (indent, tag)))

		sections_lines = {}
		for i in range(0, len(self.sections)):
			pairs = self.kvs[i]
			if len(pairs) == 0:
				continue
			section = self.sections[i]
			section_lines = []
			section_lines.append(Line('[%s]' % section))
			for k, v, gig in pairs:
				v = render_float_val(v)
				line = '%s%s: %s' % (indent, k, v)
				sym = ''
				cmp_str, has_cmp_str, better = baseline.cmp(self.id, section, k, v)
				if has_cmp_str:
					line += ' ' + cmp_str
					sym = cmp_str[0]
				section_lines.append(Line(line, gig, better, sym))
			sections_lines[section] = section_lines
		return (header_lines, tags_lines, self.sections, sections_lines)

class RunsLines:
	def __init__(self, ids, infos, verb, baseline, use_color, indent):
		self.use_color = use_color
		self.runs_lines = {}
		self.ids = []
		for id in ids:
			if id not in infos:
				continue
			self.runs_lines[id] = infos[id].render(verb, baseline, indent)
			self.ids.append(id)

	def _scan_lines_heights(self):
		self.header_max = 0
		self.tags_max = 0
		self.sections_all = []
		self.sections_max = {}

		for id in self.ids:
			lines = self.runs_lines[id]
			header_lines, tags_lines, sections, sections_lines = lines
			if len(header_lines) > self.header_max:
				self.header_max = len(header_lines)
			if len(tags_lines) > self.tags_max:
				self.tags_max = len(tags_lines)
			for section in sections:
				if section not in self.sections_all:
					self.sections_all.append(section)
				section_lines_len = len(sections_lines[section])
				if section not in self.sections_max or self.sections_max[section] < section_lines_len:
					self.sections_max[section] = section_lines_len

	def v_align(self):
		self._scan_lines_heights()
		for id in self.ids:
			lines = self.runs_lines[id]
			header_lines, tags_lines, sections, sections_lines = lines
			while len(header_lines) < self.header_max:
				header_lines.append(Line(''))
			while len(tags_lines) < self.tags_max:
				tags_lines.append(Line(''))
			for section in self.sections_all:
				if section not in sections_lines:
					sections_lines[section] = []
				section_lines = sections_lines[section]
				while len(section_lines) < self.sections_max[section]:
					section_lines.append(Line(''))
				sections_lines[section] = section_lines
			self.runs_lines[id] = (header_lines, tags_lines, self.sections_all, sections_lines)

	def pop_h_merged(self, width, gap):
		if len(self.ids) == 0:
			return None, 0, 0
		merging = BenchResultMerging()
		merged_cnt, line_max = self._merge_aligned_and_colorize(merging, width, gap)
		self.ids = self.ids[merged_cnt:]
		return merging, len(self.ids), line_max

	def _merge_aligned_and_colorize(self, merging, width, indent, min_line_max = 34):
		ids = self.ids
		prefix_len = 0
		max_line_max = -1
		for i in range(0, len(ids)):
			id = ids[i]
			lines = self.runs_lines[id]
			if max_line_max > 0 and max_line_max > min_line_max:
				min_line_max = max_line_max
			self.runs_lines[id], line_max, ok = RunsLines._h_padding(lines, width, prefix_len, min_line_max)

			# re-pad previous
			if max_line_max < 0:
				max_line_max = line_max
			elif line_max > max_line_max:
				delta = line_max - max_line_max
				for j in range(0, i):
					pre_id = ids[j]
					lines = self.runs_lines[pre_id]
					self.runs_lines[pre_id] = RunsLines._extend_tail_padding(lines, delta)
					prefix_len += delta
				max_line_max = line_max

			if i > 0 and not ok:
				ids = ids[:i]
				break
			prefix_len += line_max + (indent * 2 + 1)

		for id in ids:
			header_lines, tags_lines, sections, sections_lines = self.runs_lines[id]
			self._colorize_lines(header_lines, 0, 86, 214, 0)
			self._colorize_lines(tags_lines, 129, 91, 0, 0)
			for section in self.sections_all:
				self._colorize_lines(sections_lines[section], 27, 0, 0, 130)
			self.runs_lines[id] = (header_lines, tags_lines, sections, sections_lines)

		merging.merge(ids, self.runs_lines, indent)
		return len(ids), prefix_len - (indent * 2 + 1)

	def _colorize_lines(self, lines, c1, c2, c3, c4):
		if not self.use_color:
			return lines
		for i in range(0, len(lines)):
			lines[i].colorize(c1, c2, c3, c4)

	@staticmethod
	def _extend_tail_padding(lines, extend_size):
		header_lines, tags_lines, sections, sections_lines = lines
		for j in range(0, len(header_lines)):
			header_lines[j].pad_tail(extend_size)
		for j in range(0, len(tags_lines)):
			tags_lines[j].pad_tail(extend_size)
		for section in sections:
			section_lines = sections_lines[section]
			for j in range(0, len(section_lines)):
				section_lines[j].pad_tail(extend_size)
		return (header_lines, tags_lines, sections, sections_lines)

	@staticmethod
	def _h_padding(lines, width, prefix_len, min_line_max):
		header_lines, tags_lines, sections, sections_lines = lines
		line_max = min_line_max
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
			header_lines[j].pad_to(line_max)
		for j in range(0, len(tags_lines)):
			tags_lines[j].pad_to(line_max)
		for section in sections:
			section_lines = sections_lines[section]
			for j in range(0, len(section_lines)):
				section_lines[j].pad_to(line_max)

		return (header_lines, tags_lines, sections, sections_lines), line_max, True

def tags_uniq_id(workload, tags):
    return workload + ':' + ','.join(copy.deepcopy(tags))

# TODO: aggregate(use the agg method in the record) by run_host before grouping
def group_infos_by_tags(infos):
	same_tags_infos = {}
	tags_lists = {}
	workloads = {}
	for id in infos.keys():
		info = infos[id]
		_, _, _, _, workload = info.meta
		tags_id = tags_uniq_id(workload, info.tags)
		if tags_id not in same_tags_infos:
			same_tags_infos[tags_id] = []
		same_tags_infos[tags_id].append(info)
		tags_lists[tags_id] = copy.deepcopy(info.tags)
		workloads[tags_id] = workload
	tags_ids = []
	for key in same_tags_infos.keys():
		tags_ids.append(key)
	tags_ids.sort()
	return tags_ids, tags_lists, workloads, same_tags_infos

def data_transformer_agg(infos, agg_class):
	class SectionKvs:
		def __init__(self, section):
			self.section = section
			self.keys = []
			self.gigs = []
			self.vals = {}
		def on_kvs(self, kvs):
			for k, v, gig in kvs:
				if k not in self.keys:
					self.keys.append(k)
					self.gigs.append(gig)
					self.vals[k] = agg_class()
				self.vals[k].on_val(float(v))
		def final(self):
			kvs = []
			for i in range(0, len(self.keys)):
				key = self.keys[i]
				kvs.append((key, self.vals[key].final(), self.gigs[i]))
			return kvs

	tags_ids, tags_lists, workloads, same_tags_infos = group_infos_by_tags(infos)
	new_ids = []
	new_infos = {}

	for i in range(0, len(tags_ids)):
		tags_id = tags_ids[i]
		infos = same_tags_infos[tags_id]
		if len(infos) == 0:
			continue
		workload = workloads[tags_id]
		new_id = 'v' + str(i)
		new_meta = ('', '', '', '', workload)
		new_tags = tags_lists[tags_id]

		new_sections = []
		new_sections_kvs = {}
		for info in infos:
			for j in range(0, len(info.sections)):
				section = info.sections[j]
				kvs = info.kvs[j]
				if section not in new_sections:
					new_sections_kvs[section] = SectionKvs(section)
					new_sections.append(section)
				new_sections_kvs[section].on_kvs(kvs)
		if len(new_sections) == 0:
			continue
		new_kvs = []
		for section in new_sections:
			new_section_kvs = new_sections_kvs[section]
			new_kvs.append(new_section_kvs.final())

		agg_kvs = [(agg_class.name() + '.count', str(len(infos)), -1)]
		new_kvs.insert(0, agg_kvs)
		new_sections.insert(0, 'AggregateInfo')

		info = RunInfo(new_id, new_meta, new_tags, new_sections, new_kvs)
		new_infos[new_id] = info
		new_ids.append(new_id)

	baseline = Baseline.select_first_as_baseline(new_ids, new_infos)
	return new_ids, new_infos, baseline

def data_transformer_agg_avg(ids, infos, baseline):
	class Avg:
		@staticmethod
		def name():
			return 'avg'
		def __init__(self):
			self.cnt = 0
			self.sum = 0.0
		def on_val(self, val):
			self.cnt += 1
			self.sum += val
		def final(self):
			return self.cnt != 0 and self.sum / self.cnt or 0.0
	return data_transformer_agg(infos, Avg)

def data_transformer_agg_natural(ids, infos, baseline):
	raise Exception('TODO: impl')

def data_transformer_none(ids, infos, baseline):
	return ids, infos, baseline

class DataTransformers:
	@staticmethod
	def agg_names():
		return ['', 'avg', 'natural']

	@staticmethod
	def formal_names():
		return ['none', 'agg.avg', 'agg.natural']

	@staticmethod
	def normalize_name(name):
		if len(name) == 0 or to_false(name):
			name = 'none'
		elif to_true(name):
			name = 'agg.avg'
		elif name == 'average' or name == 'avg':
			name = 'agg.avg'
		elif name == 'nature':
			name = 'agg.natural'
		return name, name in DataTransformers.formal_names()

	@staticmethod
	def from_name(name):
		return {
			'none': data_transformer_none,
			'agg.avg': data_transformer_agg_avg,
			'agg.natural': data_transformer_agg_natural,
		}[name]

class BenchResultDisplay:
	def __init__(self, host, port, user, pp, db, verb, ids_str, use_color, width, baseline_id, first_as_baseline, max_cnt, data_transformer_name, order_list):
		self.host = host
		self.port = port
		self.user = user
		self.pp = pp
		self.db = db
		self.ids_str = ids_str
		self.use_color = use_color
		self.width = width
		self.max_cnt = max_cnt
		self.data_transformer = DataTransformers.from_name(data_transformer_name)
		self.order_list = order_list

		self.verb = int(verb)
		if self.verb <= 0:
			self.verb = 4096

		self.first_as_baseline = first_as_baseline
		self.baseline_id = baseline_id
		if len(baseline_id) > 0:
			self.first_as_baseline = False

	def display(self, h_sep = '='):
		ids, infos, baseline = self._fetch_result()
		ids, infos, baseline = self.data_transformer(ids, infos, baseline)
		ids, infos, baseline = self.reorder_by_id_list(ids, infos, baseline)
		runs_lines = RunsLines(ids, infos, self.verb, baseline, self.use_color, 4)
		runs_lines.v_align()
		while True:
			merged, remain, line_max = runs_lines.pop_h_merged(self.width, 3)
			if merged == None:
				break
			BenchResultDisplay._display_one(merged.header_lines, merged.tags_lines, runs_lines.sections_all, merged.sections_lines)
			if remain > 0:
				print(h_sep * line_max)

	def reorder_by_id_list(self, ids, infos, baseline):
		if len(self.order_list) == 0 or len(ids) == 0:
			return ids, infos, baseline
		new_ids = []
		for id in self.order_list:
			if id not in infos:
				continue
			new_ids.append(id)
			ids.remove(id)
		if len(new_ids) != 0 and new_ids[0] != baseline.my_id:
			baseline = Baseline.select_first_as_baseline(self.order_list, infos)
		return new_ids + ids, infos, baseline

	@staticmethod
	def _display_one(header_lines, tags_lines, sections, sections_lines):
		for line in header_lines:
			line.display()
		for line in tags_lines:
			line.display()
		for section in sections:
			for line in sections_lines[section]:
				line.display()

	def _fetch_result(self):
		ids = []
		baseline = Baseline()
		if len(self.baseline_id) > 0:
			baseline.set_my_id(self.baseline_id)
			ids.append(self.baseline_id)
		if len(self.ids_str) > 0:
			new_ids = self.ids_str.split(',')
			for id in new_ids:
				try:
					id = str(int(id))
				except ValueError:
					# TODO: print warning
					continue
				ids.append(id)

		ids_dedup = []
		ids_set = set()
		for id in ids:
			id = id.strip()
			if id not in ids_set:
				ids_dedup.append(id)
				ids_set.add(id)
		ids = ids_dedup[len(ids_dedup)-self.max_cnt:]

		metas_map = self._read_meta(ids)
		tags_map = self._read_tags(ids)
		runs_map = self._read_sections(ids)

		infos = {}
		for id in ids:
			if id not in metas_map:
				continue
			meta = metas_map[id]
			if id not in tags_map:
				tags = []
			else:
				tags = tags_map[id]
			if id not in runs_map:
				continue
			run_sections = runs_map[id]
			if run_sections.kv_cnt <= 0:
				continue
			if self.first_as_baseline and baseline.uninited():
				baseline.set_my_id(id)
			baseline.add(id, run_sections.sections, run_sections.kvs)
			infos[id] = RunInfo(id, meta, tags, run_sections.sections, run_sections.kvs)

		return ids, infos, baseline

	def _read_meta(self, ids):
		metas_map = {}
		if len(ids) == 0:
			return metas_map
		query = '''
			SELECT DISTINCT
				id,
				bench_id,
				run_id,
				end_ts,
				run_host,
				workload
			FROM
				bench_meta
			WHERE
				id IN (%s)
			AND
				finished=1
		''' % ','.join(ids)
		rows = self._my_exe(query)
		for id, bench_id, begin, end, run_host, workload in rows:
			assert(id not in metas_map)
			metas_map[id] = (bench_id, begin, end, run_host, workload)
		return metas_map

	def _read_tags(self, ids):
		tags_map = {}
		if len(ids) == 0:
			return tags_map
		query = '''
			SELECT
				id,
				tag
			FROM
				bench_tags
			WHERE
				id IN (%s)
			ORDER BY
				display_order
		''' % ','.join(ids)
		rows = self._my_exe(query)
		for id, tag in rows:
			if id not in tags_map:
				tags_map[id] = []
			tags_map[id].append(tag)
		return tags_map

	def _read_sections(self, ids):
		runs_map = {}
		if len(ids) == 0:
			return runs_map
		query = '''
			SELECT
				id,
				section,
				name,
				val,
				greater_is_good AS gig
			FROM
				bench_data
			WHERE
				id IN (%s)
			AND
				verb_level<=%d
			ORDER BY
				display_order
			''' % (','.join(ids), self.verb)
		rows = self._my_exe(query)

		class RunSections:
			def __init__(self):
				# [section-0, section-1, ...]
				self.sections = []
				# [[kvs-0], [kvs-1], ...]
				self.kvs = []
				self.kv_cnt = 0

			def add(self, section, k, v, gig):
				if section not in self.sections:
					self.sections.append(section)
					self.kvs.append([])
				self.kvs[-1].append((k, v, int(gig)))
				self.kv_cnt += 1

		for id, section, k, v, gig in rows:
			if id not in runs_map:
				runs_map[id] = RunSections()
			runs_map[id].add(section, k, v, gig)
		return runs_map

	def _my_exe(self, query):
		return my_exe(self.host, self.port, self.user, self.pp, self.db, query, 'tab')

def bench_result_display(host, port, user, pp, db, verb, ids_str, use_color, width, baseline_id = '', first_as_baseline = True, max_cnt = 32, data_transformer = 'none', order_list = ''):
	tables = my_exe(host, port, user, pp, db, "SHOW TABLES", 'tab')
	BenchResultDisplay(host, port, user, pp, db, verb, ids_str, use_color, width, baseline_id, first_as_baseline, max_cnt, data_transformer, order_list).display()

if __name__ == '__main__':
	sys.stderr.write('XX'+ids+'\n')

	if len(sys.argv) != 10:
		print('usage: display_ids.py host port user pwd db verb colorize display-width session-id-list')
		sys.exit(1)

	host = sys.argv[1]
	port = sys.argv[2]
	user = sys.argv[3]
	pp = sys.argv[4]
	db = sys.argv[5]
	verb = int(sys.argv[6])
	use_color = to_true(sys.argv[7].lower())
	width = int(sys.argv[8])
	ids = sys.argv[9]

	bench_result_display(host, port, user, pp, db, verb, ids, use_color, width)
