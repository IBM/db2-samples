/* policy.h
 *
 * This is a sample C header file describing the XBSA.
 *
 * This appendix is not a normative part of the
 * specification and is provided for illustrative
 * purposes only.
 *
 * Implementations must ensure that the sizes of integer
 * datatypes match their names, not necessarily the typedefs
 * presented in this example.
 *
 */
/* policy.h
 */

#ifndef _BSA_POLICY_H_
#define _BSA_POLICY_H_

#include "xbsa.h"

/* AdminName
 */
typedef char AdminName[BSA_MAX_ADMIN_NAME];

/* Administrator
 *
 * Field        Value     Explanation
 * -----        -----     -----------
 * system       True      Has XBSA Backup Services privileges.
 *              False     Does not have XBSA Backup Services privileges.
 * policy       True      Has XBSA policy privileges.
 *              False     Does not have XBSA policy privileges.
 */
typedef struct {
    AdminName   name;               /* Name of the administrator              */
    Description desc;               /* Descriptive info re the administrator  */
    BSA_Boolean system;
    BSA_Boolean policy;
    char *      policyList[BSA_MAX_POLICYDOMAINS];  /* List of policy domains */
                                /* for which the administrator has privileges */
} Administrator;

/* FilterRuleSet
 *
 * The following notation is used to specify the syntax
 * to be used for the definition of a Filter Rule Set:
 * Elements enclosed in {} may be repeated zero or more times.
 * Rules separated by | are alternate production rules.
 * Literal words are specified as all uppercase characters.
 * FilterRuleSet       ::= FilterRule {FilterRule XBSADELIMITER}
 * FilterRule          ::= Predicate {AND Predicate} LGName
 * Predicate           ::= empty |
 *                         EqualityPredicate |
 *                         RelationalPredicate
 * EqualityPredicate   ::= XBSAUSERNAME  = "XBSAUserName"  |
 *                         APPUSERNAME   = "AppUserName"   |
 *                         FILESPACENAME = "filespaceName" |
 *                         PATHNAME      = "pathname"      |
 *                         RESOURCETYPE  = "ResourceType"  |
 *                         OBJECTTYPE    = "ObjectType"
 *
 * RelationalPredicate ::= OBJECTSIZE RelOp Number
 * RelOp               ::= = | <> | < | <= | > | >=
 * Number              ::= digit {digit}    any sequence of digits that
 *                                          can be represented as an
 *                                          unsigned 64 bit integer
 * LGName              ::= a valid life cycle group name
 * ObjectType          ::= any of the allowed values for ObjectType
 *
 * The predicate for the last rule in a filter rule set
 * is always assumed to be true.
 *
 * XBSAUserName, AppUserName, filespaceName, pathname,
 * and ResourceType are character strings that do not exceed
 * the valid length for these types of character arrays (as
 * defined in the type definitions).  These character strings
 * may include the character "*" which matches zero or
 * more characters.  The character "\" is used as an escape
 * character to allow the use of " or * as valid characters
 * in a character string.  Specifying "\\" would allow the use
 * of the backslash character.
 * There can be no spaces in EqualityPredicates.
 */
 typedef char FilterRuleSet[BSA_MAX_FILTERRULESET];

/* LifeCycleGroup
 */
typedef struct {
    LGName          name;       /* Lifecycle Group name                       */
    Description     desc;       /* Lifecycle Group description                */
    CopyGroup *     copyGroups[BSA_MAX_COPYGROUPS];
} LifecycleGroup;

/* PolicySetName
 */
typedef char PolicySetName[ BSA_MAX_POLICYSET_NAME];

/* PolicySetDescriptor
 */
typedef struct {
    PolicySetName   policySetName;
    Description     desc;
    LGName          lGNameList[BSA_MAX_LIFECYCLEGROUPS];
} PolicySetDescriptor;

/* PolicyDomainDescriptor
 */
typedef struct {
    DomainName          policyDomName;
    Description         desc;
    PolicySetDescriptor policySetList[BSA_MAX_POLICYSETS];
} PolicyDomainDescriptor;

/* PolicyDomainList
 */
typedef struct {
    DomainName          policyDomList[BSA_MAX_POLICYDOMAINS];
} PolicyDomainList;

/* Function Prototypes : include these for full XBSA Compliance,
 * together with the Data Movement API Subset, which is defined
 * in header file "xbsa.h"
 */

extern BSA_Int16
BSAActivatePolicySet
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       char             *policySetNamePtr
);

