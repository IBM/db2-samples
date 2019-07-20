/****************************************************************************
** (c) Copyright IBM Corp. 2014 All rights reserved.
**
** The following sample of source code ("Sample") is owned by International
** Business Machines Corporation or one of its subsidiaries ("IBM") and is
** copyrighted and licensed, not sold. You may use, copy, modify, and
** distribute the Sample in any form without payment to IBM, for the purpose of
** assisting you in the development of your applications.
**
** The Sample code is provided to you on an "AS IS" basis, without warranty of
** any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
** IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
** MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
** not allow for the exclusion or limitation of implied warranties, so the above 
** limitations or exclusions may not apply to you. IBM shall not be liable for
** any damages you suffer as a result of using, copying, modifying or
** distributing the Sample, even if IBM has been advised of the possibility of
** such damages.
*****************************************************************************
**
** SOURCE FILE NAME: udfsampl.cpp
**
** SAMPLE: C++ user-defined function example
**
** UDSF CustomerName(varchar(1024)) returns integer
**
** COMPILE:
**    routinecompile udfsampl.cpp
**
** COMPILE AND REGISTER:
**    routinecompile udfsampl.cpp --sig "CustomerName(varchar(1024))" \
**        --return integer --class CCustomerName --db sample --schema myschema
**
** REGISTRATION COMMAND:
**    CREATE OR REPLACE FUNCTION db2user.CustomerName(VARCHAR(1024))      \
**    RETURNS INTEGER LANGUAGE  CPP  PARAMETER STYLE  NPSGENERIC          \
**    FENCED   NO FINAL CALL   DISALLOW PARALLEL   NO DBINFO              \
**    NOT DETERMINISTIC   RETURNS NULL ON NULL INPUT   NO SQL             \
**    EXTERNAL NAME '/home/db2user/udfsampl!CCustomerName'
**
** USAGE:
**    select customername(varcharcol) from tab
**
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing C++ User-defined scalar functions,
** see the Application Development Guide.
**
** For the latest information on programming, building, and running DB2
** applications, visit the DB2 application development website:
**     http://www.software.ibm.com/data/db2/udb/ad
**
****************************************************************************/


#include "udxinc.h"
#include <string.h>

using namespace nz::udx_ver2;

class CCustomerName: public nz::udx_ver2::Udf
{
    public:

    CCustomerName(UdxInit *pInit) : Udf(pInit)
    {
    }

    static nz::udx_ver2::Udf* instantiate(UdxInit *pInit);

    virtual nz::udx_ver2::ReturnValue evaluate()
    {
        StringArg *str;
        str = stringArg(0); // 4
        int lengths = str->length; // 5
        char *datas = str->data; // 6
        int32 retval = 0;
        if (lengths >= 10)
            if (memcmp("Customer A",datas,10) == 0)
                retval = 1;
        NZ_UDX_RETURN_INT32(retval); // 11
    }
};

nz::udx_ver2::Udf* CCustomerName::instantiate(UdxInit *pInit)
{
    return new CCustomerName(pInit);
}

