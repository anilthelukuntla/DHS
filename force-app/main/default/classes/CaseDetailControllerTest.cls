@isTest
public class CaseDetailControllerTest {
	  @testSetup static void setup() {
     	 Contact__c con = new Contact__c();
         con.first_name__c = 'Test';
          
         con.last_name__c = 'Name';
         con.Email__c  = 'test@test.com';
         con.Contact_Type__c = 'Subject';
		 con.ssn__c = '123-12-1123';
         insert con;
         Case__c CaseTemp = new Case__c();
         CaseTemp.contact__c = con.id;
         CaseTemp.Assigned_To__c = userinfo.getuserId();
         insert CaseTemp;
         Lead__c Lead = new Lead__c();
         Lead.case__c = CaseTemp.id;
         //Lead.Assigned_To__c = userinfo.getuserid();
         Lead.Coverage_Type__c = 'Subject Interview';
         Lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert Lead;
     }
    testMethod private static void TestMethod1(){
        list<Case__c> casesCreated = [select id from case__c];
         PageReference casedetailpage = Page.Bicasedetail;
        Test.setCurrentPage(casedetailpage);
        casedetailpage.getParameters().put('id',casesCreated[0].id); 
        casesCreated[0].case_number__c = '1234';
        update casesCreated[0];
        
        
        //Insert a document
        document__c doc = new document__c();
        doc.Case__c = casesCreated[0].id;
        doc.Name__c = 'testingdocument.pdf';
        insert doc;
        Attachment att = new Attachment();
        att.Body = Blob.valueOf('String1');
        att.ParentId = doc.id;
        att.name = 'testingdocument.pdf';
        insert att;
        
        doc = new document__c();
        doc.Case__c = casesCreated[0].id;
        doc.Name__c = 'ROIReport';
        insert doc;
        att = new Attachment();
        att.Body = Blob.valueOf('String1');
        att.ParentId = doc.id;
        att.name = 'ROIReport';
        insert att;
        DownloadDeliverablesController ddctrl = new DownloadDeliverablesController();
        ddctrl.caseNumberToSearch = '1234';
        ddctrl.searchaction();
        CaseDetailController casedetailctrl = new CaseDetailController();
        casesCreated[0].subject_type__c = 'Applicant';
        casedetailctrl.SetPPFContactInfo();
        casesCreated[0].subject_type__c = 'Contractor';
        casedetailctrl.SetPPFContactInfo();
        //create new lead
        casedetailctrl.newLead.LeadType__c = 'Subject Interview (ESI/TESI)';
        casedetailctrl.newLead.Method__c = 'Telephonic';
        casedetailctrl.newLead.Coverage_Type__c = 'Personal';
        casedetailctrl.CreateLeadAction();
        List<Lead__c> leadsCreated = [Select Id from Lead__c];
        CaseDetailController.CheckIfLeadIsAssigned(leadsCreated[0].id);
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
        Waiver_Information__c wi = new Waiver_Information__c();
        wi.case__c = casesCreated[0].id;
        insert wi;
        casedetailctrl.FetchWaiverInformation();
        casedetailctrl.waiverinformationidtoupdate = wi.id;
        casedetailctrl.autosavewaiverinformationaction();
        casedetailctrl.updatewaiverinformation();
     
    }
    testMethod private static void Testmethod20(){ 
       	case__c c =new case__c(Subject_Type__c = 'Applicant');
        insert c;
          PageReference casedetailpage = Page.Bicasedetail;
        Test.setCurrentPage(casedetailpage);
        casedetailpage.getParameters().put('id',c.id); 
        CaseDetailController casedetailctrl = new CaseDetailController();
        casedetailctrl.SetPPFContactInfo();
        
        case__c c1 =new case__c(Subject_Type__c = 'Contractor');
        insert c1;
          PageReference casedetailpage1 = Page.Bicasedetail;
        Test.setCurrentPage(casedetailpage1);
        casedetailpage1.getParameters().put('id',c1.id); 
        CaseDetailController casedetailctrl1 = new CaseDetailController();
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
        CaseDetailController.FetchToAddressOfCase(c,u);
        CaseDetailController.FetchUsersOfCase(c,u);
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
        Case__c c = new Case__c();
        insert c;
        casedetailpage.getParameters().put('id',c.id); 
        CaseDetailController ctrl = new CaseDetailController();
        ctrl.SendMessage();
         ctrl.SendMessage('test','test',[select id from lead__c limit 1].id);
        ctrl.deleteLeadId = [select id from lead__c limit 1].id;
        ctrl.DeleteLeadAction();
        
       Message__c msg = new Message__c(Subject__c  = 'Test',Message_body__c='TestBody');
        insert msg;
        CaseDetailController temp1 = New CaseDetailController();
        temp1.selectedMessageId = msg.Id;
        temp1.selectedMessage = msg;
        temp1.modalAction = 'edit';
        temp1.openModal();
        temp1.updateMessage();
        temp1.deleteMessage();
        
        
    }
}