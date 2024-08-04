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
assert_eq "$observed" "Deutsche Nationalbibliothek: Belletristik 2013 (DeLiKo@DNB)" "c.title contains year and DeLiKo@DNB"

observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/sourceDesc/biblStruct/monogr/h.author[contains(., '[')])"  target/dnb13.i5.xml)
assert_eq "$observed" "0" "authors do not contain []"

observed=$(xmlstarlet sel --net -t -v "/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/sourceDesc/biblStruct/monogr/editor[@role='translator'][1]"  target/dnb13.i5.xml)
assert_eq "$observed" "Zwack, Heinz" "translator is correctly identified"

observed=$(grep -Ec '^Copyright' target/dnb13.i5.xml)
assert_eq "$observed" "2" "spaces at <br> elements are inserted correctly"

observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/profileDesc/textDesc/textType[contains(., 'Arztroman')])"  target/dnb18.i5.xml)
assert_gt "$observed" "0" "at least one textType contains 'Arztroman'"

observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/profileDesc/textDesc/textType[normalize-space(.)=''])"  target/dnb18.i5.xml)
assert_eq "$observed" "0" "no empty textType elements"

observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/profileDesc/textDesc/textTypeRef[normalize-space(.)=''])"  target/dnb18.i5.xml)
assert_eq "$observed" "0" "no empty textTypeRef elements"

min_expected=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText)"  target/dnb18.i5.xml)
observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/publicationStmt/idno)"  target/dnb18.i5.xml)
assert_gt "$observed" "$min_expected" "exvery text has more than one idno element"

observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/publicationStmt/idno[@type='URN'])"  target/dnb18.i5.xml)
assert_eq "$observed" "$min_expected" "exvery text has one idno element of type URN"

observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/publicationStmt/idno[@type='URL' and starts-with(@rend, 'URN;urn:nbn:de:')])"  target/dnb18.i5.xml)
assert_eq "$observed" "$min_expected" "for every idno element of type URN, there is also an URL element with @rend starting with 'URN;urn:nbn:de:'"

observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/sourceDesc/biblStruct/note[@type='award'][@subtype='Deutscher Buchpreis 2024'])"  target/dnb13.i5.xml)
assert_eq "$observed" "1" "award is correctly identified'"

observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/sourceDesc/biblStruct/note[@type='award'])"  target/dnb18.i5.xml)
assert_eq "$observed" "0" "no falsely identified awards'"

exit_with_test_summary


