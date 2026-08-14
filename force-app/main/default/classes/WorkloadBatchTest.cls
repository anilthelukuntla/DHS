@isTest
/** Exercises the existing WorkloadBatch behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.LocalVariableNamingConventions')
public class WorkloadBatchTest {
    @IsTest static void method1(){
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
         Lead.Assigned_To__c = userinfo.getuserid();
         Lead.Coverage_Type__c = 'Subject Interview';
         Lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert Lead;
        
        lead.Status__c = 'Assigned Not Accepted';
        update lead;
        
        Lead__c Lead1 = new Lead__c();
         Lead1.case__c = CaseTemp.id;
         Lead1.Assigned_To__c = userinfo.getuserid();
         Lead1.Coverage_Type__c = 'Subject Interview';
         Lead1.LeadType__c = 'Subject Interview (ESI/TESI)';
         
         insert Lead1;
        Lead1.Status__c = 'In-Progress';
        update Lead1;
        
        Lead__c Lead2 = new Lead__c();
         Lead2.case__c = CaseTemp.id;
         Lead2.Assigned_To__c = userinfo.getuserid();
         Lead2.Coverage_Type__c = 'Subject Interview';
         Lead2.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert Lead2;
        Lead2.Status__c = 'QA Rejected';
        update Lead2;
        database.executeBatch(New WorkloadBatch(),100);
        database.executeBatch(New WorkloadCMOBatch(),100);
        
        system.schedule('Test Schedule','0 0 12 * * ?',New ScheduleWorkload());
        system.schedule('Test Schedule 1','0 0 12 * * ?',New ScheduleCMOWorkload());
        
    }
}