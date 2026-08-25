@isTest
public class DIACaseDetailControllerTest {
	  @testSetup static void setup() {
     	 DIA_Contact__c con = new DIA_Contact__c();
         con.first_name__c = 'Test';
         con.last_name__c = 'Name';
         con.Email__c  = 'test@test.com';
         con.Contact_Type__c = 'Subject';
		 con.ssn__c = '123-12-1123';
         insert con;
         DIA_Case__c diaCase = new DIA_Case__c();
         diaCase.contact__c = con.id;
         diaCase.Assigned_To__c = userinfo.getuserId();
         insert diaCase;
         DIA_Lead__c diaLead = new DIA_Lead__c();
         diaLead.case__c = diaCase.id;
         //diaLead.Assigned_To__c = userinfo.getuserid();
         diaLead.Coverage_Type__c = 'Subject Interview';
         diaLead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert diaLead;
     }
    testMethod private static void TestMethod1(){
        list<dia_Case__c> casesCreated = [select id from dia_case__c];
         PageReference casedetailpage = Page.Bicasedetail;
        Test.setCurrentPage(casedetailpage);
        casedetailpage.getParameters().put('id',casesCreated[0].id); 
        casesCreated[0].case_number__c = '1234';
        update casesCreated[0];
        
        
        //Insert a document
        DIA_document__c doc = new DIA_document__c();
        doc.Case__c = casesCreated[0].id;
        doc.Name__c = 'testingdocument.pdf';
        insert doc;
        Attachment att = new Attachment();
        att.Body = Blob.valueOf('String1');
        att.ParentId = doc.id;
        att.name = 'testingdocument.pdf';
        insert att;
        
        doc = new DIA_document__c();
        doc.Case__c = casesCreated[0].id;
        doc.Name__c = 'ROIReport';
        insert doc;
        att = new Attachment();
        att.Body = Blob.valueOf('String1');
        att.ParentId = doc.id;
        att.name = 'ROIReport';
        insert att;
        
        DIADownloadDeliverablesController ddctrl = new DIADownloadDeliverablesController();
        ddctrl.caseNumberToSearch = '1234';
        ddctrl.searchaction();
        DIACaseDetailController casedetailctrl = new DIACaseDetailController();
        casedetailctrl.regenerateroireportbuttonaction();
        casesCreated[0].subject_type__c = 'Applicant';
        casedetailctrl.SetPPFContactInfo();
        casesCreated[0].subject_type__c = 'Contractor';
        casedetailctrl.SetPPFContactInfo();
        casedetailctrl.AutoSaveCaseAction();
        //create new lead
        casedetailctrl.newLead.LeadType__c = 'Subject Interview (ESI/TESI)';
        casedetailctrl.newLead.Method__c = 'Telephonic';
        casedetailctrl.newLead.Coverage_Type__c = 'Personal';
        casedetailctrl.CreateLeadAction();
        List<DIA_Lead__c> leadsCreated = [Select Id from DIA_Lead__c];
        DIACaseDetailController.CheckIfLeadIsAssigned(leadsCreated[0].id);
        casedetailctrl.deleteDocumentID = doc.id;
        casedetailctrl.DeleteDocumentAction();
        //Lead creation check
        system.assertEquals(2,leadsCreated.size());
        casedetailctrl.markleadcreationcompleteaction();
        casedetailctrl.AddCommentsAction();
        casedetailctrl.qareviewcompleteaction();
        

        casedetailctrl.leadIdToUpdate = leadscreated[0].id;
        casedetailctrl.itemnumbertoupdate = 4;
        casedetailctrl.updatelead();
        casedetailctrl.updatecaseaction();
        casedetailctrl.selectedUserIdForAssignment = userinfo.getuserid();
        casedetailctrl.updatecaseaction();
        DIA_Waiver_Information__c wi = new DIA_Waiver_Information__c();
        wi.case__c = casesCreated[0].id;
        insert wi;
        DIACaseDetailController ctrl = new DIACaseDetailController();
        ctrl.caseRecord = casesCreated[0];
        ctrl.waiverreason = 'Other';
        ctrl.type = 'Waiver';
        ctrl.otherreason = 'Test';
        ctrl.justification = 'Test';
        ctrl.applyforwaiveraction();
        
        casedetailctrl.FetchWaiverInformation();
        casedetailctrl.waiverinformationidtoupdate = wi.id;
        casedetailctrl.autosavewaiverinformationaction();
        casedetailctrl.updatewaiverinformation();
     
    }
    testMethod private static void Testmethod20(){ 
       	dia_case__c c =new dia_case__c(Subject_Type__c = 'Applicant');
        insert c;
          PageReference casedetailpage = Page.Bicasedetail;
        Test.setCurrentPage(casedetailpage);
        casedetailpage.getParameters().put('id',c.id); 
        DIACaseDetailController casedetailctrl = new DIACaseDetailController();
        casedetailctrl.SetPPFContactInfo();
        
        dia_case__c c1 =new dia_case__c(Subject_Type__c = 'Contractor');
        insert c1;
          PageReference casedetailpage1 = Page.Bicasedetail;
        Test.setCurrentPage(casedetailpage1);
        casedetailpage1.getParameters().put('id',c1.id); 
        DIACaseDetailController casedetailctrl1 = new DIACaseDetailController();
        casedetailctrl1.SetPPFContactInfo();
        
          ContentVersion content=new ContentVersion(); 
        content.Title='2022-02-11-12_46_39S_12313123123'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.LinkedEntityId=sPayoff.id;
        content.origin = 'H';
        insert content;
        
        DIACaseDetailController.CreateOrderNDocuments(new list<string>{content.id},c.id);
        user u = [select id, email,User_Type__c from user where id=:userinfo.getuserid()];
        DIACaseDetailController.FetchToAddressOfCase(c,u);
        DIACaseDetailController.FetchUsersOfCase(c,u);
    }
    testMethod private static void TestAutoCreateLeads(){
        Auto_Lead_Generation_Template__c temp = new Auto_Lead_Generation_Template__c(Name__c='Test');
        insert temp;
        Auto_Lead_Generation_Setting__c setting = new Auto_Lead_Generation_Setting__c();
        setting.Auto_Lead_Generation_Template__c =temp.id;
        setting.Coverage_Type__c = 'Personal';
        setting.Item_number__c = 1;
        setting.Lead_Type__c = 'UnEmployment';
        insert setting;
        PageReference casedetailpage = Page.Bicasedetail;
        Test.setCurrentPage(casedetailpage);
        DIA_Case__c c = new DIA_Case__c();
        insert c;
        casedetailpage.getParameters().put('id',c.id); 
        DIACaseDetailController ctrl = new DIACaseDetailController();
        ctrl.selectedLeadTemplateId = temp.id;
        ctrl.autocreateleads();
        ctrl.onleadtemplateselect();
        ctrl.SendMessage();
         ctrl.SendMessage('test','test');
        ctrl.deleteLeadId = [select id from dia_lead__c limit 1].id;
        ctrl.DeleteLeadAction();
        /*ctrl.messageSubjectForSubject = 'test';
        ctrl.messageBodyForSubject = 'test';
        ctrl.SendSubjectMessage();
        
        MailUtilities.sendBISubjectEmail(c.id,'test','test',new list<string>{'test@isncorp.com'},null,null); 
        MailUtilities.sendBIEmailWithSetTargetObjectId('test','test',userinfo.getuserid(),null,null);
        */List<SelectOption> temp2 = ctrl.getItems(); 
    }
}