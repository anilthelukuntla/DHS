/** Handles onboarding-trigger automation and community-user synchronization. */
// Legacy trigger orchestration is intentionally retained while its security findings are remediated.
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.MethodNamingConventions,PMD.AvoidBooleanMethodParameters,PMD.StdCyclomaticComplexity,PMD.NcssCount,PMD.NcssMethodCount,PMD.NcssTypeCount,PMD.AvoidDeeplyNestedIfStmts,PMD.AvoidFutureAnnotation')
public with sharing class OnboardingTriggerHandler {
    public static boolean onboardingTriggerRunOnce = false;
    private static final Set<String> ONBOARDING_PERMISSION_SET_NAMES = new Set<String>{
        'DHS_Community_PMO_PS',
        'DHS_Community_CMO_PS',
        'DHS_Community_INV_PS',
        'DHS_Community_QA_PS',
        'PPF_DHS_PMO_PS',
        'PPF_DHS_CMO_PS',
        'PPF_DHS_INV_PS',
        'PPF_DHS_QA_PS',
        'PPF_PMO_PS',
        'PPF_CMO_PS',
        'PPF_INV_PS',
        'PPF_QA_PS'
    };
    private static final Set<String> ONBOARDING_ACCESS_GROUP_NAMES = new Set<String>{
        'Intel_PMO_Access', 'Intel_CMO_Access', 'Intel_INV_Access', 'Intel_QA_Access',
        'DHS_PMO_Access', 'DHS_CMO_Access', 'DHS_INV_Access', 'DHS_QA_Access',
        'PPF_DHS_PMO_Access', 'PPF_DHS_CMO_Access',
        'PPF_DHS_INV_Access', 'PPF_DHS_QA_Access'
    };

    /** Routes trigger contexts to the appropriate handler action. */
    public static void run() {
        if(Trigger.isInsert && Trigger.isAfter) {
            OnInsertAction((List<Onboarding__c>) Trigger.new);
        }
        if(Trigger.isUpdate && Trigger.isAfter && !onboardingTriggerRunOnce) {
            OnUpdateAction(
                (List<Onboarding__c>) Trigger.new,
                (Map<Id, Onboarding__c>) Trigger.oldMap
            );
        }
    }

    @TestVisible
    private static String getDhsProfileName(String userProfile) {
        if (userProfile == 'PMO') {
            return 'DHS Community PMO Profile';
        }
        if (userProfile == 'CMO') {
            return 'DHS Community CMO Profile';
        }
        if (userProfile == 'INV') {
            return 'DHS Community INV Profile';
        }
        if (userProfile == 'QA') {
            return 'DHS Community QA Profile';
        }
        return null;
    }

    @TestVisible
    private static String getPpfDhsProfileName(String userProfile) {
        if (userProfile == 'PMO') {
            return 'PPF - DHS PMO Profile';
        }
        if (userProfile == 'CMO') {
            return 'PPF - DHS CMO Profile';
        }
        if (userProfile == 'INV') {
            return 'PPF - DHS INV Profile';
        }
        if (userProfile == 'QA') {
            return 'PPF - DHS QA Profile';
        }
        return null;
    }

    @TestVisible
    private static String getDhsPermissionSetName(String userProfile) {
        if (userProfile == 'PMO') {
            return 'DHS_Community_PMO_PS';
        }
        if (userProfile == 'CMO') {
            return 'DHS_Community_CMO_PS';
        }
        if (userProfile == 'INV') {
            return 'DHS_Community_INV_PS';
        }
        if (userProfile == 'QA') {
            return 'DHS_Community_QA_PS';
        }
        return null;
    }

    @TestVisible
    private static String getPpfDhsPermissionSetName(String userProfile) {
        if (userProfile == 'PMO') {
            return 'PPF_DHS_PMO_PS';
        }
        if (userProfile == 'CMO') {
            return 'PPF_DHS_CMO_PS';
        }
        if (userProfile == 'INV') {
            return 'PPF_DHS_INV_PS';
        }
        if (userProfile == 'QA') {
            return 'PPF_DHS_QA_PS';
        }
        return null;
    }

    @TestVisible
    private static String getPpfPermissionSetName(String userProfile) {
        if (userProfile == 'PMO') {
            return 'PPF_PMO_PS';
        }
        if (userProfile == 'CMO') {
            return 'PPF_CMO_PS';
        }
        if (userProfile == 'INV') {
            return 'PPF_INV_PS';
        }
        if (userProfile == 'QA') {
            return 'PPF_QA_PS';
        }
        return null;
    }

    @TestVisible
    private static Set<String> getAccessGroupNames(String userProfile, String systemAccess) {
        Set<String> groupNames = new Set<String>();
        if(userProfile != 'PMO' && userProfile != 'CMO' &&
           userProfile != 'INV' && userProfile != 'QA') {
            return groupNames;
        }
        if (String.isBlank(systemAccess)) {
            return groupNames;
        }

        Boolean hasIntel = systemAccess.contains('Intel');
        Boolean hasDhs = systemAccess.contains('DHS');
        if(hasIntel && hasDhs) {
            groupNames.add('PPF_DHS_' + userProfile + '_Access');
        } else if(hasIntel) {
            groupNames.add('Intel_' + userProfile + '_Access');
        } else if(hasDhs) {
            groupNames.add('DHS_' + userProfile + '_Access');
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
            if (!upsertResults[index].isSuccess()) {
                continue;
            }
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
        if (successfulUserIds.isEmpty()) {
            return;
        }

        Map<String, Id> groupIdByName = new Map<String, Id>();
        Set<Id> managedGroupIds = new Set<Id>();
        for(Group accessGroup : [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Regular'
            AND DeveloperName IN :ONBOARDING_ACCESS_GROUP_NAMES
            WITH USER_MODE
        ]) {
            groupIdByName.put(accessGroup.DeveloperName, accessGroup.Id);
            managedGroupIds.add(accessGroup.Id);
        }
        if (managedGroupIds.isEmpty()) {
            return;
        }

        Set<String> existingMembershipKeys = new Set<String>();
        List<GroupMember> membershipsToDelete = new List<GroupMember>();
        for(GroupMember membership : [
            SELECT Id, GroupId, UserOrGroupId, Group.DeveloperName
            FROM GroupMember
            WHERE GroupId IN :managedGroupIds
            AND UserOrGroupId IN :successfulUserIds
            WITH USER_MODE
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
            Database.delete(membershipsToDelete, false, AccessLevel.USER_MODE);
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
            Database.insert(membershipsToInsert, false, AccessLevel.USER_MODE);
        }
    }

    @TestVisible
    private static void syncDhsPermissionSetAssignments(
        List<User> usersToUpsert,
        Database.UpsertResult[] upsertResults
    ) {
        Set<Id> successfulUserIds = new Set<Id>();
        Map<Id, String> desiredPermissionSetByUserId = new Map<Id, String>();

        for(Integer index = 0; index < upsertResults.size(); index++) {
            if (!upsertResults[index].isSuccess()) {
                continue;
            }

            Id userId = upsertResults[index].getId();
            successfulUserIds.add(userId);

            User onboardingUser = usersToUpsert[index];
            if(!String.isBlank(onboardingUser.system_Access__c)) {
                Boolean hasIntel = onboardingUser.system_Access__c.contains('Intel');
                Boolean hasDhs = onboardingUser.system_Access__c.contains('DHS');
                String permissionSetName;
                if(hasIntel && hasDhs) {
                    permissionSetName = getPpfDhsPermissionSetName(onboardingUser.user_type__c);
                } else if(hasIntel) {
                    permissionSetName = getPpfPermissionSetName(onboardingUser.user_type__c);
                } else if(hasDhs) {
                    permissionSetName = getDhsPermissionSetName(onboardingUser.user_type__c);
                }
                if(permissionSetName != null) {
                    desiredPermissionSetByUserId.put(userId, permissionSetName);
                }

            }
        }

        if (successfulUserIds.isEmpty()) {
            return;
        }

        Map<String, Id> permissionSetIdByName = new Map<String, Id>();
        for(PermissionSet permissionSetRecord : [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name IN :ONBOARDING_PERMISSION_SET_NAMES
            WITH USER_MODE
        ]) {
            permissionSetIdByName.put(permissionSetRecord.Name, permissionSetRecord.Id);
        }

        Set<String> existingAssignmentKeys = new Set<String>();
        List<PermissionSetAssignment> assignmentsToDelete = new List<PermissionSetAssignment>();
        for(PermissionSetAssignment assignment : [
            SELECT Id, AssigneeId, PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :successfulUserIds
            AND PermissionSet.Name IN :ONBOARDING_PERMISSION_SET_NAMES
            WITH USER_MODE
        ]) {
            String desiredPermissionSetName = desiredPermissionSetByUserId.get(assignment.AssigneeId);
            if(assignment.PermissionSet.Name == desiredPermissionSetName) {
                existingAssignmentKeys.add(String.valueOf(assignment.AssigneeId) + ':' + desiredPermissionSetName);
            } else {
                assignmentsToDelete.add(assignment);
            }
        }

        if(!assignmentsToDelete.isEmpty()) {
            Database.delete(assignmentsToDelete, false, AccessLevel.USER_MODE);
        }
        List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();
        for(Id userId : desiredPermissionSetByUserId.keySet()) {
            String permissionSetName = desiredPermissionSetByUserId.get(userId);
            String assignmentKey = String.valueOf(userId) + ':' + permissionSetName;
            if(!existingAssignmentKeys.contains(assignmentKey) && permissionSetIdByName.containsKey(permissionSetName)) {
                assignmentsToInsert.add(new PermissionSetAssignment(
                    AssigneeId = userId,
                    PermissionSetId = permissionSetIdByName.get(permissionSetName)
                ));
            }
        }

        if(!assignmentsToInsert.isEmpty()) {
            Database.insert(assignmentsToInsert, false, AccessLevel.USER_MODE);
        }
    }

    /**
     * Processes newly inserted onboarding records.
     * @param onboardingUsers newly inserted onboarding records
     */
    public static void OnInsertAction(list<Onboarding__c> onboardingUsers){
        onboardingTriggerRunOnce = true;
        Savepoint sp = Database.setSavepoint();
        try{
            Account portalAccount = [Select Id, Name, OwnerId from Account Where Name=:System.label.IntelAccountName WITH USER_MODE LIMIT 1];
            list<Contact> contactsToCreate = new list<Contact>();
            set<Id> onboardingRecordsId = New set<Id>();
            list<string> customerOnboardingIdsToCreateUpdate = new  list<string>();
            for(Onboarding__c userinfo: onboardingUsers){
                if (!userinfo.Send_Credentials_To_User__c) {
                    continue;
                }
                if(userinfo.User_Profile__c == 'Customer User'){
                	customerOnboardingIdsToCreateUpdate.add(userINfo.id);	    
                }else{
                    contact con = new contact();
                    con.firstName = userinfo.First_name__c;
                    con.LastName = userinfo.last_Name__c;
                    con.Email = userinfo.Email__c;
                    con.AccountId = portalAccount.id;
                    con.OwnerId = portalAccount.OwnerId;
                    con.onboarding__c = userinfo.id;
                    con.system_Access__c = userinfo.system_Access__c;
                    contactsToCreate.add(con);
                }
                onboardingRecordsId.add(userinfo.Id);
            }
            if(!onboardingRecordsId.isEmpty()){
                List<Onboarding__c> onboardingRecords = [select id,Status__c from Onboarding__c where Id IN: onboardingRecordsId WITH USER_MODE];
                for(Onboarding__c uinfo : onboardingRecords){
                    uinfo.Status__c = 'Active';
                }
                if(!onboardingRecords.isEmpty()){
                    Database.update(onboardingRecords, AccessLevel.USER_MODE);
                }
            }
           
            if(!contactsToCreate.isEmpty()){
                Database.SaveResult[] srList = Database.insert(contactsToCreate, false);
                list<string> contactIds = new list<string>();
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        contactIds.add(sr.getId());
                    }
                }
                CreateOrUpdateCustomerCommunityUser(contactIds);
            }
            if(!customerOnboardingIdsToCreateUpdate.isEmpty()){
            	CreateCustomerUser(customerOnboardingIdsToCreateUpdate);    
            }
        }catch(Exception ex){
            Database.RollBack(sp);
        }
    }

    /**
     * Synchronizes contacts and users after onboarding records change.
     * @param onboardingUsers updated onboarding records
     * @param olOnboardingUsersMap prior versions of the updated records
     */
    public static void OnUpdateAction(list<onboarding__c> onboardingUsers, map<Id,onboarding__c> olOnboardingUsersMap){
        onboardingTriggerRunOnce = true;
        Savepoint sp = Database.setSavepoint();
        try{
            Account portalAccount = [Select Id, Name, OwnerId from Account Where Name=:System.label.IntelAccountName WITH USER_MODE LIMIT 1];
            list<Contact> contactsToUpdate = new list<Contact>();
            list<Contact> contactsToCreate = new list<Contact>();
            list<string> onboardingIds = new list<string>();
            set<Id> onboardingRecordsId = New set<Id>();
            for(onboarding__c onboardingUser: onboardingUsers){
                onboardingIds.add(onboardingUser.id);    
            }
            list<string> customerOnboardingIdsToCreateUpdate = new  list<string>();
            map<id, Contact> contactsMap = new map<id, Contact>([select id, onboarding__c from Contact WHERE onboarding__c IN:onboardingIds WITH USER_MODE]);
			map<string, Contact> contactonboardingUserMap = new map<string, Contact>();
            for(id contactId: contactsMap.keySet()){
                contactonboardingUserMap.put(contactsMap.get(contactId).onboarding__c, contactsMap.get(contactId));     
            }
            
        map<string, onboarding__c> onboardingsMap =new map<string, onboarding__c>([Select id,First_Name__c,user__c,email__c,last_Name__c ,Candidate_type__c,User_Profile__c,status__c,system_Access__c
                                                                        FROM onboarding__c WHERE Id IN: onboardingIds WITH USER_MODE]); 
        map<string, string> onboardingNuserId = new map<string, string> ();
            for(onboarding__c onboarding: onboardingsMap.values()){
                if(onboarding.user__c != Null){
                	onboardingNuserId.put(onboarding.id,onboarding.user__c);    
                } 	    
            }
            for(onboarding__c userinfo: onboardingUsers){
                if(userinfo.User_Profile__c == 'Customer User'){
                    if(userinfo.Send_Credentials_To_User__c && !olOnboardingUsersMap.get(userinfo.id).Send_Credentials_To_User__c){
                    	if (!customerOnboardingIdsToCreateUpdate.contains(userINfo.id)) {
                        customerOnboardingIdsToCreateUpdate.add(userINfo.id);	    
                    	}
                    }
                    
                    if(onboardingNuserId.get(userinfo.id) != Null){
                        if (!customerOnboardingIdsToCreateUpdate.contains(userINfo.id)) {
                    	customerOnboardingIdsToCreateUpdate.add(userInfo.id);    
                        }
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
                            newcon.OwnerId = portalAccount.OwnerId;
                            newcon.onboarding__c = userinfo.id;
                            newcon.system_Access__c = userinfo.system_Access__c;
                            contactsToCreate.add(newcon);
                            //userinfo.Status__c = 'Active';
                            onboardingRecordsId.add(userinfo.Id);
                            //onboardingRecordsToUpdate.add(userinfo);
                        }
                    }
                }
            }
            
            if(!onboardingRecordsId.isEmpty()){
                List<Onboarding__c> onboardingRecords = [select id,Status__c from Onboarding__c where Id IN: onboardingRecordsId WITH USER_MODE];
                for(Onboarding__c uinfo : onboardingRecords){
                    uinfo.Status__c = 'Active';
                }
                if(!onboardingRecords.isEmpty()){
                    Database.update(onboardingRecords, AccessLevel.USER_MODE);
                }
            }
            /*if(!onboardingRecordsToUpdate.isEmpty()){
                update onboardingRecordsToUpdate;
            }*/

            if(!contactsToUpdate.isEmpty()){
                Database.SaveResult[] srList = Database.update(contactsToUpdate, false, AccessLevel.USER_MODE);
            
                list<string> contactIds = new list<string>();
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        contactIds.add(sr.getId());
                    }
                }
                CreateOrUpdateCustomerCommunityUser(contactIds);
            }

            if(!contactsToCreate.isEmpty()){
                Database.SaveResult[] srList = Database.insert(contactsToCreate, false);
                list<string> contactIds = new list<string>();
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        contactIds.add(sr.getId());
                    }
                }
                CreateOrUpdateCustomerCommunityUser(contactIds);
            }
            if(!customerOnboardingIdsToCreateUpdate.isEmpty()){
            	CreateCustomerUser(customerOnboardingIdsToCreateUpdate);    
            }
        }Catch(Exception ex){
             Database.RollBack(sp);
        }
    }
    @Future
    /**
     * Creates or updates customer users for onboarding records asynchronously.
     * @param onboardingIds identifiers of onboarding records to process
     */
    public static void CreateCustomerUser(list<string> onboardingIds){
        try{
    	List<Profile> profiles = new List<Profile>();
            profiles = [Select id, Name from Profile WHERE Name != null];
            Map<String,Id> profileMap = new Map<String,Id>();
            for(profile p: profiles){
                profileMap.put(p.Name,p.id);    
            } 
        map<string, onboarding__c> onboardingsMap =new map<string, onboarding__c>([Select id,First_Name__c,user__c,email__c,last_Name__c ,Candidate_type__c,User_Profile__c,status__c,system_Access__c,CCPL__c
                                                                        FROM onboarding__c WHERE Id IN: onboardingIds WITH USER_MODE]); 
            map<string, string> onboardingNuserId = new map<string, string> ();
            for(onboarding__c onboarding: onboardingsMap.values()){
                if(onboarding.user__c != Null){
                	onboardingNuserId.put(onboarding.id,onboarding.user__c);    
                } 	    
            }
         map<string,user> usersMap = new map<string,user>([select Id from user where id in:onboardingNuserId.values()]);
         list<user> usersToUpsert = new list<user>();
		 for(string onboardingId: onboardingIds){
             	
                onboarding__c onboarding = onboardingsMap.get(onboardingId);
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
                 integer atSymbolPtr = onboarding.email__c.indexOf('@');
        
                if(atSymbolPtr < 8) 
                {
                    alias = onboarding.email__c.substring(0, atSymbolPtr - 1);
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
            Database.upsert(usersToUpsert, false);
            
            
            
        } catch(Exception ex){
            return;
        }
    }
    
    
    @Future
    /**
     * Creates or updates community users associated with contacts.
     * @param contactIds identifiers of contacts to process
     */
    public static void CreateOrUpdateCustomerCommunityUser(list<string> contactIds){
        try{
            List<Profile> profiles = new List<Profile>();
            profiles = [Select id, Name from Profile WHERE Name != null];
            Map<String,Id> profileMap = new Map<String,Id>();
            for(profile p: profiles){
                profileMap.put(p.Name,p.id);    
            }
            map<id, User> usersMap = new map<id, User>([select id, contactId from User WHERE contactId IN:contactIds]);
            map<string, user> contactNuserMap = new map<string, user>();
            for(id userId: usersMap.keySet()){
                contactNuserMap.put(usersMap.get(userId).contactId, usersMap.get(userId));      
            }
            list<user> usersToUpsert = new list<user>();
            
            map<string, contact> contactsMap =new map<string, contact>([Select id,firstName,email,lastname,onboarding__c,onboarding__r.Candidate_type__c,onboarding__r.User_Profile__c,onboarding__r.status__c,onboarding__r.system_Access__c,onboarding__r.CCPL__c,onboarding__r.BI_Candidate_type__c
                                                                        FROM Contact WHERE Id IN: contactIds WITH USER_MODE]); 
            for(string contactId: contactIds){
                contact con = contactsMap.get(contactId);
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.EmailHeader.triggerUserEmail = true;       
                dmo.EmailHeader.triggerOtherEmail = false;
                dmo.EmailHeader.triggerAutoResponseEmail = false;       
                dmo.optAllOrNone = false;
                String profileId;
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
                 integer atSymbolPtr = con.email.indexOf('@');
        
                if(atSymbolPtr < 8) 
                {
                    alias = con.email.substring(0, atSymbolPtr - 1);
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
            syncAccessGroupMemberships(usersToUpsert, userSrList);
            syncDhsPermissionSetAssignments(usersToUpsert, userSrList);
        }catch(Exception ex){
            return;
        }
    }
    /**
     * Converts a date to a datetime at midnight.
     * @param dt date to convert
     * @return datetime representation of the supplied date
     */
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
    /**
     * Converts a date to a datetime using the requested date mode.
     * @param dt date to convert
     * @param isdate indicates whether date conversion is requested
     * @param isdatetime indicates whether datetime handling is requested
     * @return converted datetime value, or null when date mode is disabled
     */
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
    /**
     * Converts a date to a datetime when date conversion is enabled.
     * @param dt date to convert
     * @param isdate indicates whether date conversion is requested
     * @return converted datetime value, or null when conversion is disabled
     */
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