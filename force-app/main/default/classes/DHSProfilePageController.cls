/** Controls DHS user profile and out-of-office backup settings. */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexXSSFromURLParam, PMD.AvoidBooleanMethodParameters')
public with sharing class DHSProfilePageController {

    public string userId {get;set;}
    public User userRecord {get;set;}
    public list<selectoption> assignUserList {get;set;}
    public boolean showFields {get;set;}
    public list<selectoption> assignLeaveTypes {get;set;}



    public DHSProfilePageController(){
    
        List<user> assignUsers = new List<user>();
        assignUsers = [select Id, User_Type__c, FirstName, lastname  FROM User where user_type__c = 'INV' WITH SECURITY_ENFORCED];
        assignUserList = new List<SelectOption>();
        assignLeaveTypes =  new List<SelectOption>();
        String requestedUserId = apexpages.currentpage().getparameters().get('id');
        userId = String.isBlank(requestedUserId)
            ? null
            : String.valueOf(Id.valueOf(requestedUserId));

        assignLeaveTypes.add(new SelectOption('','--None--'));
        assignLeaveTypes.add(new SelectOption('vacation','vacation'));
        assignLeaveTypes.add(new SelectOption('leave','leave'));
        
        assignUserList.add(new SelectOption('','--None--'));
        for(User u: assignUsers){
            assignUserList.add(new SelectOption(u.id,u.firstname+' '+u.lastname));
        }
        
       
       showFields = false;
       userRecord = getUserInfo(userId);
       if(userRecord != Null){
          if(userRecord.Out_of_office__c != Null){
              showFields = true;
          } 
          
          selectedUserIdForAssignment = userRecord.Backup_UserId__c; 
       }
        
       
    }

    public string selectedUserIdForAssignment{get;set;}
    public string selectedLeaveType{get;set;}

     
    private User getUserInfo(String userId){


        userRecord = [Select FirstName, LastName, Address, Email, Backup_User__c, Backup_UserId__c , From_Date__c,To_Date__c,Out_of_Office__c  from User where id=:userId WITH SECURITY_ENFORCED];

        //System.debug('User Record'+ userRecord);

        return userRecord;
    }

    public PageReference updateuserrecordaction(){

        if (selectedUserIdForAssignment!=null) {
            userRecord.Backup_UserId__c = selectedUserIdForAssignment;
        }
         
        
        database.update(userRecord,false,AccessLevel.USER_MODE);
        //selectedUserIdForAssignment = null;
        return null;

    }
    
    public void updatefieldfisibility(){
     
        if (userRecord.Out_of_office__c!=null){
            showFields = true;

        }else{
             showFields = false;
        }
        
    }

}