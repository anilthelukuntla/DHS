@isTest
public class IntelHeaderControllerTest {
	testMethod private static void TestMisc(){
        IntelHeaderController ctrl = new IntelHeaderController();
        user currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid()];
        currentUser.User_Type__c = 'CMO';
        update currentUser;
        IntelHeaderController ctrl2 = new IntelHeaderController();
        currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid()];
        currentUser.User_Type__c = 'QA';
        update currentUser;
        IntelHeaderController ctrl3 = new IntelHeaderController();
        currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid()];
        currentUser.User_Type__c = 'INV';
        update currentUser;
        IntelHeaderController ctrl5 = new IntelHeaderController();
        currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid()];
        currentUser.User_Type__c = 'PMO';
        update currentUser;
        IntelHeaderController.updateLogoutTime();
        IntelHeaderController.updateIdleTime(10);
        IntelHeaderController ctrl4 = new IntelHeaderController();
        customer_order__c co = new customer_order__c(status__c = 'Uploaded'); insert co;
        customer_order__c co1 = new customer_order__c(status__c = 'Executed'); insert co1;        
        CustomerInterfaceController ciCtrl = new CustomerInterfaceController();
        
        onboarding__c onboardingUser = new onboarding__c();
        onboardingUser.First_Name__c = 'test';
        onboardingUser.Last_Name__c = 'investigator';
        onboardingUser.Email__c = 'testinvestigator@test.com';
        onboardingUser.Candidate_type__c = 'SCA';
        onboardingUser.User_Created__c = false;
        insert onboardingUser;
        
         Account acc = new Account(Name='ISN');
        insert acc;
        CreateUserFromOnboardingBatch CreateUserFromOnboardingBatchctrl = new CreateUserFromOnboardingBatch(onboardingUser.id);
        database.executeBatch(CreateUserFromOnboardingBatchctrl);
         PageReference IntelProfilePage = Page.IntelProfilePage;
        Test.setCurrentPage(IntelProfilePage);
        IntelProfilePage.getParameters().put('id',userinfo.getUserId());
        IntelProfilePageController ipc = new IntelProfilePageController();
        currentUser.Out_of_office__c = 'Vacation';
        ipc.updatefieldfisibility();
        
        ContentVersion content=new ContentVersion(); 
        content.Title='2022-02-11-12_46_39S_12313123123'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.LinkedEntityId=sPayoff.id;
        content.origin = 'H';
        insert content;
        
        //List<Schema.FieldSetMember> temp = ApexUtil.readFieldSet('OnboardingUser','OnboardingUser__c');
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
    }
}