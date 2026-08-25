public with sharing class DIAROIReportControllerV2 {
    public string caseId {get;set;}
    public DIA_Case__c caseRecord {get;set;}
    public List<DIA_Lead__c> leads {get;set;}
    public user currentUser{get;set;}
    public integer totalLeads {get;set;}
    public String investigationDates {get;set;}
    public String investigators {get;set;}
    public map<string,integer> leadsCountMap {get;set;}
    public map<string,DIA_Lead__c> leadsMap {get;set;}
    public map<integer,DIA_Lead__c> itemNumberNLeadsMap {get;set;}
    public List<String> subjectInterviewList {get;set;}
    public List<String> subjectContactList {get;set;}
    public Map<String,Map<String,List<String>>> employmentMap {get;set;}
    public Map<String,Map<String,List<String>>> educationMap {get;set;}
    public Map<String,Map<String,List<String>>> medicalMap {get;set;}
    public List<String> residenceList {get;set;}
    public List<String> referencesList {get;set;}
    public List<String> generalLeadsList {get;set;}
    public List<String> formerSpouseList {get;set;}
    public List<String> unEmploymentList {get;set;}
    public List<String> lawEnforcementList {get;set;}
    public List<String> financialList {get;set;}
    public List<String> employmentList {get;set;}
    public List<String> educationList {get;set;}
    public List<String> medicalList {get;set;}
    public string sequenceId{get;set;}
    public list<integer> leadOrder {get;set;}
    public string derogatorySummary {get;set;}
    public boolean hasSubjectInterview {get;set;}
    public boolean hasSubjectRecontact {get;set;}
    public boolean hasResidence {get;set;}
    public integer numOfSubjectRecontacts {get;set;}
    
    public DIAROIReportControllerV2(){
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId() WITH SECURITY_ENFORCED];
        caseId = apexpages.currentpage().getparameters().get('id');
        sequenceId = apexpages.currentpage().getparameters().get('sequenceid');
        leadsCountMap = new map<string,integer>();
        totalLeads= 0;
        leadOrder = new list<integer>();
        if(sequenceId != Null){
            System.debug('sequenceId...'+sequenceId);
            DIA_ROI_Report_Order__c ro = [select Id, ROI_Report_Order__c from DIA_ROI_Report_Order__c WHERE Id=:sequenceId WITH SECURITY_ENFORCED];
            if(ro.ROI_Report_Order__c != Null){
                list<string> temp = ro.ROI_Report_Order__c.split(',');
                for(string s: temp){
                    leadOrder.add(integer.valueof(s));    
                }
            }
        }
        hasSubjectInterview = false;
        hasSubjectRecontact = false;
        hasResidence = false;
        FetchCaseInformation();
        FetchLeadInformation();
    }
    
    public void FetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('DIA_Case__c');
        caseFields.add('contact__r.First_Name__c');
        caseFields.add('contact__r.Last_Name__c');
        caseFields.add('contact__r.Email__c');
        caseFields.add('contact__r.Address__c');
        caseFields.add('contact__r.City__c');
        caseFields.add('contact__r.State__c');
        caseFields.add('contact__r.Zip__c');
        caseFields.add('contact__r.SSN__c');
        String query = 'Select '+string.join(caseFields, ',') + ' From DIA_Case__c ';
        
        if(String.isNotBlank(caseId)){
            whereCriteria.add(new ApexUtil.Criteria('Id',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ ' WITH SECURITY_ENFORCED'; 
        System.debug('query...'+query);
        list<DIA_Case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0];
            DateTime fromDate = caseRecord.createddate;
            String fromDateFormatted = fromDate.format('MM/dd/yyyy');
            DateTime toDate;
            String toDateFormatted;
            if(caseRecord.Customer_Delivery_Date__c != null){
        query = query + ' WHERE '+where_cond+ ' WITH SECURITY_ENFORCED'; 
                toDate = DateTime.newInstance(caseRecord.Customer_Delivery_Date__c.year(), caseRecord.Customer_Delivery_Date__c.month(),caseRecord.Customer_Delivery_Date__c.day() );
                toDateFormatted = toDate.format('MM/dd/yyyy');
            } else{
                toDateFormatted = 'N/A';
            }
            investigationDates = fromDateFormatted +' to '+ toDateFormatted;    
            /*if(caseRecord.investigations_review_Date__c != Null && caseRecord.QA_and_review_Date__c != Null){
                DateTime fromDate = DateTime.newInstance(caseRecord.investigations_review_Date__c.year(), caseRecord.investigations_review_Date__c.month(),caseRecord.investigations_review_Date__c.day());
                String fromDateFormatted = fromDate.format('MM/dd/yyyy');
                DateTime toDate = DateTime.newInstance(caseRecord.QA_and_review_Date__c.year(), caseRecord.QA_and_review_Date__c.month(),caseRecord.QA_and_review_Date__c.day());
                String toDateFormatted = toDate.format('MM/dd/yyyy');
                investigationDates = fromDateFormatted +' to '+ toDateFormatted;  
            }*/
        }    
    }
    
    PUBLIC Map<String, DIA_Lead_RTA_Extension__c> subjectInterviewNLeadRTAExtension {get;set;}
    public void FetchLeadInformation(){
        leadsMap = new Map<string,DIA_Lead__c>();
        itemNumberNLeadsMap = new Map<integer,DIA_Lead__c>();
        subjectInterviewNLeadRTAExtension = new Map<String, DIA_Lead_RTA_Extension__c>();
        leads = new List<DIA_Lead__c> ();
        List<string> leadFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        leadFields = ApexUtil.FetchFields('DIA_Lead__c');  
        leadFields.add('contact__r.First_Name__c');    
        leadFields.add('contact__r.Last_Name__c');
         leadFields.add('contact__r.State__c');   
        String query = 'Select '+string.join(leadFields, ',') + ' From DIA_Lead__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        whereCriteria.add(new ApexUtil.Criteria('Status__c','Cancelled','!='));
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ 'ORDER BY LeadType__c Asc'; 
        
        leads = database.query(query);
        System.debug('leads...'+leads);
        List<string> esiLeadIds = new List<String>();
        for(DIA_Lead__c lc: leads){
            system.debug( integer.valueof(lc.item_number__c)+' ===> '+lc.LeadType__c +' ===> '+lc.Narrator_Comments__c);
            itemNumberNLeadsMap.put(integer.valueof(lc.item_number__c), lc);
            if(lc.LeadType__c == 'Subject Interview (ESI/TESI)'){
                esiLeadIds.add(lc.id);
            }
            if(String.isNotblank(lc.Standardised_Issues_Picklist__c)){
                if(String.isBlank(derogatorySummary)){
                    derogatorySummary = lc.Standardised_Issues_Picklist__c; 
                }else{
                    derogatorySummary = derogatorySummary + '<br/>' + lc.Standardised_Issues_Picklist__c;
                }
                System.debug('lc.Standardised_Issues_Other_Description__c...'+lc.Standardised_Issues_Other_Description__c);
                if(String.isNotBlank(lc.Standardised_Issues_Other_Description__c)){
                     derogatorySummary = derogatorySummary + '; '+lc.Standardised_Issues_Other_Description__c;
                }
                System.debug('derogatorySummary..'+derogatorySummary);
            }
            
           
        }
        
        List<DIA_Lead_RTA_Extension__c> leadRTAExtensions = [Select Id, Lead__c, Foreign_Activities__c, Foreign_Contacts__c, Foreign_Travel1__c, Foreign_Travel2__c
                                                         FROM DIA_Lead_RTA_Extension__c
                                                         WHERE Lead__c IN:esiLeadIds WITH SECURITY_ENFORCED];
        
        for(DIA_Lead_RTA_Extension__c lrta: leadRTAExtensions){
            subjectInterviewNLeadRTAExtension.put(lrta.lead__c, lrta);
        }  
        
        for(String str: esiLeadIds){
            if(!subjectInterviewNLeadRTAExtension.keyset().contains(str)){
                subjectInterviewNLeadRTAExtension.put(str, new DIA_Lead_RTA_Extension__c());
            }
        }                                                
        
        for(DIA_Lead__c l: leads){
            system.debug('l.leadtype__c...'+l.leadtype__c);
            if(!leadsCountMap.containsKey(l.leadtype__c)){
                leadsCountMap.put(l.leadtype__c, 1);    
            }else{
                leadsCountMap.put(l.leadtype__c, leadsCountMap.get(l.leadtype__c)+1);    
            }
            totalLeads++;
            
            string assignedDate;
            if(l.Assignee_Date__c != Null){
             assignedDate = l.Assignee_Date__c.year()+'-'+l.Assignee_Date__c.month()+'-'+l.Assignee_Date__c.day();
            }
            string completedDate;
            if(l.Completed_Date__c != Null){
             completedDate= l.Completed_Date__c.year()+'-'+l.Completed_Date__c.month()+'-'+l.Completed_Date__c.day();
            }
            
            /*if(investigationDates != Null){
                investigationDates =investigationDates+','+assignedDate+' to '+completedDate;
            }else{
                investigationDates =assignedDate+' to '+completedDate;
            }*/
            if(investigators != Null){
                if(l.Assigned_To_Name__c != Null){
                    if(!investigators.contains(l.Assigned_To_Name__c)){
                        investigators = investigators +', '+l.Assigned_To_Name__c;
                    }
                }
            }else{
                investigators = l.Assigned_To_Name__c;
            }
            leadsMap.put(l.id,l);
        }
         employmentMap = new Map<String,Map<String,List<String>>>();
        educationMap = new Map<String,Map<String,List<String>>>();
        medicalMap = new Map<String,Map<String,List<String>>> ();
        subjectInterviewList = new List<String>();
        subjectContactList = new List<String>();
        residenceList = new List<String>();
        referencesList = new List<String>();
        generalLeadsList = new List<String>();
        formerSpouseList = new List<String>();
        unEmploymentList = new List<String>();
        lawEnforcementList = new List<String>();
        financialList = new List<String>();
        employmentList = new list<string>();
        educationList= new list<string>();
        medicalList= new list<string>();
        
        for(DIA_Lead__c l: leads){
            if(l.leadType__c == 'Employment (EMPL)'){
                employmentList.add(l.id);
            }
            if(l.leadType__c == 'Education (EDUC)'){
                educationList.add(l.id);
            }
             if(l.leadType__c == 'Medical (MEDI)'){
                medicalList.add(l.id);
            }
            if(l.leadType__c == 'Subject Interview (ESI/TESI)'){
                subjectInterviewList.add(l.id);
                hasSubjectInterview = true;
            }
            if(l.leadType__c == 'Subject contact (SUBC)'){
                subjectContactList.add(l.id);
                hasSubjectRecontact = true;
            }
            
            if(l.leadType__c == 'Residence (RESI)'){
                residenceList.add(l.id);
                hasResidence = true;
            }
            if(l.leadType__c == 'References (REFE)'){
                referencesList.add(l.id);
            }
            if(l.leadType__c == 'General (GENL)'){
                generalLeadsList.add(l.id);
            }
            if(l.leadType__c == 'Former Spouse (FMSP)'){
                formerSpouseList.add(l.id);
            }
            if(l.leadType__c == 'Unemployment'){
                unEmploymentList.add(l.id);
            }
            if(l.leadType__c == 'Law Enforcement (LAWE)'){
                lawEnforcementList.add(l.id);
            }
            if(l.leadType__c == 'Financial (FINL)'){
                financialList.add(l.id);
            }
       
        }

    }
}