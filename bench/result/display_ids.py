# -*- coding: utf-8 -*-

# TODO: support multiply client's data aggregation

import copy
import sys
sys.path.append('../../helper/python.helper')

from my import my_exe
from strs import colorize

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
		percent = abs(baseline_v - v) * 100 / baseline_v
		percent = "%.2f" % percent
		if percent == '0.00':
			return '', False, -1
		sym = '-'
		if v > baseline_v:
			sym = '+'
		better = (gig == 1 and v > baseline_v) or (gig == 0 and v < baseline_v)
		return sym + percent + '%', True, better

	def should_show_baseline_mark(self, id):
		if id != self.my_id:
			return False
		return len(self.seen_ids) > 1

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
		header_lines.append(Line('workload:  %s' % workload))
		header_lines.append(Line('begin:     %s' % begin))
		if verb > 0:
			header_lines.append(Line('end:       %s' % end))
		if verb > 3:
			header_lines.append(Line('run-host:  %s ' % run_host))
			header_lines.append(Line('bench-id:  %s ' % bench_id))

		indent = ' ' * indent
		tags_lines = []
		if len(self.tags) != 0:
			tags_lines.append(Line('[tags]'))
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
				line = '%s%s: %s' % (indent, k, v)
				sym = ''
				cmp_str, has_cmp, better = baseline.cmp(self.id, section, k, v)
				if has_cmp:
					line += ' ' + cmp_str
					sym = cmp_str[0]
				section_lines.append(Line(line, gig, better, sym))
			sections_lines[section] = section_lines
		return (header_lines, tags_lines, self.sections, sections_lines)

class RunsLines:
	def __init__(self, ids, infos, verb, baseline, use_color, indent):
		self.ids = ids
		self.use_color = use_color
		self.runs_lines = {}
		for id in ids:
			self.runs_lines[id] = infos[id].render(verb, baseline, indent)

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
		for i in range(0, len(ids)):
			id = ids[i]
			lines = self.runs_lines[id]
			self.runs_lines[id], line_max, ok = RunsLines._h_padding(lines, width, prefix_len, min_line_max)
			if i > 0 and not ok:
				ids = ids[:i]
				break
			prefix_len += line_max + (indent * 2 + 1)

		for id in ids:
			header_lines, tags_lines, sections, sections_lines = self.runs_lines[id]
			self._colorize_lines(header_lines, 0, 86, 214, 0)
			self._colorize_lines(tags_lines, 27, 91, 0, 0)
			for section in self.sections_all:
				self._colorize_lines(sections_lines[section], 27, 0, 0, 130)
			self.runs_lines[id] = (header_lines, tags_lines, sections, sections_lines)

		merging.merge(ids, self.runs_lines, indent)
		return len(ids), prefix_len - indent * 2 + 1

	def _colorize_lines(self, lines, c1, c2, c3, c4):
		if not self.use_color:
			return lines
		for i in range(0, len(lines)):
			lines[i].colorize(c1, c2, c3, c4)

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

class BenchResultDisplay:
	def __init__(self, host, port, user, db, verb, ids_str, use_color, width, baseline_id = '', first_as_baseline = True):
		self.host = host
		self.port = port
		self.user = user
		self.db = db
		self.ids_str = ids_str
		self.use_color = use_color
		self.width = width

		self.verb = int(verb)
		if self.verb <= 0:
			self.verb = 4096

		self.first_as_baseline = first_as_baseline
		self.baseline_id = baseline_id
		if len(baseline_id) > 0:
			self.first_as_baseline = False

	def display(self):
		ids, infos, baseline = self._fetch_result()
		runs_lines = RunsLines(ids, infos, self.verb, baseline, self.use_color, 4)
		runs_lines.v_align()
		while True:
			merged, remain, line_max = runs_lines.pop_h_merged(self.width, 3)
			if merged == None:
				break
			BenchResultDisplay._display_one(merged.header_lines, merged.tags_lines, runs_lines.sections_all, merged.sections_lines)
			if remain > 0:
				#print('-' * self.width)
				print('=' * line_max)

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
		ids += self.ids_str.split(',')

		ids_dedup = []
		ids_set = set()
		for id in ids:
			id = id.strip()
			if id not in ids_set:
				ids_dedup.append(id)
				ids_set.add(id)
		ids = ids_dedup

		infos = {}
		for id in ids:
			meta = self._read_meta(id)
			if meta == None:
				break
			tags = self._read_tags(id)
			sections, kvs, cnt = self._read_sections(id)
			if self.first_as_baseline and baseline.uninited():
				baseline.set_my_id(id)
			if cnt == 0:
				continue
			baseline.add(id, sections, kvs)
			infos[id] = RunInfo(id, meta, tags, sections, kvs)

		return ids, infos, baseline

	def _read_meta(self, id):
		query = 'SELECT bench_id, run_id, end_ts, run_host, workload FROM bench_meta WHERE id=\"%s\"' % id
		meta = self._my_exe(query)
		if len(meta) == 0:
			return None
		return meta[0]

	def _read_tags(self, id):
		query = 'SELECT tag FROM bench_tags WHERE id=\"%s\" ORDER BY display_order' % id
		return self._my_exe(query)

	def _read_sections(self, id):
		query = '''
			SELECT
				section,
				name,
				val,
				greater_is_good as gig
			FROM
				bench_data
			WHERE id=\"%s\"
			AND verb_level<=\"%d\"
			ORDER BY display_order''' % (id, self.verb)
		kvs = self._my_exe(query)
		return self._kvs_to_section(kvs)

	def _kvs_to_section(self, rows):
		sections = []
		kvs = []
		section = ''
		row_cnt = 0
		for name, k, v, gig in rows:
			if section != name:
				section = name
				sections.append(section)
				kvs.append([])
			kvs[-1].append((k, v, int(gig)))
			row_cnt += 1
		return sections, kvs, row_cnt

	def _my_exe(self, query):
		return my_exe(self.host, self.port, self.user, self.db, query, 'tab')

def bench_result_display(host, port, user, db, verb, ids_str, use_color, width, baseline_id = '', first_as_baseline = True):
	tables = my_exe(host, port, user, db, "SHOW TABLES", 'tab')
	BenchResultDisplay(host, port, user, db, verb, ids_str, use_color, width, baseline_id, first_as_baseline).display()

if __name__ == '__main__':
	if len(sys.argv) != 9:
		print('usage: display_ids.py host port user db verb colorize display-width session-id-list')
		sys.exit(1)

	host = sys.argv[1]
	port = sys.argv[2]
	user = sys.argv[3]
	db = sys.argv[4]
	verb = int(sys.argv[5])
	use_color = sys.argv[6].lower() == 'true'
	width = int(sys.argv[7])
	ids = sys.argv[8]

	bench_result_display(host, port, user, db, verb, ids, use_color, width)
