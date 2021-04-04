import unittest

from integration_tests.fake_trash_dir import FakeTrashDir, a_trashinfo
from trashcli.fs import read_file
from unit_tests.support import MyPath
import os
from os.path import join as pj
from os.path import exists as file_exists
from integration_tests import run_command


class TestEndToEndRestore(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = MyPath.make_temp_dir()

    def test_no_file_trashed(self):
        result = run_command.run_command(self.tmp_dir, "trash-list", ['--help'])

        self.assertEqual("""\
Usage: trash-list [OPTIONS...]

List trashed files

Options:
  --version   show program's version number and exit
  -h, --help  show this help message and exit

Report bugs to https://github.com/andreafrancia/trash-cli/issues
""", result.stdout)

    def tearDown(self):
        self.tmp_dir.clean_up()
