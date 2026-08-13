@IsTest
/** Exercises the existing DHSApexUtil behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSApexUtilTest {

    @IsTest
    static void testObjectDescribeUtilities() {
        Test.startTest();

        List<String> accountFields = DHSApexUtil.FetchFields('Account');

        Schema.DescribeSObjectResult accountDescribe =
            DHSApexUtil.getObjectTypeDescribe('Account');

        Map<String, Schema.SObjectField> describedFields =
            DHSApexUtil.getObjectFieldsDescribe('Account');

        Map<Object, Object> fieldTypes =
            DHSApexUtil.getSObjectFieldTypes('Account');

        Test.stopTest();

        System.assertNotEquals(null, accountFields, 'Assertion failed in DHSApexUtilTest at source line 23');
        System.assert(!accountFields.isEmpty(), 'Assertion failed in DHSApexUtilTest at source line 24');
        System.assert(containsIgnoreCase(accountFields, 'Id'), 'Assertion failed in DHSApexUtilTest at source line 25');
        System.assert(containsIgnoreCase(accountFields, 'Name'), 'Assertion failed in DHSApexUtilTest at source line 26');

        System.assertEquals(
            'Account',
            accountDescribe.getName()
        , 'Assertion failed in DHSApexUtilTest at source line 28');

        System.assertNotEquals(null, describedFields, 'Assertion failed in DHSApexUtilTest at source line 33');
        System.assert(
            containsFieldIgnoreCase(describedFields, 'Name'),
            'Account Name should be returned'
        );

        System.assertNotEquals(null, fieldTypes, 'Assertion failed in DHSApexUtilTest at source line 39');
        System.assert(
            containsObjectKeyIgnoreCase(fieldTypes, 'Name'),
            'Account Name field type should be returned'
        );
    }

    @IsTest
    static void testBuildMapOfRecordTypes() {
        Test.startTest();
        Map<String, Id> recordTypeMap =
            DHSApexUtil.buildMapOfRecordTypes('Account');
        Test.stopTest();

        System.assertNotEquals(null, recordTypeMap, 'Assertion failed in DHSApexUtilTest at source line 53');

        for (String recordTypeName : recordTypeMap.keySet()) {
            System.assertNotEquals(null, recordTypeName, 'Assertion failed in DHSApexUtilTest at source line 56');
            System.assertNotEquals(null, recordTypeMap.get(recordTypeName), 'Assertion failed in DHSApexUtilTest at source line 57');
        }
    }

    @IsTest
    static void testGetPickListValues() {
        Test.startTest();

        List<String> accountTypeValues =
            DHSApexUtil.getPickListValues(
                new Account(),
                'Type'
            );

        List<String> accountTypeValuesByName =
            DHSApexUtil.getPickListValuesIntoList(
                'Account',
                'Type'
            );

        Test.stopTest();

        System.assertNotEquals(null, accountTypeValues, 'Assertion failed in DHSApexUtilTest at source line 79');
        System.assertNotEquals(null, accountTypeValuesByName, 'Assertion failed in DHSApexUtilTest at source line 80');

        System.assertEquals(
            accountTypeValues.size(),
            accountTypeValuesByName.size(),
            'Both methods should return the same number of values'
        );

        System.assertEquals(
            new Set<String>(accountTypeValues),
            new Set<String>(accountTypeValuesByName),
            'Both methods should return the same picklist labels'
        );
    }

    @IsTest
    static void testQueryBuilderWithFilters() {
        List<String> fields = new List<String>{
            'Id',
            'Name'
        };

        List<String> filters = new List<String>{
            'Name != null',
            'IsDeleted = false'
        };

        Test.startTest();
        String generatedQuery =
            DHSApexUtil.queryBuilder(
                'Account',
                fields,
                filters
            );
        Test.stopTest();

        System.assertEquals(
            'SELECT Id,Name FROM Account' +
            ' WHERE Name != null and IsDeleted = false',
            generatedQuery
        , 'Assertion failed in DHSApexUtilTest at source line 116');
    }

    @IsTest
    static void testQueryBuilderWithoutFilters() {
        Test.startTest();

        String generatedQuery =
            DHSApexUtil.queryBuilder(
                'Contact',
                new List<String>{'Id', 'FirstName', 'LastName'},
                null
            );

        Test.stopTest();

        System.assertEquals(
            'SELECT Id,FirstName,LastName FROM Contact',
            generatedQuery
        , 'Assertion failed in DHSApexUtilTest at source line 136');
    }

    @IsTest
    static void testQueryBuilderWithOrderBy() {
        Test.startTest();

        String generatedQuery =
            DHSApexUtil.queryBuilder(
                'Account',
                new List<String>{'Id', 'Name'},
                new List<String>{'Name != null'},
                new List<String>{'Name ASC', 'CreatedDate DESC'}
            );

        Test.stopTest();

        System.assertEquals(
            'SELECT Id,Name FROM Account' +
            ' WHERE Name != null' +
            ' ORDER BY Name ASC,CreatedDate DESC',
            generatedQuery
        , 'Assertion failed in DHSApexUtilTest at source line 156');
    }

    @IsTest
    static void testCriteriaForTextValue() {
        DHSApexUtil.Criteria criterion =
            new DHSApexUtil.Criteria(
                'Name',
                'Test Account',
                '='
            );

        System.assertEquals(
            'Name = \'Test Account\'',
            criterion.getSOQLCriteria()
        , 'Assertion failed in DHSApexUtilTest at source line 173');

        System.assertEquals(true, criterion.IsFieldValueGiven(), 'Assertion failed in DHSApexUtilTest at source line 178');
    }

    @IsTest
    static void testCriteriaForNumericAndDateValues() {
        DHSApexUtil.Criteria integerCriterion =
            new DHSApexUtil.Criteria(
                'NumberOfEmployees',
                '100',
                '>=',
                'Integer'
            );

        DHSApexUtil.Criteria doubleCriterion =
            new DHSApexUtil.Criteria(
                'AnnualRevenue',
                '5000.50',
                '>',
                'Double'
            );

        DHSApexUtil.Criteria dateCriterion =
            new DHSApexUtil.Criteria(
                'CreatedDate',
                '2026-01-01',
                '>=',
                'Date'
            );

        System.assertEquals(
            'NumberOfEmployees >=100',
            integerCriterion.getSOQLCriteria()
        , 'Assertion failed in DHSApexUtilTest at source line 207');

        System.assertEquals(
            'AnnualRevenue >5000.50',
            doubleCriterion.getSOQLCriteria()
        , 'Assertion failed in DHSApexUtilTest at source line 212');

        System.assertEquals(
            'CreatedDate >=2026-01-01',
            dateCriterion.getSOQLCriteria()
        , 'Assertion failed in DHSApexUtilTest at source line 217');
    }

    @IsTest
    static void testCriteriaForNullAndEmptyValues() {
        DHSApexUtil.Criteria nullCriterion =
            new DHSApexUtil.Criteria(
                'ParentId',
                null,
                '='
            );

        DHSApexUtil.Criteria emptyCriterion =
            new DHSApexUtil.Criteria(
                'Name',
                '',
                '='
            );

        System.assertEquals(
            'ParentId = null',
            nullCriterion.getSOQLCriteria()
        , 'Assertion failed in DHSApexUtilTest at source line 239');

        System.assertEquals(false, nullCriterion.IsFieldValueGiven(), 'Assertion failed in DHSApexUtilTest at source line 244');
        System.assertEquals(false, emptyCriterion.IsFieldValueGiven(), 'Assertion failed in DHSApexUtilTest at source line 245');
    }

    @IsTest
    static void testGenerateWhereQuery() {
        List<DHSApexUtil.Criteria> criteria =
            new List<DHSApexUtil.Criteria>{
                new DHSApexUtil.Criteria(
                    'Name',
                    'Test Account',
                    '='
                ),
                new DHSApexUtil.Criteria(
                    'NumberOfEmployees',
                    '10',
                    '>=',
                    'Integer'
                ),
                new DHSApexUtil.Criteria(
                    'ParentId',
                    null,
                    '='
                )
            };

        Test.startTest();
        String whereClause =
            DHSApexUtil.generateWhereQuery(criteria);
        Test.stopTest();

        System.assertEquals(
            'Name = \'Test Account\'' +
            ' AND NumberOfEmployees >=10' +
            ' AND ParentId = null',
            whereClause
        , 'Assertion failed in DHSApexUtilTest at source line 275');
    }

    @IsTest
    static void testGenerateEmptyWhereQuery() {
        Test.startTest();

        String whereClause =
            DHSApexUtil.generateWhereQuery(
                new List<DHSApexUtil.Criteria>()
            );

        Test.stopTest();

        System.assertEquals('', whereClause, 'Assertion failed in DHSApexUtilTest at source line 294');
    }

    @IsTest
    static void testRunningInASandbox() {
        Boolean expectedValue = [
            SELECT IsSandbox
            FROM Organization
            LIMIT 1
        ].IsSandbox;

        Test.startTest();
        Boolean actualValue = DHSApexUtil.runningInASandbox();
        DHSApexUtil.dt(System.today());
        DHSApexUtil.dt(System.today());
        DHSApexUtil.dt(System.today());
        Test.stopTest();

        System.assertEquals(expectedValue, actualValue, 'Assertion failed in DHSApexUtilTest at source line 312');
    }

    @IsTest
    static void testFieldSetUtilities() {
        List<Schema.FieldSetMember> members = DHSApexUtil.readFieldSet(
            'OnboardingUser',
            'OnBoarding__c'
        );
        List<String> fields = DHSApexUtil.getFieldSetFields(
            'OnBoarding__c',
            'OnboardingUser'
        );
        List<Schema.FieldSetMember> describedMembers =
            DHSApexUtil.getFieldSetFieldsObjs(
                'OnBoarding__c',
                'OnboardingUser'
            );
        String query = DHSApexUtil.queryBuilder(
            'OnBoarding__c',
            'OnboardingUser',
            new List<String>{ 'Id != null' }
        );

        System.assert(!members.isEmpty(), 'Assertion failed in DHSApexUtilTest at source line 336');
        System.assertEquals(members.size(), fields.size(), 'Assertion failed in DHSApexUtilTest at source line 337');
        System.assertEquals(members.size(), describedMembers.size(), 'Assertion failed in DHSApexUtilTest at source line 338');
        System.assert(query.contains('WHERE Id != null'), 'Assertion failed in DHSApexUtilTest at source line 339');
    }

    private static Boolean containsIgnoreCase(
        List<String> values,
        String expectedValue
    ) {
        for (String currentValue : values) {
            if (currentValue != null &&
                currentValue.equalsIgnoreCase(expectedValue)) {
                return true;
            }
        }

        return false;
    }

    private static Boolean containsFieldIgnoreCase(
        Map<String, Schema.SObjectField> fields,
        String expectedField
    ) {
        for (String fieldName : fields.keySet()) {
            if (fieldName.equalsIgnoreCase(expectedField)) {
                return true;
            }
        }

        return false;
    }

    private static Boolean containsObjectKeyIgnoreCase(
        Map<Object, Object> values,
        String expectedKey
    ) {
        for (Object currentKey : values.keySet()) {
            if (String.valueOf(currentKey)
                .equalsIgnoreCase(expectedKey)) {
                return true;
            }
        }

        return false;
    }
}