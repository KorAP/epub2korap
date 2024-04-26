#!/usr/bin/env bash
TESTDIR=$(dirname $0)
ASSERTSH=${TESTDIR}/assert.sh
# set -e
. ${ASSERTSH}
ERRORS=0
TEXTS=6
I5_FILE=target/dnb18.i5.xml
if [ ! -f "$I5_FILE" ]; then
  log_failure "File $I5_FILE does not exist"
  exit 1
fi


observed=$(xmlstarlet  sel --net -t -v "count(//idsText)"  $I5_FILE)

if $(assert_eq "$observed" "$TEXTS"); then
  log_success "$I5_FILE contains $TEXTS idsText elements"
else
  log_failure "$I5_FILE does not contain $TEXTS idsText elements, but: $observed"
  ((ERRORS++))
fi


observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/sourceDesc/biblStruct/monogr/h.author[normalize-space(.)])"  $I5_FILE)
if $(assert_eq "$observed" "$TEXTS"); then
  log_success "$I5_FILE contains $TEXTS non-empty h.author elements"
else
  log_failure "$I5_FILE does not contain $TEXTS non-empty h.author elements: $observed"
fi

observed=$(xmlstarlet sel --net -t -v "/idsCorpus/idsHeader/fileDesc/titleStmt/c.title" target/dnb13.i5.xml)
if $(assert_eq "$observed" "Deutsche Nationalbibliothek: Belletristik 2013"); then
  log_success "c.title contains yeaar"
else
  log_failure "c.title does not contain year: $observed"
  ((ERRORS++))
fi

observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/sourceDesc/biblStruct/monogr/h.author[contains(., '[')])"  target/dnb13.i5.xml)
if $(assert_eq "$observed" "0"); then
  log_success "authors do not contain []"
else
  log_failure "authors contain []: $observed"
  ((ERRORS++))
fi

observed=$(xmlstarlet sel --net -t -v "/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/sourceDesc/biblStruct/monogr/editor[@role='translator'][1]"  target/dnb13.i5.xml)
if $(assert_eq "$observed" "Zwack, Heinz"); then
  log_success "translator is correctly identified"
else
  log_failure "translator is not correctly identified: $observed"
  ((ERRORS++))
fi


if [ $ERRORS -gt 0 ]; then
  log_failure "There were $ERRORS errors"
  exit 1
else
  log_success "All tests passed"
fi
