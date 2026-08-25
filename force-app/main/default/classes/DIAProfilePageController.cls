public class DIAProfilePageController {

    public string userId {get;set;}
    public User userRecord {get;set;}
    public list<selectoption> assignUserList {get;set;}
    public boolean showFields {get;set;}
    public list<selectoption> assignLeaveTypes {get;set;}



    public DIAProfilePageController(){
    
        List<user> assignUsers = new List<user>();
        assignUsers = [select Id, User_Type__c, FirstName, lastname  FROM User where user_type__c = 'INV'];
        assignUserList = new List<SelectOption>();
        assignLeaveTypes =  new List<SelectOption>();
        userId = apexpages.currentpage().getparameters().get('id');

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

        System.debug('User Id'+ userId);

        userRecord = [Select FirstName, LastName, Address, Email, Backup_User__c, Backup_UserId__c , From_Date__c,To_Date__c,Out_of_Office__c  from User where id=:userId];

        //System.debug('User Record'+ userRecord);

        return userRecord;
    }

    public PageReference updateuserrecordaction(){

        if (selectedUserIdForAssignment!=null) {
            userRecord.Backup_UserId__c = selectedUserIdForAssignment;
        }
         
        System.debug('Selected User Id'+selectedUserIdForAssignment); 
        System.debug('User record'+userRecord);
        
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('User');

        if(Schema.SobjectType.User.isUpdateable() && 
            fields.get('Backup_UserId__c').getDescribe().isAccessible()){

            Database.SaveResult dsr = database.update(userRecord, false, AccessLevel.USER_MODE);
            return null;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update User'));
            return null;
        }
    }
    
    public void updatefieldfisibility(){
     
        if (userRecord.Out_of_office__c!=null){
            showFields = true;
            System.debug('update field'+showFields);

        }else{
             showFields = false;
        }
        
    }

}