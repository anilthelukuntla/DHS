@isTest
public class ROIReportControllerV3Test {

    @testSetup
    static void setupData() {

        // Create a mock case
        Case__c caseRecord = new Case__c( Customer_Delivery_Date__c=Date.today());
        insert caseRecord;

        // Create ROI Report Order
        ROI_Report_Order__c roiOrder = new ROI_Report_Order__c(
            ROI_Report_Order__c='1,2',
            Subheader_Order__c='{Employment (EMPL)={1=(Job1, Job2)}, Education (EDUC)={1=(School1)}}',
            Without_Subheader_Order_del__c='',
            Case__c = caseRecord.Id
        );
        insert roiOrder;

        // Create sample Leads
        List<Lead__c> leads = new List<Lead__c>();
        leads.add(new Lead__c(
            Case__c=caseRecord.Id,
            LeadType__c='Subject Interview (ESI/TESI)',
            Item_Number__c= 1,
            Standardised_Issues_Picklist__c='Issue1;Issue2',
            Standardised_Issues_Other_Description__c='OtherDesc',
            Assignee_Date__c=Date.today(),
            Completed_Date__c=Date.today()
        ));
        leads.add(new Lead__c(
            Case__c=caseRecord.Id,
            LeadType__c='Employment (EMPL)',
            Item_Number__c=2
        ));
        insert leads;

        // Create RTA Extension
        Lead_RTA_Extension__c rta = new Lead_RTA_Extension__c(
            Lead__c=leads[0].Id,
            Foreign_Activities__c='Yes',
            Foreign_Contacts__c='Yes'
        );
        insert rta;
    }

    @isTest
    static void testROIReportControllerV3FullCoverage() {
        Test.startTest();

        // Mock page parameters
        ApexPages.currentPage().getParameters().put('id', [SELECT Id FROM Case__c LIMIT 1].Id);
        ApexPages.currentPage().getParameters().put('sequenceid', [SELECT Id FROM ROI_Report_Order__c LIMIT 1].Id);

        // Mock ApexUtil static methods
        

        // Instantiate the controller
        ROIReportControllerV3 controller = new ROIReportControllerV3();

        // Optionally invoke public methods to verify behavior
        controller.FetchCaseInformation();
        controller.FetchLeadInformation();

        Test.stopTest();

        // Add assertions to validate logic
        
        
        string str = '{Employment (EMPL)={1=(Job1, Job2)}, Education (EDUC)={1=(School1)}}';
        ROIReportControllerV3.parseFullMapString(str);
        ROIReportControllerV3.dt(system.today());
        ROIReportControllerV3.dt(system.today(),false);
        ROIReportControllerV3.dt(system.today(),false,true);
    }

    
}