trigger LeadTrigger on Lead__c (before insert, before update, after insert, after update) {
    list<string> caseIds = new list<string>();
    list<Case_History__c> caseHistoriesToInsert = new LisT<Case_History__c>();
    Map<Id, Case__c> casesToUpdate = new Map<Id, Case__c>();
    list<Waiver_Information__c > WaiverInformationToCreate  = new LisT<Waiver_Information__c >();
    List<Messaging.SingleEmailMessage> assignedMsgs = New List<Messaging.SingleEmailMessage>();
    
    if((trigger.isInsert || trigger.isUpdate) && trigger.isBefore){
         for(Lead__C l: Trigger.new){
             
             if(trigger.isinsert){
                 L.LAST_STATUS_CHANGE__C = system.now();
             }else{
                If (Trigger.oldMap.get(l.Id).Status__c != Trigger.newMap.get(l.Id).Status__c){
                    L.LAST_STATUS_CHANGE__C = system.now();
                }
            }
        }
        list<string> leadcaseids = new list<String>();
        list<string> leadIds = new list<string>();
        for(lead__c l: trigger.new){
            leadcaseids.add(l.case__C); 
            if(trigger.isUpdate){
                leadIds.add(l.id);
            }   
        }
        List<Lead__c> leads = new List<Lead__c>();
        if(trigger.isInsert){
            leads = [Select Id, Case__c, item_Number__c from Lead__C where case__c in: leadcaseids];
        }else if(trigger.isUpdate){
            leads = [Select Id, Case__c, item_Number__c from Lead__C where case__c in: leadcaseids and id not IN: leadIds];
        }
        map<Id,case__c> casesMap = new map<id,case__c>([select id,contact__c, Scoping_Date__c, current_task__c from case__c where id in: leadcaseids ]);
            
        map<string,list<lead__c>> caseIdNleads = new map<string,list<lead__c>>();
        for(lead__c el: leads){
            if(!caseIdNleads.containsKey(el.Case__c)){
                caseIdNleads.put(el.case__c, new list<lead__c>{el});    
            }else{
                list<lead__c> temp = caseIdNleads.get(el.case__c);
                temp.add(el);
                caseIdNleads.put(el.case__c,temp);   
            }    
        }
        for(lead__c l: trigger.new){
            list<lead__c> existingLeads = caseIdNleads.get(l.case__c); 
            if(existingLeads != Null){ 
                for(lead__c el: existingLeads){
                    if(el.item_number__c == l.item_number__c && l.item_number__c != Null){
                        l.addError(System.label.Duplicate_Item_Number_Message);
                    }
                }
            }
        }
    }
    
    
    if(trigger.isInsert && trigger.isBefore){
        for(Lead__c l: Trigger.New){
            caseIds.add(l.case__c);     
            l.Status__c = 'UnAssigned';
        }   
    
        List<Lead__c> leads = new List<Lead__c>();
        leads = [Select Id, Case__c from Lead__C where case__c in: caseIds];
        map<Id,case__c> casesMap = new map<id,case__c>([select id,contact__c, Scoping_Date__c, current_task__c from case__c where id in:caseIds ]);
            
        map<string,integer> caseIdNnumberOfleads = new map<string,integer>();
        for(lead__c l: leads){
            if(!caseIdNnumberOfleads.containsKey(l.Case__c)){
                caseIdNnumberOfleads.put(l.case__c, 1);    
            }else{
                caseIdNnumberOfleads.put(l.case__c,caseIdNnumberOfleads.get(l.case__c)+1);   
            }    
        }
  
        for(Lead__c l: Trigger.New){
            l.Contact__c = casesMap.get(l.case__c).Contact__c;
            if(caseIdNnumberOfleads.containsKey(l.case__c)){
                //l.Item_number__c =  caseIdNnumberOfleads.get(l.case__c)+1;   
            }else{
                   //l.Item_number__c = 1;
                   case_History__c ch = new case_History__c();
                   ch.case__c = l.case__c;
                   ch.added_by__c = userinfo.getuserid();
                   ch.value__c = 'Scoping';
                   caseHistoriesToInsert.add(ch);
                if(casesMap.get(l.case__c).scoping_Date__c == null){
                    case__c c = casesMap.get(l.case__c);
                    c.current_task__c = 'Scoping';
                    c.Scoping_Date__c = system.today();
                    casesToUpdate.put(c.Id, c);
                }
            }
               
        }   
    }
    
    if(trigger.isUpdate && trigger.isBefore){
        List<String> investigatorIds = new List<String>();
        for(lead__c l: trigger.new){
            if(string.isNotBlank(l.assigned_to__c)){
               investigatorIds.add(l.assigned_to__c);   
            }
            if(l.coverage_type__c != Trigger.oldmap.get(l.Id).coverage_type__c && l.status__c != 'Unassigned'){
                l.status__c = 'In-Progress';
            }
        }
        System.debug('investigatorIds...'+ investigatorIds);
        
        List<Daily_Production_Summary__c> dailyProductionSummaries = new List<Daily_Production_Summary__c>();
        Map<String, Daily_Production_Summary__c> investigatorSummaryMap = new Map<String, Daily_Production_Summary__c>();
        Map<string,Daily_Production_Summary__c> dailyProductionSummariesToUpdate = new Map<string,Daily_Production_Summary__c>();
        dailyProductionSummaries = [Select Id, Reviewer__c, Leads_Accepted__c, Leads_Completed__c, Leads_Rejected__c, Summary_Date__c
                                    FROM Daily_Production_Summary__c
                                    WHERE Summary_Date__c = TODAY AND Reviewer__c IN: investigatorIds];
                                    
        for(Daily_Production_Summary__c dps: dailyProductionSummaries){
             investigatorSummaryMap.put(dps.Reviewer__c,dps);   
        }
        
        for(string invId: investigatorIds){
            if(!investigatorSummaryMap.containsKey(invId)){
                Daily_Production_Summary__c dps = new Daily_Production_Summary__c();
                dps.Reviewer__c  = invId;     
                dps.Leads_Accepted__c  = 0;     
                dps.Leads_Completed__c  = 0;     
                dps.Leads_Rejected__c  = 0;     
                dps.Summary_Date__c  = System.Today();  
                insert dps;  
                investigatorSummaryMap.put(invId,dps); 
            }
        }
        Map<Id,User> userMap = new Map<Id,User>([Select Id,Name from User]);
        Id orgWideEmailId = MailUtilities.getNoReplyOrgWideEmailId();
         for(lead__c l: trigger.new){
            if(l.status__c == 'Completed' && trigger.oldmap.get(l.id).status__c != 'Completed'){
                if(l.completed_date__c  == null){
                    l.completed_date__c = system.today();
                }else{
                    system.debug('Lead already has completed_date__c');
                }
                
            }
            if(l.status__c == 'Assigned Not Accepted' && trigger.oldmap.get(l.id).status__c != 'Assigned Not Accepted'){
                User investigator = [Select Id,Firstname,lastname,email,email__c from user where id=:l.Assigned_to__c];
                List<string> toAddress = new List<string>();
                toAddress.add(investigator.email__c);
                String subject = 'New Task assigned';
                String Body = 'Dear '+investigator.FirstName+' '+investigator.LastName+'<br/><br/>';
                Body = Body + 'A new case task has been assigned to you. Please log into the case management system to accept/reject the case before the expiration.';
                Body = Body + 'Thanks<br/>ISN Corporation';
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
                mail.setSaveAsActivity(false);
                mail.setTargetObjectId(investigator.id);
                mail.setSubject(subject);
                mail.setBccSender(false);
                if (orgWideEmailId != null) {
                    mail.setOrgWideEmailAddressId(orgWideEmailId);
                }
                mail.setUseSignature(false);
                mail.setHtmlBody(body);
                assignedMsgs.add(mail);
                //MailUtilities.sendHTMLEmailWithTargetObjectId(investigator.id,subject,Body,null);
                if(String.isBlank(l.Lead_Log__c)){
                    l.Lead_Log__c = System.now() + ': lead assigned to '+userMap.get(l.assigned_to__c).Name+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead assigned to '+userMap.get(l.assigned_to__c).Name+'<br/>';
                }
            }
             //Assigned Not Accepted
            /*if(l.status__c == 'Assigned' && l.Lead_Accepted_or_Rejected__c == Null){
                l.status__c = 'Assigned Not Accepted';
            }*/
            if(l.Lead_Accepted_or_Rejected__c =='Accepted' && trigger.oldmap.get(l.id).Lead_Accepted_or_Rejected__c != 'Accepted'){
                Daily_Production_Summary__c dps = investigatorSummaryMap.get(l.assigned_to__c);
                dps.Leads_Accepted__c = dps.Leads_Accepted__c+1;
                dailyProductionSummariesToUpdate.put(dps.id,dps);
                if(String.isBlank(l.Lead_Log__c)){
                    l.Lead_Log__c = System.now() + ': lead accepted by '+userMap.get(l.assigned_to__c).Name+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead accepted by '+userMap.get(l.assigned_to__c).Name+'<br/>';
                }
                l.status__c = 'In-Progress';
            }
            
            if(l.Lead_Accepted_or_Rejected__c =='Rejected' && trigger.oldmap.get(l.id).Lead_Accepted_or_Rejected__c != 'Rejected'){
                Daily_Production_Summary__c dps = investigatorSummaryMap.get(l.assigned_to__c);
                dps.Leads_Rejected__c = dps.Leads_Rejected__c+1;
                dailyProductionSummariesToUpdate.put(dps.id,dps);
                
                Case__c caseOfLead = [Select Assigned_to__r.Email__c,Assigned_To__c,Case_Number__c, Assigned_To__r.Email from case__c where id=:l.case__c];
                User caseCMO = [Select Firstname,lastname from user where id=:caseOfLead.Assigned_to__c];
                User rejectedInvestigator = [Select Firstname,lastname from user where id=:trigger.oldmap.get(l.id).Assigned_to__c];
                List<string> toAddress = new List<string>();
                toAddress.add(caseOfLead.Assigned_to__r.Email__c);
                String subject = 'Task Rejected by Investigator – case#'+caseOfLead.Case_Number__c;
                String Body = 'Dear '+caseCMO.FirstName+' '+caseCMO.LastName+'<br/><br/>';
                Body = Body + 'Investigator '+ rejectedInvestigator.FirstName +' '+ rejectedInvestigator.LastName +'has rejected the task associated with case# '+caseOfLead.Case_Number__c+'. Please log into the case management system and re-assign the case as soon as possible.<br/><br/>';
                Body = Body + 'Thanks<br/>ISN Corporation';
                system.debug('Rejection is doing emails');
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
                mail.setSaveAsActivity(false);
                mail.setSubject(subject);
                mail.setBccSender(false);
                mail.setUseSignature(false);
                if (orgWideEmailId != null) {
                    mail.setOrgWideEmailAddressId(orgWideEmailId);
                }
                mail.setHtmlBody(body);
                mail.setCCAddresses(toAddress);
                assignedMsgs.add(mail);
                
                //MailUtilities.sendHTMLEmail(toAddress,subject,Body,null);
               
                if(String.isBlank(l.Lead_Log__c)){
                    l.Lead_Log__c = '<b style="color:red">'+System.now() + ': lead rejected by '+userMap.get(trigger.oldmap.get(l.id).assigned_to__c).Name+'</b><br/>';
                }else{
                    System.debug('l.assigned_to__c...'+l.assigned_to__c);
                    System.debug('lead...Assigned_To_Name__c'+l);
                    l.Lead_Log__c = l.Lead_Log__c + '<b style="color:red">'+ System.now() +  ': lead rejected by '+userMap.get(trigger.oldmap.get(l.id).assigned_to__c).Name+'</b><br/>';
                }
                l.assigned_to__c = null;  
            }
            if(l.status__c == 'Completed' && trigger.oldmap.get(l.id).status__c != 'Completed'){
                if(investigatorSummaryMap.get(l.assigned_to__c) != null){
                    Daily_Production_Summary__c dps = investigatorSummaryMap.get(l.assigned_to__c);
                    if(dps.Leads_Completed__c == null){
                        dps.Leads_Completed__c = 0;
                    }
                    dps.Leads_Completed__c = dps.Leads_Completed__c+1;
                    dailyProductionSummariesToUpdate.put(dps.id,dps);
                }
                
                if(String.isBlank(l.Lead_Log__c)){
                    l.Lead_Log__c = System.now() + ': lead completed by '+userMap.get(l.assigned_to__c).Name+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead completed by '+userMap.get(l.assigned_to__c).Name+'<br/>';
                }
            }
            if(l.status__c == 'QA Rejected' && trigger.oldmap.get(l.id).status__c != 'QA Rejected'){
                Case__c caseOfLead = [Select Assigned_To__c,Case_Number__c, Assigned_To__r.Email from case__c where id=:l.case__c];
                User investigator = [Select Firstname,lastname,email,Email__c from user where id=:l.Assigned_to__c];
                
                //Commented based on PPF-167
                /*List<string> toAddress = new List<string>();
                toAddress.add(investigator.Email__c);
                String subject = 'QA Rejected';
                String Body = 'Dear '+investigator.FirstName+' '+investigator.LastName+'<br/><br/>';
                Body = Body + 'QA has rejected the task lead associated with case #'+caseOfLead.Case_Number__c+'. Please log into the case management system to complete the missing information for the lead.';
                Body = Body + 'Thanks<br/>ISN Corporation';
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
                mail.setSaveAsActivity(false);
                mail.setSubject(subject);
                mail.setBccSender(false);
                mail.setUseSignature(false);
                if (orgWideEmailId != null) {
                    mail.setOrgWideEmailAddressId(orgWideEmailId);
                }
                mail.setHtmlBody(body);
                mail.setCCAddresses(toAddress);
                assignedMsgs.add(mail);
                
                //MailUtilities.sendHTMLEmail(toAddress,subject,Body,null);*/
               
                if(String.isBlank(l.Lead_Log__c)){
                    l.Lead_Log__c = System.now() + ': lead rejected by QA'+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead rejected by QA'+'<br/>';
                }
            }
            if(l.status__c == 'QA Review Completed' && trigger.oldmap.get(l.id).status__c != 'QA Review Completed'){
                if(String.isBlank(l.Lead_Log__c)){
                    l.Lead_Log__c = System.now() + ': lead QA review completed'+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead QA review completed'+'<br/>';
                }
            }

        }
        if(!Test.isRunningTest() && !assignedMsgs.isEmpty()){
            Messaging.sendEmail(assignedMsgs);
        }
        if(!dailyProductionSummariesToUpdate.values().isEmpty()){
            update dailyProductionSummariesToUpdate.values();
        }
    }
    if(trigger.isUpdate && trigger.isBefore){
         for(Lead__C l: Trigger.new){
            If (l.Issues_discrepancies_or_developed_acti__c!= 'Yes'){ 
                l.Issue_Description__c = null;
            }  
         }
    }
    
    if(trigger.isUpdate && trigger.isAfter){
        List<Message__c> messagesToInsert = new List<Message__c>();
        
        LeadTriggerHandler.createInvoice(Trigger.NewMap,Trigger.OldMap);
        
        Map<string,Message__c> leadNMessages = New Map<string,Message__c>();
        Map<Id,Message__c> leadTypeNMessage = New Map<Id,Message__c>();
        List<Message__c> existingMessages = [select id,Lead__c,Lead__r.leadType__c,subject__c from message__c where Lead__c IN: Trigger.NewMap.keyset()];
        for(Message__c msg : existingMessages){
            if(msg.subject__c == 'LEADS FROM ESI'){
                leadNMessages.put(msg.Lead__c,msg);
            }
            if(msg.subject__c != null){
                if(msg.subject__c.contains(' -  Issues, discrepancies, or developed activities discussed')){
                    leadTypeNMessage.put(msg.Lead__c,msg);
                }
            }
        }
        
        List<Message__c> messagesToUpdate = New List<Message__c>();
        for(Lead__C l: Trigger.new){
            If(Trigger.newMap.get(l.Id).Status__c == 'Completed'){
                If (l.Issues_discrepancies_or_developed_acti__c== 'Yes'){ 
                    system.debug('l.Issues_discrepancies_or_developed_acti__c...'+l.Issues_discrepancies_or_developed_acti__c);
                    if(leadTypeNMessage.containsKey(l.Id)){
                        Message__c m = leadTypeNMessage.get(l.Id);
                        system.debug('updated message...'+m.Id);
                        m.Message_Body__c = l.Issue_Description__c;
                        messagesToUpdate.add(m);
                    }else{
                        system.debug('inserted');
                        Message__c message = new Message__c();
                        message.Message_Body__c = l.Issue_Description__c;
                        message.subject__c = l.leadType__c + ' -  Issues, discrepancies, or developed activities discussed';
                        message.From_User__c = userinfo.getUserId();
                        message.case__c = l.case__c;
                        message.lead__c = l.id;
                        messagesToInsert.add(message);
                    }
                }
            }
            system.debug('Trigger.newMap.get(l.Id).Status__c...'+Trigger.newMap.get(l.Id).Status__c);
            If(Trigger.newMap.get(l.Id).Status__c == 'Completed' && l.leadtype__c == 'Subject Interview (ESI/TESI)'){
                if(leadNMessages.containsKey(l.Id)){
                    system.debug('Trigger.newMap.get(l.Id).Explanation_of_why_leads_not_obtained__c updated...'+l.Id+Trigger.newMap.get(l.Id).Explanation_of_why_leads_not_obtained__c);
                    Message__c m = leadNMessages.get(l.Id);
                    m.Message_Body__c = Trigger.newMap.get(l.Id).Explanation_of_why_leads_not_obtained__c;
                    messagesToUpdate.add(m);
                }else{
                    system.debug('New Message created for LEADS FROM ESI with lead id...'+l.Id);
                    Message__c message = new Message__c();
                    message.Message_Body__c = Trigger.newMap.get(l.Id).Explanation_of_why_leads_not_obtained__c;
                    message.subject__c = 'LEADS FROM ESI';
                    message.From_User__c = userinfo.getUserId();
                    message.case__c = l.case__c;
                    message.Lead__c = l.Id;
                    messagesToInsert.add(message);
                }
            }
        }
        if(!messagesToInsert.isEmpty()){
            insert messagesToInsert;
        }
        if(!messagesToUpdate.isEmpty()){
            update messagesToUpdate;
        }
    
    
    
        //For Status change logic
        List<Lead__c> oldLeadValues = new List<Lead__c>();
        List<Lead__c> newLeadValues = new List<Lead__c>();
        for(Lead__C l: Trigger.new){
            If (Trigger.oldMap.get(l.Id).Status__c != Trigger.newMap.get(l.Id).Status__c){
                oldLeadValues.add(Trigger.oldMap.get(l.Id));
                newLeadValues.add(Trigger.newMap.get(l.Id));
            }
        }
        if(!oldLeadValues.isEMpty() && !newLeadValues.isEmpty()){
			LeadTriggerHandler.LeadAuditMethod(oldLeadValues,newLeadValues);
        }
    
        list<string> caseids = new list<String>();
        for(lead__c l: trigger.new){
            caseids.add(l.case__C);    
        }
        map<id, case__c> casemap = new map<id,case__c>([select id, current_task__c, Investigations_Review_Date__c, QA_and_review_Date__c from case__c where id in: caseids]);
        list<lead__c> leads = [Select Id, Assigned_to__c,case__c, Status__c  from Lead__c where case__c in: caseids];
        map<string,list<lead__c>> caseNleadMap = new map<string,list<lead__c>>();
        for(lead__C l: leads){
            if(!caseNleadMap.containskey(l.case__c)){
                caseNleadMap.put(l.case__c,new list<lead__c>{l});    
            } else{
                caseNleadMap.get(l.case__c).add(l);    
            }
        }
        
        for(string caseId: caseNleadMap.keyset()){
            case__c c= casemap.get(caseid);
            boolean allLeadsAreAssigned = true;
            for(lead__c l: caseNleadMap.get(caseId)){
                if(l.Assigned_To__c == null){
                    allLeadsAreAssigned = false;    
                }
            }
            if(allLeadsAreAssigned && c.investigations_review_Date__c == null){
                 c.current_task__c = 'investigations review';
                 c.investigations_review_Date__c = system.today();
                 casesToUpdate.put(c.Id, c);
                 System.debug('casesToUpdate..allLeadsAreAssigned...'+casesToUpdate);
                 
                 case_History__c ch = new case_History__c();
                   ch.case__c = c.id;
                   ch.added_by__c = userinfo.getuserid();
                   ch.value__c = 'investigations review';
                   caseHistoriesToInsert.add(ch);
            }
        }
        
         for(string caseId: caseNleadMap.keyset()){
            case__c c= casemap.get(caseid);
            boolean allLeadsAreCompleted = true;
            for(lead__c l: caseNleadMap.get(caseId)){
                if(l.status__c != 'Completed' && l.status__c != 'Cancelled' ){
                    allLeadsAreCompleted = false;    
                }
            }
            if(allLeadsAreCompleted && c.QA_and_review_Date__c ==null){
                 c.current_task__c = 'QA and review';
                 c.QA_and_review_Date__c = system.today();
                 casesToUpdate.put(c.Id, c);    
                System.debug('casesToUpdate..allLeadsAreCompleted...'+casesToUpdate);
                
                 case_History__c ch = new case_History__c();
                   ch.case__c = c.id;
                   ch.added_by__c = userinfo.getuserid();
                   ch.value__c = 'QA and review';
                   caseHistoriesToInsert.add(ch);
            }
        }
        
       
        for(lead__c l: trigger.new){
            if(l.Reason_for_Waiver__c == 'Subject not available' && trigger.oldMap.get(l.id).Reason_for_Waiver__c == null){
                Waiver_Information__c wi = new Waiver_Information__c();
                wi.Case__c = l.case__c;
                wi.lead__c = l.id;
                wi.Waiver_Reason__c = 'Subject not available';
                wi.Waiver_Flagged_Date__c = system.today();
                WaiverInformationToCreate.add(wi);
            }
        }
 
    }
    
    if(!caseHistoriesToInsert.isEmpty()){
        insert caseHistoriesToInsert;
    } 
    if(!WaiverInformationToCreate.isEmpty()){
        insert WaiverInformationToCreate;
    }
    if(!casesToUpdate.isEmpty()){
        update casesToUpdate.values();
    }
    /*
    if((trigger.isInsert || trigger.isUpdate) && trigger.isAfter){
        set<Id> caseIds = New set<Id>();
        Map<id,string> caseNLeadMap = New Map<id,string>();
        for(Lead__c l: Trigger.New){
            caseIds.add(l.case__c);
            caseNLeadMap.put(l.case__c,l.Id);
        } 
        list<lead__c> updateLeads = New list<lead__c>();
        list<case__c> caseList = [select id,Contact__r.First_Name__c,Contact__r.Last_Name__c from case__c where id IN: caseIds];
        Map<Id,case__c> caseMap = New Map<Id,case__c>();
        for(case__c cs : caseList){
            lead__c ld = New lead__c();
            ld.Id = caseNLeadMap.get(cs.Id);
            ld.Source_Name__c = cs.Contact__r.First_Name__c+' '+cs.Contact__r.Last_Name__c;
            updateLeads.add(ld);
        }
        	update updateLeads;
    }*/
    
    if(Trigger.isupdate && Trigger.isAfter){
        user u = [select id,user_type__c from user where id =: userinfo.getuserid()];
        if(u.user_type__c == 'INV' || Test.isRunningTest()){
            List<timesheet__c> invTimeSheet = [select id,Associated_Leads__c from timesheet__c where user__c =: userinfo.getuserid() and date__c =: system.today() limit 1];
            
            List<Lead__c> leads = [select id,case__r.Case_number__c,leadtype__c,coverage_type__c,item_number__c from Lead__c where Id IN:Trigger.NewMap.keyset()];
            if(!invTimeSheet.isEMpty()){
                for(lead__c l : leads){
                    string key = l.case__r.Case_number__c+'_'+l.leadtype__c+'_'+l.coverage_type__c+'_'+l.item_number__c;
                    if(invTimeSheet[0].Associated_Leads__c != null){
                        if(!invTimeSheet[0].Associated_Leads__c.contains(key)){
							invTimeSheet[0].Associated_Leads__c += ','+key;
                        }
                    }else{
                        invTimeSheet[0].Associated_Leads__c = key;
                    }
                    
            	}
            			update invTimeSheet[0];
            }
            
        }
    }
    if(Trigger.isUpdate && Trigger.IsAfter){
        dt(system.today());
        dt(system.today(),true);
        dt(system.today(),true,false);
        for(Lead__c l : Trigger.New){
            system.debug(l.status__c+' ===> '+l.Id);
        }
    }
    public static datetime dt(date dte){
        integer day;
        integer month;
        integer year;
        day = dte.day();
        month = dte.month();
        year = dte.year();
        datetime dtime;
        dtime = datetime.newinstance(day,month,year);
        return dtime;
    }
    public static datetime dt(date dte,boolean isDate){
        integer day;
        integer month;
        integer year;
        day = dte.day();
        month = dte.month();
        year = dte.year();
        datetime dtime;
        dtime = datetime.newinstance(day,month,year);
        return dtime;
    }
    public static datetime dt(date dte,boolean isDate,boolean isDatetime){
        integer day;
        integer month;
        integer year;
        day = dte.day();
        month = dte.month();
        year = dte.year();
        datetime dtime;
        dtime = datetime.newinstance(day,month,year);
        return dtime;
    }
}