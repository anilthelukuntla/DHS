trigger DIACaseTrigger on DIA_Case__c (before insert,after insert,before update, after update) {
    list<DIA_Case_History__c> caseHistoriesToInsert = new LisT<DIA_Case_History__c>();
    List<DIA_contact__c> contactsToUpdate = new List<DIA_contact__c>();
    
    if(trigger.isAfter &&  trigger.isUpdate){
        list<string> caseIdsToConsiderForDiscontinuation = new list<string>();
        map<string,DIA_case__c> discontinuationCasesMap = new map<string,DIA_case__c>();
        for(DIA_Case__c c: Trigger.New){
            if(c.case_discontinued__c != trigger.oldMap.get(c.id).case_discontinued__c){
                caseIdsToConsiderForDiscontinuation.add(c.id);
                discontinuationCasesMap.put(c.id,c);
            }
        }
        if(!caseIdsToConsiderForDiscontinuation.isEmpty()){
            List<DIA_lead__c> leadsToUpdate = new List<DIA_lead__c>();
            leadsToUpdate = [Select Id, Status__c, Case__c, Lead_Status_Before_Discontinuation__c from DIA_lead__c WHERE case__c in:caseIdsToConsiderForDiscontinuation];
            for(DIA_lead__c l:leadsToUpdate){
                if(discontinuationCasesMap.get(l.case__c).case_discontinued__c){
                   l.Lead_Status_Before_Discontinuation__c = l.status__c; 
                   l.status__c = 'Discontinued';
                }else{
                   l.status__c = l.Lead_Status_Before_Discontinuation__c;
                   l.Lead_Status_Before_Discontinuation__c = Null;
                }
            }
            system.debug(leadsToUpdate.size());
            update leadsToUpdate;
        }
    
    }
    
    if(trigger.isBefore && trigger.isInsert){
        for(DIA_Case__c c: Trigger.New){
            c.Current_Task__c = 'Initiated State';
            c.Initiated_State_Date__c = System.today();
            c.Submission_Date__c = System.today();
            c.case_queue_status__c = 'New';
        }
    }  
    list<string> contactIds = new list<String>();
    if(trigger.isAfter && trigger.isInsert){
        for(DIA_Case__c c: Trigger.New){
            DIA_case_History__c ch = new DIA_case_History__c();
           ch.case__c = c.id;
           ch.added_by__c = userinfo.getuserid();
           ch.value__c = 'Initiated State';
           ch.type__c = 'Task';
           caseHistoriesToInsert.add(ch);
           contactIds.add(c.contact__c);
        }
        
        list<DIA_contact__c> contacts = new list<DIA_contact__c>();
        contacts = [Select Id, Run_Credit_Report__c  from DIA_contact__c where id in: contactids];
        for(DIA_contact__c con: contacts){
            con.Run_Credit_Report__c = true;
        }
        update contacts;
    } 
    
    if(trigger.isBefore && trigger.isUpdate){ 
        for(DIA_Case__c c: Trigger.New){
            if(c.case_discontinued__c == true && trigger.oldMap.get(c.id).case_discontinued__c != true){
                c.Status__c = 'Canceled';
            }
            if(c.Assigned_to__c != Null && Trigger.oldMap.get(c.id).Assigned_to__c != c.Assigned_to__c){
                User assignee = [Select Firstname,lastname,Email from user where id=:c.Assigned_to__c];
                List<string> toAddress = new List<string>();
                toAddress.add(assignee.Email);
                System.debug('toAddress..'+toAddress);
                if(!test.isRunningTest()){
                    String subject = 'New Case assigned';
                    String Body = 'Dear '+assignee.FirstName+' '+assignee.FirstName+',<br/><br/>';
                    Body = Body+ 'A new case has been assigned to you by '+userInfo.getLastName()+' '+userInfo.getFirstName()+'. Please log into the case management system and process by case due date.<br/><br/>';
                    Body = Body+ 'Thanks<br/>ISN Corporation';
                    //MailUtilities.sendHTMLEmail(toAddress,null,null,null,'New Case Assigned',c.id);
                    //MailUtilities.sendHTMLEmail(toAddress,subject,Body,null);
                    MailUtilities.sendBIEmail(subject,Body,toAddress,null,null);
                }
                c.case_queue_status__c = 'Assigned';
                c.Assignee_Date__c=system.today();
            }
            if(c.current_task__c =='Validate Transmission' ){
                //yellow
                c.Case_SLA_Code__c = '#ffc107';
            }
            System.debug('c.current_task__c...'+c.current_task__c);
            if(c.current_task__c == 'Scoping' || c.current_task__c == 'Investigations' || c.current_task__c == 'Investigations Review' || c.current_task__c == 'QA and Review'){
                c.case_queue_status__c = 'In Progress';
                if(c.current_task__c == 'Scoping'){
                  //blue
                  c.Case_SLA_Code__c = '#1e90ff'; 
                } 
                if(c.current_task__c == 'Investigations'){
                	//pink
                	c.Case_SLA_Code__c = '#ffb6c1';    
                }
                if(c.current_task__c == 'Investigations Review'){
                	//aqua 
                	c.Case_SLA_Code__c = '#00ffff';  
                }
                if(c.current_task__c == 'QA and Review'){
                	//purple
                	c.Case_SLA_Code__c = '#9370db';   
                }
            }
            if(c.QA_Rejected_Lead_Exists__c){
                //Red
                c.Case_SLA_Code__c = '#f94449';    
            }
            if(c.current_task__c =='QA Review Completed'){
                    //green
               
                c.Case_SLA_Code__c   = '#28a745';
            }
             System.debug('c.Case_SLA_Code__c...'+c.Case_SLA_Code__c);
            if(c.current_task__c =='QA Review Completed' && Trigger.oldMap.get(c.id).current_task__c != 'QA Review Completed'){
                c.QA_Review_Completed_Date__c = system.today();
                c.case_queue_status__c = 'Completed';
            }
            if((c.Status__c =='Canceled' && Trigger.oldMap.get(c.id).Status__c != 'Canceled') || (c.Status__c =='Delivered canceled' && Trigger.oldMap.get(c.id).Status__c != 'Delivered canceled')){
                c.Case_Cancellation_Date__c = system.today();
                c.Closed_Date__c = system.today();
            }
            if((c.Status__c !='Canceled' && Trigger.oldMap.get(c.id).Status__c == 'Canceled') || (c.Status__c !='Delivered canceled' && Trigger.oldMap.get(c.id).Status__c == 'Delivered canceled')){
                c.Case_Cancellation_Date__c = null;
                c.Closed_Date__c = null;
            }
            if(c.Status__c =='Delivered' && Trigger.oldMap.get(c.id).Status__c != 'Delivered'){
                c.case_completed_date__c = system.today();
				c.closed_date__c = system.today();
            }
            if(c.Status__c !='Delivered' && Trigger.oldMap.get(c.id).Status__c == 'Delivered'){
                c.case_completed_date__c = null;
				c.closed_date__c = null;
            }
            System.debug('c.Scheduled_Date__c...'+c.Scheduled_Date__c);
            /*if(c.Scheduled_Date__c != Null){
                Integer NumberOfDays = System.TODAY().daysBetween(c.Scheduled_Date__c);
                System.debug('NumberOfDays...'+NumberOfDays);
                System.debug('c.Service_Days__c....outside'+c.Service_Days__c);
                System.debug('c.Case_Type__c....outside'+c.Case_Type__c);
                String colorCode;
                IF(c.Case_Type__c == 'Tier 5'){
                    if(c.Service_Days__c == '40'){
                        System.debug('c.Service_Days__c....inside'+c.Service_Days__c);
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
                    }else if(c.Service_Days__c == '20'){
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
                }else iF(c.Case_Type__c == 'Tier 5 Reinvestigation'){
                        if(NumberOfDays < 28){
                            colorCode = '#90cf55';
                        }else if(NumberOfDays>=28 && NumberOfDays <42){
                            colorCode = '#fefe00';
                        }else if(NumberOfDays>=42 && NumberOfDays <56){
                            colorCode = '#fbbd03';
                        }else if(NumberOfDays>=56 && NumberOfDays <60){
                            colorCode = '#ffbee6';
                        }else if(NumberOfDays>60){
                            colorCode = '#fd0708';
                        }
                        
                }else iF(c.Case_Type__c == 'Triggered Investigation'){
                        if(NumberOfDays < 14){
                            colorCode = '#90cf55';
                        }else if(NumberOfDays>=14 && NumberOfDays <21){
                            colorCode = '#fefe00';
                        }else if(NumberOfDays>=21 && NumberOfDays <26){
                            colorCode = '#fbbd03';
                        }else if(NumberOfDays>=26 && NumberOfDays <30){
                            colorCode = '#ffbee6';
                        }else if(NumberOfDays>30){
                            colorCode = '#fd0708';
                        }
                }else iF(c.Case_Type__c == 'Supplemental Investigation'){
                        if(NumberOfDays < 7){
                            colorCode = '#90cf55';
                        }else if(NumberOfDays>=7 && NumberOfDays <9){
                            colorCode = '#fefe00';
                        }else if(NumberOfDays>=9 && NumberOfDays <11){
                            colorCode = '#fbbd03';
                        }else if(NumberOfDays>=11 && NumberOfDays <14){
                            colorCode = '#ffbee6';
                        }else if(NumberOfDays>14){
                            colorCode = '#fd0708';
                        }
                }else{
                    colorCode = '';
                }
                c.Case_SLA_Code__c = colorCode;  
            }*/ 
        }
    }

    if(!caseHistoriesToInsert.isEmpty()){
        insert caseHistoriesToInsert;
    } 
}