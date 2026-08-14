@isTest
/** Exercises the existing DHSROIReportControllerV3 behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSROIReportControllerV3Test {

    @testSetup
    static void setupData() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {

        DHS_Contact__c contactRecord = new DHS_Contact__c(
            First_Name__c = 'ROI', Last_Name__c = 'Subject',
            SSN__c = '123-45-6789', Contact_Type__c = 'Subject'
        );
        insert contactRecord;
        // Create a mock case
        DHS_Case__c caseRecord = new DHS_Case__c(
            Customer_Delivery_Date__c = Date.today(),
            DHS_Contact__c = contactRecord.Id,
            DHS_Assigned_To__c = UserInfo.getUserId(),
            Subject_Type__c = 'Applicant'
        );
        insert caseRecord;

        // Create ROI Report Order
        DHS_ROI_Report_Order__c roiOrder = new DHS_ROI_Report_Order__c(
            ROI_Report_Order__c='{1=(1), 2=(2)}',
            Subheader_Order__c='1,2,3,4,5,6,7,8,9,10,11',
            Without_Subheader_Order_del__c='',
            HideTitles__c = '4',
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
        List<String> additionalTypes = new List<String>{
            'Subject Recontact (SUBC)', 'Residence (RESI)',
            'Education (EDUC)', 'Medical (MEDI)', 'References (REFE)',
            'General (GENL)', 'Former Spouse (FMSP)', 'Unemployment',
            'Law Enforcement (LAWE)'
        };
        Integer itemNumber = 3;
        for (String leadType : additionalTypes) {
            leads.add(new DHS_Lead__c(
                DHS_Case__c = caseRecord.Id,
                LeadType__c = leadType,
                Item_number__c = itemNumber,
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
        DHS_Lead_RTA_Extension__c rta = new DHS_Lead_RTA_Extension__c(
            DHS_Lead__c=leads[0].Id,
            Foreign_Activities__c='Yes',
            Foreign_Contacts__c='Yes'
        );
        insert rta;
        }
    }

    @isTest
    static void testROIReportControllerV3FullCoverage() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        Test.startTest();

        // Mock page parameters
        ApexPages.currentPage().getParameters().put('id', [SELECT Id FROM DHS_Case__c LIMIT 1].Id);
        ApexPages.currentPage().getParameters().put('sequenceid', [SELECT Id FROM DHS_ROI_Report_Order__c LIMIT 1].Id);
        ApexPages.currentPage().getParameters().put('download', 'true');

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
        DHSROIReportControllerV3.dt(system.today());
        DHSROIReportControllerV3.dt(system.today());
        System.assertEquals(null, DHSROIReportControllerV3.findClosest(
            new List<Integer>(), 1
        ), 'Assertion failed in DHSROIReportControllerV3Test at source line 113');
        System.assertNotEquals(null, controller.leads, 'Assertion failed in DHSROIReportControllerV3Test at source line 116');
        }
    }

    
}