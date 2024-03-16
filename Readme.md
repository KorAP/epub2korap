# EPub to KorAP (via TEI I5) conversion

## Run

### To generate I5 corpus

```bash
make target/dnb.i5.xml
```

### To generate the KorAP-XML ZIP

Prerequisite: [KorAP-XML-CoNLL-U](https://github.com/KorAP/KorAP-XML-CoNLL-U)

```bash
make target/dnb.zip
```

### To generate Annotations

```bash
make target/dnb.spacy.zip target/dnb.tree_tagger.zip
```
## News

* 2024-03-16: first working pipeline for EPub ⮕ TEI I5 ⮕ KorAP-XML ⮕ (UDPipe+TreeTagger+Spacy) ⮕ Krill ⮕ KorAP-JSON

* 2024-03-15: DNB test data added

* 2024-03-08: example EPub and I5 added from DeReKo KJL corpus: *Christiane F. ; Kai Hermann ; Horst Rieck: Wir Kinder vom Bahnhof Zoo* in the folder [`test/resources/`](./test/resources/)  – do not distribute (copyrighted data)
