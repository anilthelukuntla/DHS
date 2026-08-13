@isTest
/** Exercises the existing DHSCaseDetailController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.LocalVariableNamingConventions, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.MethodNamingConventions, PMD.NcssCount, PMD.ApexUnitTestClassShouldHaveAsserts')
public class DHSCaseDetailControllerTest {
	  @testSetup static void setup() {
         User pmoUser = PPFDHSTestUserFactory.createPmoUser();
         PPFDHSTestUserFactory.createInvUser();
         System.runAs(pmoUser) {
     	 DHS_Contact__c con = new DHS_Contact__c();
         con.First_Name__c = 'Test';
          
         con.Last_Name__c = 'Name';
         con.Email__c  = 'test@test.com';
         con.Contact_Type__c = 'Subject';
		 con.SSN__c = '123-12-1123';
         insert con;
         DHS_Case__c CaseTemp = new DHS_Case__c();
         CaseTemp.DHS_Contact__c = con.id;
         CaseTemp.DHS_Assigned_To__c = userinfo.getuserId();
         insert CaseTemp;
         DHS_Lead__c Lead = new DHS_Lead__c();
         Lead.DHS_Case__c = CaseTemp.id;
         //Lead.DHS_Assigned_To__c = userinfo.getuserid();
         Lead.Coverage_Type__c = 'Subject Interview';
         Lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert Lead;
         }
     }
    @IsTest private static void TestMethod1(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        list<DHS_Case__c> casesCreated = [select id from DHS_Case__c];
         PageReference casedetailpage = Page.DHSCasedetail;
        Test.setCurrentPage(casedetailpage);
        casedetailpage.getParameters().put('id',casesCreated[0].id); 
        casesCreated[0].Case_Number__c = '1234';
        update casesCreated[0];
        
        
        //Insert a document
        DHS_Document__c doc = new DHS_Document__c();
        doc.DHS_Case__c = casesCreated[0].id;
        doc.Name__c = 'testingdocument.pdf';
        insert doc;
        Attachment att = new Attachment();
        att.Body = Blob.valueOf('String1');
        att.ParentId = doc.id;
        att.name = 'testingdocument.pdf';
        insert att;
        
        doc = new DHS_Document__c();
        doc.DHS_Case__c = casesCreated[0].id;
        doc.Name__c = 'ROIReport';
        insert doc;
        att = new Attachment();
        att.Body = Blob.valueOf('String1');
        att.ParentId = doc.id;
        att.name = 'ROIReport';
        insert att;
        DHSDownloadDeliverablesController ddctrl = new DHSDownloadDeliverablesController();
        ddctrl.caseNumberToSearch = '1234';
        ddctrl.searchaction();
        DHSCaseDetailController casedetailctrl = new DHSCaseDetailController();
        casesCreated[0].Subject_Type__c = 'Applicant';
        casedetailctrl.SetPPFContactInfo();
        casesCreated[0].Subject_Type__c = 'Contractor';
        casedetailctrl.SetPPFContactInfo();
        //create new lead
        casedetailctrl.newLead.LeadType__c = 'Subject Interview (ESI/TESI)';
        casedetailctrl.newLead.Method__c = 'Telephonic';
        casedetailctrl.newLead.Coverage_Type__c = 'Personal';
        casedetailctrl.CreateLeadAction();
        List<DHS_Lead__c> leadsCreated = [Select Id from DHS_Lead__c];
        DHSCaseDetailController.CheckIfLeadIsAssigned(leadsCreated[0].id);
        casedetailctrl.deleteDocumentID = doc.id;
        casedetailctrl.DeleteDocumentAction();
        //Lead creation check
        system.assertEquals(2,leadsCreated.size(), 'Assertion failed in DHSCaseDetailControllerTest at source line 77');
        casedetailctrl.markleadcreationcompleteaction();
        casedetailctrl.AddCommentsAction();
        casedetailctrl.qareviewcompleteaction();
        casedetailctrl.regenerateroireportbuttonaction();
        casedetailctrl.leadIdToUpdate = leadscreated[0].id;
        casedetailctrl.itemnumbertoupdate = 4;
        casedetailctrl.updatelead();
        casedetailctrl.updatecaseaction();
        casedetailctrl.selectedUserIdForAssignment = userinfo.getuserid();
        casedetailctrl.updatecaseaction();
        DHS_Waiver_Information__c wi = new DHS_Waiver_Information__c();
        wi.DHS_Case__c = casesCreated[0].id;
        insert wi;
        casedetailctrl.FetchWaiverInformation();
        casedetailctrl.waiverinformationidtoupdate = wi.id;
        casedetailctrl.autosavewaiverinformationaction();
        casedetailctrl.updatewaiverinformation();
        }
    }
    @IsTest private static void Testmethod20(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
       	DHS_Case__c c =new DHS_Case__c(Subject_Type__c = 'Applicant');
        insert c;
          PageReference casedetailpage = Page.DHSCasedetail;
        Test.setCurrentPage(casedetailpage);
        casedetailpage.getParameters().put('id',c.id); 
        DHSCaseDetailController casedetailctrl = new DHSCaseDetailController();
        casedetailctrl.SetPPFContactInfo();
        
        DHS_Case__c c1 =new DHS_Case__c(Subject_Type__c = 'Contractor');
        insert c1;
          PageReference casedetailpage1 = Page.DHSCasedetail;
        Test.setCurrentPage(casedetailpage1);
        casedetailpage1.getParameters().put('id',c1.id); 
        DHSCaseDetailController casedetailctrl1 = new DHSCaseDetailController();
        casedetailctrl1.SetPPFContactInfo();
        
          ContentVersion content=new ContentVersion(); 
        content.Title='2022-02-11-12_46_39S_12313123123'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.LinkedEntityId=sPayoff.id;
        content.origin = 'H';
        insert content;
        
        user u = [select id, email,User_Type__c from user where id=:userinfo.getuserid()];
        DHSCaseDetailController.FetchToAddressOfCase(c,u);
        DHSCaseDetailController.FetchUsersOfCase(c,u);
        }
    }
    @IsTest private static void TestAutoCreateLeads(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        DHS_Auto_Lead_Generation_Template__c temp = new DHS_Auto_Lead_Generation_Template__c(Name__c='Test');
        insert temp;
        DHS_Auto_Lead_Generation_Setting__c setting = new DHS_Auto_Lead_Generation_Setting__c();
        setting.DHS_Auto_Lead_Generation_Template__c =temp.id;
        setting.Coverage_Type__c = 'Personal';
        setting.Item_number__c = 1;
        setting.Lead_Type__c = 'UnEmployment';
        insert setting;
        PageReference casedetailpage = Page.DHSCasedetail;
        Test.setCurrentPage(casedetailpage);
        DHS_Case__c c = new DHS_Case__c();
        insert c;
        casedetailpage.getParameters().put('id',c.id); 
        DHSCaseDetailController ctrl = new DHSCaseDetailController();
        ctrl.SendMessage();
         ctrl.SendMessage('test','test',[select id from DHS_Lead__c limit 1].id);
        ctrl.deleteLeadId = [select id from DHS_Lead__c limit 1].id;
        ctrl.DeleteLeadAction();
        
       DHS_Message__c msg = new DHS_Message__c(Subject__c  = 'Test',Message_Body__c='TestBody');
        insert msg;
        DHSCaseDetailController temp1 = New DHSCaseDetailController();
        temp1.selectedMessageId = msg.Id;
        temp1.selectedMessage = msg;
        temp1.modalAction = 'edit';
        temp1.openModal();
        temp1.updateMessage();
        temp1.deleteMessage();
        }
        
    }

    @IsTest
    static void testMessagePaginationBranches() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            DHS_Case__c caseRecord = [SELECT Id FROM DHS_Case__c LIMIT 1];
            insert new List<DHS_Message__c>{
                new DHS_Message__c(
                    DHS_Case__c = caseRecord.Id, Subject__c = 'First', Message_Body__c = 'Body'
                ),
                new DHS_Message__c(
                    DHS_Case__c = caseRecord.Id, Subject__c = 'Second', Message_Body__c = 'Body'
                )
            };
            Test.setCurrentPage(Page.DHSCasedetail);
            ApexPages.currentPage().getParameters().put('id', caseRecord.Id);
            DHSCaseDetailController controller = new DHSCaseDetailController();
            controller.selectedLeadId = [SELECT Id FROM DHS_Lead__c LIMIT 1].Id;
            controller.selectLeadAction();
            controller.updateLeadAction();
            controller.AutoSaveCaseAction();
            controller.firstRecordName = '';
            controller.pageNumber = 2;
            controller.handlePrev();
            controller.lastRecordName = '';
            controller.pageNumber = 1;
            controller.TotalPages = 2;
            controller.handleNext();
            System.assertEquals(2, controller.messages.size(), 'Assertion failed in DHSCaseDetailControllerTest at source line 189');
        }
    }

    @IsTest
    static void testInvestigatorAndRecipientBranches() {
        User pmoUser = PPFDHSTestUserFactory.getPmoUser();
        System.runAs(PPFDHSTestUserFactory.getInvUser()) {
            DHS_Case__c caseRecord = [
                SELECT Id, OwnerId, Owner.Email, DHS_Assigned_To__c,
                    DHS_Assigned_To__r.Email, DHS_Contact__c
                FROM DHS_Case__c LIMIT 1
            ];
            DHS_Lead__c leadRecord = [SELECT Id, DHS_Assigned_To__c FROM DHS_Lead__c LIMIT 1];
            leadRecord.DHS_Assigned_To__c = pmoUser.Id;
            update leadRecord;

            User currentUser = [SELECT Id, User_Type__c FROM User WHERE Id = :UserInfo.getUserId()];
            List<String> emailRecipients =
                DHSCaseDetailController.FetchToAddressOfCase(caseRecord, currentUser);
            List<String> userRecipients =
                DHSCaseDetailController.FetchUsersOfCase(caseRecord, currentUser);
            System.assert(!emailRecipients.isEmpty(), 'Assertion failed in DHSCaseDetailControllerTest at source line 211');
            System.assert(!userRecipients.isEmpty(), 'Assertion failed in DHSCaseDetailControllerTest at source line 212');

            Test.setCurrentPage(Page.DHSCasedetail);
            ApexPages.currentPage().getParameters().put('id', caseRecord.Id);
            ApexPages.currentPage().getParameters().put('tab', 'Leads');
            ApexPages.currentPage().getParameters().put('source', 'dashboard');
            DHSCaseDetailController controller = new DHSCaseDetailController();
            System.assertEquals(false, controller.showMultiUploadDocuments, 'Assertion failed in DHSCaseDetailControllerTest at source line 219');
            controller.newLead.LeadType__c = 'General (GENL)';
            controller.newLead.Coverage_Type__c = 'Personal';
            controller.CreateLeadAction();
            System.assertEquals(null, controller.errorMessage, 'Assertion failed in DHSCaseDetailControllerTest at source line 223');
        }
    }
}