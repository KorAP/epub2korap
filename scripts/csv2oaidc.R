#!/bin/env Rscript
library(glue)
library(tidyverse)
library(readr)

df <- read_delim("Metadaten.csv", delim = ";",  locale = readr::locale(encoding = "cp1252"))

recordBuilder <- function(ID, ISBN, author, creationDate, title, publisher, pubPlace, ...) {
  glue::glue(
'    <record>
      <recordSchema>oai_dc</recordSchema>
      <recordPacking>xml</recordPacking>
      <recordData>
        <dc xmlns:dnb="http://d-nb.de/standards/dnbterms" xmlns:tel="http://krait.kb.nl/coop/tel/handbook/telterms.html" xmlns="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <dc:title>{title}</dc:title>
          <dc:creator>{author}</dc:creator>
          <dc:publisher>{publisher}</dc:publisher>
          <dc:date>{creationDate}</dc:date>
          <dc:language>ger</dc:language>
          <dc:identifier xsi:type="tel:ISBN">{ISBN}</dc:identifier>
          <dc:identifier xsi:type="dnb:IDN">{ID}</dc:identifier>
          <dc:subject>830 Deutsche Literatur</dc:subject>
          <dc:subject>B Belletristik</dc:subject>
          <dc:type>Online-Ressource</dc:type>
        </dc>
      </recordData>
    </record>
')
}

escape_xml <- function(x) {
  x <- gsub("&", "&amp;", x)
  x <- gsub("<", "&lt;", x)
  x <- gsub(">", "&gt;", x)
  x <- gsub("\"", "&quot;", x)
  x <- gsub("'", "&apos;", x)
  return(x)
}

df <- df %>%
  mutate(across(everything(), ~ escape_xml(.)))

xmlRecords <- df %>% purrr::pmap(recordBuilder) %>% unlist %>% paste(collapse = "\n")

glue::glue(
'<?xml version="1.0" encoding="UTF-8"?>
<searchRetrieveResponse xmlns="http://www.loc.gov/zing/srw/">
  <records>
{xmlRecords}
    <!-- From here on only fake examples for testing -->
    <record>
      <recordSchema>oai_dc</recordSchema>
      <recordPacking>xml</recordPacking>
      <recordData>
        <dc xmlns:dnb="http://d-nb.de/standards/dnbterms" xmlns:tel="http://krait.kb.nl/coop/tel/handbook/telterms.html" xmlns="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <dc:title>Ein Hauch von Meer und Mord : Juist-Krimi / Barbara Saladin</dc:title>
          <dc:creator>Saladin, Barbara [Verfasser]</dc:creator>
          <dc:publisher>Hillesheim : KBV Verlags- &amp; Medien</dc:publisher>
          <dc:date>2012</dc:date>
          <dc:language>ger</dc:language>
          <dc:identifier xsi:type="tel:URN">urn:nbn:de:101:1-2012112917525</dc:identifier>
          <dc:identifier xsi:type="tel:URL">http://nbn-resolving.de/urn:nbn:de:101:1-2012112917525</dc:identifier>
          <dc:identifier xsi:type="tel:ISBN">978-3-95441-123-8</dc:identifier>
          <dc:identifier xsi:type="tel:URL">http://d-nb.info/1028379862/34</dc:identifier>
          <dc:identifier xsi:type="dnb:IDN">8999999998</dc:identifier>
          <dc:subject>830 Deutsche Literatur</dc:subject>
          <dc:subject>B Belletristik</dc:subject>
          <dc:type>Online-Ressource</dc:type>
        </dc>
      </recordData>
      <recordPosition>1</recordPosition>
    </record>

    <record>
      <recordSchema>oai_dc</recordSchema>
      <recordPacking>xml</recordPacking>
      <recordData>
        <dc xmlns:dnb="http://d-nb.de/standards/dnbterms" xmlns:tel="http://krait.kb.nl/coop/tel/handbook/telterms.html" xmlns="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <dc:title>Herzblut : Kriminalroman aus Düsseldorf / David Daniel</dc:title>
          <dc:creator>Daniel, David [Verfasser]</dc:creator>
          <dc:publisher>Hillesheim : KBV Verlags- &amp; Medien</dc:publisher>
          <dc:date>2018</dc:date>
          <dc:language>ger</dc:language>
          <dc:identifier xsi:type="tel:URN">urn:nbn:de:101:1-2012112917539</dc:identifier>
          <dc:identifier xsi:type="tel:URL">http://nbn-resolving.de/urn:nbn:de:101:1-2012112917539</dc:identifier>
          <dc:identifier xsi:type="tel:ISBN">978-3-95441-027-9</dc:identifier>
          <dc:identifier xsi:type="tel:URL">http://d-nb.info/1028379870/34</dc:identifier>
          <dc:identifier xsi:type="dnb:IDN">8999999999</dc:identifier>
          <dc:subject>830 Deutsche Literatur</dc:subject>
          <dc:subject>B Belletristik</dc:subject>
          <dc:type>Online-Ressource</dc:type>
        </dc>
      </recordData>
    </record>
  </records>
</searchRetrieveResponse>
'
) %>% cat(file = "static_metadata.xml")

