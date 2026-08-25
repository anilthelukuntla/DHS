public with sharing class DIAMyTrainingsController{
    public User currentUser {get;set;}
    public list<SelectOption> usersList {get;set;}
    public string selecteduseridtocreatetraining {get;set;}
    public DIA_Training__c newTraining{get;set;}
    public List<DIA_Training__c> myTrainings{get;set;}
    public DIAMyTrainingsController(){
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId() WITH SECURITY_ENFORCED];
        newTraining = new DIA_Training__c();
        FetchUsersList();
        FetchMyTrainings();
    }
    public void SubmitTraining(){
        newTraining.user__c = userinfo.getuserid();
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Training__c');

        if(Schema.SobjectType.DIA_Training__c.iscreateable() && 
            fields.get('user__c').getDescribe().isAccessible()){

            Database.SaveResult dsr = database.insert(newTraining, false, AccessLevel.USER_MODE);
            if(dsr.isSuccess()){
                FetchMyTrainings();
                newTraining = new DIA_Training__c();
                selecteduseridtocreatetraining = null;
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Training'));
        }
    }
    public void FetchUsersList(){
        usersList = new list<selectoption>();
        usersList.add(new selectoption('','--None--'));
        List<String> userProfiles = new List<String>();
        userProfiles.addAll(System.label.IntelUserProfiles.split(','));    
        Map<String, Profile> profileMap = new Map<String, Profile>([Select Id, Name from Profile WHERE Name IN: userProfiles]);
        List<String> profileIds = new List<String> ();
        profileIds.addAll(profileMap.Keyset());
        List<string> userFields = new List<string>();
        userFields = ApexUtil.FetchFields('User');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(userFields, ',') + ' From User ';
        String where_cond;
        query = query + ' WHERE ProfileId IN:profileIds'; 
        System.debug('query....'+query);
        List<User> intelUsers = database.query(query);
        for(User u: intelUsers){
            usersList.add(new selectoption(u.id, u.Name));
        }
    }
    
    public void FetchMyTrainings(){
        myTrainings = new List<DIA_Training__c>();
        List<string> trainingFields = new List<string>();
        trainingFields = ApexUtil.FetchFields('DIA_Training__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(trainingFields, ',') + ' From DIA_Training__c';
        String where_cond;
        whereCriteria.add(new ApexUtil.Criteria('User__c',userinfo.getUserId(),'='));
        
        
        where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        query = query + ' WHERE '+where_cond+ ' ORDER BY Createddate DESC '; 
        
        myTrainings = database.query(query);
    }
    
    public string deleteTrainingID{get;set;}
    
    public void DeleteTrainingAction(){
        List<DIA_Training__c> deleteTraining = [select id from DIA_Training__c where id=:deleteTrainingID WITH SECURITY_ENFORCED];
        if(Schema.SobjectType.DIA_Case__c.isDeletable()){
           delete deleteTraining;
           FetchMyTrainings();
            /*Database.DeleteResult[] drList = database.delete(deleteTraining,false,AccessLevel.USER_MODE);
            integer i = 0;
            for( Database.DeleteResult dr : drList){
                if(dr.isSuccess()) i++;
            }
            if(i == deleteTraining.size()){
                
            }*/
        }
    }
}