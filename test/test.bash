#!/bin/bash
# test.bash: back box testing for trash-cli commands
#
# Copyright (C) 2007,2008 Andrea Francia Trivolzio(PV) Italy
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  
# 02110-1301, USA.



#set -o nounset

topdir="$(pwd)/test-volume"

uid="$(python -c "import os; 
try: 
    print os.getuid()
except AttributeError: 
    print 0")"

# --- commands --------------------------------------------
_trash() {
	echo "Invoking: trash $@" >2
	../src/trash "$@"
}

_empty-trash() {
	echo "Invoking: empty-trash $@" >2
	../src/empty-trash "$@"
}

_list-trash() {
	echo "Invoking: list-trash $@" >2
	../src/list-trash "$@"
}

_restore-trash() {
	echo "Invoking: restore-trash $@" >2
	../src/restore-trash "$@"
}
# --- end of commands --------------------------------------

testPrintVersion()
{
	_trash --version
	assertEquals 0 "$?"
}

# Usage:
#   check_trashinfo <path-to-trashinfo> <expected-path>
# Description:
#   Check that the trashinfo file contains the expected information
check_trashinfo() {
        local trashinfo="$1"
        local expected_path="$2"

        assertEquals 3 "$(wc -l <$trashinfo)"

        local line1="$(sed -n '1p'< "$trashinfo")"
        local line2="$(sed -n '2p'< "$trashinfo")"
        local line3="$(sed -n '3p'< "$trashinfo")"

        assertEquals "[Trash Info]" "[Trash Info]" "$line1"
        assertEquals "Path" "Path=$expected_path" "$line2"
        assertTrue "DeletionDate" '[[ '"$line3"' == DeletionDate=????-??-??T??:??:?? ]]'
}

assert_does_not_exists() {
        local path="$1"
        assertTrue "[ ! -e \"$path\" ]" 
}

# usage:
#  assert_trashed <trashcan> <expected_content> <expected_trash_name> <expected_trashinfo_path>
assert_trashed () {
        local trashcan="$1"
        local expected_content="$2"
        local expected_trash_name="$3"
        local expected_trashinfo_path="$4"

        # check that trashcan has been created
        assertTrue "[ -d \"$trashcan\" ]"
        assertTrue "[ -d \"$trashcan/files\" ]"
        assertTrue "[ -d \"$trashcan/info\" ]"

        # check that the file has been trashed
        assertTrue "[ -e \"$trashcan/files/$expected_trash_name\" ]"
        assertTrue "[ -f \"$trashcan/info/$expected_trash_name.trashinfo\" ]"

        check_trashinfo "$trashcan/info/$expected_trash_name.trashinfo" "$expected_trashinfo_path"

        assertEquals "$expected_content" "$(<$trashcan/files/$expected_trash_name)"
}

