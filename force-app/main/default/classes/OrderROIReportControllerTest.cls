@istest
public class OrderROIReportControllerTest {
    testMethod private static void OrderROIReportControllerTest(){ 
        case__c casesCreated = new case__c();
        insert casesCreated;
        lead__c l = new lead__c();
        l.case__c = casesCreated.id;
        l.Item_number__c = 1;
        insert l;
        PageReference ROIReport = Page.OrderROIReport;
        Test.setCurrentPage(ROIReport);
        ROIReport.getParameters().put('id',casesCreated.id);
        OrderROIReportController oCtrl = new OrderROIReportController();
        oCtrl.GenerateROIReport();
        oCtrl.GenerateNattachROIReport();
        oCtrl.GenerateROIDraft();
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
    }
}