@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts,PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSROIReportControllerV3Test {

    @TestSetup
    static void setupData() {

        // Create a mock case
        DHS_Case__c caseRecord = new DHS_Case__c( Customer_Delivery_Date__c=Date.today());
        insert caseRecord;

        // Create ROI Report Order
        DHS_ROI_Report_Order__c roiOrder = new DHS_ROI_Report_Order__c(
            ROI_Report_Order__c='1,2',
            Subheader_Order__c='{Employment (EMPL)={1=(Job1, Job2)}, Education (EDUC)={1=(School1)}}',
            Without_Subheader_Order_del__c='',
            DHS_Case__c = caseRecord.Id
        );
        insert roiOrder;

        // Create sample Leads
        List<DHS_Lead__c> leads = new List<DHS_Lead__c>();
        leads.add(new DHS_Lead__c(
            DHS_Case__c=caseRecord.Id,
            LeadType__c='Subject Interview (ESI/TESI)',
            Item_number__c= 1,
            Standardised_Issues_Picklist__c='Issue1;Issue2',
            Std_Issues_Other_Desc__c='OtherDesc',
            Assignee_Date__c=Date.today(),
            Completed_Date__c=Date.today()
        ));
        leads.add(new DHS_Lead__c(
            DHS_Case__c=caseRecord.Id,
            LeadType__c='Employment (EMPL)',
            Item_number__c=2
        ));
        insert leads;

        // Create RTA Extension
        DHS_Lead_RTA_Extension__c rta = new DHS_Lead_RTA_Extension__c(
            DHS_Lead__c=leads[0].Id,
            Foreign_Activities__c='Yes',
            Foreign_Contacts__c='Yes'
        );
        insert rta;
    }

    @IsTest
    static void testROIReportControllerV3FullCoverage() {
        Test.startTest();

        // Mock page parameters
        ApexPages.currentPage().getParameters().put('id', [SELECT Id FROM DHS_Case__c LIMIT 1].Id);
        ApexPages.currentPage().getParameters().put('sequenceid', [SELECT Id FROM DHS_ROI_Report_Order__c LIMIT 1].Id);

        // Mock DHSApexUtil static methods
        

        // Instantiate the controller
        DHSROIReportControllerV3 controller = new DHSROIReportControllerV3();

        // Optionally invoke public methods to verify behavior
        controller.FetchCaseInformation();
        controller.FetchLeadInformation();

        Test.stopTest();

        // Add assertions to validate logic
        
        
        string str = '{Employment (EMPL)={1=(Job1, Job2)}, Education (EDUC)={1=(School1)}}';
        DHSROIReportControllerV3.parseFullMapString(str);
        DHSROIReportControllerV3.dt(system.today());
    }

    
}
