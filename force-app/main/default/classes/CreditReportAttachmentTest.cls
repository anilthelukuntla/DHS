@isTest
public class CreditReportAttachmentTest {
    testMethod private static void testMethod1(){  
        Case__c c = new Case__c();
        insert c;
        creditchecker__Credit_Report__c cr = new creditchecker__Credit_Report__c();
        cr.creditchecker__Applicants_First_Name__c = 'test';
        cr.creditchecker__Applicants_Last_Name__c = 'test';
        cr.creditchecker__Applicants_SSN__c = '12345678912';
        cr.creditchecker__Current_Line__c = 'Ms Alice Smith Apartment 1c 213 Derrick Street';
        cr.creditchecker__Current_City__c = 'Boston';
        cr.creditchecker__Current_Zip_Code__c = '02130';
        cr.creditchecker__Applicants_Residency_Type__c = 'Own';
        cr.creditchecker__Current_StateCode__c = 'MD';
        cr.creditchecker__Current_Country__c = 'USA';
        cr.case_custom__c = c.id;
        insert cr;
        attachment att = new attachment();
        att.name = 'Test.pdf';
        att.body = blob.valueof('test');
        att.parentid = cr.id;
        insert att;
       
    
    }
}