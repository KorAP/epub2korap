# EPub to KorAP (via TEI I5) conversion

## Run

### To generate an I5 corpus

```bash
make -j $(nproc) target/dnb18.i5.xml
```

### To generate an all I5 corpora

```bash
make -j $(nproc) i5
```

### To generate a KorAP-XML ZIP

Prerequisite: [KorAP-XML-CoNLL-U](https://github.com/KorAP/KorAP-XML-CoNLL-U)

```bash
make -j $(nproc) target/dnb23.zip
```

### To generate Annotations

Install prerequisite korap/conllu2treetagger and korap/conllu2spacy docker images if not present:

```bash
docker image inspect korap/conllu2treetagger:latest || curl -Ls 'https://gitlab.ids-mannheim.de/KorAP/CoNLL-U-Treetagger/-/jobs/artifacts/master/raw/conllu2treetagger.xz?job=build-docker-image' | docker load

docker image inspect korap/conllu2spacy:latest || curl -Ls https://corpora.ids-mannheim.de/tools/conllu2spacy.tar.xz | docker load
```

Make annotations fro dnb20:

```bash
make -j $(nproc) target/dnb20.marmot-malt.zip target/dnb20.spacy.zip target/dnb20.tree_tagger.zip
```

### To build KorAP index (also directly)

Build KorAP all, up to the ~~deployable~~ index:

```bash
make -j $(nproc) all
```

## News

* 2024-04-15
  * added pass2 and pass3 to xslt conversion to …
    * fix div, p, hi, ref … nestings
    * remove empty elements
    * join subsequent hi elements
  * improved korapxml2krill performance by using all cores (-1 does not work here)
  * sanitized the Makefile and dropped YY variable, use YEARS instead

* 2024-04-10
  * multiple authors (and non-authors) are now correctly handled
  * some more .(x)html files are now dropped (toc, cover, etc.)
  * **PRELIMINARY** support for splitting everything into annual volumes
    * use `make YY=22` to select 2022
    * does not yet work for the index!

* 2024-03-24
  * slow udpipe2 dropped
  * added marmot POS and morpho-syntactic annotations
  * added malt dependency annotations

* 2024-03-18
  * added `make deploy` to install new index and restart local KorAP@DNB instance (also available as ci target)
  * added `show-server-logs` and `show-server-status` make targets to monitor the local KorAP@DNB instance

* 2024-03-17
  * added `make all` to build all targets, including the index

* 2024-03-16
  * CI/CD pipeline added
  * first working pipeline for EPub ⮕ TEI I5 ⮕ KorAP-XML ⮕ (UDPipe+TreeTagger+Spacy) ⮕ Krill ⮕ KorAP-JSON

* 2024-03-15: DNB test data added

* 2024-03-08: example EPub and I5 added from DeReKo KJL corpus: *Christiane F. ; Kai Hermann ; Horst Rieck: Wir Kinder vom Bahnhof Zoo* in the folder [`test/resources/`](./test/resources/)  – do not distribute (copyrighted data)
