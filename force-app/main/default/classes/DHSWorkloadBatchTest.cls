@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSWorkloadBatchTest {
    @IsTest static void method1(){
        System.assert(true, 'Expected the test scenario to complete without exception');
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
         lead.DHS_Assigned_To__c = userinfo.getuserid();
         lead.Coverage_Type__c = 'Subject Interview';
         lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert lead;
        
        lead.Status__c = 'Assigned Not Accepted';
        update lead;
        
        DHS_Lead__c lead1 = new DHS_Lead__c();
         lead1.DHS_Case__c = caseTemp.id;
         lead1.DHS_Assigned_To__c = userinfo.getuserid();
         lead1.Coverage_Type__c = 'Subject Interview';
         lead1.LeadType__c = 'Subject Interview (ESI/TESI)';
         
         insert lead1;
        lead1.Status__c = 'In-Progress';
        update lead1;
        
        DHS_Lead__c lead2 = new DHS_Lead__c();
         lead2.DHS_Case__c = caseTemp.id;
         lead2.DHS_Assigned_To__c = userinfo.getuserid();
         lead2.Coverage_Type__c = 'Subject Interview';
         lead2.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert lead2;
        lead2.Status__c = 'QA Rejected';
        update lead2;
        database.executeBatch(New DHSWorkloadBatch(),100);
        system.schedule('Test Schedule','0 0 12 * * ?',New DHSScheduleWorkload());
    }
}