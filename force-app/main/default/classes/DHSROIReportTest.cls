@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
public class DHSROIReportTest {
    @IsTest
    static void buildsOrderedRoiReportForCase() {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'ROI',
            Last_Name__c = 'Report Test',
            Email__c = 'roi-report-test@example.com'
        );
        insert subject;
        DHS_Case__c caseRecord = new DHS_Case__c(
            DHS_Contact__c = subject.Id,
            Case_Number__c = 'ROI-REPORT-TEST'
        );
        insert caseRecord;
        DHS_Lead__c lead = new DHS_Lead__c(
            DHS_Case__c = caseRecord.Id,
            LeadType__c = 'Subject Interview (ESI/TESI)',
            Coverage_Type__c = 'Subject Interview',
            Item_number__c = 1
        );
        insert lead;
        DHS_ROI_Report_Order__c reportOrder = new DHS_ROI_Report_Order__c(
            DHS_Case__c = caseRecord.Id,
            ROI_Report_Order__c = '1'
        );
        insert reportOrder;

        Test.setCurrentPage(Page.DHSROIReportV2);
        ApexPages.currentPage().getParameters().put('id', caseRecord.Id);
        ApexPages.currentPage().getParameters().put(
            'sequenceid', reportOrder.Id
        );

        Test.startTest();
        DHSROIReportControllerV2 controller =
            new DHSROIReportControllerV2();
        Test.stopTest();

        System.assertEquals(caseRecord.Id, controller.caseRecord.Id);
        System.assertEquals(1, controller.totalLeads);
    }
}
