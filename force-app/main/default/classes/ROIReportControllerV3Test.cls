@isTest
/** Exercises the existing ROIReportControllerV3 behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs')
public class ROIReportControllerV3Test {

    @testSetup
    static void setupData() {

        Contact__c contactRecord = new Contact__c(
            First_Name__c = 'ROI', Last_Name__c = 'Subject',
            SSN__c = '123-45-6789', Contact_Type__c = 'Subject'
        );
        insert contactRecord;
        // Create a mock case
        Case__c caseRecord = new Case__c(
            Customer_Delivery_Date__c = Date.today(),
            Contact__c = contactRecord.Id,
            Assigned_To__c = UserInfo.getUserId(),
            Subject_Type__c = 'Applicant'
        );
        insert caseRecord;

        // Create ROI Report Order
        ROI_Report_Order__c roiOrder = new ROI_Report_Order__c(
            ROI_Report_Order__c='1,2',
            Subheader_Order__c='{Employment (EMPL)={1=(Job1, Job2)}, Education (EDUC)={1=(School1)}}',
            Without_Subheader_Order_del__c='',
            HideTitles__c = '4',
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
            Assigned_To__c = UserInfo.getUserId(),
            Assignee_Date__c=Date.today(),
            Completed_Date__c=Date.today()
        ));
        leads.add(new Lead__c(
            Case__c=caseRecord.Id,
            LeadType__c='Employment (EMPL)',
            Assigned_To__c = UserInfo.getUserId(),
            Item_Number__c=2
        ));
        List<String> additionalTypes = new List<String>{
            'Subject Recontact (SUBC)', 'Residence (RESI)',
            'Education (EDUC)', 'Medical (MEDI)', 'References (REFE)',
            'General (GENL)', 'Former Spouse (FMSP)', 'Unemployment',
            'Law Enforcement (LAWE)', 'Financial (FINL)'
        };
        Integer itemNumber = 3;
        for (String leadType : additionalTypes) {
            leads.add(new Lead__c(
                Case__c = caseRecord.Id,
                LeadType__c = leadType,
                Item_Number__c = itemNumber,
                Assigned_To__c = UserInfo.getUserId(),
                Coverage_Type__c = leadType == 'General (GENL)'
                    ? 'General Record' : 'Other',
                Status__c = 'Completed',
                Was_the_record_obtained__c = leadType == 'General (GENL)'
                    ? 'Yes' : null
            ));
            itemNumber++;
        }
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
        ApexPages.currentPage().getParameters().put('download', 'true');

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
        ROIReportControllerV3.dt(system.today());
        ROIReportControllerV3.dt(system.today());
        System.assertEquals(
            null,
            ROIReportControllerV3.findClosest(new List<Integer>(), 1)
        , 'Assertion failed in ROIReportControllerV3Test at source line 112');
        System.assertEquals(
            2,
            ROIReportControllerV3.findClosest(
                new List<Integer>{ 10, 2 },
                1
            )
        , 'Assertion failed in ROIReportControllerV3Test at source line 116');
        System.assertNotEquals(null, controller.leads, 'Assertion failed in ROIReportControllerV3Test at source line 123');
    }

    
}