# EPub to KorAP (via TEI I5) conversion

## Note

This version has been trimmed of all licensed and copyrighted materials. As a result, the test data is not included in this repository, and commands may not run as expected without additional setup.

## Testing

### Run TEI I5 conversion tests on local test data

```bash
make -j $(nproc) test
```

### Build test index

```bash
make -j $(nproc) test index
```

### Run local KorAP with test index

```bash
INDEX=./target/dnb.index docker compose -p korap4dnb --profile=lite -f korap4dnb-compose.yml up -d

xdg-open http://localhost:4000/?q=Test
```

### Stop local KorAP

```bash
docker compose -p korap4dnb down
```

## Production

### Build new KorAP index, just with prize winners index

```bash
make clean && time make -j $(( $(nproc) / 2 )) index SRC_DIR=./Buchpreis
```

The index will be in `target/dnb.index`.

### Generate all I5 corpora

```bash
make -j $(nproc) i5
```

### Generate a KorAP-XML ZIP

Prerequisite: [KorAP-XML-CoNLL-U](https://github.com/KorAP/KorAP-XML-CoNLL-U)

```bash
make -j $(nproc) target/dnb18.zip SRC_DIR=test/resources/DNB YEARS=18
```

### Build new KorAP index

```bash
make -j $(nproc) index
```

The index will be in `target/dnb.index`.

### Run KorAP

and start the docker:

```bash
INDEX=./target/dnb.index docker compose -p korap4dnb --profile=lite -f korap4dnb-compose.yml up -d
```

### Stop KorAP

```bash
docker compose -p korap4dnb down
```

### Restart KorAP

```bash
docker compose -p korap4dnb --profile=lite restart
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

Build KorAP all, up to the deployable index:

```bash
make -j $(nproc) all
```
