

----------- This Makefile is obsolete ---------------

to compile a stored procedure do the following instead:

////////////////////////////////////////////////////////////////
//                  COMPILING + INSTALLING  (unix/win)     
//  - copy the stored proc (*SQC file) to ~/sqllib/sample/cpp
//  - make sure the suffix of this file is sqC(unix)/sqx(win) 
//    (rename this file if it's suffix is not sqC)               
//  - copy the file asnqspC.exp(unix)/asnqspC.def(win) to   
//    that directory as well
//  - use the script 'bldrtn' to precomile, compile and install
//    the stored procedure;                             
//    example: 'bldrtn asnqspC <databaseName>'           
////////////////////////////////////////////////////////////////

