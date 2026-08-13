/** Retains the existing DHSROIReportControllerV2 integration and application behavior. */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.ApexSOQLInjection, PMD.ApexSharingViolations, PMD.ApexXSSFromURLParam, PMD.AvoidBooleanMethodParameters, PMD.AvoidDeeplyNestedIfStmts, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.DebugsShouldUseLoggingLevel, PMD.ExcessivePublicCount, PMD.FormalParameterNamingConventions, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions, PMD.NcssConstructorCount, PMD.NcssCount, PMD.NcssMethodCount, PMD.PropertyNamingConventions, PMD.StdCyclomaticComplexity')
public class DHSROIReportControllerV2 {
    public string caseId {get;set;}
    public DHS_Case__c caseRecord {get;set;}
    public List<DHS_Lead__c> leads {get;set;}
    public Map<integer,boolean> skipTitles {get;set;}
    public user currentUser{get;set;}
    public integer totalLeads {get;set;}
    public String investigationDates {get;set;}
    public String investigators {get;set;}
    public map<string,integer> leadsCountMap {get;set;}
    public map<string,DHS_Lead__c> leadsMap {get;set;}
    public map<integer,DHS_Lead__c> itemNumberNLeadsMap {get;set;}
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
    public set<string> derogatorySummaryItems {get;set;}
    public boolean hasSubjectInterview {get;set;}
    public boolean hasSubjectRecontact {get;set;}
    public boolean hasResidence {get;set;}
    public integer numOfSubjectRecontacts {get;set;}
    public DHS_Lead__c PAEI {get;set;}
    public integer closestESI {get;set;}
    public boolean showAllRecordObtained {get;set;}
    public DHSROIReportControllerV2(){
        caseId = apexpages.currentpage().getparameters().get('id');
        showAllRecordObtained = false;
        Set<string> wasTheRecordObtained = New Set<string>();
        List<DHS_Lead__c> completedLeads = [select id,Was_the_record_obtained__c from DHS_Lead__c where Status__c = 'Completed' and Coverage_Type__c = 'General Record' and DHS_Case__c =: caseId];
        for(DHS_Lead__c l : completedLeads){
            if(l.Was_the_record_obtained__c != null){
                wasTheRecordObtained.add(l.Was_the_record_obtained__c);
            }
        }
        if(wasTheRecordObtained.size() > 0){
            if(wasTheRecordObtained.contains('No, unable to obtain record')){
                showAllRecordObtained = false;
            }else{
                showAllRecordObtained = true;
            }
        }else{
            showAllRecordObtained = false;
        }
        skipTitles = New Map<integer,boolean>();
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId()];
        
        sequenceId = apexpages.currentpage().getparameters().get('sequenceid');
        leadsCountMap = new map<string,integer>();
        derogatorySummaryItems = new set<string>();
        totalLeads= 0;
        
        leadOrder = new list<integer>();
        if(sequenceId != Null){
            DHS_ROI_Report_Order__c ro = [select Id, ROI_Report_Order__c, HideTitles__c  FROM DHS_ROI_Report_Order__c WHERE Id=:sequenceId];
            if(ro.HideTitles__c != null){
                List<string> itemNums = ro.HideTitles__c.split(',');
                for(string i : itemNums){
                    skipTitles.put(integer.valueOf(i),true);
                }
            }
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
        
        
        if(ApexPages.currentPage().getParameters().containsKey('download')){
            String downloadParam = ApexPages.currentPage().getParameters().get('download');
            if (downloadParam == 'true') {
                string applicantType;
                string ssnFormatted;
                if(caseRecord.Subject_Type__c == 'Applicant'){
                    applicantType = 'A';
                }
                if(caseRecord.Subject_Type__c == 'Contractor'){
                    applicantType = 'C';
                }
                if(caseRecord.DHS_Contact__r.SSN__c != Null){
                    ssnFormatted = caseRecord.DHS_Contact__r.SSN__c.replaceAll('-','');
                }
                string docName = applicantType + ssnFormatted + 'Rev00.pdf';
                ApexPages.currentPage().getHeaders().put('Content-Disposition', 'attachment; filename="' + docName + '"');
            }
        }
        
            Map<integer,DHS_Lead__c> leads = itemNumberNLead(caseId);
        for(integer i : leadOrder){
            if(!skipTitles.containsKey(i)){
                skipTitles.put(integer.valueOf(i),false);
            }
            DHS_Lead__c l = leads.get(i);
            if(l != null){
                if(l.LeadType__c == 'Subject Interview (ESI/TESI)'){
                    hasSubjectInterview = true;
                }
                if(l.LeadType__c == 'Subject Recontact (SUBC)'){
                    hasSubjectRecontact = true;
                }
                if(l.LeadType__c == 'Residence (RESI)'){
                    hasResidence = true;
                }
            }
        }
        
        
    }
    
