import os
import re

FEATURE_DIR = os.path.join('specs', 'working')

summary = []

for fname in sorted(os.listdir(FEATURE_DIR)):
    if not fname.endswith('.feature'):
        continue
    path = os.path.join(FEATURE_DIR, fname)
    feature_name = ''
    with open(path, encoding='utf-8') as f:
        lines = f.readlines()
    for line in lines:
        m = re.match(r'\s*Feature:\s*(.*)', line)
        if m:
            feature_name = m.group(1).strip()
            break
    i = 0
    while i < len(lines):
        line = lines[i]
        m = re.match(r'\s*Scenario(?: Outline)?:\s*(.*)', line)
        if m:
            scenario_name = m.group(1).strip()
            # find first step after scenario
            j = i + 1
            first_step = ''
            while j < len(lines):
                step_line = lines[j].strip()
                if step_line and not step_line.startswith('#'):
                    if re.match(r'^(Given|When|Then|And|But)', step_line):
                        first_step = step_line
                        break
                j += 1
            summary.append({'file': fname, 'feature': feature_name, 'scenario': scenario_name, 'step': first_step})
            i = j
        else:
            i += 1

with open('SCENARIO_SUMMARY.md', 'w', encoding='utf-8') as out:
    current_file = None
    for item in summary:
        if item['file'] != current_file:
            out.write(f"\n## {item['feature']} ({item['file']})\n")
            current_file = item['file']
        step_part = f" - {item['step']}" if item['step'] else ''
        out.write(f"- **{item['scenario']}**{step_part}\n")
print(f"Summary written with {len(summary)} scenarios")
