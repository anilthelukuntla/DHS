global class CreateUserFromOnboardingBatch implements Database.Batchable<sObject>,Database.Stateful {
    global string onboardingId;
    global CreateUserFromOnboardingBatch(string obId){
        onboardingId = obId;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('onboardingUser id in batch class...'+onboardingId);
        List<string> onboardingFields = new List<string>();
        onboardingFields = ApexUtil.FetchFields('Onboarding__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(onboardingFields, ',') + ' From Onboarding__c ';
        String where_cond;
        if(onboardingId != Null){
            whereCriteria.add(new Apexutil.Criteria('Id',onboardingId, '='));
        }else{
            whereCriteria.add(new Apexutil.Criteria('Start_Date__c',String.valueof(system.today()), '=', 'Date'));
        }    
        
        where_cond = ApexUtil.generateWhereQuery(whereCriteria);  
        //if(!test.isRunningTest()){
            query = query + ' WHERE User_Created__c = false AND '+where_cond;     
       // }
        System.debug('query...'+query);
        return Database.getQueryLocator(query);    
    }

    global void execute(Database.BatchableContext bc, List<Onboarding__c> scope) {
        Savepoint sp = Database.setSavepoint();
        try{
            List<string> profileNames = new List<String>();
            profileNames = System.label.User_Profiles.split(','); 
            List<Profile> profiles = new List<Profile>();
            profiles = [Select id, Name from Profile];
            Map<String,Id> profileMap = new Map<String,Id>();
            for(profile p: profiles){
                profileMap.put(p.Name,p.id);    
            }
            System.debug('profileMap..'+profileMap);
            List<Account> accounts = new List<Account>();
            accounts = [Select Id, Name from Account where Name=:System.label.IntelAccountName];
            List<Contact> contactsToCreate = new List<Contact>();
            List<User> usersToCreate = new List<User>();
            list<Onboarding__c> onboardingRecordsToUpdate = new List<Onboarding__c>();
            for(Onboarding__c userinfo:scope){
                Contact con = new contact();
                con.firstName = userinfo.First_name__c;
                con.LastName = userinfo.last_Name__c;
                con.Email = userinfo.Email__c;
                con.AccountId = accounts[0].id;
                con.onboarding__c = userinfo.id;
                contactsToCreate.add(con);
                userinfo.user_Created__C = true;
                onboardingRecordsToUpdate.add(userinfo);
            }
            if(!onboardingRecordsToUpdate.isEmpty()){
                update onboardingRecordsToUpdate;
            }
            if(!contactsToCreate.isEmpty()){
                insert contactsToCreate;
                
                List<string> contactIdsCreated = new List<string>();
                for(contact con: contactsToCreate){
                    contactIdsCreated.add(con.id);   
                }
                
                list<contact> contactsToCreateusers = new List<contact>();
                contactsToCreateusers = [Select id,firstName,email,lastname,onboarding__c,onboarding__r.User_Profile__c 
                                        From Contact where id in:contactIdsCreated ];
                
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.EmailHeader.triggerUserEmail = true;       
                dmo.EmailHeader.triggerOtherEmail = false;
                dmo.EmailHeader.triggerAutoResponseEmail = false;       
                dmo.optAllOrNone = false;
                for(Contact con: contactsToCreateusers){
                    System.debug('con...'+con.id);
                    String profileId;
                    System.debug('con.onboarding__r.User_Profile__c...'+con.onboarding__r.User_Profile__c);
                    if(con.onboarding__r.User_Profile__c=='PMO'){
                        profileId = profileMap.get('Customer Community PMO User');    
                    }
                    if(con.onboarding__r.User_Profile__c=='CMO'){
                        profileId = profileMap.get('Customer Community CMO User');    
                    }
                    if(con.onboarding__r.User_Profile__c=='INV'){
                        profileId = profileMap.get('Customer Community Investigator User');    
                    }
                    if(con.onboarding__r.User_Profile__c=='Customer User'){
                        profileId = profileMap.get('Foresite Customer Profile');    
                    }
                    if(con.onboarding__r.User_Profile__c=='QA'){
                        profileId = profileMap.get('Customer Community QA User');    
                    }
                    string nick = con.email!=null?con.email.substring(0, con.email.indexOf('@')):'';
                    nick += Datetime.now().getTime();
                    string userName;
                    if(apexutil.runningInASandbox()){
                        if(con.email == 'devdistro@isncorp.com'){
                            username = con.email+'.test'+con.onboarding__r.User_Profile__c.replace(' ',''); 
                        }else{
                            username = con.email+'.test';
                        }   
                    }else{
                        username = con.email;        
                    }
                    User newUser = new User(alias=con.firstName, 
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
                                            IsActive = true);
                    newUser.setOptions(dmo);
                    usersToCreate.add(newUser);
                    
                }
                if(!usersToCreate.isEmpty()){
                    insert usersToCreate;   
                }
            }
        }catch(Exception e) {
            Database.RollBack(sp);
        }
    }

    global void finish(Database.BatchableContext bc) {
        system.debug('batch job id = '+bc.getJobId());
    }
    
}