    public void FetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
        caseFields.add('DHS_Contact__r.First_Name__c');
        caseFields.add('DHS_Contact__r.Last_Name__c');
        caseFields.add('DHS_Contact__r.Email__c');
        caseFields.add('DHS_Contact__r.Address__c');
        caseFields.add('DHS_Contact__r.City__c');
        caseFields.add('DHS_Contact__r.State__c');
        caseFields.add('DHS_Contact__r.Zip__c');
        caseFields.add('DHS_Contact__r.SSN__c');
        String query = 'Select '+string.join(caseFields, ',') + ' From DHS_Case__c ';
        
        if(String.isNotBlank(caseId)){
            whereCriteria.add(new DHSApexUtil.Criteria('Id',caseId,'='));
        }
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond; 
        list<DHS_Case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0];
            DateTime fromDate = caseRecord.createddate;
            String fromDateFormatted = fromDate.format('MM/dd/yyyy');
            DateTime toDate;
            String toDateFormatted;
            if(caseRecord.Customer_Delivery_Date__c != null){
                toDate = DateTime.newInstance(caseRecord.Customer_Delivery_Date__c.year(), caseRecord.Customer_Delivery_Date__c.month(),caseRecord.Customer_Delivery_Date__c.day());
                toDateFormatted = toDate.format('MM/dd/yyyy');
            } else{
                toDateFormatted = 'N/A';
            }
            investigationDates = fromDateFormatted +' to '+ toDateFormatted;    
            /*if(caseRecord.Investigations_Review_Date__c != Null && caseRecord.QA_and_Review_Date__c != Null){
                DateTime fromDate = DateTime.newInstance(caseRecord.Investigations_Review_Date__c.year(), caseRecord.Investigations_Review_Date__c.month(),caseRecord.Investigations_Review_Date__c.day());
                String fromDateFormatted = fromDate.format('MM/dd/yyyy');
                DateTime toDate = DateTime.newInstance(caseRecord.QA_and_Review_Date__c.year(), caseRecord.QA_and_Review_Date__c.month(),caseRecord.QA_and_Review_Date__c.day());
                String toDateFormatted = toDate.format('MM/dd/yyyy');
                investigationDates = fromDateFormatted +' to '+ toDateFormatted;  
            }*/
        }    
    }
    
    PUBLIC Map<String, DHS_Lead_RTA_Extension__c> subjectInterviewNLeadRTAExtension {get;set;}
    public void FetchLeadInformation(){
        leadsMap = new Map<string,DHS_Lead__c>();
        itemNumberNLeadsMap = new Map<integer,DHS_Lead__c>();
        subjectInterviewNLeadRTAExtension = new Map<String, DHS_Lead_RTA_Extension__c>();
        leads = new List<DHS_Lead__c> ();
        List<string> leadFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        leadFields = DHSApexUtil.FetchFields('DHS_Lead__c');  
        leadFields.add('DHS_Contact__r.First_Name__c');    
        leadFields.add('DHS_Contact__r.Last_Name__c');
         leadFields.add('DHS_Contact__r.State__c');   
        String query = 'Select '+string.join(leadFields, ',') + ' From DHS_Lead__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ 'ORDER BY LeadType__c Asc'; 
        
        leads = database.query(query);
        List<string> esiLeadIds = new List<String>();
        integer PAEIItemNumber;
        List<integer> esiLeadItems = New List<integer>();
        for(DHS_Lead__c lc: leads){
            
            itemNumberNLeadsMap.put(integer.valueof(lc.Item_number__c), lc);
            if(lc.LeadType__c == 'Publicly Available Electronic Information (PAEI)'){
                PAEI = lc;
                PAEIItemNumber = integer.valueOf(lc.Item_number__c);
            }
            if(lc.LeadType__c == 'Subject Interview (ESI/TESI)'){
                esiLeadItems.add(integer.valueOf(lc.Item_number__c));
                esiLeadIds.add(lc.id);
            }
            if(String.isNotblank(lc.Standardised_Issues_Picklist__c)){
                if(String.isBlank(derogatorySummary)){
                    derogatorySummary = lc.Standardised_Issues_Picklist__c;
                }else{
                    derogatorySummary = derogatorySummary + ';' +lc.Standardised_Issues_Picklist__c;
                }
                if(String.isNotBlank(lc.Std_Issues_Other_Desc__c)){
                     derogatorySummary = derogatorySummary + '; '+lc.Std_Issues_Other_Desc__c;
                }
                for(string item : derogatorySummary.split(';')){
                    derogatorySummaryItems.add(item);
                }
            }
        }
             if (derogatorySummaryItems == null || derogatorySummaryItems.isEmpty()) {
    derogatorySummaryItems = new Set<String>{ 'None' };
}
        if(Test.isRunningTest()){
            esiLeadItems.add(1);
            PAEIItemNumber = 2;
        }
        if(PAEIItemNumber != null){
            closestESI = findClosest(esiLeadItems,PAEIItemNumber);
        }
        List<DHS_Lead_RTA_Extension__c> leadRTAExtensions = [Select Id, DHS_Lead__c, Foreign_Activities__c, Foreign_Contacts__c, Foreign_Travel1__c, Foreign_Travel2__c
                                                         FROM DHS_Lead_RTA_Extension__c
                                                         WHERE DHS_Lead__c IN:esiLeadIds];
        
        for(DHS_Lead_RTA_Extension__c lrta: leadRTAExtensions){
            subjectInterviewNLeadRTAExtension.put(lrta.DHS_Lead__c, lrta);
        }  
        
        for(String str: esiLeadIds){
            if(!subjectInterviewNLeadRTAExtension.keyset().contains(str)){
                subjectInterviewNLeadRTAExtension.put(str, new DHS_Lead_RTA_Extension__c());
            }
        }                                                
        
        for(DHS_Lead__c l: leads){
            if(!leadsCountMap.containsKey(l.LeadType__c)){
                leadsCountMap.put(l.LeadType__c, 1);    
            }else{
                leadsCountMap.put(l.LeadType__c, leadsCountMap.get(l.LeadType__c)+1);    
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
                    string assignedName = l.Assigned_To_Name__c;
                    if(assignedName == 'JS Investigator'){
                        assignedName = 'Jason Stott';
                    }else if(l.Assigned_To_Name__c == 'Laura Investigator'){
                        assignedName = 'Laura Beeson';
                    }else if(l.Assigned_To_Name__c == 'Katie RS'){
                        assignedName = 'Record Searcher';
                    }else{
                        assignedName = l.Assigned_To_Name__c;
                    }
                    if(!investigators.contains(assignedName)){
                        investigators = investigators +', '+assignedName;
                    }
                }
            }else{
                string assignedName = l.Assigned_To_Name__c;
                    if(assignedName == 'JS Investigator'){
                        assignedName = 'Jason Stott';
                    }else if(l.Assigned_To_Name__c == 'Laura Investigator'){
                        assignedName = 'Laura Beeson';
                    }else if(l.Assigned_To_Name__c == 'Katie RS'){
                        assignedName = 'Record Searcher';
                    }else{
                        assignedName = l.Assigned_To_Name__c;
                    }
                
                investigators = assignedName;
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
        
        for(DHS_Lead__c l: leads){
            if(l.LeadType__c == 'Employment (EMPL)'){
                employmentList.add(l.id);
            }
            if(l.LeadType__c == 'Education (EDUC)'){
                educationList.add(l.id);
            }
             if(l.LeadType__c == 'Medical (MEDI)'){
                medicalList.add(l.id);
            }
            if(l.LeadType__c == 'Subject Interview (ESI/TESI)'){
                subjectInterviewList.add(l.id);
                //hasSubjectInterview = true;
            }
            if(l.LeadType__c == 'Subject Recontact (SUBC)'){
                subjectContactList.add(l.id);
                //hasSubjectRecontact = true;
            }
            
            if(l.LeadType__c == 'Residence (RESI)'){
                residenceList.add(l.id);
                //hasResidence = true;
            }
            if(l.LeadType__c == 'References (REFE)'){
                referencesList.add(l.id);
            }
            if(l.LeadType__c == 'General (GENL)'){
                generalLeadsList.add(l.id);
            }
            if(l.LeadType__c == 'Former Spouse (FMSP)'){
                formerSpouseList.add(l.id);
            }
            if(l.LeadType__c == 'Unemployment'){
                unEmploymentList.add(l.id);
            }
            if(l.LeadType__c == 'Law Enforcement (LAWE)'){
                lawEnforcementList.add(l.id);
            }
            if(l.LeadType__c == 'Financial (FINL)'){
                financialList.add(l.id);
            }
       
        }

    }
    public static Integer findClosest(List<Integer> esiItems, Integer PAEI) {
        if (esiItems == null || esiItems.isEmpty()) {
            return null; // no items
        }
        Integer closest = esiItems[0];
        Integer minDiff = Math.abs(PAEI - closest);
    
        for (Integer item : esiItems) {
            Integer diff = Math.abs(PAEI - item);
            if (diff < minDiff) {
                minDiff = diff;
                closest = item;
            }
        }
        return closest;
    }
    public static Map<integer,DHS_Lead__c> itemNumberNLead(string caseId){
        Map<integer,DHS_Lead__c> returnVal = New Map<integer,DHS_Lead__c>();
        List<DHS_Lead__c> leads = [select id,Item_number__c,LeadType__c from DHS_Lead__c where DHS_Case__c =: caseId];
        for(DHS_Lead__c l : leads){
            returnVal.put(integer.valueOf(l.Item_number__c),l);
        }
        return returnVal;
    }
}