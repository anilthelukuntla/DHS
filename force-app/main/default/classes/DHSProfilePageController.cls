/**
 * @description Controls DHS user profile and out-of-office backup settings.
 */
@SuppressWarnings('PMD.UnusedMethod')
public with sharing class DHSProfilePageController {

    /** @description Provides this DHS API member. */
    public string userId {get;set;}
    /** @description Provides this DHS API member. */
    public User userRecord {get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> assignUserList {get;set;}
    public boolean showFields {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public list<selectoption> assignLeaveTypes {get;set;}



    /** @description Provides this DHS API member. */
    public DHSProfilePageController(){
    
        List<user> assignUsers = new List<user>();
        assignUsers = [select Id, User_Type__c, FirstName, lastname  FROM User where user_type__c = 'INV'];
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

    /** @description Provides this DHS API member. */
    public string selectedUserIdForAssignment{get;set;}
    /** @description Provides this DHS API member. */
    public string selectedLeaveType{get;set;}

     
    private User getUserInfo(String userId){


        userRecord = [Select FirstName, LastName, Address, Email, Backup_User__c, Backup_UserId__c , From_Date__c,To_Date__c,Out_of_Office__c  from User where id=:userId];

        //

        return userRecord;
    }

    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference updateuserrecordaction(){

        if (selectedUserIdForAssignment!=null) {
            userRecord.Backup_UserId__c = selectedUserIdForAssignment;
        }
         
        
        database.update(userRecord,false,AccessLevel.USER_MODE);
        //selectedUserIdForAssignment = null;
        return null;

    }
    
    /** @description Provides this DHS API member. */
    public void updatefieldfisibility(){
     
        if (userRecord.Out_of_office__c!=null){
            showFields = true;

        }else{
             showFields = false;
        }
        
    }

}