@IsTest
/** Exercises the existing DHSROIReportControllerV2 behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSROIReportControllerV2Test {
    @IsTest
    static void buildsVersionTwoReportWithoutLeads() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        DHS_Contact__c contactRecord = new DHS_Contact__c(
            First_Name__c = 'ROI', Last_Name__c = 'Subject',
            SSN__c = '123-45-6789', Contact_Type__c = 'Subject'
        );
        insert contactRecord;
        DHS_Case__c parentCase = new DHS_Case__c(
            Case_Number__c = 'ROI-V2-TEST',
            DHS_Contact__c = contactRecord.Id,
            DHS_Assigned_To__c = UserInfo.getUserId(),
            Customer_Delivery_Date__c = Date.today()
        );
        insert parentCase;
        List<String> leadTypes = new List<String>{
            'Subject Interview (ESI/TESI)', 'Subject Recontact (SUBC)',
            'Residence (RESI)', 'Employment (EMPL)', 'Education (EDUC)',
            'Medical (MEDI)', 'References (REFE)', 'General (GENL)',
            'Former Spouse (FMSP)', 'Unemployment', 'Law Enforcement (LAWE)',
            'Financial (FINL)'
        };
        List<DHS_Lead__c> leads = new List<DHS_Lead__c>();
        Integer itemNumber = 1;
        for (String leadType : leadTypes) {
            leads.add(new DHS_Lead__c(
                DHS_Case__c = parentCase.Id,
                Item_Number__c = itemNumber,
                LeadType__c = leadType,
                Coverage_Type__c = leadType == 'General (GENL)'
                    ? 'General Record' : 'Other',
                Status__c = 'Completed',
                Was_the_record_obtained__c = leadType == 'General (GENL)'
                    ? 'Yes' : null
            ));
            itemNumber++;
        }
        insert leads;
        DHS_ROI_Report_Order__c sequenceRecord =
            new DHS_ROI_Report_Order__c(
                DHS_Case__c = parentCase.Id,
                ROI_Report_Order__c = '1,2,3,4,5,6,7,8,9,10,11,12',
                HideTitles__c = '4'
            );
        insert sequenceRecord;
        Test.setCurrentPage(Page.DHSROIReport);
        ApexPages.currentPage().getParameters().put('id', parentCase.Id);
        ApexPages.currentPage().getParameters().put(
            'sequenceid', sequenceRecord.Id
        );
        ApexPages.currentPage().getParameters().put('download', 'true');
        DHSROIReportControllerV2 controller = new DHSROIReportControllerV2();
        System.assertEquals(parentCase.Id, controller.caseRecord.Id, 'Assertion failed in DHSROIReportControllerV2Test at source line 58');
        System.assertEquals(12, controller.totalLeads, 'Assertion failed in DHSROIReportControllerV2Test at source line 59');
        System.assertEquals(true, controller.hasSubjectInterview, 'Assertion failed in DHSROIReportControllerV2Test at source line 60');
        System.assertEquals(true, controller.hasSubjectRecontact, 'Assertion failed in DHSROIReportControllerV2Test at source line 61');
        System.assertEquals(true, controller.hasResidence, 'Assertion failed in DHSROIReportControllerV2Test at source line 62');
        System.assertEquals(
            null,
            DHSROIReportControllerV2.findClosest(new List<Integer>(), 1)
        , 'Assertion failed in DHSROIReportControllerV2Test at source line 63');
        }
    }
}