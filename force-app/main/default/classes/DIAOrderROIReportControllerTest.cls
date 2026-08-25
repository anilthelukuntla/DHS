@isTest
public class DIAOrderROIReportControllerTest {
    TestMethod static void DIAOrderROIReportController(){
        Account acc = new Account(name='ISN');
        insert acc;
        DIACaseWizardController wizardController = new DIACaseWizardController();
        //To create new subject
        wizardController.newSubject.First_Name__c = 'test';
        wizardController.newSubject.Last_Name__c = 'investigator';
        wizardController.newSubject.Phone__c = '8197277272';
        wizardController.newSubject.State__c = 'CA';
        wizardController.newSubject.Email__c = 'test.investigator@test.com';
        
        pagereference pref = wizardController.CreateNewSubjectAction();
        //To search for existing subject
        wizardController.subjectFirstNameSearchEntry = 'test';
        wizardController.subjectLastNameSearchEntry = 'investigator';
        wizardController.subjectEmailSearchEntry = 'test.investigator@test.com';
        wizardController.SearchSubjectsAction();
        //check if the subject is present in the system.
        system.assertEquals(1, wizardController.subjectsSearched.size());
        wizardController.subjectsSearched[0].isSelected = true;
        //create a case
        wizardController.CreateCaseAction();
        List<DIA_case__c> casesCreated = [Select Id from DIA_case__c];
        
        DIAOrderROIReportController oCtrl = new DIAOrderROIReportController();
        oCtrl.GenerateROIReport();
        oCtrl.GenerateNattachROIReport();
        oCtrl.caseId = casesCreated[0].id;
        DIA_ROI_Report_Order__c roiOrder = new DIA_ROI_Report_Order__c();
        roiOrder.case__c = casesCreated[0].id;
        
        roiOrder.ROI_Report_Order__c ='1,2,3';
        insert roiOrder;
        oCtrl.currentsequenceid =roiOrder.id; 
        oCtrl.GenerateROIDraft();
        octrl.GenerateImprovisedROIDraft();
        dia_lead__c ld = new dia_lead__c();
        ld.case__c = casesCreated[0].id;
        ld.Assigned_To__c = userinfo.getuserId();
        ld.LeadType__c = 'Employment (EMPL)';
        insert ld;
        
        //ROIReportController test starts...
        PageReference ROIReport2 = Page.BIROIReportV2;
        Test.setCurrentPage(ROIReport2);
        ROIReport2.getParameters().put('id',casesCreated[0].id);
        ROIReport2.getParameters().put('sequenceid',roiOrder.id);
        DIAROIReportControllerV2 roictrl = new DIAROIReportControllerV2 ();
        
        DIAOrderROIReportController oCtrl1 = new DIAOrderROIReportController();
        oCtrl1.GenerateROIReport();
        oCtrl1.GenerateNattachROIReport();
        oCtrl1.caseId = casesCreated[0].id;
        DIA_ROI_Report_Order__c roiOrder1 = new DIA_ROI_Report_Order__c();
        roiOrder1.case__c = casesCreated[0].id;
        
        roiOrder1.ROI_Report_Order__c ='1,2,3';
        insert roiOrder1; 
        oCtrl1.GenerateROIDraft();
        oCtrl1.GenerateImprovisedROIDraft();
    }
}