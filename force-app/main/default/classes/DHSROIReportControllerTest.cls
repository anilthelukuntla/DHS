@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSROIReportControllerTest {
    @IsTest
    static void buildsReportForCaseWithoutLeads() {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'ROI', Last_Name__c = 'Subject',
            Email__c = 'roi@example.test', SSN__c = '123-45-6789'
        );
        insert subject;
        DHS_Case__c parentCase = new DHS_Case__c(
            Case_Number__c = 'ROI-TEST',
            DHS_Contact__c = subject.Id,
            Investigations_Review_Date__c = Date.today().addDays(-5),
            QA_and_Review_Date__c = Date.today()
        );
        insert parentCase;
        List<String> leadTypes = new List<String>{
            'Employment (EMPL)', 'Education (EDUC)', 'Medical (MEDI)',
            'Subject Interview (ESI/TESI)', 'Subject Recontact (SUBC)',
            'Residence (RESI)', 'References (REFE)', 'General (GENL)',
            'Former Spouse (FMSP)', 'Unemployment',
            'Law Enforcement (LAWE)', 'Financial (FINL)'
        };
        List<DHS_Lead__c> leads = new List<DHS_Lead__c>();
        for (String leadType : leadTypes) {
            leads.add(new DHS_Lead__c(
                DHS_Case__c = parentCase.Id,
                DHS_Contact__c = subject.Id,
                LeadType__c = leadType,
                Assignee_Date__c = Date.today().addDays(-2),
                Completed_Date__c = Date.today()
            ));
        }
        insert leads;
        Test.setCurrentPage(Page.DHSROIReport);
        ApexPages.currentPage().getParameters().put('id', parentCase.Id);
        DHSROIReportController controller = new DHSROIReportController();
        System.assertEquals(parentCase.Id, controller.caseRecord.Id, 'Expected the asserted condition to hold');
        System.assertEquals(leadTypes.size(), controller.totalLeads, 'Expected the asserted condition to hold');
        System.assertEquals(1, controller.subjectInterviewList.size(), 'Expected the asserted condition to hold');
        System.assertNotEquals(null, controller.investigationDates, 'Expected the asserted condition to hold');
    }
}
