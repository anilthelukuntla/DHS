@IsTest
/** Focused coverage for DHS report and data-shaping utilities. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSUtilsTest {
    @IsTest
    static void flattensAndConvertsRecords() {
        Map<String, Object> flattened = DHSUtils.flatten(
            new Map<String, Object>{
                'case' => new Map<String, Object>{
                    'name' => 'Test',
                    'empty' => null
                },
                'status' => 'Active'
            },
            null
        );
        System.assertEquals('Test', flattened.get('case.name'), 'Assertion failed in DHSUtilsTest at source line 17');
        System.assert(flattened.containsKey('case.empty'), 'Assertion failed in DHSUtilsTest at source line 18');

        Account accountRecord = new Account(Name = 'Utility Account');
        insert accountRecord;
        accountRecord = [
            SELECT Name, CreatedDate, Owner.Name, Parent.Name
            FROM Account WHERE Id = :accountRecord.Id
        ];
        List<Map<String, Object>> converted = DHSUtils.convertToMapList(
            new List<SObject>{ accountRecord },
            new List<String>{ 'Name', 'CreatedDate', 'Owner.Name', 'Parent.Name' }
        );
        System.assertEquals('Utility Account', converted[0].get('name'), 'Assertion failed in DHSUtilsTest at source line 30');
        System.assertNotEquals('', converted[0].get('createddate'), 'Assertion failed in DHSUtilsTest at source line 31');
        System.assertNotEquals('', converted[0].get('owner.name'), 'Assertion failed in DHSUtilsTest at source line 32');
        System.assertEquals('', converted[0].get('parent.name'), 'Assertion failed in DHSUtilsTest at source line 33');
        System.assertEquals(null, DHSUtils.getRelationalValue(null, 'Name'), 'Assertion failed in DHSUtilsTest at source line 34');
    }

    @IsTest
    static void maintainsReportConfigurationAndDescribesFields() {
        DHS_Report_Export__c reportField = new DHS_Report_Export__c(
            Label__c = 'Case Number',
            Api_Name__c = 'Name',
            Order__c = 1,
            System__c = 'Intel',
            Report_Type__c = 'Case__c'
        );
        insert reportField;

        System.assertEquals(
            1,
            DHSUtils.getReportExport('Case__c', 'Intel').size()
        , 'Assertion failed in DHSUtilsTest at source line 48');
        System.assertEquals(
            true,
            DHSUtils.saveReport(
                new Map<String, String>{ String.valueOf(reportField.Id) => '2' }
            )
        , 'Assertion failed in DHSUtilsTest at source line 52');
        System.assertEquals(
            true,
            DHSUtils.updateReport(new Map<String, String>{
                'id' => reportField.Id,
                'label' => 'Updated Label',
                'apiname' => 'Name'
            })
        , 'Assertion failed in DHSUtilsTest at source line 58');
        System.assertEquals(
            true,
            DHSUtils.updateReport(new Map<String, String>{
                'label' => 'Status',
                'apiname' => 'Status__c',
                'currentsystem' => 'Intel',
                'objectname' => 'Case__c'
            })
        , 'Assertion failed in DHSUtilsTest at source line 66');
        System.assert(!DHSUtils.getFieldData('Account').isEmpty(), 'Assertion failed in DHSUtilsTest at source line 75');
        System.assert(!new DHSUtils().data.isEmpty(), 'Assertion failed in DHSUtilsTest at source line 76');
    }
}