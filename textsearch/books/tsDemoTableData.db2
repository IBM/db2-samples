----------------------------------------------------------------------------
-- Licensed Materials - Property of IBM
-- Governed under the terms of the IBM Public License
--
-- (C) COPYRIGHT International Business Machines Corp. 2022
-- All Rights Reserved.
--
-- US Government Users Restricted Rights - Use, duplication or
-- disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
----------------------------------------------------------------------------
--
-- Product Name:     Db2 Text Search
--
-- Source File Name: tsDemoTableData.db2
--
-- Version:          Any
--
-- Description: Add text search table data.
--
-- SQL STATEMENTS USED:
--         INSERT
--
--
----------------------------------------------------------------------------
insert into TS_DEMO.books values
(1,
'9780262032933',
'Introduction To Algorithms', 'Thomas H Cormen, Charles E Leiserson, Ronald L Rivest, Clifford Stein',
'MIT Press',
2001,
'There are books on algorithms that are rigorous but incomplete and others that cover masses of material but lack rigor. Introduction to Algorithms combines rigor and comprehensiveness. The book covers a broad range of algorithms in depth, yet makes their design and analysis accessible to all levels of readers. Each chapter is relatively self-contained and can be used as a unit of study. The algorithms are described in English and in a pseudocode designed to be readable by anyone who has done a little programming. The explanations have been kept elementary without sacrificing depth of coverage or mathematical rigor. The first edition became the standard reference for professionals and a widely used text in universities worldwide. The second edition features new chapters on the role of algorithms, probabilistic analysis and randomized algorithms, and linear programming, as well as extensive revisions to virtually every section of the book. In a subtle but important change, loop invariants are introduced early and used throughout the text to prove algorithm correctness. Without changing the mathematical and analytic focus, the authors have moved much of the mathematical foundations material from Part I to an appendix and have included additional motivational material at the beginning. Computed.',
NULL,
'<book><isbn>9780262032933</isbn><title>Introduction To Algorithms</title><authors>Thomas H.. Cormen, Thomas H Cormen, Charles E Leiserson, Ronald L Rivest, Clifford Stein</authors><publishers>MIT Press</publishers><year>2001</year><summary>There are books on algorithms that are rigorous but incomplete and others that cover masses of material but lack rigor. Introduction to Algorithms combines rigor and comprehensiveness. The book covers a broad range of algorithms in depth, yet makes their design and analysis accessible to all levels of readers. Each chapter is relatively self-contained and can be used as a unit of study. The algorithms are described in English and in a pseudocode designed to be readable by anyone who has done a little programming. The explanations have been kept elementary without sacrificing depth of coverage or mathematical rigor. The first edition became the standard reference for professionals and a widely used text in universities worldwide. The second edition features new chapters on the role of algorithms, probabilistic analysis and randomized algorithms, and linear programming, as well as extensive revisions to virtually every section of the book. In a subtle but important change, loop invariants are introduced early and used throughout the text to prove algorithm correctness. Without
changing the mathematical and analytic focus, the authors have moved much of the mathematical foundations material from Part I to an appendix and have
included additional motivational material at the beginning.</summary></book>');

insert into TS_DEMO.books values (
2,
'3540421335',
'Datenbanksysteme',
'Theo Härder, Erhard Rahm',
'Springer Verlag',
'2001',
'The book offers a expansive and current description of the concepts and techniques for implementing database management systems. Using didactic layout and practicallity it can be used as much as a text book and as a hand book for computer science students that develop or administer large scale systems. Starting point is a hierarchical arcitecture model and its layers that allow to describe the system, the classification of applicable functions and their interaction in detail. All aspects of the data mapping using algorithms and data structures are explained, especially the external storage mapping, implementation of storage structures amd access paths as well as the derived logical layers. These tasks are separated into storage system, access system and data system. The second focus of the book is the transaction concept including its extensions. Specifically, functions for the synchronisation in a multi-user environment and restoring of the data base in an error (logging and recovery) are presented. Computed.',
NULL,
'<book><isbn>3540421335</isbn><title>Datenbanksysteme</title><authors>Theo Härder, Erhard Rahm</authors><publishers>Springer Verlag</publishers><year>2001</year><summary>The book offers a expansive and current description of the concepts and techniques for implementing database management systems. Using didactic layout and practicallity it can be used as much as a text book and as a hand book for computer science students that develop or administer large scale systems. Starting point is a hierarchical arcitecture model and its layers that allow to describe the system, the classification of applicable functions and their interaction in detail. All aspects of the data mapping using algorithms and data structures are explained, especially the external storage mapping, implementation of storage structures amd access paths as well as the derived logical layers. These tasks are separated into storage system, access system and data system. The second focus of the book is the transaction concept including its extensions. Specifically, functions for the synchronisation in a multi-user environment and restoring of the data base in an error (logging and recovery) are presented.</summary></book>');

