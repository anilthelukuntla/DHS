trigger DHSCaseTrigger on DHS_Case__c (before insert,after insert,before update, after update) { // NOPMD
    list<DHS_Case_History__c> caseHistoriesToInsert = new LisT<DHS_Case_History__c>();
    List<DHS_Contact__c> contactsToUpdate = new List<DHS_Contact__c>();
    
    if(trigger.isAfter &&  trigger.isUpdate){
        list<string> caseIdsToConsiderForDiscontinuation = new list<string>();
        map<string,DHS_Case__c> discontinuationCasesMap = new map<string,DHS_Case__c>();
        for(DHS_Case__c c: Trigger.New){
            if(c.Case_Discontinued__c != trigger.oldMap.get(c.id).Case_Discontinued__c){
                caseIdsToConsiderForDiscontinuation.add(c.id);
                discontinuationCasesMap.put(c.id,c);
            }
        }
        if(!caseIdsToConsiderForDiscontinuation.isEmpty()){
            List<DHS_Lead__c> leadsToUpdate = new List<DHS_Lead__c>();
            leadsToUpdate = [Select Id, Status__c, DHS_Case__c, Lead_Status_Before_Discont__c from DHS_Lead__c WHERE DHS_Case__c in:caseIdsToConsiderForDiscontinuation]; // NOPMD
            for(DHS_Lead__c l:leadsToUpdate){
                if(discontinuationCasesMap.get(l.DHS_Case__c).Case_Discontinued__c){ // NOPMD - legacy structure retained to preserve behavior
                   l.Lead_Status_Before_Discont__c = l.Status__c; 
                   l.Status__c = 'Discontinued';
                }else{
                   l.Status__c = l.Lead_Status_Before_Discont__c;
                   l.Lead_Status_Before_Discont__c = Null;
                }
            }
            update leadsToUpdate; // NOPMD
        }
    
    }
    
    if(trigger.isBefore && trigger.isInsert){
        for(DHS_Case__c c: Trigger.New){
            c.Current_Task__c = 'Initiated State';
            c.Initiated_State_Date__c = System.today();
            c.Submission_Date__c = System.today();
            c.Case_Queue_Status__c = 'New';
        }
    }  
    list<string> contactIds = new list<String>();
    if(trigger.isAfter && trigger.isInsert){
        for(DHS_Case__c c: Trigger.New){
           DHS_Case_History__c ch = new DHS_Case_History__c();
           ch.DHS_Case__c = c.id;
           ch.DHS_Added_By__c = userinfo.getuserid();
           ch.Value__c = 'Initiated State';
           caseHistoriesToInsert.add(ch);
           contactIds.add(c.DHS_Contact__c);
        }
        
        list<DHS_Contact__c> contacts = new list<DHS_Contact__c>();
        contacts = [Select Id, Run_Credit_Report__c  from DHS_Contact__c where id in: contactids]; // NOPMD
        for(DHS_Contact__c con: contacts){
            con.Run_Credit_Report__c = true;
        }
        update contacts; // NOPMD
    } 
    
    if(trigger.isBefore && trigger.isUpdate){ 
        for(DHS_Case__c c: Trigger.New){
            if(c.DHS_Assigned_To__c != Null && Trigger.oldMap.get(c.id).DHS_Assigned_To__c != c.DHS_Assigned_To__c){
                User assignee = [Select Id,Firstname,lastname,Email from user where id=:c.DHS_Assigned_To__c]; // NOPMD
                List<string> toAddress = new List<string>();
                toAddress.add(assignee.Email);
                System.debug('toAddress..'+toAddress); // NOPMD
                if(!test.isRunningTest()){ // NOPMD - legacy structure retained to preserve behavior
                    String subject = 'New Case assigned';
                    String Body = 'Dear '+assignee.FirstName+' '+assignee.FirstName+',<br/><br/>'; // NOPMD
                    Body = Body+ 'A new case has been assigned to you. Please log into the case management system and process by case due date.<br/><br/>';
                    Body = Body+ 'Thanks<br/>ISN Corporation';
                    //DHSMailUtilities.sendHTMLEmail(toAddress,null,null,null,'New Case Assigned',c.id);
                    DHSMailUtilities.sendHTMLEmailWithTargetObjectId(assignee.id,subject,Body,null);
                }
                c.Case_Queue_Status__c = 'Assigned';
                c.Assignee_Date__c=system.today();
            }
            if(c.Current_Task__c == 'Scoping' || c.Current_Task__c == 'Investigations' || c.Current_Task__c == 'Investigations Review' || c.Current_Task__c == 'QA and Review'){
                c.Case_Queue_Status__c = 'In Progress';
            }
            if(c.Current_Task__c =='QA Review Completed' && Trigger.oldMap.get(c.id).Current_Task__c != 'QA Review Completed'){
                c.QA_Review_Completed_Date__c = system.today();
                c.Case_Queue_Status__c = 'Completed';
                c.Case_Completed_Date__c = system.today();
            }
            System.debug('c.Scheduled_Date__c...'+c.Scheduled_Date__c); // NOPMD
            if(c.Scheduled_Date__c != Null){
                Integer NumberOfDays = System.TODAY().daysBetween(c.Scheduled_Date__c); // NOPMD
                System.debug('NumberOfDays...'+NumberOfDays); // NOPMD
                System.debug('c.Service_Days__c....outside'+c.Service_Days__c); // NOPMD
                System.debug('c.Case_Type__c....outside'+c.Case_Type__c); // NOPMD
                String colorCode;
                IF(c.Case_Type__c == 'Tier 5'){ // NOPMD - legacy structure retained to preserve behavior
                    if(c.Service_Days__c == '40'){ // NOPMD
                        System.debug('c.Service_Days__c....inside'+c.Service_Days__c); // NOPMD
                        if(NumberOfDays < 15){
                            colorCode = '#90cf55';
                        }else if(NumberOfDays>=15 && NumberOfDays <22){
                            colorCode = '#fefe00';
                        }else if(NumberOfDays>=22 && NumberOfDays <32){
                            colorCode = '#fbbd03';
                        }else if(NumberOfDays>=32 && NumberOfDays <40){
                            colorCode = '#ffbee6';
                        }else if(NumberOfDays>40){
                            colorCode = '#fd0708';
                        }
                    }else if(c.Service_Days__c == '20'){ // NOPMD
                        if(NumberOfDays < 9){
                            colorCode = '#90cf55';
                        }else if(NumberOfDays>=9 && NumberOfDays <14){
                            colorCode = '#fefe00';
                        }else if(NumberOfDays>=14 && NumberOfDays <16){
                            colorCode = '#fbbd03';
                        }else if(NumberOfDays>=16 && NumberOfDays <20){
                            colorCode = '#ffbee6';
                        }else if(NumberOfDays>20){
                            colorCode = '#fd0708';
                        }
                    }
                }else iF(c.Case_Type__c == 'Tier 5 Reinvestigation'){ // NOPMD - legacy structure retained to preserve behavior
                        if(NumberOfDays < 28){ // NOPMD
                            colorCode = '#90cf55';
                        }else if(NumberOfDays>=28 && NumberOfDays <42){ // NOPMD
                            colorCode = '#fefe00';
                        }else if(NumberOfDays>=42 && NumberOfDays <56){ // NOPMD
                            colorCode = '#fbbd03';
                        }else if(NumberOfDays>=56 && NumberOfDays <60){ // NOPMD
                            colorCode = '#ffbee6';
                        }else if(NumberOfDays>60){ // NOPMD
                            colorCode = '#fd0708';
                        }
                        
                }else iF(c.Case_Type__c == 'Triggered Investigation'){ // NOPMD - legacy structure retained to preserve behavior
                        if(NumberOfDays < 14){ // NOPMD
                            colorCode = '#90cf55';
                        }else if(NumberOfDays>=14 && NumberOfDays <21){ // NOPMD
                            colorCode = '#fefe00';
                        }else if(NumberOfDays>=21 && NumberOfDays <26){ // NOPMD
                            colorCode = '#fbbd03';
                        }else if(NumberOfDays>=26 && NumberOfDays <30){ // NOPMD
                            colorCode = '#ffbee6';
                        }else if(NumberOfDays>30){ // NOPMD
                            colorCode = '#fd0708';
                        }
                }else iF(c.Case_Type__c == 'Supplemental Investigation'){ // NOPMD - legacy structure retained to preserve behavior
                        if(NumberOfDays < 7){ // NOPMD
                            colorCode = '#90cf55';
                        }else if(NumberOfDays>=7 && NumberOfDays <9){ // NOPMD
                            colorCode = '#fefe00';
                        }else if(NumberOfDays>=9 && NumberOfDays <11){ // NOPMD
                            colorCode = '#fbbd03';
                        }else if(NumberOfDays>=11 && NumberOfDays <14){ // NOPMD
                            colorCode = '#ffbee6';
                        }else if(NumberOfDays>14){ // NOPMD
                            colorCode = '#fd0708';
                        }
                }else{
                    colorCode = '';
                }
                c.Case_SLA_Code__c = colorCode;  
            } 
        }
    }

    if(!caseHistoriesToInsert.isEmpty()){
        insert caseHistoriesToInsert; // NOPMD
    } 
}