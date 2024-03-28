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
**  Source File Name = src/gss/AWSSDKRAII.cpp          (%W%)
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
#include "AWSSDKRAII.h"


std::atomic<size_t> Initialize::mCount(0);

Initialize::Initialize()
{
    const size_t origCount = mCount++;

    if (origCount == 0)
    {
        mOptions.loggingOptions.logLevel = Aws::Utils::Logging::LogLevel::Info;
        Aws::InitAPI(mOptions);
    }
}

Initialize::~Initialize()
{
    const size_t newCount = --mCount;

    if (newCount == 0)
    {
        Aws::ShutdownAPI(mOptions);
    }
}
