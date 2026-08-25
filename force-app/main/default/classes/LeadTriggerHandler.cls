Public with sharing Class LeadTriggerHandler {
    public static void LeadAuditMethod(List<Lead__c> leadOldIds , List<Lead__c> LeadNewIds){
        List< Lead_Status_History__c > LSHList = New List< Lead_Status_History__c >();

        try
        {
             lisT<string> newLeadIds = new list<String>();
             For(Lead__c LN : LeadNewIds){
                 newLeadIds.add(ln.id);
             }
            list<Lead_Status_History__c> statusHistories = new list<Lead_Status_History__c>();
            statusHistories = [Select Id,Completed_By__c,lead__c FROM Lead_Status_History__c WHERE lead__c=:newLeadIds WITH SECURITY_ENFORCED order by createddate desc];
            map<string,list<Lead_Status_History__c>> leadNstatushistorymap = new map<string,list<Lead_Status_History__c>>();
            for(Lead_Status_History__c temp: statusHistories){
                if(!leadNstatushistorymap.containsKey(temp.lead__c)){
                    leadNstatushistorymap.put((string)temp.lead__c,new list<Lead_Status_History__c>{temp});
                }else{
                    list<Lead_Status_History__c> temp2= leadNstatushistorymap.get(temp.lead__c);
                    temp2.add(temp);
                    leadNstatushistorymap.put((string)temp.lead__c,temp2);
                }
            }
                        
            For(Lead__c LO : leadOldIds)
            {
                For(Lead__c LN : LeadNewIds)
                {
                    IF((LO.Id == LN.Id) && (LO.Last_Status_Change__c != LN.Last_Status_Change__c))
                    {
                        list<Lead_Status_History__c> temp = new list<Lead_Status_History__c>();
                        if(leadNstatushistorymap.containsKey(ln.id)){
                            temp = leadNstatushistorymap.get(ln.id);
                        }
                        Lead_Status_History__c CSHVal = New Lead_Status_History__c();
                        if(!temp.isEmpty()){
                            CSHVal.initiated_By__c = temp[0].Completed_By__c;    
                        }else{
                            CSHVal.initiated_By__c = ln.createdbyid;
                        }
                        CSHVal.Completed_By__c = userinfo.getuserid();
                        CSHVal.Lead__C = LO.Id;
                        CSHVal.Status_Name__c = LO.Status__C;
                        CSHVal.Status_Start_Time__c = LO.Last_Status_Change__c;
                        CSHVal.Status_End_Time__c = LN.Last_Status_Change__c;
                        Long dt1Long = LO.Last_Status_Change__c.getTime();
                        Long dt2Long = LN.Last_Status_Change__c.getTime();
                        Long milliseconds = dt2Long - dt1Long;
                        Long seconds = milliseconds / 1000;
                        Long minutes = seconds / 60;
                        Long hours = minutes / 60;
                        Long days = hours / 24;
                        Long Subhours = (minutes - (days * 24 * 60)) / 60 ;
                        Long Submin = ((minutes - (days * 24 * 60)) - (Subhours * 60)) ;
                        CSHVal.Status_Duration__c = days + ' Days /  ' + Subhours + ' Hrs /  ' + Submin + ' Mins ';
                        LSHList.add(CSHVal);
                    }
                }
                
            }
            database.Insert(LSHList,false,AccessLevel.USER_MODE);
        } Catch(Exception e){
        
        }
    }
    public static void createInvoice(Map<Id,Lead__c> NewLeads,Map<Id,Lead__c> oldLeads){
        Map<Id,Invoice__c> invoiceMap = New Map<Id,Invoice__c>();
        List<Invoice__c> invoices = [select id,Lead__c from Invoice__c where lead__c in: NewLeads.keyset()];
        for(Invoice__c inovice : invoices){
            invoiceMap.put(inovice.Lead__c,inovice);
        }
        Set<Id> UserId = New Set<Id>();
        for(Lead__c l : NewLeads.values()){
            UserId.add(l.Assigned_To__c);
        }
        Map<Id,string> userNCT = New Map<Id,string>();
        List<string> candidateTypes = New List<string>{'Employee', 'SCA', 'Non-SCA'};
        
        for(user u : [select id,contact.onboarding__r.Candidate_Type__c from user where Id IN: UserId]){
            if(candidateTypes.contains(u.contact.onboarding__r.Candidate_Type__c)){
                userNCT.put(u.Id,u.contact.onboarding__r.Candidate_Type__c);
            }
        }
        List<Invoice__c> updateInvoices = New List<Invoice__c>();
        List<Invoice__c> createInvoices = new List<Invoice__c>();
        List<string> status = New List<string>{'Completed','QA Review Completed'};
        for(Lead__c l : newLeads.values()){
            if(!userNCT.containsKey(l.Assigned_To__c)) continue;
            System.debug('Old Status: ' + oldLeads.get(l.Id).Status__c);
            System.debug('New Status: ' + l.Status__c);
            System.debug('New is completed: ' + status.contains(l.Status__c));
            System.debug('Old is completed: ' + status.contains(oldLeads.get(l.Id).Status__c));
            if(status.contains(l.Status__c) && !status.contains(oldLeads.get(l.id).Status__c)){
                if(!invoiceMap.containsKey(l.Id)){
                    //create invoice
                    createInvoices.add(generateInvoices(l));
                }else{
                    if(!invoiceMap.containsKey(l.id)) continue;
                    invoice__c inv = invoiceMap.get(l.id);
                    inv.Status__c = 'Generated';
                    updateInvoices.add(inv);
                    system.debug('invoice is already generated...');
                }
            }else{
                system.debug('creation condition failed');
            }
            if(status.contains(oldLeads.get(l.id).Status__c) && !status.contains(l.Status__c)){
                if(!invoiceMap.containsKey(l.id)) continue;
                invoice__c inv = invoiceMap.get(l.id);
                inv.Status__c = 'In-Review';
                updateInvoices.add(inv);
            }
        }
        if(!updateInvoices.isEmpty()){
            update updateInvoices;
        }
        	
        if(!createInvoices.isEmpty()){
            insert createInvoices;
        }
        	
    }
    public static Invoice__c generateInvoices(Lead__c l){
        Invoice__c inv = New Invoice__c();
        inv.Lead__c = l.Id;
        inv.Case__c = l.case__c;
        inv.Interview_Method__c = getInterviewMethod(l);
        inv.Item_Price__c = getItemPrice(l,getInterviewMethod(l));
        inv.Status__c = 'Generated';
        system.debug('getPayPeriodEndingDate(l.Completed_Date__c)...'+getPayPeriodEndingDate(l.Completed_Date__c));
        inv.Pay_Period_Ending__c = getPayPeriodEndingDate(l.Completed_Date__c);
        return inv;
    }
    private static String getInterviewMethod(Lead__c leadRecord) {
		if (leadRecord.LeadType__c == 'Subject Interview (ESI/TESI)') {
			return leadRecord.Was_Subject_interview_conducted__c == 'Yes' ? 'P' : 'P-UC';
		}

		String personalResult = leadRecord.Was_the_record_obtained_Personal__c;
		if (personalResult == 'Yes, Source was interviewed') {
			return isPersonalRemoteMethod(leadRecord.Personal_Contact_Method__c) ? 'PO' : 'P';
		}
		if (personalResult == 'No, Unable to interview source') {
			return 'P-UC';
		}

		String recordResult = leadRecord.Was_the_record_obtained__c;
		if (recordResult == 'No, unable to obtain record') {
			return 'R-UC';
		}
		if (recordResult == 'Yes, record was obtained' || recordResult == 'No, record does not exist') {
			String contactMethod = getRecordContactMethod(leadRecord);
			return isRecordRemoteMethod(contactMethod) ? 'RO' : 'R';
		}
            return '';
        }
    private static String getRecordContactMethod(Lead__c leadRecord) {
            if (leadRecord.LeadType__c == 'Employment (EMPL)' && leadRecord.Coverage_Type__c == 'Record') {
                return leadRecord.Employment_Contact_Method__c;
            }
            return leadRecord.Contact_Method__c;
        }

        private static Boolean isPersonalRemoteMethod(String contactMethod) {
            return contactMethod == 'Telephone' ||
                contactMethod == 'Fax' ||
                contactMethod == 'Email' ||
                contactMethod == 'By Telephone/Fax';
        }

        private static Boolean isRecordRemoteMethod(String contactMethod) {
            return contactMethod == 'Approved Internet Site' ||
                contactMethod == 'Telephone' ||
                contactMethod == 'Fax' ||
                contactMethod == 'Email' ||
                contactMethod == 'Telephone/Fax';
        }
    private static Decimal getItemPrice(Lead__c leadRecord, String interviewMethod) {
            if (leadRecord.LeadType__c == 'Subject Interview (ESI/TESI)') {
                return interviewMethod == 'P' ? 450.00 : 15.00;
            }
            if (interviewMethod == 'PO') {
                return 75.00;
            }
            if (interviewMethod == 'P') {
                return 115.00;
            }
            if (interviewMethod == 'RO') {
                return 50.00;
            }
            if (interviewMethod == 'R') {
                return 60.00;
            }
            if (interviewMethod == 'P-UC' || interviewMethod == 'R-UC') {
                return 15.00;
            }
            return null;
        }
    public static Map<Id, String> getPaychexIds(List<Lead__c> invoiceLeads) {
        Set<Id> userIds = new Set<Id>();
        for (Lead__c leadRecord : invoiceLeads) {
            if (leadRecord.Assigned_To__c != null) {
                userIds.add(leadRecord.Assigned_To__c);
            }
        }

        Map<Id, String> userIdToPaychexId = new Map<Id, String>();
        if (userIds.isEmpty()) {
            return userIdToPaychexId;
        }
        for(user u : [select id,contact.onboarding__r.Paychex_ID__c from user where Id IN: userIds]){
            userIdToPaychexId.put(u.Id,u.contact.onboarding__r.Paychex_ID__c);
        }        
        return userIdToPaychexId;
    }
    public static Date getPayPeriodEndingDate(Date completedDate) {
        if (completedDate == null) {
            return null;
        }
    
        // Custom Label format: MM-dd-yyyy
        List<String> dateParts =
            System.Label.SecondSundayStartDate.split('-');
    
        Date cycleStartDate = Date.newInstance(
            Integer.valueOf(dateParts[2]),
            Integer.valueOf(dateParts[0]),
            Integer.valueOf(dateParts[1])
        );
    
        Integer cycleLengthDays = 14;
        Integer daysFromStart = cycleStartDate.daysBetween(completedDate);
    
        /*
         * Select the first cycle-ending date that is greater than
         * or equal to the completed date.
         */
        Integer cycleNumber = Integer.valueOf(
            Math.ceil(
                Decimal.valueOf(daysFromStart) / cycleLengthDays
            )
        );
    
        return cycleStartDate.addDays(cycleNumber * cycleLengthDays);
    }
}