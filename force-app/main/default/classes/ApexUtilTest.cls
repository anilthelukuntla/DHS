@isTest
public class ApexUtilTest {
    TestMethod static void method1(){
        Map<String, Id> temp2 =  ApexUtil.buildMapOfRecordTypes('Lead__c');
        Map<String, Schema.SObjectType> globalDescMap=Schema.getGlobalDescribe();
        Schema.SObjectType targetType=globalDescMap.get('Lead__c');
        sObject sObj=targetType.newSObject();
        list<String> temp24 = apexutil.getPickListValues(sObj,'LeadType__c');
        //list<string> temp3 = apexutil.getFieldSetFields('OnboardingUser','OnboardingUser__c');
        Map<object,object> temp5 = apexutil.getSObjectFieldTypes('Lead__c');
        List<string> userFields = ApexUtil.FetchFields('User');
        List<String> userFilters = new List<String>();
        userFilters.add('id =: currentUserId');
        String userQuery = ApexUtil.queryBuilder('User', userFields, userFilters);
        String onboardingQuery = ApexUtil.queryBuilder('Onboarding__c', 'OnboardingUser', new list<string>{});
        ApexUtil.runningInASandbox();
        ApexUtil.getObjectFieldsDescribe('User');
        ApexUtil.dt(system.today());
		ApexUtil.dt(system.today(),true);
    }
    
}