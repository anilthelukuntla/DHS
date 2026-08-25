trigger DIALeadTrigger on DIA_Lead__c (before insert, before update, after insert, after update) {
    if(trigger.isBefore && trigger.isUpdate){
        DIALeadTriggerHandler.UpdatePricingOnLead(Trigger.New,Trigger.oldMap);    
    }
    list<string> caseIds = new list<string>();
    list<DIA_Case_History__c> caseHistoriesToInsert = new LisT<DIA_Case_History__c>();
    Map<id,DIA_case__c> casesToUpdate = New Map<id,DIA_case__c>();
    List<dia_case__c> updateCases = New List<dia_case__c>();
    list<DIA_Waiver_Information__c > WaiverInformationToCreate  = new LisT<DIA_Waiver_Information__c >();
    if((trigger.isInsert || trigger.isUpdate) && trigger.isBefore){
         for(DIA_Lead__C l: Trigger.new){
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
        for(DIA_lead__c l: trigger.new){
            leadcaseids.add(l.case__C); 
            if(trigger.isUpdate){
                leadIds.add(l.id);
            }   
        }
        List<DIA_Lead__c> leads = new List<DIA_Lead__c>();
        if(trigger.isInsert){
            leads = [Select Id, Case__c, item_Number__c from DIA_Lead__C where case__c in: leadcaseids];
        }else if(trigger.isUpdate){
            leads = [Select Id, Case__c, item_Number__c from DIA_Lead__C where case__c in: leadcaseids and id not IN: leadIds];
        }
        map<Id,DIA_case__c> casesMap = new map<id,DIA_case__c>([select id,contact__c, Scoping_Date__c, current_task__c from DIA_case__c where id in: leadcaseids ]);
            
        map<string,list<DIA_lead__c>> caseIdNleads = new map<string,list<DIA_lead__c>>();
        for(DIA_lead__c el: leads){
            if(!caseIdNleads.containsKey(el.Case__c)){
                caseIdNleads.put(el.case__c, new list<DIA_lead__c>{el});    
            }else{
                list<DIA_lead__c> temp = caseIdNleads.get(el.case__c);
                temp.add(el);
                caseIdNleads.put(el.case__c,temp);   
            }    
        }
        for(DIA_lead__c l: trigger.new){
            list<DIA_lead__c> existingLeads = caseIdNleads.get(l.case__c); 
            if(existingLeads != Null){ 
                for(DIA_lead__c el: existingLeads){
                    if(el.item_number__c == l.item_number__c && l.item_number__c != Null){
                        l.addError(System.label.Duplicate_Item_Number_Message);
                    }
                }
            }
        }
    }
    
    
    if(trigger.isInsert && trigger.isBefore){
        for(DIA_Lead__c l: Trigger.New){
            caseIds.add(l.case__c);     
            l.Status__c = 'UnAssigned';
        }   
    
        List<DIA_Lead__c> leads = new List<DIA_Lead__c>();
        leads = [Select Id, Case__c from DIA_Lead__c where case__c in: caseIds];
        map<Id,DIA_case__c> casesMap = new map<id,DIA_case__c>([select id,contact__c, Scoping_Date__c, current_task__c from DIA_case__c where id in:caseIds ]);
        map<string,integer> caseIdNnumberOfleads = new map<string,integer>();
        for(DIA_lead__c l: leads){
            if(!caseIdNnumberOfleads.containsKey(l.Case__c)){
                caseIdNnumberOfleads.put(l.case__c, 1);    
            }else{
                caseIdNnumberOfleads.put(l.case__c,caseIdNnumberOfleads.get(l.case__c)+1);   
            }    
        }
  
        for(DIA_Lead__c l: Trigger.New){
            l.Contact__c = casesMap.get(l.case__c).Contact__c;
            if(caseIdNnumberOfleads.containsKey(l.case__c)){
                //l.Item_number__c =  caseIdNnumberOfleads.get(l.case__c)+1;   
            }else{
                   //l.Item_number__c = 1;
                   DIA_case_History__c ch = new DIA_case_History__c();
                   ch.case__c = l.case__c;
                   ch.added_by__c = userinfo.getuserid();
                   ch.value__c = 'Scoping';
                   ch.type__c = 'Task';
                   caseHistoriesToInsert.add(ch);
                if(casesMap.get(l.case__c).scoping_Date__c == null){
                    DIA_case__c c = casesMap.get(l.case__c);
                    /*c.current_task__c = 'Scoping';
                    c.Scoping_Date__c = system.today();
                    casesToUpdate.add(c); */
                    if(casesToUpdate.containskey(c.id)){
                        DIA_case__c existing = casesToUpdate.get(c.id);
                        existing.current_task__c = 'Scoping';
                    	existing.Scoping_Date__c = system.today();
                        casesToUpdate.put(existing.id,existing);
                    }else{
                        c.current_task__c = 'Scoping';
                    	c.Scoping_Date__c = system.today();
                        casesToUpdate.put(c.id,c);
                    }
                    system.debug('Came into scoping...');
                }
            }
               
        }   
    }
    
    if(trigger.isUpdate && trigger.isBefore){
        List<String> investigatorIds = new List<String>();
        for(DIA_lead__c l: trigger.new){
            if(string.isNotBlank(l.assigned_to__c)){
               investigatorIds.add(l.assigned_to__c);   
            }
        }
        
        List<DIA_Daily_Production_Summary__c> dailyProductionSummaries = new List<DIA_Daily_Production_Summary__c>();
        Map<String, DIA_Daily_Production_Summary__c> investigatorSummaryMap = new Map<String, DIA_Daily_Production_Summary__c>();
        Map<string,DIA_Daily_Production_Summary__c> dailyProductionSummariesToUpdate = new Map<string,DIA_Daily_Production_Summary__c>();
        dailyProductionSummaries = [Select Id, Reviewer__c, Leads_Accepted__c, Leads_Completed__c, Leads_Rejected__c, Summary_Date__c
                                    FROM DIA_Daily_Production_Summary__c
                                    WHERE Summary_Date__c = TODAY AND Reviewer__c IN: investigatorIds];
                                    
        for(DIA_Daily_Production_Summary__c dps: dailyProductionSummaries){
             investigatorSummaryMap.put(dps.Reviewer__c,dps);   
        }
        
        for(string invId: investigatorIds){
            if(!investigatorSummaryMap.containsKey(invId)){
                DIA_Daily_Production_Summary__c dps = new DIA_Daily_Production_Summary__c();
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
         for(DIA_lead__c l: trigger.new){

            if(l.status__c == 'Completed' && trigger.oldmap.get(l.id).status__c != 'Completed'){
                l.completed_date__c = system.today();
            } 
            
           
            
            if(l.status__c == 'Assigned' && trigger.oldmap.get(l.id).status__c != 'Assigned'){
                User investigator = [Select Id,Firstname,lastname,email from user where id=:l.Assigned_to__c];
                List<string> toAddress = new List<string>();
                toAddress.add(investigator.Email);
                String subject = 'New Task assigned';
                String Body = 'Dear '+investigator.FirstName+' '+investigator.LastName+'<br/><br/>';
                Body = Body + 'A new case task has been assigned to you  by '+userInfo.getLastName()+' '+userInfo.getFirstName()+'. Please log into the case management system to accept/reject the case before the expiration.<br/><br/>';
                Body = Body + 'Thanks<br/>ISN Corporation';
                
                //MailUtilities.sendBIEmail(subject,Body,toAddress,string.valueOf(system.label.AdminEmail).split(','),null);
                MailUtilities.sendBIEmailWithSetTargetObjectId(subject,Body,investigator.id,null,null);
                if(String.isBlank(l.Lead_Log__c)){
                    l.Lead_Log__c = System.now() + ': lead assigned to '+userMap.get(l.assigned_to__c).Name+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead assigned to '+userMap.get(l.assigned_to__c).Name+'<br/>';
                }
            }
             //Assigned Not Accepted
            if(l.status__c == 'Assigned' && l.Lead_Accepted_or_Rejected__c == Null){
                l.status__c = 'Assigned Not Accepted';
            }
            if(l.Lead_Accepted_or_Rejected__c =='Accepted' && trigger.oldmap.get(l.id).Lead_Accepted_or_Rejected__c != 'Accepted'){
                DIA_Daily_Production_Summary__c dps = investigatorSummaryMap.get(l.assigned_to__c);
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
                DIA_Daily_Production_Summary__c dps = investigatorSummaryMap.get(l.assigned_to__c);
                dps.Leads_Rejected__c = dps.Leads_Rejected__c+1;
                dailyProductionSummariesToUpdate.put(dps.id,dps);
                
                DIA_Case__c caseOfLead = [Select Assigned_To__c,Case_Number__c, Assigned_To__r.Email from DIA_Case__c where id=:l.case__c];
                User caseCMO = [Select Firstname,lastname from user where id=:caseOfLead.Assigned_to__c];
                User rejectedInvestigator = [Select Firstname,lastname from user where id=:trigger.oldmap.get(l.id).Assigned_to__c];
                List<string> toAddress = new List<string>();
                toAddress.add(caseOfLead.Assigned_to__r.Email);
                String subject = 'Task Rejected by Investigator – case#'+caseOfLead.Case_Number__c;
                String Body = 'Dear '+caseCMO.FirstName+' '+caseCMO.LastName+'<br/><br/>';
                Body = Body + 'Investigator '+ rejectedInvestigator.FirstName +' '+ rejectedInvestigator.LastName +'has rejected the task associated with case# '+caseOfLead.Case_Number__c+'. Please log into the case management system and re-assign the case as soon as possible.<br/><br/>';
                Body = Body + 'Thanks<br/>ISN Corporation';
                
                
                MailUtilities.sendBIEmail(subject,Body,toAddress,null,null);
                if(String.isBlank(l.Lead_Log__c)){
                    l.Lead_Log__c = '<b style="color:red">'+System.now() + ': lead rejected by '+userMap.get(trigger.oldmap.get(l.id).assigned_to__c).Name+'</b><br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + '<b style="color:red">'+ System.now() +  ': lead rejected by '+userMap.get(trigger.oldmap.get(l.id).assigned_to__c).Name+'</b><br/>';
                }
                l.assigned_to__c = null;  
            }
            if(l.status__c != 'Completed' && trigger.oldmap.get(l.id).status__c == 'Completed'){
                DIA_Daily_Production_Summary__c dps = investigatorSummaryMap.get(l.assigned_to__c);
                dps.Leads_Completed__c = dps.Leads_Completed__c+1;
                dailyProductionSummariesToUpdate.put(dps.id,dps);
                if(String.isBlank(l.Lead_Log__c)){
                    l.Lead_Log__c = System.now() + ': lead completed by '+userMap.get(l.assigned_to__c).Name+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead completed by '+userMap.get(l.assigned_to__c).Name+'<br/>';
                }
            }
            if(l.status__c == 'QA Rejected' && trigger.oldmap.get(l.id).status__c != 'QA Rejected'){
                DIA_Case__c caseOfLead = [Select Assigned_To__c,Case_Number__c, Assigned_To__r.Email from DIA_Case__c where id=:l.case__c];
                User investigator = [Select Firstname,lastname,email from user where id=:l.Assigned_to__c];
                List<string> toAddress = new List<string>();
                toAddress.add(investigator.Email);
                String subject = 'QA Rejected';
                String Body = 'Dear '+investigator.FirstName+' '+investigator.LastName+'<br/><br/>';
                Body = Body + 'QA has rejected the task lead associated with case #'+caseOfLead.Case_Number__c+'. Please log into the case management system to complete the missing information for the lead.<br/><br/>';
                Body = Body + 'Thanks<br/>ISN Corporation';
                
                MailUtilities.sendBIEmail(subject,Body,toAddress,null,null);
               
                if(String.isBlank(l.Lead_Log__c)){
                    l.Lead_Log__c = System.now() + ': lead rejected by QA'+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead rejected by QA'+'<br/>';
                }
            }
            if(l.status__c != 'QA Review Completed' && trigger.oldmap.get(l.id).status__c == 'QA Review Completed'){
                if(String.isBlank(l.Lead_Log__c)){
                    l.Lead_Log__c = System.now() + ': lead QA review completed'+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead QA review completed'+'<br/>';
                }
            }

        }
        
        if(!dailyProductionSummariesToUpdate.values().isEmpty()){
            update dailyProductionSummariesToUpdate.values();
        }
    }
    if(trigger.isUpdate && trigger.isBefore){
         for(DIA_Lead__C l: Trigger.new){
            If (l.Issues_discrepancies_or_developed_acti__c!= 'Yes'){ 
                l.Issue_Description__c = null;
            }  
         }
    }
    
    if(trigger.isUpdate && trigger.isAfter){
        List<DIA_Message__c> messagesToInsert = new List<DIA_Message__c>();
        List<DIA_Message__c> messagesToUpdate = new List<DIA_Message__c>();
        Map<string,string> leadNMessage = New Map<string,string>();
        set<id> messageIdsToDelete = New set<id>();
        List<dia_Message__c> messages = [select id,dia_lead__c,subject__c,message_body__c from dia_Message__c where dia_lead__c IN: Trigger.newmap.keyset()];
        for(dia_Message__c message : messages){
            leadNMessage.put(message.dia_lead__c,message.Id);
        }
        for(DIA_Lead__C l: Trigger.new){
            system.debug(l.Issues_discrepancies_or_developed_acti__c);
            If ( l.Issues_discrepancies_or_developed_acti__c== 'Yes'){   
                system.debug(leadNMessage.get(l.Id));
                if(leadNMessage.containsKey(l.Id)){
                    DIA_Message__c ExistingMessage = new DIA_Message__c(id=leadNMessage.get(l.Id));
                    ExistingMessage.Message_Body__c = Trigger.newMap.get(l.Id).Issue_Description__c;
                    ExistingMessage.subject__c = l.leadType__c + ' -  Issues, discrepancies, or developed activities discussed';
                    ExistingMessage.From_User__c = userinfo.getUserId();
                    ExistingMessage.case__c = l.case__c;
                    ExistingMessage.dia_lead__c = l.Id;
                    messagesToUpdate.add(ExistingMessage);
                }else{
                    DIA_Message__c message = new DIA_Message__c();
                    message.Message_Body__c = Trigger.newMap.get(l.Id).Issue_Description__c;
                    message.subject__c = l.leadType__c + ' -  Issues, discrepancies, or developed activities discussed';
                    message.From_User__c = userinfo.getUserId();
                    message.case__c = l.case__c;
                    message.dia_lead__c = l.Id;
                    messagesToInsert.add(message); 
                }
                
            }else{
                if(leadNMessage.containsKey(l.Id)){
                    messageIdsToDelete.add(leadNMessage.get(l.Id));
                }
            }
        }
        if(!messagesToInsert.isEmpty()){
            insert messagesToInsert;
        }
        if(!messagesToUpdate.isEmpty()){
            update messagesToUpdate;
        }
        if(!messageIdsToDelete.isEmpty()){
            delete [select id from dia_message__c where id IN: messageIdsToDelete];
        }
    
    
    
        //For Status change logic
       // for(DIA_Lead__C l: Trigger.new){
       //     If (Trigger.oldMap.get(l.Id).Status__c != Trigger.newMap.get(l.Id).Status__c){
                DIALeadTriggerHandler.LeadAuditMethod(Trigger.Old,Trigger.New);
       //     }
        //        }
    
    
        list<string> caseids = new list<String>();
        for(DIA_lead__c l: trigger.new){
            caseids.add(l.case__C);    
        }
        map<id, DIA_case__c> casemap = new map<id,DIA_case__c>([select id, current_task__c, Investigations_Review_Date__c, QA_and_review_Date__c from DIA_case__c where id in: caseids]);
        list<DIA_lead__c> leads = [Select Id, Assigned_to__c,case__c, Status__c  from DIA_Lead__c where case__c in: caseids];
        map<string,list<DIA_lead__c>> caseNleadMap = new map<string,list<DIA_lead__c>>();
        for(DIA_lead__c l: leads){
            if(!caseNleadMap.containskey(l.case__c)){
                caseNleadMap.put(l.case__c,new list<DIA_lead__c>{l});    
            } else{
                caseNleadMap.get(l.case__c).add(l);    
            }
        }
        
        for(string caseId: caseNleadMap.keyset()){
            DIA_case__c c= casemap.get(caseid);
            boolean allLeadsAreAssigned = true;
            for(DIA_lead__c l: caseNleadMap.get(caseId)){
                if(l.Assigned_To__c == null){
                    allLeadsAreAssigned = false;    
                }
            }
            if(allLeadsAreAssigned && c.investigations_review_Date__c == null){
                	if(casesToUpdate.containskey(c.id)){
                        DIA_case__c existing = casesToUpdate.get(c.id);
                        existing.current_task__c = 'investigations review';
                 		existing.investigations_review_Date__c = system.today();
                        casesToUpdate.put(existing.id,existing);
                    }else{
                        c.current_task__c = 'investigations review';
                 		c.investigations_review_Date__c = system.today();
                        casesToUpdate.put(c.id,c);
                    }
                /*
                 c.current_task__c = 'investigations review';
                 c.investigations_review_Date__c = system.today();
                 casesToUpdate.add(c);  */
                 system.debug('Came into investigations review...');
                 
                DIA_case_History__c ch = new DIA_case_History__c();
                   ch.case__c = c.id;
                   ch.added_by__c = userinfo.getuserid();
                   ch.value__c = 'investigations review';
                     ch.type__c = 'Task';
                   caseHistoriesToInsert.add(ch);
            }
        }
        
        for(string caseId: caseNleadMap.keyset()){
            DIA_case__c c= casemap.get(caseid);
            boolean allLeadsAreCompleted = true;
            boolean allLeadsAreQAReviewCompleted = true;
            for(DIA_lead__c l: caseNleadMap.get(caseId)){
                system.debug(l.status__c);
                if(l.status__c != 'Completed' && l.status__c != 'Cancelled' &&  l.status__c != 'QA Review Completed'){
                    allLeadsAreCompleted = false;    
                }
            }
            if(allLeadsAreCompleted && c.QA_and_review_Date__c ==null){
                	if(casesToUpdate.containskey(c.id)){
                        DIA_case__c existing = casesToUpdate.get(c.id);
                        existing.current_task__c = 'QA and review';
                 		existing.QA_and_review_Date__c = system.today();
                        casesToUpdate.put(existing.id,existing);
                    }else{
                        c.current_task__c = 'QA and review';
                 		c.QA_and_review_Date__c = system.today();
                        casesToUpdate.put(c.id,c);
                    }
                
                 /*c.current_task__c = 'QA and review';
                 c.QA_and_review_Date__c = system.today();
                 casesToUpdate.add(c); */   
                system.debug('Came into QA and review...');
                 DIA_case_History__c ch = new DIA_case_History__c();
                 ch.case__c = c.id;
                   ch.added_by__c = userinfo.getuserid();
                   ch.value__c = 'QA and review';
                   ch.type__c = 'Task';
                   caseHistoriesToInsert.add(ch);
            }
            boolean anyLeadQARejected = false;
            for(DIA_lead__c l: caseNleadMap.get(caseId)){
                if(l.status__c != 'QA Review Completed' && l.status__c != 'Cancelled'){
                    allLeadsAreQAReviewCompleted = false;    
                }
                if(l.status__c == 'QA Rejected'){
                        anyLeadQARejected = true;
                }
            }
             
            if(allLeadsAreQAReviewCompleted){
                	if(casesToUpdate.containskey(c.id)){
                        DIA_case__c existing = casesToUpdate.get(c.id);
                        existing.current_task__c = 'QA Review Completed';
                		existing.QA_and_review_Date__c = system.today();
                        casesToUpdate.put(existing.id,existing);
                    }else{
                        c.current_task__c = 'QA Review Completed';
                		c.QA_and_review_Date__c = system.today();
                        casesToUpdate.put(c.id,c);
                    }
                
                /*c.current_task__c = 'QA Review Completed';
                c.QA_and_review_Date__c = system.today();
                casesToUpdate.add(c); */   
                system.debug('Came into QA Review Completed...');
                 DIA_case_History__c ch = new DIA_case_History__c();
                 ch.case__c = c.id;
                   ch.added_by__c = userinfo.getuserid();
                   ch.value__c = 'QA Review Completed';
                   ch.type__c = 'Task';
                   caseHistoriesToInsert.add(ch);
            }
            if(anyLeadQARejected){
                //c.QA_Rejected_Lead_Exists__c = true;
                	if(casesToUpdate.containskey(c.id)){
                        DIA_case__c existing = casesToUpdate.get(c.id);
                        existing.QA_Rejected_Lead_Exists__c = true;
                        casesToUpdate.put(existing.id,existing);
                    }else{
                		c.QA_Rejected_Lead_Exists__c = true;
                        casesToUpdate.put(c.id,c);
                    }
                
                //if(!casesToUpdate.contains(c))
                //casesToUpdate.add(c);    
                system.debug('Came into anyLeadQARejected...');
            }else{
                //c.QA_Rejected_Lead_Exists__c = false;
                	if(casesToUpdate.containskey(c.id)){
                        DIA_case__c existing = casesToUpdate.get(c.id);
                        existing.QA_Rejected_Lead_Exists__c = false;
                        casesToUpdate.put(existing.id,existing);
                    }else{
                		c.QA_Rejected_Lead_Exists__c = false;
                        casesToUpdate.put(c.id,c);
                    }
                //if(!casesToUpdate.contains(c))
                //casesToUpdate.add(c); 
                system.debug('Came into QA_Rejected_Lead_Exists__c...');
            }
              
             
             
        }
        /*
        Map<Id,list<string>> caseIdNType = New Map<Id,list<string>>();
        for(DIA_lead__c l: trigger.new){
            if(l.Reason_for_Waiver__c != null && trigger.oldMap.get(l.id).Reason_for_Waiver__c == null){
                DIA_Waiver_Information__c wi = new DIA_Waiver_Information__c();
                wi.Case__c = l.case__c;
                wi.lead__c = l.id;
                wi.Waiver_Reason__c = l.Reason_for_Waiver__c;
                wi.Waiver_Flagged_Date__c = system.today();
                wi.Type__c = l.type__c;
                wi.Other_Reason__c = l.Other_Reason__c;
                wi.justification__c = l.waiver_extension_justification__c;
                if(!caseIdNType.containsKey(l.case__c)) caseIdNType.put(l.case__c,New list<string>());
                caseIdNType.get(l.case__c).add(l.type__c);
                WaiverInformationToCreate.add(wi);
            }
        }
        
        List<dia_case__c> cases = [select id from dia_case__c where Id IN: caseIdNType.keyset()];
        for(dia_case__c dCase : cases){
            list<string> types = caseIdNType.get(dCase.Id);
            if(types.contains('Waiver')){
                dCase.ISP_requested_Waiver__c = 'Yes';
            }
            if(types.contains('Extension')){
                dCase.ISP_requested_Extension__c = 'Yes';
            }
            updateCases.add(dCase);
        }*/
 
    }
    
    if(!caseHistoriesToInsert.isEmpty()){
        insert caseHistoriesToInsert;
    } 
    if(!WaiverInformationToCreate.isEmpty()){
        insert WaiverInformationToCreate;
    }
    if(!casesToUpdate.isEmpty()){
        system.debug(casesToUpdate.values());
        update casesToUpdate.values();
    }
    if(!updateCases.isEmpty()){
        update updateCases;
    }
}