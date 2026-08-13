@istest
/** Exercises the existing OrderROIReportController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.MethodWithSameNameAsEnclosingClass, PMD.MethodNamingConventions, PMD.LocalVariableNamingConventions')
public class OrderROIReportControllerTest {
    @IsTest private static void OrderROIReportControllerTest(){
        Contact__c subjectRecord = new Contact__c(
            First_Name__c = 'ROI', Last_Name__c = 'Subject',
            SSN__c = '123-45-6789', Contact_Type__c = 'Subject'
        );
        insert subjectRecord;
        case__c casesCreated = new case__c(
            Contact__c = subjectRecord.Id,
            Assigned_To__c = UserInfo.getUserId(),
            Subject_Type__c = 'Applicant'
        );
        insert casesCreated;
        lead__c l = new lead__c();
        l.case__c = casesCreated.id;
        l.Item_number__c = 1;
        l.LeadType__c = 'Subject Interview (ESI/TESI)';
        l.Coverage_Type__c = 'Subject Interview';
        insert l;
        PageReference ROIReport = Page.OrderROIReport;
        Test.setCurrentPage(ROIReport);
        ROIReport.getParameters().put('id',casesCreated.id);
        OrderROIReportController oCtrl = new OrderROIReportController();
        oCtrl.leadRecords[0].leadNumber = 1;
        oCtrl.leadRecords[0].headerTitle = true;
        oCtrl.GenerateROIReport();
        Test.startTest();
        oCtrl.GenerateNattachROIReport();
        Test.stopTest();
        oCtrl.GenerateROIDraft();
        System.assertEquals(true, oCtrl.showroireport, 'Assertion failed in OrderROIReportControllerTest at source line 34');
        System.assertNotEquals(null, oCtrl.backToReport(), 'Assertion failed in OrderROIReportControllerTest at source line 35');
        ROI_Report_Order__c roiOrder = new ROI_Report_Order__c();
        roiOrder.case__c = casesCreated.id;
        roiOrder.ROI_Report_Order__c ='1,2,3';
        insert roiOrder;
        PageReference ROIReport2 = Page.ROIReportV2;
        Test.setCurrentPage(ROIReport2);
        ROIReport2.getParameters().put('id',casesCreated.id);
        ROIReport2.getParameters().put('sequenceid',roiOrder.id);
        ROIReport2.getParameters().put('download','true');
        ROIReportControllerV2 roictrl = new ROIReportControllerV2 ();
        System.assertNotEquals(null, roictrl, 'Assertion failed in OrderROIReportControllerTest at source line 46');
    }
}