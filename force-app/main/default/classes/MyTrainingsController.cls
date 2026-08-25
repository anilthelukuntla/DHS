public class MyTrainingsController{
    public User currentUser {get;set;}
    public list<SelectOption> usersList {get;set;}
    public string selecteduseridtocreatetraining {get;set;}
    public Training__c newTraining{get;set;}
    public List<Training__c> myTrainings{get;set;}
    public MyTrainingsController(){
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId()];
        newTraining = new Training__c();
        FetchUsersList();
        FetchMyTrainings();
    }
    public void SubmitTraining(){
        newTraining.user__c = userinfo.getuserid();
        insert newTraining;
        FetchMyTrainings();
        newTraining = new Training__c();
        selecteduseridtocreatetraining = null;
    }
    public void FetchUsersList(){
        usersList = new list<selectoption>();
        usersList.add(new selectoption('','--None--'));
        List<String> userProfiles = new List<String>();
        userProfiles.addAll(System.label.IntelUserProfiles.split(','));    
        Map<String, Profile> profileMap = new Map<String, Profile>([Select Id, Name from Profile WHERE Name IN: userProfiles ]);
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
        myTrainings = new List<Training__c>();
        List<string> trainingFields = new List<string>();
        trainingFields = ApexUtil.FetchFields('Training__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(trainingFields, ',') + ' From Training__c';
        String where_cond;
        whereCriteria.add(new ApexUtil.Criteria('User__c',userinfo.getUserId(),'='));
        
        
        where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        query = query + ' WHERE '+where_cond+ 'ORDER BY Createddate DESC'; 
        
        myTrainings = database.query(query);
    }
    
    public string deleteTrainingID{get;set;}
    
    public void DeleteTrainingAction(){
        delete [select id from Training__c where id=:deleteTrainingID];
        FetchMyTrainings();
        
    }

}