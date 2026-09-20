import json

with open('extracted_10_questions.txt', 'r', encoding='utf-8') as f:
    lines = f.readlines()

questions = []
current_q = None
key = None

for line in lines:
    l = line.strip()
    if l.startswith('## QUESTION '):
        if current_q:
            questions.append(current_q)
        current_q = {
            'id': int(l.replace('## QUESTION ', '').strip()),
            'character': '',
            'story': '',
            'question': '',
            'badge': '',
            'visual': ''
        }
        key = None
        continue
    if not current_q:
        continue
    if l == 'Character:':
        key = 'character'
        continue
    elif l == 'Story:':
        key = 'story'
        continue
    elif l == 'Question:':
        key = 'question'
        continue
    elif l == 'Location badge:':
        key = 'badge'
        continue
    elif l == 'Visual reference:':
        key = 'visual'
        continue
    
    if key and l:
        clean = l.strip('* \t\r\n"\'“”')
        if clean:
            if current_q[key]:
                current_q[key] += ' ' + clean
            else:
                current_q[key] = clean

if current_q:
    questions.append(current_q)

with open('parsed_10_questions.json', 'w', encoding='utf-8') as f:
    json.dump(questions, f, indent=2, ensure_ascii=False)

print(f"Parsed {len(questions)} questions successfully.")
