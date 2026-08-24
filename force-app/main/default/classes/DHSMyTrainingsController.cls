/** Controls DHS training creation, listing, and deletion. */
@SuppressWarnings('PMD.ApexDoc')
public with sharing class DHSMyTrainingsController{
    public User currentUser {get;set;}
    public list<SelectOption> usersList {get;set;}
    public string selecteduseridtocreatetraining {get;set;}
    public DHS_Training__c newTraining{get;set;}
    public List<DHS_Training__c> myTrainings{get;set;}
    public DHSMyTrainingsController(){
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId() WITH USER_MODE];
        newTraining = new DHS_Training__c();
        fetchUsersList();
        fetchMyTrainings();
    }
    public void submitTraining(){
        newTraining.DHS_User__c = userinfo.getuserid();
        Database.insert(newTraining, AccessLevel.USER_MODE);
        fetchMyTrainings();
        newTraining = new DHS_Training__c();
        selecteduseridtocreatetraining = null;
    }
    public void fetchUsersList(){
        usersList = new list<selectoption>();
        usersList.add(new selectoption('','--None--'));
        List<String> userProfiles = new List<String>();
        userProfiles.addAll(System.label.DHS_UserProfiles.split(','));    
        Map<String, Profile> profileMap = new Map<String, Profile>([Select Id, Name from Profile WHERE Name IN: userProfiles WITH USER_MODE]);
        List<String> profileIds = new List<String> ();
        profileIds.addAll(profileMap.Keyset());
        List<string> userFields = new List<string>();
        userFields = DHSApexUtil.FetchFields('User');
        String query = 'Select '+string.join(userFields, ',') + ' From User ';
        query = query + ' WHERE ProfileId IN:profileIds '; 
        List<User> intelUsers = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
        for(User u: intelUsers){
            usersList.add(new selectoption(u.id, u.Name));
        }
    }
    
    public void fetchMyTrainings(){
        myTrainings = new List<DHS_Training__c>();
        List<string> trainingFields = new List<string>();
        trainingFields = DHSApexUtil.FetchFields('DHS_Training__c');
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        String query = 'Select '+string.join(trainingFields, ',') + ' From DHS_Training__c';
        whereCriteria.add(new DHSApexUtil.Criteria('DHS_User__c',userinfo.getUserId(),'='));
        
        
        String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria); 
        query = query + ' WHERE '+whereCondition+ ' WITH USER_MODE ORDER BY Createddate DESC'; 
        
        myTrainings = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
    }
    
    public string deleteTrainingID{get;set;}
    
    public void deleteTrainingAction(){
        list<DHS_Training__c> deltrainging = [select id from DHS_Training__c where id=:deleteTrainingID WITH USER_MODE];
        database.delete(deltrainging,false,AccessLevel.USER_MODE);
        fetchMyTrainings();
        
    }

}
