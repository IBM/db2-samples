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
*  Source File Name = src/gss/AWSSDKRAII.h          (%W%)
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
