import unittest

import pytest

from ..fake_trash_dir import FakeTrashDir
from ..support import MyPath
from .. import run_command


@pytest.mark.slow
class TestEndToEndList(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = MyPath.make_temp_dir()
        self.trash_dir = self.tmp_dir / 'trash-dir'
        self.fake_trash_dir = FakeTrashDir(self.trash_dir)

    def test_list(self):
        self.fake_trash_dir.add_trashinfo("/file1", '2000-01-01T00:00:01')
        self.fake_trash_dir.add_trashinfo("/file2", '2000-01-01T00:00:01')

        result = run_command.run_command(self.tmp_dir, "trash-list",
                                         ['--trash-dir', self.trash_dir])

        assert [
                   '2000-01-01 00:00:01 /file1',
                   '2000-01-01 00:00:01 /file2',
               ] == sorted(result.stdout.splitlines())

    def test_help(self):
        result = run_command.run_command(self.tmp_dir, "trash-list", ['--help'])

        self.assertEqual("""\
usage: trash-list [-h] [--version] [--trash-dir TRASH_DIRS]

List trashed files

optional arguments:
  -h, --help            show this help message and exit
  --version             show program's version number and exit
  --trash-dir TRASH_DIRS
                        specify the trash directory to use

Report bugs to https://github.com/andreafrancia/trash-cli/issues
""", result.stdout)

    def tearDown(self):
        self.tmp_dir.clean_up()