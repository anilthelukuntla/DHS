@isTest
/** Exercises the existing DHSWorkloadBatch behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.LocalVariableNamingConventions')
public class DHSWorkloadBatchTest {
    @IsTest static void method1(){
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
         Lead.DHS_Assigned_To__c = userinfo.getuserid();
         Lead.Coverage_Type__c = 'Subject Interview';
         Lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert Lead;
        
        lead.Status__c = 'Assigned Not Accepted';
        update lead;
        
        DHS_Lead__c Lead1 = new DHS_Lead__c();
         Lead1.DHS_Case__c = CaseTemp.id;
         Lead1.DHS_Assigned_To__c = userinfo.getuserid();
         Lead1.Coverage_Type__c = 'Subject Interview';
         Lead1.LeadType__c = 'Subject Interview (ESI/TESI)';
         
         insert Lead1;
        Lead1.Status__c = 'In-Progress';
        update Lead1;
        
        DHS_Lead__c Lead2 = new DHS_Lead__c();
         Lead2.DHS_Case__c = CaseTemp.id;
         Lead2.DHS_Assigned_To__c = userinfo.getuserid();
         Lead2.Coverage_Type__c = 'Subject Interview';
         Lead2.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert Lead2;
        Lead2.Status__c = 'QA Rejected';
        update Lead2;
        database.executeBatch(New DHSWorkloadBatch(),100);
        system.schedule('Test Schedule','0 0 12 * * ?',New DHSScheduleWorkload());
    }
}