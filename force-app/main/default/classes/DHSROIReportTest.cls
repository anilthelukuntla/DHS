@IsTest
/** Exercises the existing DHSROIReport behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSROIReportTest {
    @IsTest
    static void buildsOrderedRoiReportForCase() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'ROI',
            Last_Name__c = 'Report Test',
            Email__c = 'roi-report-test@example.com',
            Contact_Type__c = 'Subject', SSN__c = '123-45-6789'
        );
        insert subject;
        DHS_Case__c caseRecord = new DHS_Case__c(
            DHS_Contact__c = subject.Id,
            Case_Number__c = 'ROI-REPORT-TEST',
            DHS_Assigned_To__c = UserInfo.getUserId(),
            Customer_Delivery_Date__c = Date.today()
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

        System.assertEquals(caseRecord.Id, controller.caseRecord.Id, 'Assertion failed in DHSROIReportTest at source line 47');
        System.assertEquals(1, controller.totalLeads, 'Assertion failed in DHSROIReportTest at source line 48');
        }
    }
}