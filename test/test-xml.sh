#!/usr/bin/env bash
TESTDIR=$(dirname $0)
ASSERTSH=${TESTDIR}/assert.sh
set -e
. ${ASSERTSH}

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
fi

observed=$(xmlstarlet sel --net -t -v "count(/idsCorpus/idsDoc/idsText/idsHeader/fileDesc/sourceDesc/biblStruct/monogr/h.author[contains(., '[')])"  target/dnb13.i5.xml)
if $(assert_eq "$observed" "0"); then
  log_success "authors do not contain []"
else
  log_failure "authors contain []: $observed"
fi