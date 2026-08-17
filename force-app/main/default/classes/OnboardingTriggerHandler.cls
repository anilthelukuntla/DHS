public class OnboardingTriggerHandler {
    public static boolean OnboardingTriggerRunOnce = false;
    private static final Set<String> ONBOARDING_PERMISSION_SET_GROUP_NAMES = new Set<String>{
        'DHS_PMO_PSG', 'DHS_CMO_PSG', 'DHS_INV_PSG', 'DHS_QA_PSG', 'DHS_Customer_PSG',
        'PPF_PMO_PSG', 'PPF_CMO_PSG', 'PPF_INV_PSG', 'PPF_QA_PSG', 'PPF_Customer_PSG',
        'PPF_DHS_PMO_PSG', 'PPF_DHS_PMO_Delete_PSG', 'PPF_DHS_CMO_PSG',
        'PPF_DHS_INV_PSG', 'PPF_DHS_QA_PSG', 'PPF_DHS_Customer_PSG'
    };
    private static final Set<String> ONBOARDING_ACCESS_GROUP_NAMES = new Set<String>{
        'Intel_PMO_Access', 'Intel_CMO_Access', 'Intel_INV_Access', 'Intel_QA_Access',
        'Intel_Customer_Access',
        'DHS_PMO_Access', 'DHS_CMO_Access', 'DHS_INV_Access', 'DHS_QA_Access',
        'DHS_Customer_Access',
        'PPF_DHS_PMO_Access', 'PPF_DHS_CMO_Access',
        'PPF_DHS_INV_Access', 'PPF_DHS_QA_Access', 'PPF_DHS_Customer_Access'
    };

    @TestVisible
    private static String getDhsProfileName(String userProfile) {
        if(userProfile == 'PMO') return 'DHS Community PMO Profile';
        if(userProfile == 'CMO') return 'DHS Community CMO Profile';
        if(userProfile == 'INV') return 'DHS Community INV Profile';
        if(userProfile == 'QA') return 'DHS Community QA Profile';
        return null;
    }

    @TestVisible
    private static String getPpfDhsProfileName(String userProfile) {
        if(userProfile == 'PMO') return 'PPF - DHS PMO Profile';
        if(userProfile == 'CMO') return 'PPF - DHS CMO Profile';
        if(userProfile == 'INV') return 'PPF - DHS INV Profile';
        if(userProfile == 'QA') return 'PPF - DHS QA Profile';
        return null;
    }

    @TestVisible
    private static Set<String> getPermissionSetGroupNames(String userProfile, String systemAccess) {
        Set<String> groupNames = new Set<String>();
        String roleName = userProfile == 'Customer User' ? 'Customer' : userProfile;
        if(roleName != 'PMO' && roleName != 'CMO' && roleName != 'INV' &&
           roleName != 'QA' && roleName != 'Customer') {
            return groupNames;
        }
        if(String.isBlank(systemAccess)) return groupNames;

        Boolean hasIntel = systemAccess.contains('Intel');
        Boolean hasDhs = systemAccess.contains('DHS');
        if(hasIntel && hasDhs) {
            groupNames.add('PPF_DHS_' + roleName + '_PSG');
            if(roleName == 'PMO') {
                groupNames.add('PPF_DHS_PMO_Delete_PSG');
            }
        } else if(hasIntel) {
            groupNames.add('PPF_' + roleName + '_PSG');
        } else if(hasDhs) {
            groupNames.add('DHS_' + roleName + '_PSG');
        }
        return groupNames;
    }

    @TestVisible
    private static Set<String> getAccessGroupNames(String userProfile, String systemAccess) {
        Set<String> groupNames = new Set<String>();
        String roleName = userProfile == 'Customer User' ? 'Customer' : userProfile;
        if(roleName != 'PMO' && roleName != 'CMO' &&
           roleName != 'INV' && roleName != 'QA' && roleName != 'Customer') {
            return groupNames;
        }
        if(String.isBlank(systemAccess)) return groupNames;

        Boolean hasIntel = systemAccess.contains('Intel');
        Boolean hasDhs = systemAccess.contains('DHS');
        if(hasIntel && hasDhs) {
            groupNames.add('PPF_DHS_' + roleName + '_Access');
        } else if(hasIntel) {
            groupNames.add('Intel_' + roleName + '_Access');
        } else if(hasDhs) {
            groupNames.add('DHS_' + roleName + '_Access');
        }
        return groupNames;
    }

    @TestVisible
    private static void syncAccessGroupMemberships(
        List<User> usersToUpsert,
        Database.UpsertResult[] upsertResults
    ) {
        Set<Id> successfulUserIds = new Set<Id>();
        Map<Id, Set<String>> desiredGroupsByUserId = new Map<Id, Set<String>>();
        for(Integer index = 0; index < upsertResults.size(); index++) {
            if(!upsertResults[index].isSuccess()) continue;
            Id userId = upsertResults[index].getId();
            successfulUserIds.add(userId);
            desiredGroupsByUserId.put(
                userId,
                getAccessGroupNames(
                    usersToUpsert[index].user_type__c,
                    usersToUpsert[index].system_Access__c
                )
            );
        }
        if(successfulUserIds.isEmpty()) return;

        Map<String, Id> groupIdByName = new Map<String, Id>();
        Set<Id> managedGroupIds = new Set<Id>();
        for(Group accessGroup : [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Regular'
            AND DeveloperName IN :ONBOARDING_ACCESS_GROUP_NAMES
        ]) {
            groupIdByName.put(accessGroup.DeveloperName, accessGroup.Id);
            managedGroupIds.add(accessGroup.Id);
        }
        if(managedGroupIds.isEmpty()) return;

        Set<String> existingMembershipKeys = new Set<String>();
        List<GroupMember> membershipsToDelete = new List<GroupMember>();
        for(GroupMember membership : [
            SELECT Id, GroupId, UserOrGroupId, Group.DeveloperName
            FROM GroupMember
            WHERE GroupId IN :managedGroupIds
            AND UserOrGroupId IN :successfulUserIds
        ]) {
            Set<String> desiredGroupNames = desiredGroupsByUserId.get(membership.UserOrGroupId);
            if(desiredGroupNames != null &&
               desiredGroupNames.contains(membership.Group.DeveloperName)) {
                existingMembershipKeys.add(
                    String.valueOf(membership.UserOrGroupId) + ':' +
                    membership.Group.DeveloperName
                );
            } else {
                membershipsToDelete.add(membership);
            }
        }
        if(!membershipsToDelete.isEmpty()) {
            Database.delete(membershipsToDelete, false);
        }

        List<GroupMember> membershipsToInsert = new List<GroupMember>();
        for(Id userId : desiredGroupsByUserId.keySet()) {
            for(String groupName : desiredGroupsByUserId.get(userId)) {
                String membershipKey = String.valueOf(userId) + ':' + groupName;
                if(!existingMembershipKeys.contains(membershipKey) &&
                   groupIdByName.containsKey(groupName)) {
                    membershipsToInsert.add(new GroupMember(
                        GroupId = groupIdByName.get(groupName),
                        UserOrGroupId = userId
                    ));
                }
            }
        }
        if(!membershipsToInsert.isEmpty()) {
            Database.insert(membershipsToInsert, false);
        }
    }

    @TestVisible
    private static void syncPermissionSetGroupAssignments(
        List<User> usersToUpsert,
        Database.UpsertResult[] upsertResults
    ) {
        Set<Id> successfulUserIds = new Set<Id>();
        Map<Id, Set<String>> desiredGroupsByUserId = new Map<Id, Set<String>>();

        for(Integer index = 0; index < upsertResults.size(); index++) {
            if(!upsertResults[index].isSuccess()) continue;

            Id userId = upsertResults[index].getId();
            successfulUserIds.add(userId);

            User onboardingUser = usersToUpsert[index];
            desiredGroupsByUserId.put(
                userId,
                getPermissionSetGroupNames(
                    onboardingUser.user_type__c,
                    onboardingUser.system_Access__c
                )
            );
        }

        if(successfulUserIds.isEmpty()) return;

        Map<String, Id> groupIdByName = new Map<String, Id>();
        for(PermissionSetGroup groupRecord : [
            SELECT Id, DeveloperName
            FROM PermissionSetGroup
            WHERE DeveloperName IN :ONBOARDING_PERMISSION_SET_GROUP_NAMES
        ]) {
            groupIdByName.put(groupRecord.DeveloperName, groupRecord.Id);
        }

        Set<String> existingAssignmentKeys = new Set<String>();
        List<PermissionSetAssignment> assignmentsToDelete = new List<PermissionSetAssignment>();
        for(PermissionSetAssignment assignment : [
            SELECT Id, AssigneeId, PermissionSetGroup.DeveloperName
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :successfulUserIds
            AND PermissionSetGroup.DeveloperName IN :ONBOARDING_PERMISSION_SET_GROUP_NAMES
        ]) {
            String groupName = assignment.PermissionSetGroup.DeveloperName;
            Set<String> desiredGroupNames = desiredGroupsByUserId.get(assignment.AssigneeId);
            if(desiredGroupNames != null && desiredGroupNames.contains(groupName)) {
                existingAssignmentKeys.add(String.valueOf(assignment.AssigneeId) + ':' + groupName);
            } else {
                assignmentsToDelete.add(assignment);
            }
        }

        if(!assignmentsToDelete.isEmpty()) {
            Database.delete(assignmentsToDelete, false);
        }
        List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();
        for(Id userId : desiredGroupsByUserId.keySet()) {
            for(String groupName : desiredGroupsByUserId.get(userId)) {
                String assignmentKey = String.valueOf(userId) + ':' + groupName;
                if(!existingAssignmentKeys.contains(assignmentKey) && groupIdByName.containsKey(groupName)) {
                    assignmentsToInsert.add(new PermissionSetAssignment(
                        AssigneeId = userId,
                        PermissionSetGroupId = groupIdByName.get(groupName)
                    ));
                }
            }
        }

        if(!assignmentsToInsert.isEmpty()) {
            Database.SaveResult[] assignmentResults = Database.insert(assignmentsToInsert, false);
            for(Integer index = 0; index < assignmentResults.size(); index++) {
                if(assignmentResults[index].isSuccess()) continue;

                PermissionSetAssignment failedAssignment = assignmentsToInsert[index];
                for(Database.Error assignmentError : assignmentResults[index].getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'Permission set assignment failed. AssigneeId=' +
                        failedAssignment.AssigneeId +
                        ', PermissionSetGroupId=' + failedAssignment.PermissionSetGroupId +
                        ', StatusCode=' + assignmentError.getStatusCode() +
                        ', Message=' + assignmentError.getMessage() +
                        ', Fields=' + assignmentError.getFields()
                    );
                }
            }
        }
    }

    public static void OnInsertAction(list<Onboarding__c> onboardingUsers){
        OnboardingTriggerRunOnce = true;
        Savepoint sp = Database.setSavepoint();
        try{
            Account portalAccount = [Select Id, Name from Account Where Name=:System.label.IntelAccountName LIMIT 1];
            list<Contact> contactsToCreate = new list<Contact>();
            list<User> usersToCreate = new list<User>();
            list<Onboarding__c> onboardingRecordsToUpdate = new List<Onboarding__c>();
            set<Id> onboardingRecordsId = New set<Id>();
            list<string> customerOnboardingIdsToCreateUpdate = new  list<string>();
            for(Onboarding__c userinfo: onboardingUsers){
                if(!userinfo.Send_Credentials_To_User__c) continue;
                if(userinfo.User_Profile__c == 'Customer User'){
                	customerOnboardingIdsToCreateUpdate.add(userINfo.id);	    
                }else{
                    contact con = new contact();
                    con.firstName = userinfo.First_name__c;
                    con.LastName = userinfo.last_Name__c;
                    con.Email = userinfo.Email__c;
                    con.AccountId = portalAccount.id;
                    con.onboarding__c = userinfo.id;
                    con.system_Access__c = userinfo.system_Access__c;
                    contactsToCreate.add(con);
                }
                onboardingRecordsId.add(userinfo.Id);
            }
            if(!onboardingRecordsId.isEmpty()){
                List<Onboarding__c> onboardingRecords = [select id,Status__c from Onboarding__c where Id IN: onboardingRecordsId];
                for(Onboarding__c uinfo : onboardingRecords){
                    uinfo.Status__c = 'Active';
                }
                if(!onboardingRecords.isEmpty()){
                    update onboardingRecords;
                }
            }
           
            if(!contactsToCreate.isEmpty()){
                Database.SaveResult[] srList = Database.insert(contactsToCreate, false);
                list<string> contactIds = new list<string>();
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully inserted contact. Contact ID: ' + sr.getId());
                        contactIds.add(sr.getId());
                    }
                    else {              
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Contact fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                CreateOrUpdateCustomerCommunityUser(contactIds);
            }
            if(!customerOnboardingIdsToCreateUpdate.isEmpty()){
            	CreateCustomerUser(customerOnboardingIdsToCreateUpdate);    
            }
        }catch(Exception ex){
            System.debug('exception ex...'+ex);
            Database.RollBack(sp);
        }
    }

    public static void OnUpdateAction(list<onboarding__c> onboardingUsers, map<Id,onboarding__c> olOnboardingUsersMap){
        OnboardingTriggerRunOnce = true;
        Savepoint sp = Database.setSavepoint();
        try{
            Account portalAccount = [Select Id, Name from Account Where Name=:System.label.IntelAccountName LIMIT 1];
            list<Contact> contactsToUpdate = new list<Contact>();
            list<User> usersToUpdate = new list<User>(); 
            list<Contact> contactsToCreate = new list<Contact>();
            list<User> usersToCreate = new list<User>(); 
            list<string> onboardingIds = new list<string>();
            set<Id> onboardingRecordsId = New set<Id>();
            list<Onboarding__c> onboardingRecordsToUpdate = new List<Onboarding__c>();
            for(onboarding__c onboardingUser: onboardingUsers){
                onboardingIds.add(onboardingUser.id);    
            }
            system.debug('onboardingIds...'+onboardingIds);
            list<string> customerOnboardingIdsToCreateUpdate = new  list<string>();
            map<id, Contact> contactsMap = new map<id, Contact>([select id, onboarding__c from Contact WHERE onboarding__c IN:onboardingIds]);
			map<string, Contact> contactonboardingUserMap = new map<string, Contact>();
            for(id contactId: contactsMap.keySet()){
                contactonboardingUserMap.put(contactsMap.get(contactId).onboarding__c, contactsMap.get(contactId));     
            }
            
            system.debug('contactonboardingUserMap...'+contactonboardingUserMap);
        map<string, onboarding__c> onboardingsMap =new map<string, onboarding__c>([Select id,First_Name__c,user__c,email__c,last_Name__c ,Candidate_type__c,User_Profile__c,status__c,system_Access__c
                                                                        FROM onboarding__c WHERE Id IN: onboardingIds]); 
        map<string, string> onboardingNuserId = new map<string, string> ();
            for(onboarding__c onboarding: onboardingsMap.values()){
                if(onboarding.user__c != Null){
                	onboardingNuserId.put(onboarding.id,onboarding.user__c);    
                } 	    
            }
            system.debug('onboardingNuserId...'+onboardingNuserId);
         map<string,user> usersMap = new map<string,user>([select Id from user where id in:onboardingNuserId.values() ]);

            for(onboarding__c userinfo: onboardingUsers){
                if(userinfo.User_Profile__c == 'Customer User'){
                    if(userinfo.Send_Credentials_To_User__c && !olOnboardingUsersMap.get(userinfo.id).Send_Credentials_To_User__c){
                    	if(!customerOnboardingIdsToCreateUpdate.contains(userINfo.id))
                        customerOnboardingIdsToCreateUpdate.add(userINfo.id);	    
                    }
                    
                    if(onboardingNuserId.get(userinfo.id) != Null){
                        if(!customerOnboardingIdsToCreateUpdate.contains(userINfo.id))
                    	customerOnboardingIdsToCreateUpdate.add(userInfo.id);    
                    }
                }else{
                    Contact conOfOnboardingUser = contactonboardingUserMap.get(userinfo.id);
                    if(conOfOnboardingUser != Null){
                        //Update existing user
                        conOfOnboardingUser.firstName = userinfo.First_name__c;
                        conOfOnboardingUser.LastName = userinfo.last_Name__c;
                        conOfOnboardingUser.Email = userinfo.Email__c;
                        conOfOnboardingUser.AccountId = portalAccount.id;
                        conOfOnboardingUser.onboarding__c = userinfo.id;
                        conOfOnboardingUser.system_Access__c = userinfo.system_Access__c;
                        contactsToUpdate.add(conOfOnboardingUser);
                    }else{
                        if(userinfo.Send_Credentials_To_User__c && !olOnboardingUsersMap.get(userinfo.id).Send_Credentials_To_User__c){
                            contact newcon = new contact();
                            newcon.firstName = userinfo.First_name__c;
                            newcon.LastName = userinfo.last_Name__c;
                            newcon.Email = userinfo.Email__c;
                            newcon.AccountId = portalAccount.id;
                            newcon.onboarding__c = userinfo.id;
                            newcon.system_Access__c = userinfo.system_Access__c;
                            contactsToCreate.add(newcon);
                            //userinfo.Status__c = 'Active';
                            onboardingRecordsId.add(userinfo.Id);
                            //onboardingRecordsToUpdate.add(userinfo);
                            system.debug('newcon....'+newcon);
                        }
                    }
                }
            }
            
            if(!onboardingRecordsId.isEmpty()){
                List<Onboarding__c> onboardingRecords = [select id,Status__c from Onboarding__c where Id IN: onboardingRecordsId];
                for(Onboarding__c uinfo : onboardingRecords){
                    uinfo.Status__c = 'Active';
                }
                if(!onboardingRecords.isEmpty()){
                    update onboardingRecords;
                }
            }
            /*if(!onboardingRecordsToUpdate.isEmpty()){
                update onboardingRecordsToUpdate;
            }*/

            if(!contactsToUpdate.isEmpty()){
                Database.SaveResult[] srList = Database.update(contactsToUpdate, false);
            
                list<string> contactIds = new list<string>();
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully updated contact. Contact ID: ' + sr.getId());
                        contactIds.add(sr.getId());
                    }
                    else {              
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Contact fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                CreateOrUpdateCustomerCommunityUser(contactIds);
            }

            if(!contactsToCreate.isEmpty()){
                Database.SaveResult[] srList = Database.insert(contactsToCreate, false);
                list<string> contactIds = new list<string>();
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully inserted contact. Contact ID: ' + sr.getId());
                        contactIds.add(sr.getId());
                    }
                    else {              
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Contact fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                CreateOrUpdateCustomerCommunityUser(contactIds);
            }
            if(!customerOnboardingIdsToCreateUpdate.isEmpty()){
            	CreateCustomerUser(customerOnboardingIdsToCreateUpdate);    
            }
        }Catch(Exception ex){
             Database.RollBack(sp);
            System.debug('exception ex...'+ex);    
        }
    }
    @future
    public static void CreateCustomerUser(list<string> onboardingIds){
        System.debug('onboardingIds...'+onboardingIds);
        try{
    	List<Profile> profiles = new List<Profile>();
            profiles = [Select id, Name from Profile];
            Map<String,Id> profileMap = new Map<String,Id>();
            for(profile p: profiles){
                profileMap.put(p.Name,p.id);    
            } 
        map<string, onboarding__c> onboardingsMap =new map<string, onboarding__c>([Select id,First_Name__c,user__c,email__c,last_Name__c ,Candidate_type__c,User_Profile__c,status__c,system_Access__c,CCPL__c
                                                                        FROM onboarding__c WHERE Id IN: onboardingIds]); 
        System.debug('onboardingsMap...'+onboardingsMap);
            map<string, string> onboardingNuserId = new map<string, string> ();
            for(onboarding__c onboarding: onboardingsMap.values()){
                if(onboarding.user__c != Null){
                	onboardingNuserId.put(onboarding.id,onboarding.user__c);    
                } 	    
            }
         map<string,user> usersMap = new map<string,user>([select Id from user where id in:onboardingNuserId.values() ]);
         list<user> usersToUpsert = new list<user>();
		 for(string onboardingId: onboardingIds){
             	
                onboarding__c onboarding = onboardingsMap.get(onboardingId);
             System.debug('onboarding...'+onboarding);
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.EmailHeader.triggerUserEmail = true;       
                dmo.EmailHeader.triggerOtherEmail = false;
                dmo.EmailHeader.triggerAutoResponseEmail = false;       
                dmo.optAllOrNone = false;
                String profileId;
                //System.debug('onboarding.User_Profile__c...'+onboarding.User_Profile__c);
             
                if(onboarding.User_Profile__c=='Customer User' && onboarding.system_access__c.contains('Intel')){
                    profileId = profileMap.get('DIA Agency User');    
                }
                if(onboarding.User_Profile__c=='Customer User' && onboarding.system_access__c.contains('DIA')){
                    profileId = profileMap.get('DIA Agency User');    
                }
             
                if(test.isRunningTest()){
                	profileId = profileMap.get('DIA Agency User');      
                }
                string nick = onboarding.email__c!=null?onboarding.email__c.substring(0, onboarding.email__c.indexOf('@')):'';
                nick += Datetime.now().getTime();
                string userName;
                if(apexutil.runningInASandbox()){
                    if(onboarding.email__c == 'devdistro@isncorp.com'){
                        username = onboarding.email__c+'.test'+onboarding.User_Profile__c.replace(' ',''); 
                    }else{
                        if(!test.isRunningTest()){
                        	username = onboarding.email__c +'.test'+onboarding.User_Profile__c.replace(' ','');    
                        }else{
                         	username = onboarding.email__c +'.testpmo';       
                        }
                        
                    }   
                }else{
                    username = onboarding.email__c ;        
                }
                string existingUserId = onboardingNuserId.get(onboarding.id);
                User existingUser;
             if(existingUserId != Null){
             	existingUser = usersMap.get(existingUserId);    
             }
                 string alias;
                 integer AtSymbolPtr = onboarding.email__c.indexOf('@');
        
                if(AtSymbolPtr < 8) 
                {
                    alias = onboarding.email__c.substring(0, AtSymbolPtr - 1);
                }
                else
                {
                    alias = onboarding.email__c.substring(0, 8);
                }
                boolean isactiveuser = true;
                if(onboarding.status__c == 'Inactive'){
                	isactiveuser = false;    
                }
                
                if(existingUser != Null){
                    existingUser = new User(id=existingUser.id,
                                       alias=alias, 
                                       email = onboarding.email__c, 
                                       emailencodingkey = 'ISO-8859-1', 
                                       firstname = onboarding.first_Name__c, 
                                       lastname = onboarding.last_name__c, 
                                       languagelocalekey = 'en_US',
                                       localesidkey = 'en_US',
                                       timezonesidkey = 'America/Los_Angeles',
                                       username = username,
                                       CommunityNickname = nick,
                                       ProfileId =profileId, 
                                       user_type__c = onboarding.User_Profile__c,
                                       system_Access__c = onboarding.system_Access__c,
                                       IsActive = isactiveuser);    
                }else{
                    existingUser = new User(alias=alias, 
                                       email = onboarding.email__c, 
                                       emailencodingkey = 'ISO-8859-1', 
                                       firstname = onboarding.first_Name__c, 
                                       lastname = onboarding.last_name__c, 
                                        languagelocalekey = 'en_US',
                                       localesidkey = 'en_US',
                                       timezonesidkey = 'America/Los_Angeles',
                                       CommunityNickname = nick,
                                       ProfileId =profileId, 
                                       user_type__c = onboarding.User_Profile__c,
                                       system_Access__c = onboarding.system_Access__c,
                                       IsActive = isactiveuser);
                    
                }
                existingUser.setOptions(dmo);
                usersToUpsert.add(existingUser);
            }
            System.debug('usersToUpsert....'+usersToUpsert);
            Database.UpsertResult[] userSrList = Database.upsert(usersToUpsert, false);
            for (Database.UpsertResult sr : userSrList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully updated user. User ID: ' + sr.getId());
                } 
                else {              
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('User fields that affected this error: ' + err.getFields());
                    }
                }
            }
            syncPermissionSetGroupAssignments(usersToUpsert, userSrList);
            
            
            
        } catch(Exception ex){
            
        }
    }
    
    
    @future
    public static void CreateOrUpdateCustomerCommunityUser(list<string> contactIds){
        try{
            List<Profile> profiles = new List<Profile>();
            profiles = [Select id, Name from Profile];
            Map<String,Id> profileMap = new Map<String,Id>();
            for(profile p: profiles){
                profileMap.put(p.Name,p.id);    
            }
            System.debug('profileMap..'+profileMap);
            System.debug('contactIds...'+contactIds);
            map<id, User> usersMap = new map<id, User>([select id, contactId from User WHERE contactId IN:contactIds]);
            map<string, user> contactNuserMap = new map<string, user>();
            for(id userId: usersMap.keySet()){
                contactNuserMap.put(usersMap.get(userId).contactId, usersMap.get(userId));      
            }
            list<user> usersToUpsert = new list<user>();
            
            map<string, contact> contactsMap =new map<string, contact>([Select id,firstName,email,lastname,onboarding__c,onboarding__r.Candidate_type__c,onboarding__r.User_Profile__c,onboarding__r.status__c,onboarding__r.system_Access__c,onboarding__r.CCPL__c,onboarding__r.BI_Candidate_type__c
                                                                        FROM Contact WHERE Id IN: contactIds]); 
            for(string contactId: contactIds){
                contact con = contactsMap.get(contactId);
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.EmailHeader.triggerUserEmail = true;       
                dmo.EmailHeader.triggerOtherEmail = false;
                dmo.EmailHeader.triggerAutoResponseEmail = false;       
                dmo.optAllOrNone = false;
                System.debug('con...'+con);
                System.debug('con.onboarding__r.system_access__c...'+con.onboarding__r.system_access__c);
                String profileId;
                System.debug('con.onboarding__r.User_Profile__c...'+con.onboarding__r.User_Profile__c);
                if(con.onboarding__r.User_Profile__c=='PMO' && con.onboarding__r.system_access__c.contains('Intel')){
                    if(con.onboarding__r.CCPL__c == true){
                        profileId = profileMap.get('CCPL Login Profile');
                    }else{
                        profileId = profileMap.get('Customer Community PMO User');
                    }
                }
                if(con.onboarding__r.User_Profile__c=='CMO' && con.onboarding__r.system_access__c.contains('Intel')){
                    if(con.onboarding__r.CCPL__c == true){
                        profileId = profileMap.get('CCPL Login Profile');
                    }else{
                        profileId = profileMap.get('Customer Community CMO User');
                    }
                }
                if(con.onboarding__r.User_Profile__c=='INV' && con.onboarding__r.system_access__c.contains('Intel')){
                    if(con.onboarding__r.CCPL__c == true){
                        profileId = profileMap.get('PPF Investigator Login');
                    }else{
                        profileId = profileMap.get('Customer Community Investigator User'); 
                    } 
                }
                if(con.onboarding__r.User_Profile__c=='Customer User' && con.onboarding__r.system_access__c.contains('Intel')){
                    if(con.onboarding__r.CCPL__c == true){
                        profileId = profileMap.get('CCPL Login Profile');
                    }else{
                        profileId = profileMap.get('Foresite Customer Profile');
                    }
                }
                if(con.onboarding__r.User_Profile__c=='QA' && con.onboarding__r.system_access__c.contains('Intel')){
                    if(con.onboarding__r.CCPL__c == true){
                        profileId = profileMap.get('CCPL Login Profile');
                    }else{
                        profileId = profileMap.get('Customer Community QA User');
                    }
                }
                if(con.onboarding__r.User_Profile__c=='PMO' && con.onboarding__r.system_access__c.contains('DIA')){
                    profileId = profileMap.get('DIA Customer Community PMO User');    
                }
                if(con.onboarding__r.User_Profile__c=='CMO' && con.onboarding__r.system_access__c.contains('DIA')){
                    profileId = profileMap.get('DIA Customer Community CMO User');    
                }
                if(con.onboarding__r.User_Profile__c=='INV' && con.onboarding__r.system_access__c.contains('DIA')){
                    if(con.onboarding__r.CCPL__c == true){
                        profileId = profileMap.get('DIA Investigator Login');
                    }else{
                        profileId = profileMap.get('DIA Customer Community Investigator User');
                    }
                }
                if(con.onboarding__r.Candidate_type__c != Null){
                    if(con.onboarding__r.BI_Candidate_type__c == 'Employee' && con.onboarding__r.User_Profile__c=='INV' && con.onboarding__r.system_access__c.contains('DIA')){
                        profileId = profileMap.get('DIA Employee Investigator');    
                    }
                }
                if(con.onboarding__r.User_Profile__c=='Customer User' && con.onboarding__r.system_access__c.contains('DIA')){
                    profileId = profileMap.get('Foresite Customer Profile');    
                }
                if(con.onboarding__r.User_Profile__c=='QA' && con.onboarding__r.system_access__c.contains('DIA')){
                    profileId = profileMap.get('DIA Customer Community QA User');    
                }
                
                if(con.onboarding__r.User_Profile__c=='PMO' && con.onboarding__r.system_access__c.contains('DIA') && con.onboarding__r.system_access__c.contains('Intel')){
                    profileId = profileMap.get('ISNBI Customer Community PMO User');    
                }
                if(con.onboarding__r.User_Profile__c=='CMO' && con.onboarding__r.system_access__c.contains('DIA') && con.onboarding__r.system_access__c.contains('Intel')){
                    profileId = profileMap.get('ISNBI Customer Community CMO User');    
                }
                if(con.onboarding__r.User_Profile__c=='INV' && con.onboarding__r.system_access__c.contains('DIA') && con.onboarding__r.system_access__c.contains('Intel')){
                    profileId = profileMap.get('ISNBI Customer Community Investigator User');    
                }
                if(con.onboarding__r.User_Profile__c=='Customer User' && con.onboarding__r.system_access__c.contains('DIA') && con.onboarding__r.system_access__c.contains('Intel')){
                    profileId = profileMap.get('Foresite Customer Profile');    
                }
                if(con.onboarding__r.User_Profile__c=='QA' && con.onboarding__r.system_access__c.contains('DIA') && con.onboarding__r.system_access__c.contains('Intel')){
                    profileId = profileMap.get('ISNBI Community QA User');    
                }
                if(con.onboarding__r.User_Profile__c=='Customer User' && con.onboarding__r.system_access__c.contains('DIA')){
                    profileId = profileMap.get('BI Customer Profile');    
                }

                // Combined Intel + DHS access uses the PPF-DHS profile. DHS-only access
                // continues to use the existing DHS community profile.
                if(con.onboarding__r.system_access__c != null && con.onboarding__r.system_access__c.contains('DHS')){
                    Boolean hasIntelAndDhs = con.onboarding__r.system_access__c.contains('Intel');
                    String dhsProfileName = hasIntelAndDhs
                        ? getPpfDhsProfileName(con.onboarding__r.User_Profile__c)
                        : getDhsProfileName(con.onboarding__r.User_Profile__c);
                    if(dhsProfileName != null){
                        profileId = profileMap.get(dhsProfileName);
                    }
                }
                
                system.debug('profileId...'+profileId);
                if(test.isRunningTest()){
                	profileId = profileMap.get('ISNBI Community QA User');      
                }
                string nick = con.email!=null?con.email.substring(0, con.email.indexOf('@')):'';
                nick += Datetime.now().getTime();
                string userName;
                if(apexutil.runningInASandbox()){
                    if(con.email == 'devdistro@isncorp.com'){
                        username = con.email+'.test'+con.onboarding__r.User_Profile__c.replace(' ',''); 
                    }else{
                        if(!test.isRunningTest()){
                        	username = con.email+'.test'+con.onboarding__r.User_Profile__c.replace(' ','');    
                        }else{
                         	username = con.email+'.testpmo';       
                        }
                        
                    }   
                }else{
                    username = con.email;        
                }
                User existingUser = contactNuserMap.get(contactId);
                 string alias;
                 integer AtSymbolPtr = con.email.indexOf('@');
        
                if(AtSymbolPtr < 8) 
                {
                    alias = con.email.substring(0, AtSymbolPtr - 1);
                }
                else
                {
                    alias = con.email.substring(0, 8);
                }
                boolean isactiveuser = true;
                if(con.onboarding__r.status__c == 'Inactive'){
                	isactiveuser = false;    
                }
                if(existingUser != Null){
                    existingUser = new User(id=contactNuserMap.get(con.id).id,
                                       alias=alias, 
                                       email = con.email, 
                                       emailencodingkey = 'ISO-8859-1', 
                                       firstname = con.firstName, 
                                       lastname = con.lastname, 
                                       languagelocalekey = 'en_US',
                                       localesidkey = 'en_US',
                                       contactId = con.Id,
                                       timezonesidkey = 'America/Los_Angeles',
                                       CommunityNickname = nick,
                                       ProfileId =profileId, 
                                       user_type__c = con.onboarding__r.User_Profile__c,
                                       system_Access__c = con.onboarding__r.system_Access__c,
                                       IsActive = isactiveuser);    
                }else{
                    existingUser = new User(alias=alias, 
                                       email = con.email, 
                                       emailencodingkey = 'ISO-8859-1', 
                                       firstname = con.firstName, 
                                       lastname = con.lastname, 
                                       languagelocalekey = 'en_US',
                                       localesidkey = 'en_US',
                                       contactId = con.Id,
                                       timezonesidkey = 'America/Los_Angeles',
                                       username = username,
                                       CommunityNickname = nick,
                                       ProfileId =profileId, 
                                       user_type__c = con.onboarding__r.User_Profile__c,
                                       system_Access__c = con.onboarding__r.system_Access__c,
                                       IsActive = isactiveuser);
                    
                }
                existingUser.setOptions(dmo);
                usersToUpsert.add(existingUser);
            }
            
            Database.UpsertResult[] userSrList = Database.upsert(usersToUpsert, false);
            for (Database.UpsertResult sr : userSrList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully updated user. User ID: ' + sr.getId());
                } 
                else {              
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('User fields that affected this error: ' + err.getFields());
                    }
                }
            }
            syncAccessGroupMemberships(usersToUpsert, userSrList);
            syncPermissionSetGroupAssignments(usersToUpsert, userSrList);
        }catch(Exception ex){
            System.debug('exception ex...'+ex);       
        }
    }
    public static datetime convertDt(date dt){
        datetime dtime;
        integer day;
        integer month;
        integer year;
        day = dt.day();
        month = dt.month();
        year = dt.year();
        dtime = datetime.newinstance(day,month,year);
        return dtime;
    }
    public static datetime convertDt(date dt,boolean isdate,boolean isdatetime){
        datetime dtime;
        integer day;
        integer month;
        integer year;
        day = dt.day();
        month = dt.month();
        year = dt.year();
        dtime = datetime.newinstance(day,month,year);
        return dtime;
    }
    public static datetime convertDt(date dt,boolean isdate){
        datetime dtime;
        integer day;
        integer month;
        integer year;
        day = dt.day();
        month = dt.month();
        year = dt.year();
        dtime = datetime.newinstance(day,month,year);
        return dtime;
    }
}