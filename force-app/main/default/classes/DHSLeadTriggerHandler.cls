/** Retains the existing DHSLeadTriggerHandler integration and application behavior. */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.DebugsShouldUseLoggingLevel, PMD.EmptyCatchBlock, PMD.EmptyIfStmt, PMD.EmptyStatementBlock, PMD.FormalParameterNamingConventions, PMD.IfElseStmtsMustUseBraces, PMD.IfStmtsMustUseBraces, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions, PMD.NcssCount, PMD.NcssMethodCount, PMD.StdCyclomaticComplexity')
Public with sharing Class DHSLeadTriggerHandler {
    public static void updateCaseLeadSummaryCounts(List<DHS_Lead__c> newLeads, List<DHS_Lead__c> oldLeads) {
        Set<Id> caseIds = new Set<Id>();
        collectCaseIds(newLeads, caseIds);
        collectCaseIds(oldLeads, caseIds);
        caseIds.remove(null);
        if (caseIds.isEmpty()) {
            return;
        }

        Map<Id, DHS_Case__c> caseUpdates = new Map<Id, DHS_Case__c>();
        for (Id caseId : caseIds) {
            caseUpdates.put(caseId, blankSummaryCase(caseId));
        }

        for (AggregateResult result : [
            SELECT DHS_Case__c caseId, LeadType__c leadType, COUNT(Id) leadCount
            FROM DHS_Lead__c
            WHERE DHS_Case__c IN :caseIds
            GROUP BY DHS_Case__c, LeadType__c
        ]) {
            Id caseId = (Id) result.get('caseId');
            String leadType = String.valueOf(result.get('leadType'));
            Integer leadCount = (Integer) result.get('leadCount');
            DHS_Case__c caseRecord = caseUpdates.get(caseId);
            String fieldName = summaryFieldForLeadType(leadType);
            if (String.isNotBlank(fieldName)) {
                caseRecord.put(fieldName, leadCount);
            }
            caseRecord.Total_References_Count__c = (caseRecord.Total_References_Count__c == null ? 0 : caseRecord.Total_References_Count__c) + leadCount;
        }

        for (DHS_Lead__c leadRecord : [
            SELECT DHS_Case__c, Attachment_Description__c
            FROM DHS_Lead__c
            WHERE DHS_Case__c IN :caseIds
        ]) {
            if (String.isBlank(leadRecord.Attachment_Description__c)) {
                continue;
            }
            DHS_Case__c caseRecord = caseUpdates.get(leadRecord.DHS_Case__c);
            caseRecord.Attachment_Count__c = (caseRecord.Attachment_Count__c == null ? 0 : caseRecord.Attachment_Count__c) + 1;
        }

        update caseUpdates.values();
    }

    private static void collectCaseIds(List<DHS_Lead__c> leads, Set<Id> caseIds) {
        if (leads == null) {
            return;
        }
        for (DHS_Lead__c leadRecord : leads) {
            caseIds.add(leadRecord.DHS_Case__c);
        }
    }

    private static DHS_Case__c blankSummaryCase(Id caseId) {
        return new DHS_Case__c(
            Id = caseId,
            Education_Count__c = 0,
            Employment_Count__c = 0,
            Financial_Count__c = 0,
            Former_Spouse_Count__c = 0,
            General_Count__c = 0,
            Law_Enforcement_Count__c = 0,
            Medical_Count__c = 0,
            Public_Records_Count__c = 0,
            PAEI_Count__c = 0,
            References_Count__c = 0,
            Residence_Count__c = 0,
            Subject_Interview_Count__c = 0,
            Subject_Contact_Count__c = 0,
            Unemployment_Count__c = 0,
            Attachment_Count__c = 0,
            Total_References_Count__c = 0
        );
    }

    private static String summaryFieldForLeadType(String leadType) {
        if (String.isBlank(leadType)) return null;
        String normalized = leadType.toLowerCase();
        Map<String, String> fieldByToken = summaryFieldByLeadTypeToken();
        for (String token : summaryLeadTypeTokens()) {
            if (normalized.contains(token)) {
                return fieldByToken.get(token);
            }
        }
        return null;
    }

    private static List<String> summaryLeadTypeTokens() {
        return new List<String>{
            'education',
            'employment',
            'financial',
            'former spouse',
            'general',
            'law enforcement',
            'medical',
            'public records',
            'publicly available electronic information',
            'paei',
            'references',
            'residence',
            'subject interview',
            'subject recontact',
            'subject contact',
            'unemployment'
        };
    }

    private static Map<String, String> summaryFieldByLeadTypeToken() {
        return new Map<String, String>{
            'education' => 'Education_Count__c',
            'employment' => 'Employment_Count__c',
            'financial' => 'Financial_Count__c',
            'former spouse' => 'Former_Spouse_Count__c',
            'general' => 'General_Count__c',
            'law enforcement' => 'Law_Enforcement_Count__c',
            'medical' => 'Medical_Count__c',
            'public records' => 'Public_Records_Count__c',
            'publicly available electronic information' => 'PAEI_Count__c',
            'paei' => 'PAEI_Count__c',
            'references' => 'References_Count__c',
            'residence' => 'Residence_Count__c',
            'subject interview' => 'Subject_Interview_Count__c',
            'subject recontact' => 'Subject_Contact_Count__c',
            'subject contact' => 'Subject_Contact_Count__c',
            'unemployment' => 'Unemployment_Count__c'
        };
    }

    public static void LeadAuditMethod(List<DHS_Lead__c> leadOldIds , List<DHS_Lead__c> LeadNewIds){
        List< DHS_Lead_Status_History__c > LSHList = New List< DHS_Lead_Status_History__c >();

        try
        {
             lisT<string> newLeadIds = new list<String>();
             For(DHS_Lead__c LN : LeadNewIds){
                 newLeadIds.add(ln.id);
             }
            list<DHS_Lead_Status_History__c> statusHistories = new list<DHS_Lead_Status_History__c>();
            statusHistories = [Select Id,DHS_Completed_By__c,DHS_Lead__c FROM DHS_Lead_Status_History__c WHERE DHS_Lead__c=:newLeadIds WITH SECURITY_ENFORCED order by createddate desc];
            map<string,list<DHS_Lead_Status_History__c>> leadNstatushistorymap = new map<string,list<DHS_Lead_Status_History__c>>();
            for(DHS_Lead_Status_History__c temp: statusHistories){
                if(!leadNstatushistorymap.containsKey(temp.DHS_Lead__c)){
                    leadNstatushistorymap.put((string)temp.DHS_Lead__c,new list<DHS_Lead_Status_History__c>{temp});
                }else{
                    list<DHS_Lead_Status_History__c> temp2= leadNstatushistorymap.get(temp.DHS_Lead__c);
                    temp2.add(temp);
                    leadNstatushistorymap.put((string)temp.DHS_Lead__c,temp2);
                }
            }
                        
            For(DHS_Lead__c LO : leadOldIds)
            {
                For(DHS_Lead__c LN : LeadNewIds)
                {
                    IF((LO.Id == LN.Id) && (LO.Last_Status_Change__c != LN.Last_Status_Change__c))
                    {
                        list<DHS_Lead_Status_History__c> temp = new list<DHS_Lead_Status_History__c>();
                        if(leadNstatushistorymap.containsKey(ln.id)){
                            temp = leadNstatushistorymap.get(ln.id);
                        }
                        DHS_Lead_Status_History__c CSHVal = New DHS_Lead_Status_History__c();
                        if(!temp.isEmpty()){
                            CSHVal.DHS_Initiated_By__c = temp[0].DHS_Completed_By__c;    
                        }else{
                            CSHVal.DHS_Initiated_By__c = ln.createdbyid;
                        }
                        CSHVal.DHS_Completed_By__c = userinfo.getuserid();
                        CSHVal.DHS_Lead__c = LO.Id;
                        CSHVal.Status_Name__c = LO.Status__c;
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
    public static void createInvoice(Map<Id,DHS_Lead__c> NewLeads,Map<Id,DHS_Lead__c> oldLeads){
        Map<Id,DHS_Invoice__c> invoiceMap = New Map<Id,DHS_Invoice__c>();
        List<DHS_Invoice__c> invoices = [select id,DHS_Lead__c from DHS_Invoice__c where DHS_Lead__c in: NewLeads.keyset()];
        for(DHS_Invoice__c inovice : invoices){
            invoiceMap.put(inovice.DHS_Lead__c,inovice);
        }
        Set<Id> UserId = New Set<Id>();
        for(DHS_Lead__c l : NewLeads.values()){
            UserId.add(l.DHS_Assigned_To__c);
        }
        Map<Id,string> userNCT = New Map<Id,string>();
        List<string> candidateTypes = New List<string>{'Employee', 'SCA', 'Non-SCA'};
        for(user u : [
            SELECT Id, Candidate_type__c, Contact.OnBoarding__r.Candidate_Type__c
            FROM User
            WHERE Id IN :UserId
        ]){
            String candidateType = u.Contact != null &&
                u.Contact.OnBoarding__r != null
                ? u.Contact.OnBoarding__r.Candidate_Type__c
                : u.Candidate_type__c;
            if(candidateTypes.contains(candidateType)){
                userNCT.put(u.Id, candidateType);
            }
        }
        List<DHS_Invoice__c> updateInvoices = New List<DHS_Invoice__c>();
        List<DHS_Invoice__c> createInvoices = new List<DHS_Invoice__c>();
        Map<Id,string> paychexIdMap = getPaychexIds(NewLeads.values());
        List<string> status = New List<string>{'Completed','QA Review Completed'};
        for(DHS_Lead__c l : newLeads.values()){
            if(!userNCT.containsKey(l.DHS_Assigned_To__c)) continue;
            if(status.contains(l.Status__c) && !status.contains(oldLeads.get(l.id).Status__c)){
                if(!invoiceMap.containsKey(l.Id)){
                    //create invoice
                    createInvoices.add(generateInvoices(l,paychexIdMap.get(l.Id)));
                }else{
                    if(!invoiceMap.containsKey(l.id)) continue;
                    DHS_Invoice__c inv = invoiceMap.get(l.id);
                    inv.Status__c = 'Generated';
                    updateInvoices.add(inv);
                }
            }else{
            }
            if(status.contains(oldLeads.get(l.id).Status__c) && !status.contains(l.Status__c)){
                if(!invoiceMap.containsKey(l.id)) continue;
                DHS_Invoice__c inv = invoiceMap.get(l.id);
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
    public static DHS_Invoice__c generateInvoices(DHS_Lead__c l,string paychexId){
        DHS_Invoice__c inv = New DHS_Invoice__c();
        inv.DHS_Lead__c = l.Id;
        inv.DHS_Case__c = l.DHS_Case__c;
        inv.Interview_Method__c = getInterviewMethod(l);
        inv.Item_Price__c = getItemPrice(l,getInterviewMethod(l));
        inv.ADP_File_Number__c = paychexId;
        inv.Status__c = 'Generated';
        inv.Pay_Period_Ending__c = getClosestCycleDate(l.Completed_Date__c);
        return inv;
    }
    private static String getInterviewMethod(DHS_Lead__c leadRecord) {
		if (leadRecord.LeadType__c == 'Subject Interview (ESI/TESI)') {
			return leadRecord.Was_Subject_Interview_Conducted__c == 'Yes' ? 'P' : 'P-UC';
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
    private static String getRecordContactMethod(DHS_Lead__c leadRecord) {
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
    private static Decimal getItemPrice(DHS_Lead__c leadRecord, String interviewMethod) {
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
    public static Map<Id, String> getPaychexIds(List<DHS_Lead__c> invoiceLeads) {
        Set<Id> userIds = new Set<Id>();
        for (DHS_Lead__c leadRecord : invoiceLeads) {
            if (leadRecord.DHS_Assigned_To__c != null) {
                userIds.add(leadRecord.DHS_Assigned_To__c);
            }
        }

        Map<Id, String> userIdToPaychexId = new Map<Id, String>();
        if (userIds.isEmpty()) {
            return userIdToPaychexId;
        }
        for(user u : [select id,contact.OnBoarding__r.Paychex_ID__c from user where Id IN: userIds]){
            userIdToPaychexId.put(u.Id,u.contact.OnBoarding__r.Paychex_ID__c);
        }        
        return userIdToPaychexId;
    }
    public static Date getClosestCycleDate(Date inputDate) {
        if (inputDate == null) return null;

        // Custom Label format: MM-dd-yyyy (e.g. 06-07-2026)
        String[] parts = System.Label.DHS_SecondSundayStartDate.split('-');

        Integer month = Integer.valueOf(parts[0]);
        Integer day   = Integer.valueOf(parts[1]);
        Integer year  = Integer.valueOf(parts[2]);

        Date staticDate = Date.newInstance(year, month, day);

        Integer cycle = 14;

        Integer diff = staticDate.daysBetween(inputDate);

        // Previous cycle date
        Integer completedCycles = (Integer)Math.floor((Decimal)diff / cycle);
        Date previousCycle = staticDate.addDays(completedCycles * cycle);

        // Next cycle date
        Date nextCycle = previousCycle.addDays(cycle);

        Integer previousDiff = Math.abs(previousCycle.daysBetween(inputDate));
        Integer nextDiff = Math.abs(nextCycle.daysBetween(inputDate));

        // If equidistant, returns the earlier one.
        return previousDiff <= nextDiff ? previousCycle : nextCycle;
    }
}