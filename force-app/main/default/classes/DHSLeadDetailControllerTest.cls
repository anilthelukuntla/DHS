@IsTest
/** Verifies legacy DHS lead-detail actions under the production access model. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSLeadDetailControllerTest {
    @IsTest
    static void exercisesLegacyLeadActions() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            DHS_Contact__c contactRecord = new DHS_Contact__c(
                First_Name__c = 'Legacy', Last_Name__c = 'Subject',
                Email__c = 'legacy.subject@example.com',
                Contact_Type__c = 'Subject', SSN__c = '123-45-6789'
            );
            insert contactRecord;
            DHS_Case__c caseRecord = new DHS_Case__c(
                DHS_Contact__c = contactRecord.Id,
                DHS_Assigned_To__c = UserInfo.getUserId()
            );
            insert caseRecord;
            DHS_Lead__c leadRecord = new DHS_Lead__c(
                DHS_Case__c = caseRecord.Id,
                Coverage_Type__c = 'Subject Interview',
                DHS_Assigned_To__c = UserInfo.getUserId(),
                LeadType__c = 'Subject Interview (ESI/TESI)',
                Item_Number__c = 1,
                Status__c = 'Assigned'
            );
            insert leadRecord;
            insert new DHS_GeneralSettings__c(
                Name = 'TimeEntryDuringLeadConfirm', Value__c = 'SCA'
            );

            Test.setCurrentPage(Page.DHSLeaddetail);
            ApexPages.currentPage().getParameters().put('id', leadRecord.Id);
            DHSLeadDetailPageController controller =
                new DHSLeadDetailPageController();

            controller.updateLeadAction();
            controller.selfAssignAction();
            controller.StandardisedIssueItems = new List<String>{ 'Other' };
            controller.standardisedIssuesAction();
            controller.reopenLeadAction();
            controller.AutoSaveLeadAction();

            System.assertEquals(leadRecord.Id, controller.leadRecord.Id, 'Assertion failed in DHSLeadDetailControllerTest at source line 45');
        }
    }
}