/**********************************************************************
*
*  IBM CONFIDENTIAL
*  OCO SOURCE MATERIALS
*
*  COPYRIGHT:  P#2 P#1
*              (C) COPYRIGHT IBM CORPORATION 2023, 2024
*
*  The source code for this program is not published or otherwise divested of
*  its trade secrets, irrespective of what has been deposited with the U.S.
*  Copyright Office.
*
*  Source File Name = src/gss/AWSSDKRAII.cpp          (%W%)
*
*  Descriptive Name = GSS based authentication plugin code that helps for AWS communication using AWS SDK APIs
*
*  Function:
*
*  Dependencies:
*
*  Restrictions:
*
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
