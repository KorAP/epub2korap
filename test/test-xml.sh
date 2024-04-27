#!/usr/bin/env bash
TESTDIR=$(dirname $0)
ASSERTSH=${TESTDIR}/assert.sh
# set -e
. ${ASSERTSH}
ERRORS=0
PASSED=0
TEXTS=6
I5_FILE=target/dnb18.i5.xml
if [ ! -f "$I5_FILE" ]; then
  log_failure "File $I5_FILE does not exist"
  exit 1
fi


observed=$(xmlstarlet  sel --net -t -v "count(//idsText)"  $I5_FILE)
assert_eq "$observed" "$TEXTS" "$I5_FILE contains $TEXTS idsText elements"

observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/sourceDesc/biblStruct/monogr/h.author[normalize-space(.)])"  $I5_FILE)
assert_eq "$observed" "$TEXTS" "$I5_FILE contains $TEXTS non-empty h.author elements"

observed=$(xmlstarlet sel --net -t -v "/idsCorpus/idsHeader/fileDesc/titleStmt/c.title" target/dnb13.i5.xml)
assert_eq "$observed" "Deutsche Nationalbibliothek: Belletristik 2013" "c.title contains yeaar"

observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/sourceDesc/biblStruct/monogr/h.author[contains(., '[')])"  target/dnb13.i5.xml)
assert_eq "$observed" "0" "authors do not contain []"

observed=$(xmlstarlet sel --net -t -v "/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/sourceDesc/biblStruct/monogr/editor[@role='translator'][1]"  target/dnb13.i5.xml)
assert_eq "$observed" "Zwack, Heinz" "translator is correctly identified"

observed=$(grep -Ec '^Copyright' target/dnb13.i5.xml)
assert_eq "$observed" "2" "spaces at <br> elements are inserted correctly"

exit_with_test_summary


