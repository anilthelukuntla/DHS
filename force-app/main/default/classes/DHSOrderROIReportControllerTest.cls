@istest
/** Exercises the existing DHSOrderROIReportController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.MethodWithSameNameAsEnclosingClass, PMD.MethodNamingConventions, PMD.LocalVariableNamingConventions')
public class DHSOrderROIReportControllerTest {
    @IsTest private static void DHSOrderROIReportControllerTest(){
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        DHS_Contact__c subjectRecord = new DHS_Contact__c(
            First_Name__c = 'ROI', Last_Name__c = 'Subject',
            SSN__c = '123-45-6789', Contact_Type__c = 'Subject'
        );
        insert subjectRecord;
        DHS_Case__c casesCreated = new DHS_Case__c(
            DHS_Contact__c = subjectRecord.Id,
            DHS_Assigned_To__c = UserInfo.getUserId(),
            Subject_Type__c = 'Applicant'
        );
        insert casesCreated;
        DHS_Lead__c l = new DHS_Lead__c(
            DHS_Case__c = casesCreated.Id,
            Item_number__c = 1,
            LeadType__c = 'Subject Interview (ESI/TESI)',
            Coverage_Type__c = 'Subject Interview'
        );
        insert l;
        PageReference DHSROIReport = Page.DHSOrderROIReport;
        Test.setCurrentPage(DHSROIReport);
        DHSROIReport.getParameters().put('id',casesCreated.id);
        DHSOrderROIReportController oCtrl = new DHSOrderROIReportController();
        oCtrl.leadRecords[0].leadNumber = 1;
        oCtrl.leadRecords[0].headerTitle = true;
        oCtrl.GenerateROIReport();
        Test.startTest();
        oCtrl.GenerateNattachROIReport();
        Test.stopTest();
        oCtrl.GenerateROIDraft();
        System.assertEquals(true, oCtrl.showroireport, 'Assertion failed in DHSOrderROIReportControllerTest at source line 37');
        System.assertNotEquals(null, oCtrl.PreviewUsingDhsDesigner(), 'Assertion failed in DHSOrderROIReportControllerTest at source line 38');
        System.assertNotEquals(null, oCtrl.backToReport(), 'Assertion failed in DHSOrderROIReportControllerTest at source line 39');
        DHS_ROI_Report_Order__c roiOrder = new DHS_ROI_Report_Order__c();
        roiOrder.DHS_Case__c = casesCreated.id;
        roiOrder.ROI_Report_Order__c ='1,2,3';
        insert roiOrder;
        PageReference ROIReport2 = Page.DHSROIReportV2;
        Test.setCurrentPage(ROIReport2);
        ROIReport2.getParameters().put('id',casesCreated.id);
        ROIReport2.getParameters().put('sequenceid',roiOrder.id);
        ROIReport2.getParameters().put('download','true');
        DHSROIReportControllerV2 roictrl = new DHSROIReportControllerV2 ();
        System.assertNotEquals(null, roictrl, 'Assertion failed in DHSOrderROIReportControllerTest at source line 50');
        }
    }
}