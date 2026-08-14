@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class ReportColumnUtilitiesTest {
    @IsTest
    static void exercisesUtilityDataShaping() {
        Map<String, Object> flattened = utils.flatten(
            new Map<String, Object>{
                'root' => new Map<String, Object>{'value' => 'test'},
                'empty' => null
            },
            null
        );
        Assert.areEqual('test', flattened.get('root.value'), 'Assertion failed in ReportColumnUtilitiesTest at source line 13');
        Assert.isTrue(flattened.containsKey('empty'), 'Assertion failed in ReportColumnUtilitiesTest at source line 14');

        Account accountRecord = new Account(Name = 'Utility Account');
        insert accountRecord;
        Contact contactRecord = new Contact(
            LastName = 'Utility Contact', AccountId = accountRecord.Id
        );
        insert contactRecord;
        contactRecord = [
            SELECT Name, CreatedDate, Account.Name, Account.CreatedDate
            FROM Contact WHERE Id = :contactRecord.Id
        ];
        List<Map<String, Object>> converted = utils.convertToMapList(
            new List<SObject>{contactRecord},
            new List<String>{'Name', 'CreatedDate', 'Account.Name', 'Account.CreatedDate'}
        );
        Assert.areEqual('Utility Contact', converted[0].get('name'), 'Assertion failed in ReportColumnUtilitiesTest at source line 30');
        Assert.areEqual('Utility Account', converted[0].get('account.name'), 'Assertion failed in ReportColumnUtilitiesTest at source line 31');
        Assert.areEqual(
            'Utility Account',
            utils.getRelationalValue(contactRecord, 'Account.Name')
        , 'Assertion failed in ReportColumnUtilitiesTest at source line 32');
        Assert.isNull(utils.getRelationalValue(null, 'Name'), 'Assertion failed in ReportColumnUtilitiesTest at source line 36');
    }

    @IsTest
    static void maintainsReportConfiguration() {
        Report_Export__c reportField = new Report_Export__c(
            Label__c = 'Name', Api_Name__c = 'Name', Order__c = 1,
            System__c = 'Intel', Report_Type__c = 'Case__c'
        );
        insert reportField;
        Assert.areEqual(1, utils.getReportExport('Case__c', 'Intel').size(), 'Assertion failed in ReportColumnUtilitiesTest at source line 46');
        Assert.areEqual(true, utils.saveReport(
            new Map<String, String>{String.valueOf(reportField.Id) => '2'}
        ), 'Assertion failed in ReportColumnUtilitiesTest at source line 47');
        Assert.areEqual(true, utils.updateReport(new Map<String, String>{
            'id' => reportField.Id, 'label' => 'Updated', 'apiname' => 'Name'
        }), 'Assertion failed in ReportColumnUtilitiesTest at source line 50');
        Assert.areEqual(true, utils.updateReport(new Map<String, String>{
            'label' => 'Status', 'apiname' => 'Status__c',
            'currentsystem' => 'Intel', 'objectname' => 'Case__c'
        }), 'Assertion failed in ReportColumnUtilitiesTest at source line 53');
        Assert.isFalse(utils.getFieldData('Account').isEmpty(), 'Assertion failed in ReportColumnUtilitiesTest at source line 57');
    }

    @IsTest
    static void createsIntelAndDhsReportColumns() {
        generateReportColumn.createROIColumns();
        generateReportColumn.generateCDRLColumns();
        DHSGenerateReportColumn.createROIColumns();
        DHSGenerateReportColumn.generateCDRLColumns();
        Assert.isTrue([SELECT COUNT() FROM Report_Export__c] > 0, 'Assertion failed in ReportColumnUtilitiesTest at source line 66');
        Assert.isTrue([SELECT COUNT() FROM DHS_Report_Export__c] > 0, 'Assertion failed in ReportColumnUtilitiesTest at source line 67');
    }
}