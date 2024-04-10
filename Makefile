SRC_DIR ?= test/resources/DNB
BUILD_DIR = build
TARGET_DIR ?= target
DEPLOY_HOST ?= compute.ids-mannheim.de
DEPLOY_USER ?= korap
DEPLOY_PATH ?= /export/netapp/korap4dnb
MAX_THREADS ?= $(shell nproc)

.PHONY: all clean test krill index deploy server-log server-status

.PRECIOUS: %.zip %.tree_tagger.zip %.ud.zip %.marmot-malt.zip %.spacy.zip %.i5.xml %.tar

.DELETE_ON_ERROR:

all: index

krill: $(TARGET_DIR)/dnb.krill.tar
index: $(TARGET_DIR)/dnb.index.tar.xz

KORAPXML2CONLLU ?= java -jar lib/korapxml2conllu.jar

$(TARGET_DIR)/dnb.i5.xml: $(patsubst $(SRC_DIR)/%.epub,$(TARGET_DIR)/%.i5.xml,$(wildcard $(SRC_DIR)/*.epub))
	head -n -1 xslt/idsCorpus-template.xml > $@
	cat $^ >> $@
	tail -n 1 xslt/idsCorpus-template.xml  >> $@

test: $(TARGET_DIR)/dnb.i5.xml
	xmllint --noout --valid $<

$(BUILD_DIR)/%: $(SRC_DIR)/%.epub
	mkdir -p $@
	echo "Converting $< to $@"
	unzip -q -o $< -d $@

$(TARGET_DIR)/%.i5.xml: $(BUILD_DIR)/% xslt/epub2i5.xsl xslt/idsCorpus-template.xml
	mkdir -p $(TARGET_DIR)
	echo "Converting $< to $@"
	java -jar lib/saxon9ee.jar -xsl:xslt/epub2i5.xsl $(shell find $< -name content.opf) > $@

%.zip: %.i5.xml
	tei2korapxml -l warn -s -tk - < $< > $@

%.tree_tagger.zip: %.zip
	$(KORAPXML2CONLLU) $< | pv | docker run --rm -i korap/conllu2treetagger -l german | conllu2korapxml > $@

%.spacy.zip: %.zip
	$(KORAPXML2CONLLU) $< | pv | docker run --rm -i korap/conllu2spacy | conllu2korapxml > $@

models/de.marmot:
	mkdir -p models
	curl -sL -o $@ https://cistern.cis.lmu.de/marmot/models/CURRENT/spmrl/de.marmot

models/german.mco:
	mkdir -p models
	curl -sL -o $@  https://corpora.ids-mannheim.de/tools/$@

%.marmot-malt.zip: %.zip models/de.marmot models/german.mco
	$(KORAPXML2CONLLU) -T $(MAX_THREADS) -t marmot:models/de.marmot -P malt:models/german.mco $< | tee $(TARGET_DIR)/dnb.marmot-malt.conllu | conllu2korapxml > $@

%.ud.zip: %.zip
	$(KORAPXML2CONLLU) $< | pv | ./scripts/udpipe2 | conllu2korapxml > $@

%.krill.tar: %.zip %.marmot-malt.zip %.tree_tagger.zip %.spacy.zip
	mkdir -p $(basename $@)
	korapxml2krill archive --quiet -w -z -cfg krill-korap4dnb.cfg --non-word-tokens --meta I5 -i $< -i $(word 2,$^) -i $(word 3,$^) -i $(word 4,$^) -o $(basename $@)

%.json: %.krill.tar
	rm -rf $@
	mkdir -p $@
	for f in $<; do tar -C $@ -xf $$f; done

%.index: %.json
	rm -rf $@
	java -jar lib/Krill-Indexer.jar -c lib/krill.conf -i $< -o $@

%.index.tar.xz: %.index
	tar -I 'xz -T0' -C $(dir $<) -cf $@ $(notdir $<)

deploy: $(TARGET_DIR)/dnb.index.tar.xz korap4dnb-compose.yml
	rsync -v $^ $(DEPLOY_USER)@$(DEPLOY_HOST):$(DEPLOY_PATH)/
	ssh $(DEPLOY_USER)@$(DEPLOY_HOST) "mkdir -p $(DEPLOY_PATH) && cd $(DEPLOY_PATH) && docker compose -p korap4dnb --profile=lite -f $(notdir $(word 2,$^)) up -d --dry-run && docker compose -p korap4dnb stop && (mv -f dnb.index dnb.index.bak || true) && tar Jxvf $(notdir $<) && docker compose -p korap4dnb --profile=lite -f $(notdir $(word 2,$^)) up -d"

show-server-log:
	ssh $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_PATH) && docker compose -p korap4dnb --profile=lite -f korap4dnb-compose.yml logs -f"

show-server-status:
	ssh $(DEPLOY_USER)@$(DEPLOY_HOST) "cd $(DEPLOY_PATH) && docker compose -p korap4dnb --profile=lite -f korap4dnb-compose.yml ps"

clean:
	rm -rf $(BUILD_DIR) $(TARGET_DIR)

