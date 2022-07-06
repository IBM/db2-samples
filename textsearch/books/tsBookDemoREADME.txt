* README file for Db2 Text Search samples
*
*
* (C) COPYRIGHT INTERNATIONAL BUSINESS MACHINES CORPORATION 2022.
*
*    ALL RIGHTS RESERVED.
*

File: samples/textsearch/books/tsBookDemoREADME.txt

The Db2 Text Search sample consists of a script written in SQL that
highlights the Text Search functionality.

The sample includes two ACM papers in PDF as examples that are loaded into the
sample database and indexed after enabling the Rich Text Filter.

The papers are publicly available on the ACM website. The download links are given below.
The references are as follows:

1) FFT.pdf
Thomas H. Cormen, David M. Nicol, Out-of-core FFTs with parallel disks,
ACM SIGMETRICS Performance Evaluation Review, Volume 25, Issue 3, December 1997 pp 3–12, https://doi.org/10.1145/270900.270902
Download: https://dl.acm.org/doi/abs/10.1145/270900.270902

2) ACID.pdf
Theo Haerder, Andreas Reuter, Principles of transaction-oriented database recovery,
ACM Computing Surveys, Volume 15, Issue 4, December 1983 pp 287–317, https://doi.org/10.1145/289.291
Download: https://dl.acm.org/doi/10.1145/289.291


"Out-of-core FFTs with parallel disks" is used as the PDF for the book with the
title "Introduction to Algorithms". For this book Thomas H. Cormen is one of the authors.
"Principles of transaction-oriented database recovery" is used as the PDF for
the book with the title "Datenbanksysteme". For this book Theo Haerder is one of the authors.

--------------------------------------------------------------------------------
Notes:
Prior to running the sample, the instance must be enabled for text search.
The remaining enablement is taken care of by the tsBookDemoRunDemo script.
