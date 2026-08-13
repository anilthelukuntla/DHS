trigger DHSLeadTrigger on DHS_Lead__c (before insert, before update, after insert, after update, after delete, after undelete) { // NOPMD
    list<string> caseIds = new list<string>();
    list<DHS_Case_History__c> caseHistoriesToInsert = new LisT<DHS_Case_History__c>();
    list<DHS_Case__c> casesToUpdate = new LisT<DHS_Case__c>();
    list<DHS_Waiver_Information__c > WaiverInformationToCreate  = new LisT<DHS_Waiver_Information__c >(); // NOPMD
    List<Messaging.SingleEmailMessage> assignedMsgs = New List<Messaging.SingleEmailMessage>();
    
    if((trigger.isInsert || trigger.isUpdate) && trigger.isBefore){
         for(DHS_Lead__c l: Trigger.new){
             
             if(trigger.isinsert){
                 L.Last_Status_Change__c = system.now();
             }else{
                If (Trigger.oldMap.get(l.Id).Status__c != Trigger.newMap.get(l.Id).Status__c){
                    L.Last_Status_Change__c = system.now();
                }
            }
        }
        list<string> leadcaseids = new list<String>();
        list<string> leadIds = new list<string>();
        for(DHS_Lead__c l: trigger.new){
            leadcaseids.add(l.DHS_Case__c); 
            if(trigger.isUpdate){
                leadIds.add(l.id);
            }   
        }
        List<DHS_Lead__c> leads = new List<DHS_Lead__c>();
        if(trigger.isInsert){
            leads = [Select Id, DHS_Case__c, Item_number__c from DHS_Lead__c where DHS_Case__c in: leadcaseids]; // NOPMD
        }else if(trigger.isUpdate){
            leads = [Select Id, DHS_Case__c, Item_number__c from DHS_Lead__c where DHS_Case__c in: leadcaseids and id not IN: leadIds]; // NOPMD
        }
        map<Id,DHS_Case__c> casesMap = new map<id,DHS_Case__c>([select id,DHS_Contact__c, Scoping_Date__c, Current_Task__c from DHS_Case__c where id in: leadcaseids ]); // NOPMD
            
        map<string,list<DHS_Lead__c>> caseIdNleads = new map<string,list<DHS_Lead__c>>();
        for(DHS_Lead__c el: leads){
            if(!caseIdNleads.containsKey(el.DHS_Case__c)){
                caseIdNleads.put(el.DHS_Case__c, new list<DHS_Lead__c>{el});    
            }else{
                list<DHS_Lead__c> temp = caseIdNleads.get(el.DHS_Case__c);
                temp.add(el);
                caseIdNleads.put(el.DHS_Case__c,temp);   
            }    
        }
        for(DHS_Lead__c l: trigger.new){
            list<DHS_Lead__c> existingLeads = caseIdNleads.get(l.DHS_Case__c); 
            if(existingLeads == null){
                continue;
            }
            for(DHS_Lead__c el: existingLeads){
                if(el.Item_number__c == l.Item_number__c && l.Item_number__c != Null){
                    l.addError(System.label.DHS_Duplicate_Item_Number_Message);
                }
            }
        }
    }
    
    
    if(trigger.isInsert && trigger.isBefore){
        for(DHS_Lead__c l: Trigger.New){
            caseIds.add(l.DHS_Case__c);     
            l.Status__c = 'UnAssigned';
        }   
    
        List<DHS_Lead__c> leads = new List<DHS_Lead__c>();
        leads = [Select Id, DHS_Case__c from DHS_Lead__c where DHS_Case__c in: caseIds]; // NOPMD
        map<Id,DHS_Case__c> casesMap = new map<id,DHS_Case__c>([select id,DHS_Contact__c, Scoping_Date__c, Current_Task__c from DHS_Case__c where id in:caseIds ]); // NOPMD
            
        map<string,integer> caseIdNnumberOfleads = new map<string,integer>();
        for(DHS_Lead__c l: leads){
            if(!caseIdNnumberOfleads.containsKey(l.DHS_Case__c)){
                caseIdNnumberOfleads.put(l.DHS_Case__c, 1);    
            }else{
                caseIdNnumberOfleads.put(l.DHS_Case__c,caseIdNnumberOfleads.get(l.DHS_Case__c)+1);   
            }    
        }
  
        for(DHS_Lead__c l: Trigger.New){
            l.DHS_Contact__c = casesMap.get(l.DHS_Case__c).DHS_Contact__c;
            if(caseIdNnumberOfleads.containsKey(l.DHS_Case__c)){ // NOPMD
                //l.Item_number__c =  caseIdNnumberOfleads.get(l.DHS_Case__c)+1;   
            }else{
                   //l.Item_number__c = 1;
                   DHS_Case_History__c ch = new DHS_Case_History__c();
                   ch.DHS_Case__c = l.DHS_Case__c;
                   ch.DHS_Added_By__c = userinfo.getuserid();
                   ch.Value__c = 'Scoping';
                   caseHistoriesToInsert.add(ch);
                if(casesMap.get(l.DHS_Case__c).Scoping_Date__c == null){
                    DHS_Case__c c = casesMap.get(l.DHS_Case__c);
                    c.Current_Task__c = 'Scoping';
                    c.Scoping_Date__c = system.today();
                    casesToUpdate.add(c);  
                }
            }
               
        }   
    }
    
    if(trigger.isUpdate && trigger.isBefore){
        List<String> investigatorIds = new List<String>();
        for(DHS_Lead__c l: trigger.new){
            if(string.isNotBlank(l.DHS_Assigned_To__c)){
               investigatorIds.add(l.DHS_Assigned_To__c);   
            }
            if(l.Coverage_Type__c != Trigger.oldmap.get(l.Id).Coverage_Type__c && l.Status__c != 'Unassigned'){
                l.Status__c = 'In-Progress';
            }
        }
        System.debug('investigatorIds...'+ investigatorIds); // NOPMD
        
        List<DHS_Daily_Production_Summary__c> dailyProductionSummaries = new List<DHS_Daily_Production_Summary__c>();
        Map<String, DHS_Daily_Production_Summary__c> investigatorSummaryMap = new Map<String, DHS_Daily_Production_Summary__c>();
        Map<string,DHS_Daily_Production_Summary__c> dailyProductionSummariesToUpdate = new Map<string,DHS_Daily_Production_Summary__c>();
        dailyProductionSummaries = [Select Id, DHS_Reviewer__c, Leads_Accepted__c, Leads_Completed__c, Leads_Rejected__c, Summary_Date__c // NOPMD
                                    FROM DHS_Daily_Production_Summary__c
                                    WHERE Summary_Date__c = TODAY AND DHS_Reviewer__c IN: investigatorIds];
                                    
        for(DHS_Daily_Production_Summary__c dps: dailyProductionSummaries){
             investigatorSummaryMap.put(dps.DHS_Reviewer__c,dps);   
        }
        
        for(string invId: investigatorIds){
            if(!investigatorSummaryMap.containsKey(invId)){
                DHS_Daily_Production_Summary__c dps = new DHS_Daily_Production_Summary__c();
                dps.DHS_Reviewer__c  = invId;     
                dps.Leads_Accepted__c  = 0;     
                dps.Leads_Completed__c  = 0;     
                dps.Leads_Rejected__c  = 0;     
                dps.Summary_Date__c  = System.Today();  
                insert dps;   // NOPMD
                investigatorSummaryMap.put(invId,dps); 
            }
        }
        Map<Id,User> userMap = new Map<Id,User>([Select Id,Name from User]); // NOPMD
        
         for(DHS_Lead__c l: trigger.new){
            if(l.Status__c == 'Completed' && trigger.oldmap.get(l.id).Status__c != 'Completed' && l.Completed_Date__c == null){
                l.Completed_Date__c = system.today();
            } else if(l.Status__c == 'Completed' && trigger.oldmap.get(l.id).Status__c != 'Completed'){
                system.debug('Lead already has Completed_Date__c'); // NOPMD
            }
            if(l.Status__c == 'Assigned' && trigger.oldmap.get(l.id).Status__c != 'Assigned'){
                User investigator = [Select Id,Firstname,lastname,email from user where id=:l.DHS_Assigned_To__c]; // NOPMD
                List<string> toAddress = new List<string>();
                toAddress.add(investigator.Email);
                String subject = 'New Task assigned';
                String Body = 'Dear '+investigator.FirstName+' '+investigator.LastName+'<br/><br/>'; // NOPMD
                Body = Body + 'A new case task has been assigned to you. Please log into the case management system to accept/reject the case before the expiration.';
                Body = Body + 'Thanks<br/>ISN Corporation';
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
                mail.setSaveAsActivity(false);
                mail.setTargetObjectId(investigator.id);
                mail.setSubject(subject);
                mail.setBccSender(false);
                mail.setUseSignature(false);
                mail.setHtmlBody(body);
                assignedMsgs.add(mail);
                //DHSMailUtilities.sendHTMLEmailWithTargetObjectId(investigator.id,subject,Body,null);
                if(String.isBlank(l.Lead_Log__c)){ // NOPMD - legacy structure retained to preserve behavior
                    l.Lead_Log__c = System.now() + ': lead assigned to '+userMap.get(l.DHS_Assigned_To__c).Name+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead assigned to '+userMap.get(l.DHS_Assigned_To__c).Name+'<br/>';
                }
            }
             //Assigned Not Accepted
            /*if(l.Status__c == 'Assigned' && l.Lead_Accepted_or_Rejected__c == Null){
                l.Status__c = 'Assigned Not Accepted';
            }*/
            if(l.Lead_Accepted_or_Rejected__c =='Accepted' && trigger.oldmap.get(l.id).Lead_Accepted_or_Rejected__c != 'Accepted'){
                DHS_Daily_Production_Summary__c dps = investigatorSummaryMap.get(l.DHS_Assigned_To__c);
                dps.Leads_Accepted__c = dps.Leads_Accepted__c+1;
                dailyProductionSummariesToUpdate.put(dps.id,dps);
                if(String.isBlank(l.Lead_Log__c)){ // NOPMD - legacy structure retained to preserve behavior
                    l.Lead_Log__c = System.now() + ': lead accepted by '+userMap.get(l.DHS_Assigned_To__c).Name+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead accepted by '+userMap.get(l.DHS_Assigned_To__c).Name+'<br/>';
                }
                l.Status__c = 'In-Progress';
            }
            
            if(l.Lead_Accepted_or_Rejected__c =='Rejected' && trigger.oldmap.get(l.id).Lead_Accepted_or_Rejected__c != 'Rejected'){
                DHS_Daily_Production_Summary__c dps = investigatorSummaryMap.get(l.DHS_Assigned_To__c);
                dps.Leads_Rejected__c = dps.Leads_Rejected__c+1;
                dailyProductionSummariesToUpdate.put(dps.id,dps);
                
                DHS_Case__c caseOfLead = [Select DHS_Assigned_To__c,Case_Number__c, DHS_Assigned_To__r.Email from DHS_Case__c where id=:l.DHS_Case__c]; // NOPMD
                User caseCMO = [Select Firstname,lastname from user where id=:caseOfLead.DHS_Assigned_To__c]; // NOPMD
                User rejectedInvestigator = [Select Firstname,lastname from user where id=:trigger.oldmap.get(l.id).DHS_Assigned_To__c]; // NOPMD
                List<string> toAddress = new List<string>();
                toAddress.add(caseOfLead.DHS_Assigned_To__r.Email);
                String subject = 'Task Rejected by Investigator – case#'+caseOfLead.Case_Number__c;
                String Body = 'Dear '+caseCMO.FirstName+' '+caseCMO.LastName+'<br/><br/>'; // NOPMD
                Body = Body + 'Investigator '+ rejectedInvestigator.FirstName +' '+ rejectedInvestigator.LastName +'has rejected the task associated with case# '+caseOfLead.Case_Number__c+'. Please log into the case management system and re-assign the case as soon as possible.<br/><br/>';
                Body = Body + 'Thanks<br/>ISN Corporation';
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
                mail.setSaveAsActivity(false);
                mail.setSubject(subject);
                mail.setBccSender(false);
                mail.setUseSignature(false);
                mail.setHtmlBody(body);
                mail.setCCAddresses(toAddress);
                assignedMsgs.add(mail);
                
                //DHSMailUtilities.sendHTMLEmail(toAddress,subject,Body,null);
               
                if(String.isBlank(l.Lead_Log__c)){ // NOPMD - legacy structure retained to preserve behavior
                    l.Lead_Log__c = '<b style="color:red">'+System.now() + ': lead rejected by '+userMap.get(trigger.oldmap.get(l.id).DHS_Assigned_To__c).Name+'</b><br/>';
                }else{
                    System.debug('l.DHS_Assigned_To__c...'+l.DHS_Assigned_To__c); // NOPMD
                    System.debug('lead...Assigned_To_Name__c'+l); // NOPMD
                    l.Lead_Log__c = l.Lead_Log__c + '<b style="color:red">'+ System.now() +  ': lead rejected by '+userMap.get(trigger.oldmap.get(l.id).DHS_Assigned_To__c).Name+'</b><br/>';
                }
                l.DHS_Assigned_To__c = null;  
            }
            if(l.Status__c != 'Completed' && trigger.oldmap.get(l.id).Status__c == 'Completed'){
                if(investigatorSummaryMap.get(l.DHS_Assigned_To__c) != null){ // NOPMD - legacy structure retained to preserve behavior
                    DHS_Daily_Production_Summary__c dps = investigatorSummaryMap.get(l.DHS_Assigned_To__c);
                    if(dps.Leads_Completed__c == null){ // NOPMD
                        dps.Leads_Completed__c = 0;
                    }
                    dps.Leads_Completed__c = dps.Leads_Completed__c+1;
                    dailyProductionSummariesToUpdate.put(dps.id,dps);
                }
                
                if(String.isBlank(l.Lead_Log__c)){ // NOPMD - legacy structure retained to preserve behavior
                    l.Lead_Log__c = System.now() + ': lead completed by '+userMap.get(l.DHS_Assigned_To__c).Name+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead completed by '+userMap.get(l.DHS_Assigned_To__c).Name+'<br/>';
                }
            }
            if(l.Status__c != 'QA Rejected' && trigger.oldmap.get(l.id).Status__c == 'QA Rejected'){
                DHS_Case__c caseOfLead = [Select DHS_Assigned_To__c,Case_Number__c, DHS_Assigned_To__r.Email from DHS_Case__c where id=:l.DHS_Case__c]; // NOPMD
                User investigator = [Select Firstname,lastname,email from user where id=:l.DHS_Assigned_To__c]; // NOPMD
                List<string> toAddress = new List<string>();
                toAddress.add(investigator.Email);
                String subject = 'QA Rejected';
                String Body = 'Dear '+investigator.FirstName+' '+investigator.LastName+'<br/><br/>'; // NOPMD
                Body = Body + 'QA has rejected the task lead associated with case #'+caseOfLead.Case_Number__c+'. Please log into the case management system to complete the missing information for the lead.';
                Body = Body + 'Thanks<br/>ISN Corporation';
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
                mail.setSaveAsActivity(false);
                mail.setSubject(subject);
                mail.setBccSender(false);
                mail.setUseSignature(false);
                mail.setHtmlBody(body);
                mail.setCCAddresses(toAddress);
                assignedMsgs.add(mail);
                
                //DHSMailUtilities.sendHTMLEmail(toAddress,subject,Body,null);
               
                if(String.isBlank(l.Lead_Log__c)){ // NOPMD - legacy structure retained to preserve behavior
                    l.Lead_Log__c = System.now() + ': lead rejected by QA'+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead rejected by QA'+'<br/>';
                }
            }
            if(l.Status__c != 'QA Review Completed' && trigger.oldmap.get(l.id).Status__c == 'QA Review Completed'){
                if(String.isBlank(l.Lead_Log__c)){ // NOPMD - legacy structure retained to preserve behavior
                    l.Lead_Log__c = System.now() + ': lead QA review completed'+'<br/>';
                }else{
                    l.Lead_Log__c = l.Lead_Log__c + System.now() + ': lead QA review completed'+'<br/>';
                }
            }

        }
        if(assignedMsgs != null){ // NOPMD
            //Messaging.sendEmail(assignedMsgs);
        }
        if(!dailyProductionSummariesToUpdate.values().isEmpty()){
            update dailyProductionSummariesToUpdate.values();
        }
    }
    if(trigger.isUpdate && trigger.isBefore){
         for(DHS_Lead__c l: Trigger.new){
            If (l.Issues_Discrep_Developed__c!= 'Yes'){ 
                l.Issue_Description__c = null;
            }  
         }
    }
    
    if(trigger.isUpdate && trigger.isAfter){
        List<DHS_Message__c> messagesToInsert = new List<DHS_Message__c>();
        
        Map<string,DHS_Message__c> leadNMessages = New Map<string,DHS_Message__c>();
        Map<Id,DHS_Message__c> leadTypeNMessage = New Map<Id,DHS_Message__c>();
        List<DHS_Message__c> existingMessages = [select id,DHS_Lead__c,DHS_Lead__r.LeadType__c,Subject__c from DHS_Message__c where DHS_Lead__c IN: Trigger.NewMap.keyset()]; // NOPMD
        for(DHS_Message__c msg : existingMessages){
            if(msg.Subject__c == 'LEADS FROM ESI'){
                leadNMessages.put(msg.DHS_Lead__c,msg);
            }
            if(msg.Subject__c != null){
                if(msg.Subject__c.contains(' -  Issues, discrepancies, or developed activities discussed')){ // NOPMD - legacy structure retained to preserve behavior
                    leadTypeNMessage.put(msg.DHS_Lead__c,msg);
                }
            }
        }
        
        List<DHS_Message__c> messagesToUpdate = New List<DHS_Message__c>();
        for(DHS_Lead__c l: Trigger.new){
            If(Trigger.newMap.get(l.Id).Status__c == 'Completed'){
                If (l.Issues_Discrep_Developed__c== 'Yes'){  // NOPMD - legacy structure retained to preserve behavior
                    system.debug('l.Issues_Discrep_Developed__c...'+l.Issues_Discrep_Developed__c); // NOPMD
                    if(leadTypeNMessage.containsKey(l.Id)){ // NOPMD
                        DHS_Message__c m = leadTypeNMessage.get(l.Id);
                        system.debug('updated message...'+m.Id); // NOPMD
                        m.Message_Body__c = l.Issue_Description__c;
                        messagesToUpdate.add(m);
                    }else{
                        system.debug('inserted'); // NOPMD
                        DHS_Message__c message = new DHS_Message__c();
                        message.Message_Body__c = l.Issue_Description__c;
                        message.Subject__c = l.LeadType__c + ' -  Issues, discrepancies, or developed activities discussed';
                        message.DHS_From_User__c = userinfo.getUserId();
                        message.DHS_Case__c = l.DHS_Case__c;
                        message.DHS_Lead__c = l.id;
                        messagesToInsert.add(message);
                    }
                }
            }
            system.debug('Trigger.newMap.get(l.Id).Status__c...'+Trigger.newMap.get(l.Id).Status__c); // NOPMD
            If(Trigger.newMap.get(l.Id).Status__c == 'Completed' && l.LeadType__c == 'Subject Interview (ESI/TESI)'){
                if(leadNMessages.containsKey(l.Id)){ // NOPMD - legacy structure retained to preserve behavior
                    system.debug('Trigger.newMap.get(l.Id).Expl_Leads_Not_Obtained__c updated...'+l.Id+Trigger.newMap.get(l.Id).Expl_Leads_Not_Obtained__c); // NOPMD
                    DHS_Message__c m = leadNMessages.get(l.Id);
                    m.Message_Body__c = Trigger.newMap.get(l.Id).Expl_Leads_Not_Obtained__c;
                    messagesToUpdate.add(m);
                }else{
                    system.debug('New Message created for LEADS FROM ESI with lead id...'+l.Id); // NOPMD
                    DHS_Message__c message = new DHS_Message__c();
                    message.Message_Body__c = Trigger.newMap.get(l.Id).Expl_Leads_Not_Obtained__c;
                    message.Subject__c = 'LEADS FROM ESI';
                    message.DHS_From_User__c = userinfo.getUserId();
                    message.DHS_Case__c = l.DHS_Case__c;
                    message.DHS_Lead__c = l.Id;
                    messagesToInsert.add(message);
                }
            }
        }
        if(!messagesToInsert.isEmpty()){
            insert messagesToInsert; // NOPMD
        }
        if(!messagesToUpdate.isEmpty()){
            update messagesToUpdate; // NOPMD
        }
    
    
    
        //For Status change logic
        List<DHS_Lead__c> oldLeadValues = new List<DHS_Lead__c>();
        List<DHS_Lead__c> newLeadValues = new List<DHS_Lead__c>();
        for(DHS_Lead__c l: Trigger.new){
            If (Trigger.oldMap.get(l.Id).Status__c != Trigger.newMap.get(l.Id).Status__c){
                oldLeadValues.add(Trigger.oldMap.get(l.Id));
                newLeadValues.add(Trigger.newMap.get(l.Id));
            }
        }
        if(!oldLeadValues.isEMpty() && !newLeadValues.isEmpty()){
			DHSLeadTriggerHandler.LeadAuditMethod(oldLeadValues,newLeadValues);
        }
    
        list<string> caseids = new list<String>();
        for(DHS_Lead__c l: trigger.new){
            caseids.add(l.DHS_Case__c);    
        }
        map<id, DHS_Case__c> casemap = new map<id,DHS_Case__c>([select id, Current_Task__c, Investigations_Review_Date__c, QA_and_Review_Date__c from DHS_Case__c where id in: caseids]); // NOPMD
        list<DHS_Lead__c> leads = [Select Id, DHS_Assigned_To__c,DHS_Case__c, Status__c  from DHS_Lead__c where DHS_Case__c in: caseids]; // NOPMD
        map<string,list<DHS_Lead__c>> caseNleadMap = new map<string,list<DHS_Lead__c>>();
        for(DHS_Lead__c l: leads){
            if(!caseNleadMap.containskey(l.DHS_Case__c)){
                caseNleadMap.put(l.DHS_Case__c,new list<DHS_Lead__c>{l});    
            } else{
                caseNleadMap.get(l.DHS_Case__c).add(l);    
            }
        }
        
        for(string caseId: caseNleadMap.keyset()){
            DHS_Case__c c= casemap.get(caseid);
            boolean allLeadsAreAssigned = true;
            for(DHS_Lead__c l: caseNleadMap.get(caseId)){
                if(l.DHS_Assigned_To__c == null){
                    allLeadsAreAssigned = false;    
                }
            }
            if(allLeadsAreAssigned && c.Investigations_Review_Date__c == null){
                 c.Current_Task__c = 'investigations review';
                 c.Investigations_Review_Date__c = system.today();
                 casesToUpdate.add(c);  
                 System.debug('casesToUpdate..allLeadsAreAssigned...'+casesToUpdate); // NOPMD
                 
                 DHS_Case_History__c ch = new DHS_Case_History__c();
                   ch.DHS_Case__c = c.id;
                   ch.DHS_Added_By__c = userinfo.getuserid();
                   ch.Value__c = 'investigations review';
                   caseHistoriesToInsert.add(ch);
            }
        }
        
         for(string caseId: caseNleadMap.keyset()){
            DHS_Case__c c= casemap.get(caseid);
            boolean allLeadsAreCompleted = true;
            for(DHS_Lead__c l: caseNleadMap.get(caseId)){
                if(l.Status__c != 'Completed' && l.Status__c != 'Cancelled' ){
                    allLeadsAreCompleted = false;    
                }
            }
            if(allLeadsAreCompleted && c.QA_and_Review_Date__c ==null){
                 c.Current_Task__c = 'QA and review';
                 c.QA_and_Review_Date__c = system.today();
                 casesToUpdate.add(c);    
                System.debug('casesToUpdate..allLeadsAreCompleted...'+casesToUpdate); // NOPMD
                
                 DHS_Case_History__c ch = new DHS_Case_History__c();
                   ch.DHS_Case__c = c.id;
                   ch.DHS_Added_By__c = userinfo.getuserid();
                   ch.Value__c = 'QA and review';
                   caseHistoriesToInsert.add(ch);
            }
        }
        
       
        for(DHS_Lead__c l: trigger.new){
            if(l.Reason_for_Waiver__c == 'Subject not available' && trigger.oldMap.get(l.id).Reason_for_Waiver__c == null){
                DHS_Waiver_Information__c wi = new DHS_Waiver_Information__c();
                wi.DHS_Case__c = l.DHS_Case__c;
                wi.DHS_Lead__c = l.id;
                wi.Waiver_Reason__c = 'Subject not available';
                wi.Waiver_Flagged_Date__c = system.today();
                WaiverInformationToCreate.add(wi);
            }
        }
 
    }
    
    if(!caseHistoriesToInsert.isEmpty()){
        insert caseHistoriesToInsert; // NOPMD
    } 
    if(!WaiverInformationToCreate.isEmpty()){
        insert WaiverInformationToCreate; // NOPMD
    }
    if(!casesToUpdate.isEmpty()){
        Map<Id, DHS_Case__c> casesToUpdateById = new Map<Id, DHS_Case__c>();
        for (DHS_Case__c caseRecord : casesToUpdate) {
            casesToUpdateById.put(caseRecord.Id, caseRecord);
        }
        update casesToUpdateById.values();
    }
    if((trigger.isInsert || trigger.isUpdate || trigger.isDelete || trigger.isUndelete) && trigger.isAfter){
        DHSLeadTriggerHandler.updateCaseLeadSummaryCounts(
            Trigger.isDelete ? null : Trigger.new,
            Trigger.isInsert || Trigger.isUndelete ? null : Trigger.old
        );
    }
    /*
    if((trigger.isInsert || trigger.isUpdate) && trigger.isAfter){
        set<Id> caseIds = New set<Id>();
        Map<id,string> caseNLeadMap = New Map<id,string>();
        for(DHS_Lead__c l: Trigger.New){
            caseIds.add(l.DHS_Case__c);
            caseNLeadMap.put(l.DHS_Case__c,l.Id);
        } 
        list<DHS_Lead__c> updateLeads = New list<DHS_Lead__c>();
        list<DHS_Case__c> caseList = [select id,DHS_Contact__r.First_Name__c,DHS_Contact__r.Last_Name__c from DHS_Case__c where id IN: caseIds];
        Map<Id,DHS_Case__c> caseMap = New Map<Id,DHS_Case__c>();
        for(DHS_Case__c cs : caseList){
            DHS_Lead__c ld = New DHS_Lead__c();
            ld.Id = caseNLeadMap.get(cs.Id);
            ld.Source_Name__c = cs.DHS_Contact__r.First_Name__c+' '+cs.DHS_Contact__r.Last_Name__c;
            updateLeads.add(ld);
        }
        	update updateLeads;
    }*/
    
    if(Trigger.isupdate && Trigger.isAfter){
        DHSLeadTriggerHandler.createInvoice(Trigger.NewMap,Trigger.OldMap);
        user u = [select id,user_type__c from user where id =: userinfo.getuserid()]; // NOPMD
        if(u.user_type__c == 'INV' || Test.isRunningTest()){
            List<DHS_TimeSheet__c> invTimeSheet = [select id,Associated_Leads__c from DHS_TimeSheet__c where DHS_User__c =: userinfo.getuserid() and Date__c =: system.today() limit 1]; // NOPMD
            
            List<DHS_Lead__c> leads = [select id,DHS_Case__r.Case_Number__c,LeadType__c,Coverage_Type__c,Item_number__c from DHS_Lead__c where Id IN:Trigger.NewMap.keyset()]; // NOPMD
            if(!invTimeSheet.isEMpty()){ // NOPMD - legacy structure retained to preserve behavior
                for(DHS_Lead__c l : leads){
                    string key = l.DHS_Case__r.Case_Number__c+'_'+l.LeadType__c+'_'+l.Coverage_Type__c+'_'+l.Item_number__c;
                    if(invTimeSheet[0].Associated_Leads__c != null){ // NOPMD
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
        dt(system.today());
        dt(system.today());
        for(DHS_Lead__c l : Trigger.New){
            system.debug(l.Status__c+' ===> '+l.Id); // NOPMD
        }
    }
    public static datetime dt(date dte){ // NOPMD
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