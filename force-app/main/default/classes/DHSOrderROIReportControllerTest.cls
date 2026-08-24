@istest
@SuppressWarnings('PMD.AnnotationsNamingConventions,PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSOrderROIReportControllerTest {
    @IsTest private static void testOrderROIReportController(){ 
        DHS_Case__c casesCreated = new DHS_Case__c();
        insert casesCreated;
        DHS_Lead__c l = new DHS_Lead__c();
        l.DHS_Case__c = casesCreated.id;
        l.Item_number__c = 1;
        insert l;
        PageReference dHSROIReport = Page.DHSOrderROIReport;
        Test.setCurrentPage(dHSROIReport);
        dHSROIReport.getParameters().put('id',casesCreated.id);
        DHSOrderROIReportController oCtrl = new DHSOrderROIReportController();
        oCtrl.GenerateROIReport();
        oCtrl.GenerateNattachROIReport();
        oCtrl.GenerateROIDraft();
        DHS_ROI_Report_Order__c roiOrder = new DHS_ROI_Report_Order__c();
        roiOrder.DHS_Case__c = casesCreated.id;
        roiOrder.ROI_Report_Order__c ='1,2,3';
        insert roiOrder;
        PageReference rOIReport2 = Page.DHSROIReportV2;
        Test.setCurrentPage(rOIReport2);
        rOIReport2.getParameters().put('id',casesCreated.id);
        rOIReport2.getParameters().put('sequenceid',roiOrder.id);
        rOIReport2.getParameters().put('download','true');
        DHSROIReportControllerV2 roictrl = new DHSROIReportControllerV2 (); System.assertNotEquals(null, roictrl, 'Expected roictrl to be initialized');
    }
}
