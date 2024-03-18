# EPub to KorAP (via TEI I5) conversion

## Run

### To generate I5 corpus

```bash
make -j $(nproc) target/dnb.i5.xml
```

### To generate the KorAP-XML ZIP

Prerequisite: [KorAP-XML-CoNLL-U](https://github.com/KorAP/KorAP-XML-CoNLL-U)

```bash
make -j $(nproc) target/dnb.zip
```

### To generate Annotations

Install prerequisite korap/conllu2treetagger and korap/conllu2spacy docker imeges if not present:

```bash
docker image inspect korap/conllu2treetagger:latest || curl -Ls 'https://gitlab.ids-mannheim.de/KorAP/CoNLL-U-Treetagger/-/jobs/artifacts/master/raw/conllu2treetagger.xz?job=build-docker-image' | docker load

docker image inspect korap/conllu2spacy:latest || curl -Ls https://corpora.ids-mannheim.de/tools/conllu2spacy.tar.xz | docker load
```

Make annotations:

```bash
make -j $(nproc) target/dnb.ud.zip target/dnb.spacy.zip target/dnb.tree_tagger.zip
```

### To build KorAP index (also directly)

Build KorAP all, up to the deployable index:

```bash
make -j $(nproc) all
```

## News

* 2024-03-17
  * added `make all` to build all targets, including the index

* 2024-03-16
  * CI/CD pipeline added
  * first working pipeline for EPub ⮕ TEI I5 ⮕ KorAP-XML ⮕ (UDPipe+TreeTagger+Spacy) ⮕ Krill ⮕ KorAP-JSON

* 2024-03-15: DNB test data added

* 2024-03-08: example EPub and I5 added from DeReKo KJL corpus: *Christiane F. ; Kai Hermann ; Horst Rieck: Wir Kinder vom Bahnhof Zoo* in the folder [`test/resources/`](./test/resources/)  – do not distribute (copyrighted data)
