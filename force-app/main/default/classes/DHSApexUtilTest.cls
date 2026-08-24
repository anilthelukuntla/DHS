@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
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

        System.assertNotEquals(null, accountFields);
        System.assert(!accountFields.isEmpty());
        System.assert(containsIgnoreCase(accountFields, 'Id'));
        System.assert(containsIgnoreCase(accountFields, 'Name'));

        System.assertEquals(
            'Account',
            accountDescribe.getName()
        );

        System.assertNotEquals(null, describedFields);
        System.assert(
            containsFieldIgnoreCase(describedFields, 'Name'),
            'Account Name should be returned'
        );

        System.assertNotEquals(null, fieldTypes);
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

        System.assertNotEquals(null, recordTypeMap);

        for (String recordTypeName : recordTypeMap.keySet()) {
            System.assertNotEquals(null, recordTypeName);
            System.assertNotEquals(null, recordTypeMap.get(recordTypeName));
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

        System.assertNotEquals(null, accountTypeValues);
        System.assertNotEquals(null, accountTypeValuesByName);

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
        );
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
        );
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
        );
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
        );

        System.assertEquals(true, criterion.IsFieldValueGiven());
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
        );

        System.assertEquals(
            'AnnualRevenue >5000.50',
            doubleCriterion.getSOQLCriteria()
        );

        System.assertEquals(
            'CreatedDate >=2026-01-01',
            dateCriterion.getSOQLCriteria()
        );
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
        );

        System.assertEquals(false, nullCriterion.IsFieldValueGiven());
        System.assertEquals(false, emptyCriterion.IsFieldValueGiven());
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
        );
    }

    @IsTest
    static void testGenerateEmptyWhereQuery() {
        Test.startTest();

        String whereClause =
            DHSApexUtil.generateWhereQuery(
                new List<DHSApexUtil.Criteria>()
            );

        Test.stopTest();

        System.assertEquals('', whereClause);
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
        Test.stopTest();

        System.assertEquals(expectedValue, actualValue);
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
