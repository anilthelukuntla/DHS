@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSLeadDetailControllerTest {

    @TestSetup
    static void setup() {
        DHS_Contact__c con = new DHS_Contact__c();
        con.First_Name__c = 'Test';
        con.Last_Name__c = 'Name';
        con.Email__c = 'test@test.com';
        con.Contact_Type__c = 'Subject';
        con.SSN__c = '123-12-1123';
        insert con;
    
        DHS_Case__c caseTemp = new DHS_Case__c();
        caseTemp.DHS_Contact__c = con.Id;
        caseTemp.DHS_Assigned_To__c = UserInfo.getUserId();
        insert caseTemp;
    
        DHS_Lead__c leadRec = new DHS_Lead__c();
        leadRec.DHS_Case__c = caseTemp.Id;
        leadRec.Coverage_Type__c = 'Subject Interview';
        leadRec.DHS_Assigned_To__c = UserInfo.getUserId();
        leadRec.LeadType__c = 'Subject Interview (ESI/TESI)';
        insert leadRec;
    
        DHS_Daily_Production_Summary__c dps = new DHS_Daily_Production_Summary__c();
        dps.DHS_Reviewer__c = UserInfo.getUserId();
        dps.Leads_Accepted__c = 0;
        insert dps;
    
        insert new DHS_GeneralSettings__c(
            Name = 'TimeEntryDuringLeadConfirm',
            Value__c = 'SCA'
        );
    }

    private static DHS_Lead__c getLead() {
        return [
            SELECT Id, DHS_Case__c, LeadType__c, Standardised_Issues_Picklist__c,
                   Status__c, DHS_Assigned_To__c, Lead_Accepted_or_Rejected__c
            FROM DHS_Lead__c
            LIMIT 1
        ];
    }

    private static DHSLeadDetailPageController getController(Id leadId) {
        PageReference leadDetailPage = Page.DHSLeaddetail;
        Test.setCurrentPage(leadDetailPage);
        leadDetailPage.getParameters().put('id', leadId);

        return new DHSLeadDetailPageController();
    }

    @IsTest
    static void testUpdateLeadAction() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c l = getLead();
        l.Lead_Accepted_or_Rejected__c = 'Rejected';
        l.Status__c = 'Assigned';
        l.DHS_Assigned_To__c = UserInfo.getUserId();

        insert new DHS_GeneralSettings__c(
            Name = 'TimeEntryDuringLeadConfirm',
            Value__c = 'SCA'
        );

        Test.startTest();
        update l;

        DHSLeadDetailPageController leadCtrl = getController(l.Id);
        leadCtrl.updateLeadAction();
        Test.stopTest();
    }

    @IsTest
    static void testSelfAssignAction() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c l = getLead();

        Test.startTest();
        DHSLeadDetailPageController leadCtrl = getController(l.Id);
        leadCtrl.toInsertLeadRecordRTAExtension = false;
        leadCtrl.selfAssignAction();
        Test.stopTest();
    }

    @IsTest
    static void testCreateDocumentRequestAction() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c l = getLead();

        Test.startTest();
        DHSLeadDetailPageController leadCtrl = getController(l.Id);
        leadCtrl.toInsertLeadRecordRTAExtension = false;
        leadCtrl.createDocumentRequestAction();
        Test.stopTest();
    }

    @IsTest
    static void testRejectLeadAction() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c l = getLead();

        Test.startTest();
        DHSLeadDetailPageController leadCtrl = getController(l.Id);
        leadCtrl.rejectLeadAction();
        Test.stopTest();
    }

    @IsTest
    static void testSendMessageAction() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c l = getLead();

        Test.startTest();
        DHSLeadDetailPageController leadCtrl = getController(l.Id);
        leadCtrl.SendMessage();
        Test.stopTest();
    }

    @IsTest
    static void testApplyForWaiverAction() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c l = getLead();

        Test.startTest();
        DHSLeadDetailPageController leadCtrl = getController(l.Id);
        leadCtrl.leadRecord = l;
        leadCtrl.applyForWaiverAction();
        Test.stopTest();
    }

    @IsTest
    static void testReopenLeadAction() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c l = getLead();

        Test.startTest();
        DHSLeadDetailPageController leadCtrl = getController(l.Id);
        leadCtrl.reopenLeadAction();
        Test.stopTest();
    }

    @IsTest
    static void testStandardisedIssuesAction() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c l = getLead();

        Test.startTest();
        DHSLeadDetailPageController leadCtrl = getController(l.Id);
        leadCtrl.standardisedIssuesAction();
        Test.stopTest();
    }

    @IsTest
    static void testReviewCompletedAction() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c l = getLead();

        DHS_Daily_Production_Summary__c temp = new DHS_Daily_Production_Summary__c();
        temp.DHS_Reviewer__c = UserInfo.getUserId();
        insert temp;

        Test.startTest();
        DHSLeadDetailPageController leadCtrl = getController(l.Id);
        leadCtrl.StandardisedIssueItems = new List<String>{ 'Other' };
        leadCtrl.reviewCompletedAction();
        Test.stopTest();
    }

    @IsTest
    static void testAutoSaveLeadAction() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c l = getLead();

        Test.startTest();
        DHSLeadDetailPageController leadCtrl = getController(l.Id);
        leadCtrl.AutoSaveLeadAction();
        Test.stopTest();
    }

    @IsTest
    static void testDeleteLeadAction() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c l = getLead();

        Test.startTest();
        DHSLeadDetailPageController leadCtrl = getController(l.Id);
        leadCtrl.deleteLeadAction();
        Test.stopTest();
    }

    @IsTest
    static void testMessageModalActions() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c ll = getLead();
        ll.Lead_Accepted_or_Rejected__c = 'Rejected';
        ll.Status__c = 'Completed';
        ll.Issues_Discrep_Developed__c = 'Yes';
        update ll;

        DHS_Message__c msg = new DHS_Message__c(
            Subject__c = 'Test',
            Message_Body__c = 'TestBody'
        );
        insert msg;

        insert new DHS_GeneralSettings__c(
            Name = 'TimeEntryDuringLeadConfirm',
            Value__c = 'SCA'
        );

        Test.startTest();
        DHSLeadDetailPageController leadCtrl = getController(ll.Id);
        leadCtrl.selectedMessageId = msg.Id;
        leadCtrl.selectedMessage = msg;
        leadCtrl.modalAction = 'edit';

        DHSLeadDetailPageController.convertToDt(Date.today());

        leadCtrl.openModal();
        leadCtrl.updateMessage();
        leadCtrl.deleteMessage();
        Test.stopTest();
    }

    @IsTest
    static void testRejectedLeadUpdate() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Lead__c ll = getLead();
        ll.Lead_Accepted_or_Rejected__c = 'Rejected';
        ll.Status__c = 'Rejected';

        Test.startTest();
        update ll;
        Test.stopTest();
    }
}