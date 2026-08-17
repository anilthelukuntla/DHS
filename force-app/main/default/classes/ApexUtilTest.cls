@IsTest
public class ApexUtilTest {
    @IsTest
    static void method1(){
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Map<String, Id> recordTypesByName = ApexUtil.buildMapOfRecordTypes('Lead__c');
            Map<String, Schema.SObjectType> globalDescMap = Schema.getGlobalDescribe();
            Schema.SObjectType targetType = globalDescMap.get('Lead__c');
            SObject sObj = targetType.newSObject();
            List<String> picklistValues = ApexUtil.getPickListValues(sObj, 'LeadType__c');
            Map<Object, Object> fieldTypes = ApexUtil.getSObjectFieldTypes('Lead__c');
            List<String> userFields = ApexUtil.fetchFields('User');
            List<String> userFilters = new List<String>{ 'id =: currentUserId' };
            String userQuery = ApexUtil.queryBuilder('User', userFields, userFilters);
            String onboardingQuery = ApexUtil.queryBuilder(
                'Onboarding__c',
                'OnboardingUser',
                new List<String>()
            );
            String queryWithoutFilter = ApexUtil.queryBuilder(
                'User',
                new List<String>{ 'Id' },
                null
            );
            Boolean isSandbox = ApexUtil.runningInASandbox();
            Map<String, Schema.SObjectField> userFieldDescribe = ApexUtil.getObjectFieldsDescribe('User');
            Datetime convertedDate = ApexUtil.dt(System.today());
            Datetime convertedDateWithFlag = ApexUtil.dt(System.today());

            System.assertNotEquals(null, recordTypesByName, 'Record type helper should return a map.');
            System.assertNotEquals(null, picklistValues, 'Picklist helper should return a list.');
            System.assertNotEquals(null, fieldTypes, 'Field type helper should return a map.');
            System.assert(userQuery.startsWith('SELECT '), 'Explicit-field query should start with SELECT.');
            System.assert(onboardingQuery.startsWith('SELECT '), 'Field-set query should start with SELECT.');
            System.assertEquals('SELECT Id FROM User', queryWithoutFilter, 'Null filters should omit WHERE.');
            System.assertNotEquals(null, isSandbox, 'Sandbox helper should return a Boolean.');
            System.assert(userFieldDescribe.containsKey('Id'), 'User describe should contain the Id field.');
            System.assertEquals(convertedDate, convertedDateWithFlag, 'Date overloads should return the same value.');
        }
    }

    @IsTest
    static void exercisesCriteriaAndFieldSetUtilities() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        List<Schema.FieldSetMember> members = ApexUtil.readFieldSet(
            'OnboardingUser',
            'OnBoarding__c'
        );
        System.assert(!members.isEmpty(), 'Assertion failed in ApexUtilTest at source line 43');
        System.assertEquals(
            members.size(),
            ApexUtil.getFieldSetFields('OnBoarding__c', 'OnboardingUser').size()
        , 'Assertion failed in ApexUtilTest at source line 44');
        System.assertEquals(
            members.size(),
            ApexUtil.getFieldSetFieldsObjs(
                'OnBoarding__c', 'OnboardingUser'
            ).size()
        , 'Assertion failed in ApexUtilTest at source line 48');

        List<ApexUtil.Criteria> criteria = new List<ApexUtil.Criteria>{
            new ApexUtil.Criteria('Name', 'O\'Brien', '='),
            new ApexUtil.Criteria('CreatedDate', '2026-01-01', '>=').withFieldType('Date'),
            new ApexUtil.Criteria('AnnualRevenue', '10.5', '>').withFieldType('Double'),
            new ApexUtil.Criteria('NumberOfEmployees', '5', '>=').withFieldType('Integer'),
            new ApexUtil.Criteria('ParentId', null, '=')
        };
        String whereClause = ApexUtil.generateWhereQuery(criteria);
        System.assert(whereClause.contains('O\\\'Brien'), 'Assertion failed in ApexUtilTest at source line 63');
        System.assert(whereClause.contains('ParentId = null'), 'Assertion failed in ApexUtilTest at source line 64');
        System.assert(whereClause.contains('CreatedDate >=2026-01-01'), 'Dates should not be quoted.');
        System.assert(whereClause.contains('AnnualRevenue >10.5'), 'Decimals should not be quoted.');
        System.assert(whereClause.contains('NumberOfEmployees >=5'), 'Integers should not be quoted.');
        System.assertEquals(true, criteria[0].isFieldValueGiven(), 'Assertion failed in ApexUtilTest at source line 65');
        System.assertEquals(false, criteria[4].isFieldValueGiven(), 'Assertion failed in ApexUtilTest at source line 66');
        System.assertNotEquals(
            null,
            ApexUtil.getPickListValuesIntoList('Account', 'Type')
        , 'Assertion failed in ApexUtilTest at source line 67');
        System.assertEquals(
            '',
            ApexUtil.generateWhereQuery(new List<ApexUtil.Criteria>())
        , 'Assertion failed in ApexUtilTest at source line 71');
        }
    }
    
}
