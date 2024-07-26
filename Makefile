ifneq (,$(filter test,$(MAKECMDGOALS)))
SRC_DIR = test/resources/DNB
YEARS=13 18
else
SRC_DIR ?= /mnt/data/KorAP@DNB
YEARS ?= $(shell seq -w 2012 2024 | sed 's/^.*\([0-9][0-9]\)/\1/')
endif

BUILD_DIR = build
TARGET_DIR ?= target
DEPLOY_HOST ?= compute.ids-mannheim.de
DEPLOY_USER ?= korap
DEPLOY_PATH ?= /export/netapp/korap4dnb
MAX_THREADS ?= $(shell nproc)
MAKE ?= make -j $(shell nproc)
KORAPXML2CONLLU_HEAP ?= $(shell echo "$$(($(MAX_THREADS) * 2500))")
KORAPXML2CONLLU ?= java -Xmx$(KORAPXML2CONLLU_HEAP)m -jar lib/korapxml2conllu.jar
SAXON ?= java -Djava.util.logging.config.file=/logging.properties -cp lib/saxon-ee-12.5.jar:lib/xmlresolver-5.2.2.jar:lib/textclassifier.jar:lib/xmlresolver-5.2.2-data.jar net.sf.saxon.Transform -expand:off



.DELETE_ON_ERROR:

.PHONY: all clean test i5 i5valid krill index deploy show-server-log show-server-status

.PRECIOUS: $(TARGET_DIR)/%.i5.xml $(TARGET_DIR)/dnb%.pre.i5.xml %.zip %.tree_tagger.zip %.ud.zip %.marmot-malt.zip %.spacy.zip %.i5.xml %.tar

all: index

krill: $(foreach year,$(YEARS),$(TARGET_DIR)/dnb$(year).krill.tar)

index: $(TARGET_DIR)/dnb.index

EPUBS := $(wildcard $(SRC_DIR)/**/*.epub)

$(TARGET_DIR)/dnb%.i5.xml: $(TARGET_DIR)/dnb%.pre.i5.xml  xslt/pass2.xsl xslt/pass3.xsl models/dereko_domains_s.classifier
	$(SAXON) -xsl:xslt/pass2.xsl $< | $(SAXON) -xsl:xslt/pass3.xsl - > $@

$(TARGET_DIR)/dnb%.pre.i5.xml: $(patsubst %.epub,$(TARGET_DIR)/%.i5.xml,$(notdir $(EPUBS)))
	echo $(EPUBS)
	@find $(SRC_DIR) -type f -name '*.epub' | while read src; do \
		echo $(TARGET_DIR)/$$(basename $${src%.epub}).i5.xml; \
	done | sort -u > $(TARGET_DIR)/filelist$*.txt
	sed -i -e 's/ /\n/g; /^$$/d' $(TARGET_DIR)/filelist$*.txt
	head -n -1 xslt/idsCorpus-template.xml | sed -e 's/{YY}/$*/' > $@
	@while IFS= read -r f; do \
		if head -500 "$$f" | grep -Eq '<pubDate type="year">..$*'; then \
			cat "$$f" >> $@; \
		fi; \
	done < $(TARGET_DIR)/filelist$*.txt
	tail -n 1 xslt/idsCorpus-template.xml  >> $@


test: models/dereko_domains_s.classifier i5valid test/test-xml.sh
	bash test/test-xml.sh

i5: $(foreach year,$(YEARS),$(TARGET_DIR)/dnb$(year).i5.xml)

i5valid: i5
	xmllint --noout --valid $(foreach year,$(YEARS),$(TARGET_DIR)/dnb$(year).i5.xml)


$(BUILD_DIR)/%: $(SRC_DIR)/**/%.epub
	mkdir -p $@
	echo "Converting $< to $@"
	unzip -q -o $< -d $@
	chmod -R ug+rwX $@

$(TARGET_DIR)/%.i5.xml: $(BUILD_DIR)/% xslt/epub2i5.xsl xslt/idsCorpus-template.xml
	mkdir -p $(TARGET_DIR)
	echo "Converting $< to $@"
	$(SAXON) -xsl:xslt/epub2i5.xsl $(shell find $< -name "*.opf") > $@ || (echo "WARN: ignoring invalid $@" && > $@)

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

models/dereko_domains_s.classifier:
	mkdir -p models
	curl -sL -o $@ https://corpora.ids-mannheim.de/tools/$@

%.marmot-malt.zip: %.zip models/de.marmot models/german.mco
	$(KORAPXML2CONLLU) -T $(MAX_THREADS) -t marmot:models/de.marmot -P malt:models/german.mco $< | conllu2korapxml -f "marmot dependency:malt" > $@

%.ud.zip: %.zip
	$(KORAPXML2CONLLU) $< | pv | ./scripts/udpipe2 | conllu2korapxml > $@

%.krill.tar: %.zip %.marmot-malt.zip %.tree_tagger.zip
	mkdir -p ${BUILD_DIR}/krill/$(basename $@)
	mkdir -p $(basename $@)
	K2K_TRANSLATOR_TEXT=1 korapxml2krill archive --quiet -w -z -cfg krill-korap4dnb.cfg -c ${BUILD_DIR}/krill/$(basename $@)/korapxml2krill.cache -j $(MAX_THREADS) -te ${BUILD_DIR}/krill/$(basename $@) --non-word-tokens --meta I5 -i $< -i $(word 2,$^) -i $(word 3,$^) -o $(basename $@)

%.json: %.krill.tar
	rm -rf $@
	mkdir -p $@
	for f in $<; do tar -C $@ -xf $$f; done

$(TARGET_DIR)/dnb.index: $(foreach year,$(YEARS),$(TARGET_DIR)/dnb$(year).json)
	rm -rf $@
	java -jar lib/Krill-Indexer.jar -c lib/krill.conf -i $(subst " ",;,$^) -o $@

$(TARGET_DIR)/dnb.index.tar.xz: $(TARGET_DIR)/dnb.index
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
