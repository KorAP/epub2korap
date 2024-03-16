SRC_DIR ?= test/resources/DNB
BUILD_DIR = build
TARGET_DIR ?= target

.PHONY: all clean test krill

.PRECIOUS: %.zip $(TARGET_DIR)/%.zip $(TARGET_DIR)/%.i5.xml $(TARGET_DIR)/%.tar

all: $(TARGET_DIR)/dnb.i5.xml

krill: $(TARGET_DIR)/dnb.krill.tar

KORAPXML2CONLLU ?= java -jar lib/korapxml2conllu.jar

$(TARGET_DIR)/dnb.i5.xml: $(patsubst $(SRC_DIR)/%.epub,$(TARGET_DIR)/%.i5.xml,$(wildcard $(SRC_DIR)/*.epub))
	head -n -1 xslt/idsCorpus-template.xml > $@
	cat $^ >> $@
	tail -n 1 xslt/idsCorpus-template.xml  >> $@

test: $(TARGET_DIR)/dnb.i5.xml xslt/epub2i5.xsl
	xmllint --noout --valid $<

$(BUILD_DIR)/%: $(SRC_DIR)/%.epub
	mkdir -p $@
	echo "Converting $< to $@"
	unzip -q -o $< -d $@

$(TARGET_DIR)/%.i5.xml: $(BUILD_DIR)/% xslt/epub2i5.xsl
	mkdir -p $(TARGET_DIR)
	echo "Converting $< to $@"
	java -jar lib/saxon9ee.jar -xsl:xslt/epub2i5.xsl $</*/content.opf > $@

%.zip: %.i5.xml
	tei2korapxml -l warn -s -tk - < $< > $@

%.tree_tagger.zip: %.zip
	$(KORAPXML2CONLLU) $< | pv | docker run --rm -i korap/conllu2treetagger -l german | conllu2korapxml > $@

%.spacy.zip: %.zip
	$(KORAPXML2CONLLU) $< | pv | docker run --rm -i korap/conllu2spacy | conllu2korapxml > $@

%.ud.zip: %.zip
	$(KORAPXML2CONLLU) $< | pv | ./scripts/udpipe2 | conllu2korapxml > $@

%.cmc.zip: %.zip
	$(KORAPXML2CONLLU) $< | pv | conllu2cmc -s | conllu2korapxml > $@

%.krill.tar: %.zip
	mkdir -p $(basename $@)
	korapxml2krill archive --quiet -w -z -cfg krill-korap4dnb.cfg --non-word-tokens --meta I5 -i $< -o $(basename $@)
# add annotations later
# korapxml2krill archive --quiet -w -z -cfg krill-korap4dnb.cfg --non-word-tokens --meta I5 -i $< -i $(word 2,$^) -i $(word 3,$^) -o $(basename $@)

json: *.krill.tar
	rm -rf json
	mkdir -p json
	for f in $^; do tar -C json -xf $$f; done

clean:
	rm -rf $(BUILD_DIR) $(TARGET_DIR)

