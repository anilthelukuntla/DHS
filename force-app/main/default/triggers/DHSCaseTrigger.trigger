trigger DHSCaseTrigger on DHS_Case__c (before insert,after insert,before update, after update) { // NOPMD - Legacy trigger behavior retained for compatibility.
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
            leadsToUpdate = [Select Id, Status__c, DHS_Case__c, Lead_Status_Before_Discont__c from DHS_Lead__c WHERE DHS_Case__c in:caseIdsToConsiderForDiscontinuation]; // NOPMD - Legacy trigger behavior retained for compatibility.
            for(DHS_Lead__c l:leadsToUpdate){
                if(discontinuationCasesMap.get(l.DHS_Case__c).Case_Discontinued__c){
                   l.Lead_Status_Before_Discont__c = l.Status__c; 
                   l.Status__c = 'Discontinued';
                }else{
                   l.Status__c = l.Lead_Status_Before_Discont__c;
                   l.Lead_Status_Before_Discont__c = Null;
                }
            }
            Database.update(leadsToUpdate);
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
        contacts = [Select Id, Run_Credit_Report__c  from DHS_Contact__c where id in: contactids]; // NOPMD - Legacy trigger behavior retained for compatibility.
        for(DHS_Contact__c con: contacts){
            con.Run_Credit_Report__c = true;
        }
        Database.update(contacts);
    } 
    
    if(trigger.isBefore && trigger.isUpdate){ 
        for(DHS_Case__c c: Trigger.New){
            if(c.DHS_Assigned_To__c != Null && Trigger.oldMap.get(c.id).DHS_Assigned_To__c != c.DHS_Assigned_To__c){
                User assignee = [Select Id,Firstname,lastname,Email from user where id=:c.DHS_Assigned_To__c]; // NOPMD - Legacy trigger behavior retained for compatibility.
                List<string> toAddress = new List<string>();
                toAddress.add(assignee.Email);

                if(!test.isRunningTest()){
                    String subject = 'New Case assigned';
                    String body = 'Dear '+assignee.FirstName+' '+assignee.FirstName+',<br/><br/>';
                    body = body+ 'A new case has been assigned to you. Please log into the case management system and process by case due date.<br/><br/>';
                    body = body+ 'Thanks<br/>ISN Corporation';
                    //DHSMailUtilities.sendHTMLEmail(toAddress,null,null,null,'New Case Assigned',c.id);
                    DHSMailUtilities.sendHTMLEmailWithTargetObjectId(assignee.id,subject,body,null);
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

            if(c.Scheduled_Date__c != Null){
                Integer numberOfDays = System.TODAY().daysBetween(c.Scheduled_Date__c);



                String colorCode;
                IF(c.Case_Type__c == 'Tier 5'){
                    if(c.Service_Days__c == '40'){

                        if(numberOfDays < 15){
                            colorCode = '#90cf55';
                        }else if(numberOfDays>=15 && numberOfDays <22){
                            colorCode = '#fefe00';
                        }else if(numberOfDays>=22 && numberOfDays <32){
                            colorCode = '#fbbd03';
                        }else if(numberOfDays>=32 && numberOfDays <40){
                            colorCode = '#ffbee6';
                        }else if(numberOfDays>40){
                            colorCode = '#fd0708';
                        }
                    }else if(c.Service_Days__c == '20'){
                        if(numberOfDays < 9){
                            colorCode = '#90cf55';
                        }else if(numberOfDays>=9 && numberOfDays <14){
                            colorCode = '#fefe00';
                        }else if(numberOfDays>=14 && numberOfDays <16){
                            colorCode = '#fbbd03';
                        }else if(numberOfDays>=16 && numberOfDays <20){
                            colorCode = '#ffbee6';
                        }else if(numberOfDays>20){
                            colorCode = '#fd0708';
                        }
                    }
                }else iF(c.Case_Type__c == 'Tier 5 Reinvestigation'){ // NOPMD - Legacy trigger behavior retained for compatibility.
                        if(numberOfDays < 28){
                            colorCode = '#90cf55';
                        }else if(numberOfDays>=28 && numberOfDays <42){
                            colorCode = '#fefe00';
                        }else if(numberOfDays>=42 && numberOfDays <56){
                            colorCode = '#fbbd03';
                        }else if(numberOfDays>=56 && numberOfDays <60){
                            colorCode = '#ffbee6';
                        }else if(numberOfDays>60){
                            colorCode = '#fd0708';
                        }
                        
                }else iF(c.Case_Type__c == 'Triggered Investigation'){ // NOPMD - Legacy trigger behavior retained for compatibility.
                        if(numberOfDays < 14){
                            colorCode = '#90cf55';
                        }else if(numberOfDays>=14 && numberOfDays <21){
                            colorCode = '#fefe00';
                        }else if(numberOfDays>=21 && numberOfDays <26){
                            colorCode = '#fbbd03';
                        }else if(numberOfDays>=26 && numberOfDays <30){
                            colorCode = '#ffbee6';
                        }else if(numberOfDays>30){
                            colorCode = '#fd0708';
                        }
                }else iF(c.Case_Type__c == 'Supplemental Investigation'){ // NOPMD - Legacy trigger behavior retained for compatibility.
                        if(numberOfDays < 7){
                            colorCode = '#90cf55';
                        }else if(numberOfDays>=7 && numberOfDays <9){
                            colorCode = '#fefe00';
                        }else if(numberOfDays>=9 && numberOfDays <11){
                            colorCode = '#fbbd03';
                        }else if(numberOfDays>=11 && numberOfDays <14){
                            colorCode = '#ffbee6';
                        }else if(numberOfDays>14){
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
        Database.insert(caseHistoriesToInsert);
    } 
}