extern BSA_Int16
BSACreateAccessRule
(      BSA_UInt32        bsaHandle,
       AccessRule       *accessRulePtr,
       RuleId           *ruleIdPtr
);

extern BSA_Int16
BSACreateAdministrator
(      BSA_UInt32        bsaHandle,
       Administrator    *administratorPtr
);

extern BSA_Int16
BSACreateFilterRuleSet
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       char             *policySetNamePtr,
       FilterRuleSet    *filterRulePtr
);

extern BSA_Int16
BSACreateLifecycleGroup
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       char             *policySetNamePtr,
       LifecycleGroup   *lifecycleGroupPtr
);

extern BSA_Int16
BSACreatePolicyDomain
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       char             *desc
);

extern BSA_Int16
BSACreatePolicySet
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       char             *policySetNamePtr,
       char             *desc
);

extern BSA_Int16
BSACreateSchedule
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       Schedule         *schedulePtr
);

extern BSA_Int16
BSACreateUser
(      BSA_UInt32        bsaHandle,
       char             *name,
       char             *domainNamePtr,
       char             *desc
);

extern BSA_Int16
BSADeleteAccessRule
(      BSA_UInt32        bsaHandle,
       RuleId            ruleId
);

extern BSA_Int16
BSADeleteAdministrator
(      BSA_UInt32        bsaHandle,
       char             *name
);

extern BSA_Int16
BSADeleteFilterRuleSet
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       char             *policySetNamePtr
);

extern BSA_Int16
BSADeleteLifecycleGroup
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       char             *policySetNamePtr,
       char             *lifecycleGroupName
);

extern BSA_Int16
BSADeletePolicyDomain
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr
);

extern BSA_Int16
BSADeletePolicySet
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       char             *policySetNamePtr
);

extern BSA_Int16
BSADeleteSchedule
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       Schedule          scheduleId
);

extern BSA_Int16
BSADeleteUser
(      BSA_UInt32        bsaHandle,
       char             *name
);

extern BSA_Int16
BSAGetEvent
(      BSA_UInt32        bsaHandle,
       BSAEvent         *eventPtr,
       BSA_Boolean       flags
);

extern BSA_Int16
BSAGetNextAccessRule
(      BSA_UInt32        bsaHandle,
       AccessRule       *accessRulePtr
);

extern BSA_Int16
BSAGetNextAdmin
(      BSA_UInt32        bsaHandle,
       Administrator    *administratorPtr
);

/* BSAGetNextQueryObject defined in xbsa.h because it should be part
 * of the Data Movement subset.
 */

extern BSA_Int16
BSAGetNextSchedule
(      BSA_UInt32        bsaHandle,
       Schedule         *schedulePtr
);

extern BSA_Int16
BSAGetNextUser
(      BSA_UInt32        bsaHandle,
       UserDescriptor   *userDescPtr
);

extern BSA_Int16
BSAGetPolicyDomainList
(      BSA_UInt32        bsaHandle,
       PolicyDomainList *policyDomListPtr
);

extern BSA_Int16
BSAQueryAccessRule
(      BSA_UInt32        bsaHandle,
       char             *objectName,
       AccessRule       *accessRulePtr
);

extern BSA_Int16
BSAQueryAdministrator
(      BSA_UInt32        bsaHandle,
       char             *name,
       Administrator    *administratorPtr
);

extern BSA_Int16
BSAQueryFilterRuleSet
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       char             *policySetNamePtr,
       FilterRuleSet    *filterRuleSetPtr
);

extern BSA_Int16
BSAQueryLifecycleGroup
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       char             *policySetNamePtr,
       char             *lifecycleGroupName,
       LifecycleGroup   *lGPtr
);

extern BSA_Int16
BSAQueryPolicyDomain
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       PolicyDomainDescriptor *pDDescriptorPtr
);

extern BSA_Int16
BSAQueryPolicySet
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       char             *policySetNamePtr,
       PolicySetDescriptor *pSDescriptorPtr
);

extern BSA_Int16
BSAQuerySchedule
(      BSA_UInt32        bsaHandle,
       char             *domainNamePtr,
       Schedule         *schedulePtr
);

extern BSA_Int16
BSAQueryUser
(      BSA_UInt32        bsaHandle,
       char             *name,
       UserDescriptor   *userDescPtr
);

extern BSA_Int16
BSAResolveLifecycleGroup
(      BSA_UInt32        bsaHandle,
       ObjectDescriptor *objectDescriptorPtr
);

extern BSA_Int16
BSASetEventStatus
(      BSA_UInt32        bsaHandle,
       BSAEvent         *eventPtr
);

#endif
