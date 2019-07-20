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
** SOURCE FILE NAME: udtfsampl.cpp
**
** SAMPLE: C++ user-defined table function example
**
** UDTF parsenames(varchar(1024)) returns integer
**
** COMPILE:
**    routinecompile udtfsampl.cpp
**
** COMPILE AND REGISTER:
**    routinecompile udtfsampl.cpp --sig "parsenames(VARCHAR(1024))"      \
**        --return "TABLE(product_id VARCHAR(200))" --class parseNames    \
**        --db sample --schema db2user
**
** REGISTRATION COMMAND:
**    CREATE OR REPLACE FUNCTION db2user.parsenames(VARCHAR(1024))        \
**    RETURNS TABLE(product_id VARCHAR(200)) LANGUAGE  CPP                \
**    PARAMETER STYLE  NPSGENERIC                                         \
**    FENCED   NO FINAL CALL   DISALLOW PARALLEL   NO DBINFO              \
**    NOT DETERMINISTIC   RETURNS NULL ON NULL INPUT   NO SQL             \
**    EXTERNAL NAME '/home/db2user/udtfsampl!parseNames'
**
**
** SETUP:
**     CREATE TABLE orders(order_id INTEGER, cust_id VARCHAR(200),        \
**                         prod_codes VARCHAR(1000));
**     INSERT INTO orders(order_ID, cust_ID,  PROD_CODES) VALUES          \
**                       (124, 'AB123456', '124,6,12,121');
**     INSERT INTO orders(order_ID, cust_id,  PROD_CODES) VALUES          \
**                       (125, 'AB987657', '8');
**     INSERT INTO orders(order_ID, cust_id,  PROD_CODES) VALUES          \
**                       (126, 'AB456754', '32,5,76,65,121,98');
**     INSERT INTO orders(order_ID, cust_id,  PROD_CODES) VALUES          \
**                       (131, 'AB643623', '12,88,41');
**     INSERT INTO orders(order_ID, cust_id,  PROD_CODES) VALUES          \
**                       (142, 'AB664353', '1,145,52,53,93,98,100');
**     INSERT INTO orders(order_ID, cust_id,  PROD_CODES) VALUES          \
**                       (132, 'AB643623', '121');
**     INSERT INTO orders(order_ID, cust_id,  PROD_CODES) VALUES          \
**                       (143, 'AB123456', '87,182');
**     INSERT INTO orders(order_ID, cust_id,  PROD_CODES) VALUES          \
**                       (120, 'AB876123', '28,36,80');
**     INSERT INTO orders(order_ID, cust_id,  PROD_CODES) VALUES          \
**                       (150, 'CD876543', '80,43,55,12,4,67,92');
**
** USAGE:
**    SELECT t.cust_id, f.product_id FROM orders AS t,                    \
**           TABLE ( parsenames(prod_codes) ) AS f
**
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing C++ User-defined table functions,
** see the Application Development Guide.
**
** For the latest information on programming, building, and running DB2
** applications, visit the DB2 application development website:
**     http://www.software.ibm.com/data/db2/udb/ad
**
****************************************************************************/


#include "udxinc.h"

using namespace nz::udx_ver2;

class parseNames : public Udtf
{
    private:
    char value[1000];
    int valuelen;
    int i;

    public:

    parseNames(UdxInit *pInit) : Udtf(pInit)
    {
    }

    static Udtf* instantiate(UdxInit*);

    virtual void newInputRow()
    {
        StringArg *valuesa = stringArg(0);
        bool valuesaNull = isArgNull(0);

        if (valuesaNull)
            valuelen = 0;
        else
        {
            if (valuesa->length >= 1000)
                throwUdxException("Input value must be less than 1000 characters.");
            memcpy(value, valuesa->data, valuesa->length);
            value[valuesa->length] = 0;
            valuelen = valuesa->length;
        }

        i = 0;
    }


    virtual DataAvailable nextOutputRow()
    {
        if (i >= valuelen)
            return Done;

        // save starting position of name
        int start = i;

        // scan string for next comma
        while ((i < valuelen) && value[i] != ',')
            i++;

        // return word
        StringReturn *rk = stringReturnColumn(0);
        if (rk->size < i-start)
            throwUdxException("Value exceeds return size");

        memcpy(rk->data, value+start, i-start);
        rk->size = i-start;
        i++;
        return MoreData;
    }
};

Udtf* parseNames::instantiate (UdxInit* pInit)
{
    return new parseNames(pInit);
}
