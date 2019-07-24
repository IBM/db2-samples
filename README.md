This repo contains many sets of sample application code, API usage examples, configuration examples, etc. that are organized into sub-folders according to programming language or sample topic.  Some folders contain multiple samples.

Not all sample programs are available on all platforms or supported programming languages. You can use the sample programs as templates to create your own applications, and as a learning tool to understand Db2 functionality.

Db2 sample programs are provided "as is" without any warranty of any kind. The user, and not IBM, assumes the entire risk of quality, performance, and repair of any defects.  Contributions to this open-source project are welcomed, see [CONTRIBUTING](CONTRIBUTING.md).

Besides the sample application program files, other sample files are also provided in this repo.  These include build files and makefiles to compile and link the sample programs, error-checking utility files which are linked in to most sample programs, and various script files to assist in application development. For example, scripts are provided to catalog and uncatalog stored procedures and UDFs in several language sub-directories. Each samples directory has a README file which describes the files contained in the directory.

The following table shows the sample directories and README files for the main supported programming languages and APIs.  You can also access the sample files in the listed samples directories. For the directory paths, the UNIX-style slashes are used, as in samples/c, except where the directory is for Windows only, as in samples\VB\ADO.

## Sample Details By Language
| | | |
| --- | --- | --- |
| C | [README](https://github.com/IBM/db2-samples/blob/master/c/README) | [SOURCE](https://github.com/IBM/db2-samples/tree/master/c/) |
| C++ | [README](https://github.com/IBM/db2-samples/blob/master/cpp/README) | [SOURCE](https://github.com/IBM/db2-samples/tree/master/cpp/) |
| CLI | [README](https://github.com/IBM/db2-samples/blob/master/cli/README) | [SOURCE](https://github.com/IBM/db2-samples/tree/master/cli/) |
| CLP | [README](https://github.com/IBM/db2-samples/blob/master/clp/README) | [SOURCE](https://github.com/IBM/db2-samples/tree/master/clp/) |
| Micro Focus COBOL | [README](https://github.com/IBM/db2-samples/blob/master/cobol_mf/README) | [SOURCE](https://github.com/IBM/db2-samples/tree/master/cobol_mf/) |
| JDBC | [README](https://github.com/IBM/db2-samples/blob/master/java/jdbc/README) | [SOURCE](https://github.com/IBM/db2-samples/tree/master/java/jdbc/) |
| SQLJ | [README](https://github.com/IBM/db2-samples/blob/master/java/sqlj/README) | [SOURCE](https://github.com/IBM/db2-samples/tree/master/java/sqlj/) |
| Perl | [README](https://github.com/IBM/db2-samples/blob/master/perl/README) | [SOURCE](https://github.com/IBM/db2-samples/tree/master/perl/) |
| PHP | [README](https://github.com/IBM/db2-samples/blob/master/php/README) | [SOURCE](https://github.com/IBM/db2-samples/tree/master/php/) |
| SQL Procedures | [README](https://github.com/IBM/db2-samples/blob/master/sqlpl/README) | [SOURCE](https://github.com/IBM/db2-samples/tree/master/sqlpl/) |
| XML | [README](https://github.com/IBM/db2-samples/blob/master/xml/README) | [SOURCE](https://github.com/IBM/db2-samples/tree/master/xml/) |

<dl>
  <dt>Note:</dt>
  <dd>There are various samples provided for demonstrating Native XML support in Db2.  The XML samples come with their own build files, utility files, supporting scripts etc.  XQuery samples are all further collected in a separate directory under the parent XML directory. The XQuery as well as other samples demonstrating administrative and application development support are available in various languages.</dd>
</dl>

Sample program file extensions differ for each supported language, and for embedded SQL and non-embedded SQL programs within each language. File extensions might also differ for groups of programs within a language. These different sample file extensions are categorized in the following tables:

### Sample file extensions by language

| Language |	Directory |	Embedded SQL programs |	Non-embedded SQL programs |
| --- | --- | --- | --- |
| C | samples/c <br> samples/cli (CLI programs) <br> samples/xml/c <br> samples/xml/xquery/c <br> samples/xml/cli (CLI programs) <br> samples/xml/xquery/cli (CLI programs) | .sqc |.c |
| C++ |	samples/cpp | .sqC (UNIX) <br> .sqx (Windows) <br> .C (UNIX) <br> .cxx (Windows) |
| C# | samples\\.NET\cs | | .cs |
| COBOL | samples/cobol | samples/cobol_mf | .sqb | .cbl |
| Java | samples/java/jdbc <br> samples/java/sqlj <br> samples/xml/java/jdbc <br> samples/xml/xquery/java/jdbc <br> samples/xml/java/sqlj <br> samples/xml/xquery/java/sqlj <br> samples/java/WebSphere <br> samples/java/plugin | .sqlj | .java |
| Perl | samples/perl | .pl | .pm |
| PHP | samples/php | .php | |
| REXX | samples/rexx | .cmd | .cmd |
| Visual Basic | samples\VB\ADO <br> samples\VB\MTS <br> samples\VB\RDO | | .bas .frm .vbp |
| Visual Basic .NET | samples\\.NET\vb | | .vb |
| Visual C++ | samples\VC\ADO | | .cpp .dsp .dsw |

## Sample file extensions by program group

| Sample group | Directory | File Extension |
| --- | --- | --- |
| CLP | samples/clp <br> samples/xml/clp <br> samples/xml/xquery/clp | .db2 |
| OLE | samples\ole\msvb (Visual Basic) <br> samples\ole\msvc (Visual C++) | .bas .vbp (Visual Basic) <br> .cpp (Visual C++) |
| OLE DB | samples\oledb | .db2 |
| SQLPL | samples/sqlpl | .db2 (SQL Procedure scripts) <br> .c (CLI Client Applications) <br> .sqc (embedded C Client Applications) <br> .java (JDBC Client Applications) |
| User exit | samples/c | .ctsm (UNIX & Windows) <br> .cdisk (UNIX & Windows) <br> .ctape (UNIX) <br> .cxbsa (UNIX) |


#### Notes

<dl>
  <dt>Directory delimiters</dt>
  <dd>The directory delimiter on UNIX is a /. On Windows it is a \. In the tables, the UNIX delimiters are used unless the directory is only available on Windows.</dd>

  <dt>Embedded SQL programs</dt>
  <dd>Require precompilation, except for REXX embedded SQL programs where the embedded SQL statements are interpreted when the program is run.</dd>

  <dt>IBM COBOL samples</dt>
  <dd>Are only supplied for AIX and Windows 32-bit operating systems in the cobol subdirectory.</dd>

  <dt>Micro Focus COBOL samples</dt>
  <dd>Are only supplied for AIX, Linux, and Windows 32-bit operating systems in the cobol_mf subdirectory.</dd>

  <dt>Java samples</dt>
  <dd>Are Java Database Connectivity (JDBC) applets, applications, and routines, embedded SQL for Java (SQLJ) applets, applications, and routines. Available for demonstrating native XML support as well. Java samples are available on all supported Db2 platforms.</dd>

  <dt>REXX samples</dt>
  <dd>Are only supplied for AIX and Windows 32-bit operating systems.</dd>

  <dt>CLP samples</dt>
  <dd>Are Command Line Processor scripts that execute SQL statements. Also available to show XML and XQuery support.</dd>

  <dt>OLE samples</dt>
  <dd>Are for Object Linking and Embedding (OLE) in Microsoft Visual Basic and Microsoft Visual C++, supplied for Windows operating systems only.</dd>

  <dt>Visual Basic samples</dt>
  <dd>Are ActiveX Data Objects, Remote Data Objects, and Microsoft Transaction Server samples, supplied on Windows operating systems only.</dd>

  <dt>Visual C++ samples</dt>
  <dd>Are ActiveX Data Object samples, supplied on Windows operating systems only.</dd>

  <dt>User exit samples</dt>
  <dd>Are Log Management User Exit programs used to archive and retrieve database log files. The files must be renamed with a .c extension and compiled as C language programs.
</dl>

## Structure and design

Most of the Db2 samples in C, CLI, C++, C#, Java, Perl, PHP, Visual Basic ADO, and Visual Basic .NET are organized to reflect an object-based design model of the database components.. The samples are grouped in categories representing different levels of Db2. The level to which a sample belongs is indicated by a two character prefix at the beginning of the sample name. Not all levels are represented in the samples for each Application Programming Interface, but for the samples as a whole, the levels are represented as follows:

<dl>
  <dt>prefix</dt>
  <dd>Db2 Level</dd>

  <dt>il</dt>
  <dd>Installation Image Level</dd>

  <dt>cl</dt>
  <dd>Client Level</dd>

  <dt>in</dt>
  <dd>Instance Level</dd>

  <dt>db</dt>
  <dd>Database Level</dd>

  <dt>ts</dt>
  <dd>Table Space Level</dd>

  <dt>tb</dt>
  <dd>Table Level</dd>

  <dt>dt</dt>
  <dd>Data Type Level</dd>
</dl>

The levels show a hierarchical structure. The Installation image level is the top level of Db2. Below this level, a client-level application can access different instances; an instance can have one or more databases; a database has table spaces within which tables exist, and which in turn hold data of different data types.

This design does not include all Db2 samples. The purpose of some samples is to demonstrate different methods for accessing data. These methods are the main purpose of these samples so they are represented by these methods in a similar manner as mentioned previously:

<dl>
  <dt>prefix</dt>
  <dd>Programming method</dd>

  <dt>fn</dt>
  <dd>SQL function</dd>

  <dt>sp</dt>
  <dd>Stored procedure</dd>

  <dt>ud</dt>
  <dd>User-defined function</dd>
</dl>

There are other samples not included in this design, such as the XML samples, Log Management User Exit samples, samples in COBOL, Visual C++, REXX, Object Linking and Embedding (OLE) samples, CLP scripts, and SQL Procedures. XML samples are broadly categorized into samples demonstrating native XML administration, application development and XQuery support. 
