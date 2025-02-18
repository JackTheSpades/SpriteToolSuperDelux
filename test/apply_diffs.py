from __future__ import annotations
from typing import Literal

class TestResult:
    sprite_id: int
    status: Literal['PASS', 'FAIL']

    def __init__(self, sprite_id: int, status: Literal['PASS', 'FAIL']):
        self.sprite_id = sprite_id
        self.status = status

    def __lt__(self, other: TestResult) -> bool:
        if self.status == 'FAIL' and other.status == 'PASS':
            return False
        elif self.status == 'PASS' and other.status == 'FAIL':
            return True
        else:
            return self.sprite_id < other.sprite_id
    
    def __eq__(self, other: TestResult) -> bool:
        return self.sprite_id == other.sprite_id and self.status == other.status
    
    def __str__(self) -> str:
        return f'{self.sprite_id} {self.status}'
    
    def __repr__(self) -> str:
        return f'TestResult({self.sprite_id}, {self.status})'
    
    @staticmethod
    def from_line(line: str) -> TestResult:
        sprite_id, status = line.split()
        return TestResult(int(sprite_id), status)

with open('EXPECTED.lst', 'r') as f:
    current_expected = [TestResult.from_line(line) for line in f]

added_diffs = []
removed_diffs = []
with open('diffs.txt', 'r') as f:
    for line in f:
        if line.startswith('+'):
            added_diffs.append(TestResult.from_line(line[1:].strip()))
        elif line.startswith('-'):
            removed_diffs.append(TestResult.from_line(line[1:].strip()))
        else:
            raise ValueError('Invalid line in diffs.txt')

for removed_diff in removed_diffs:
    if removed_diff in current_expected:
        current_expected.remove(removed_diff)

for added_diff in added_diffs:
    current_expected.append(added_diff)

current_expected.sort()

with open('EXPECTED.lst', 'w') as f:
    for test_result in current_expected:
        f.write(str(test_result) + '\n')
