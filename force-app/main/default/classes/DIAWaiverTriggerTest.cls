@isTest
public class DIAWaiverTriggerTest {
    TestMethod static void updateDatesOnLead(){
        dia_contact__c con = New dia_contact__c();
        insert con;
        
        DIA_Case__c cse = New DIA_Case__c();
        cse.contact__c = con.Id;
        insert cse;
        
        dia_lead__c ld = New dia_lead__c();
        ld.case__c = cse.Id;
        insert ld;
        DIA_Waiver_Information__c waiver = New DIA_Waiver_Information__c();
        waiver.Waiver_Approved_Date__c = system.today();
        waiver.Waiver_Flagged_Date__c = system.today();
        waiver.Waiver_Initiated_Date__c = system.today();
        waiver.lead__c = ld.Id;
        waiver.case__c = cse.Id;
        waiver.Type__c = 'Waiver';
        waiver.Waiver_Approved_Date__c = system.today();
        insert waiver;
        
        DIA_Waiver_Information__c extension = New DIA_Waiver_Information__c();
        extension.Waiver_Approved_Date__c = system.today();
        extension.Waiver_Flagged_Date__c = system.today();
        extension.Waiver_Initiated_Date__c = system.today();
        extension.lead__c = ld.Id;
        extension.case__c = cse.Id;
        extension.Type__c = 'Extension';
        extension.Waiver_Approved_Date__c = system.today();
        insert extension;
        
        waiver.Waiver_Initiated_Date__c = system.today().adddays(1);
        waiver.Waiver_Approved_Date__c = system.today().adddays(1);
        update waiver;
        
        extension.Waiver_Approved_Date__c = system.today().adddays(1);
        update extension;
        
    }
}