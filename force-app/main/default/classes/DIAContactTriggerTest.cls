@isTest
public class DIAContactTriggerTest {
	testMethod private static void TestContactTrigger(){ 
        Dia_Contact__c con = new Dia_Contact__c();
        con.First_Name__c  = 'test';
        con.Last_Name__c  = 'test';
        con.Email__c  = 'test@test.com';
        insert con;
    }
}