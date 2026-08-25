@isTest
public class DIALeadDetailPageControllerTest {
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
         dia_lead__c l = [select id,case__C,Standardised_Issues_Picklist__c from dia_lead__c limit 1];
          l.Reason_for_Waiver__c = 'Subject not available';
        l.Issues_discrepancies_or_developed_acti__c = 'Yes';
        update l;
        insert new DIA_GeneralSettings__c(Name = 'TimeEntryDuringLeadConfirm', Value__c='SCA');
         PageReference leaddetailpage = Page.bileaddetail;
         Test.setCurrentPage(leaddetailpage);
         leaddetailpage.getParameters().put('id',l.id);
         DIAleaddetailpagecontroller leadctrl = new DIAleaddetailpagecontroller();
        
        
        leadctrl.updateleadaction();
        leadctrl.toInsertleadRecordRTAExtension = false;
        leadctrl.completeleadaction();
        leadctrl.selfassignaction();
        //pagereference temp = leadDetailPageCtrl.reviewcompletedaction();
        leadctrl.toInsertleadRecordRTAExtension = false;
        leadctrl.createdocumentrequestaction();
        leadctrl.rejectleadaction();
         leadctrl.SendMessage();
         leadctrl.leadRecord = l;
         PageReference pref = leadctrl.applyforwaiveraction();
         leadctrl.reopenleadaction();
         leadctrl.standardisedissuesaction();
        leadctrl.StandardisedIssueItems = new list<String>{'Other'};
       leadctrl.reviewcompletedaction();
         leadctrl.AutoSaveLeadAction();
         leadctrl.deleteleadaction();
        List<SelectOption>  temp = leadctrl.getItems();
      
        
    }
    testMethod private static void TestMethod2(){
         dia_lead__c l = [select id,case__C,Standardised_Issues_Picklist__c,status__c from dia_lead__c limit 1];
         l.status__c = 'QA Rejected';
        l.Assigned_to__c = userinfo.getuserid();
        update l;
        
    }
}