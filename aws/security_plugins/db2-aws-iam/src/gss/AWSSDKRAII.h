/****************************************************************************
** Licensed Materials - Property of IBM
**
** Governed under the terms of the International
** License Agreement for Non-Warranted Sample Code.
**
** (C) COPYRIGHT International Business Machines Corp. 2024
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
**
**********************************************************************************
**
**  Source File Name = src/gss/AWSSDKRAII.h          (%W%)
**
**  Descriptive Name = GSS based authentication plugin code that helps for AWS communication using AWS SDK APIs
**
**  Function: This class will make sure the InitAPI and ShutdownAPI calls are not made multiple times.
**
**  Dependencies:
**
**  Restrictions:
**
***********************************************************************/

#ifndef _AWS_SDK_RAII_H_
#define _AWS_SDK_RAII_H_
#include <aws/core/Aws.h>


class Initialize
{
public:
    Initialize();
    ~Initialize();
    Initialize(const Initialize& ) = delete;
    Initialize& operator=(const Initialize& ) = delete;

private:
    Aws::SDKOptions mOptions;
    static std::atomic<size_t> mCount;
};

#endif // _AWS_SDK_RAII_H_