# usage:
#   1. trash_in_home_trashcan <file>
#   2. trash_in_home_trashcan <dir>
test_trash_in_home_trashcan() {
        export XDG_DATA_HOME="./sandbox/XDG_DATA_HOME"
        local expected_trashcan="$XDG_DATA_HOME/Trash"

        file_to_trash_path=(
                sandbox/trash-test/file-to-trash
                sandbox/trash-test/other-file-to-trash
                sandbox/trash-test/file-to-trash
        )

        expected_trashid=(
                file-to-trash
                other-file-to-trash
                file-to-trash_1
        )
        
        expected_path_in_trashinfo=(
                "$(pwd)/sandbox/trash-test/file-to-trash"
                "$(pwd)/sandbox/trash-test/other-file-to-trash"
                "$(pwd)/sandbox/trash-test/file-to-trash"
        )
       
	# delete trashcan
	rm -Rf "$expected_trashcan"

        for((i=0;i<${#file_to_trash_path[@]};i++));  do 
                do_trash_test "${file_to_trash_path[$i]}" "$expected_trashcan" "${expected_trashid[$i]}" "${expected_path_in_trashinfo[$i]}"
        done 

}

# Usage:
#    create_test_file <content> <path>
create_test_file() {
        local content="$1"
        local path="$2"

        mkdir --parents "$(dirname "$path")"
        echo "$content" > "$path"
}

do_trash_test() {
        local path_to_trash="$1"
        local expected_trashcan="$2"
        local expected_trashname="$3"
        local expected_stored_path="$4"

	echo trash test informations:
	echo path_to_trash="$path_to_trash"
	echo expected_trashcan="$expected_trashcan"
	echo expected_trashname="$expected_trashname"
	echo expected_stored_path="$expected_stored_path"

	local content="$RANDOM"
        create_test_file "$content" "$path_to_trash"

        _trash "$path_to_trash"
        assertEquals 0 "$?"
        assert_does_not_exists "$path_to_trash"
        
        assert_trashed "$expected_trashcan" \
                       "$content" \
                       "$expected_trashname" \
                       "$expected_stored_path"

}

do_test_trash_in_volume_trashcan() {
	local expected_trashcan="$1"

        file_to_trash_path=(
                sandbox/trash-test/file-to-trash
                sandbox/trash-test/other-file-to-trash
                sandbox/trash-test/file-to-trash
        )

        expected_trashid=(
                file-to-trash
                other-file-to-trash
                file-to-trash_1
        )
        
        expected_path_in_trashinfo=(
                sandbox/trash-test/file-to-trash
                sandbox/trash-test/other-file-to-trash
                sandbox/trash-test/file-to-trash
        )

	# delete trashcan
	rm -Rf "$expected_trashcan"

        for((i=0;i<${#file_to_trash_path[@]};i++));  do 
                do_trash_test "$topdir/${file_to_trash_path[$i]}" "$expected_trashcan" "${expected_trashid[$i]}" "${expected_path_in_trashinfo[$i]}"
        done 
}


test_trash_in_volume_trashcans_when_Trash_does_not_exist() {
	rm -Rf $topdir/.Trash
        trashcan="$topdir/.Trash-$uid"
	do_test_trash_in_volume_trashcan "$trashcan"
}

dont_test_trash_in_volume_trashcans_when_Trash_is_not_sticky_nor_writable() {
	rm -Rf $topdir/.Trash
	mkdir --parent $topdir/.Trash
	chmod a-t $topdir/.Trash	
	chmod a-w $topdir/.Trash
	do_test_trash_in_volume_trashcan "$topdir/.Trash-$uid"
}

dont_test_trash_in_volume_trashcans_when_Trash_is_not_sticky() {
	rm -Rf $topdir/.Trash
	mkdir --parent $topdir/.Trash
	chmod a-t $topdir/.Trash	
	chmod a+w $topdir/.Trash
	do_test_trash_in_volume_trashcan "$topdir/.Trash-$uid"
}

dont_test_trash_in_volume_trashcans_when_Trash_is_not_writable() {
	rm -Rf $topdir/.Trash
	mkdir --parent $topdir/.Trash
	chmod a+t $topdir/.Trash	
	chmod a-w $topdir/.Trash
	do_test_trash_in_volume_trashcan "$topdir/.Trash-$uid"
}

test_trash_in_volume_trashcans_when_Trash_is_ok() {
	rm -Rf $topdir/.Trash
	mkdir --parent $topdir/.Trash
	chmod u+t $topdir/.Trash
	chmod a+w $topdir/.Trash
	do_test_trash_in_volume_trashcan "$topdir/.Trash/$uid"
}

prepare_volume_trashcan() {
	rm -Rf $topdir/.Trash
	mkdir --parent $topdir/.Trash
	chmod u+t $topdir/.Trash
	chmod a+w $topdir/.Trash
}

get-trashed-item-count() {
	_list-trash | wc -l
}

test_empty-trash_removes_trash() {
	prepare_volume_trashcan
	_empty-trash
	assertEquals 0 "$(_list-trash | wc -l)"

	touch "$topdir/foo" "$topdir/bar" "$topdir/zap"	
	_trash "$topdir/foo" "$topdir/bar" "$topdir/zap"	
	assertEquals 3 "$(_list-trash | wc -l)"

	_empty-trash 
	assertEquals 0 "$(_list-trash | wc -l)"
}

if [ -e $topdir/not-mounted ]; then
	echo "test volume not mounted, please run mount-test-volume.sh"
	exit 
fi 

if [ ! -e $topdir ]; then
	echo "Please choose a topdir that exists."
	exit
fi

rm -Rf $topdir/.Trash
rm -Rf $topdir/.Trash-$uid

# load shunit2
. "$(dirname "$0")/../test-lib/shunit2/src/shell/shunit2"

