@IsTest
@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage,PMD.ApexUnitTestClassShouldHaveAsserts,PMD.ApexUnitTestClassShouldHaveRunAs,PMD.NcssCount')
public class DHSCaseDetailControllerTest {
	  @TestSetup static void setup() {
     	 DHS_Contact__c con = new DHS_Contact__c();
         con.First_Name__c = 'Test';
          
         con.Last_Name__c = 'Name';
         con.Email__c  = 'test@test.com';
         con.Contact_Type__c = 'Subject';
		 con.SSN__c = '123-12-1123';
         insert con;
         DHS_Case__c caseTemp = new DHS_Case__c();
         caseTemp.DHS_Contact__c = con.id;
         caseTemp.DHS_Assigned_To__c = userinfo.getuserId();
         insert caseTemp;
         DHS_Lead__c lead = new DHS_Lead__c();
         lead.DHS_Case__c = caseTemp.id;
         //Lead.DHS_Assigned_To__c = userinfo.getuserid();
         lead.Coverage_Type__c = 'Subject Interview';
         lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert lead;
     }
    @IsTest private static void testMethod1(){
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
        system.assertEquals(2,leadsCreated.size());
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
    @IsTest private static void testmethod20(){ 
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
    @IsTest private static void testAutoCreateLeads(){
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
