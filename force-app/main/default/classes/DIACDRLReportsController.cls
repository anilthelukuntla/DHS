public class DIACDRLReportsController {
    public user currentUser{get;set;}
    public list<selectoption> typesOfReports {get;set;}
    public list<selectoption> cmoUsers {get;set;}
    public list<selectoption> investigatorUsers {get;set;}
    public list<selectoption> caseTaskStatus {get;set;}
    public list<selectoption> caseStatus {get;set;}
    public list<selectoption> leadStatus {get;set;}
    public string selectedCaseStatus {get;set;}
    public string selectedCaseTaskStatus {get;set;}
    public string selectedLeadStatus {get;set;}
    public string selectedReportType {get;set;}
    public string selectedCMOUser {get;set;}
    public string selectedInvestigatorUser {get;set;}
    public date fromDate {get;set;}
    public date toDate {get;set;}
    public date waiverAcceptedFromDate {get;set;}
    public date waiverAcceptedToDate {get;set;}
    public date extensionAcceptedFromDate {get;set;}
    public date extensionAcceptedToDate {get;set;}
    public boolean showonly90daysfromCaseClosed {get;set;}
    public transient list<ReportRecord> reports {get;set;}
    public boolean showViewButton {get;set;}
    public boolean leadsView {get;set;}
    public boolean casesView {get;set;}
    public boolean messagesView {get;set;}
    public boolean checkincheckoutView {get;set;}
    public string selectedTDY {get;set;}
    public list<selectoption> leadTDY {get;set;}
    public boolean waiversView {get;set;}
    public boolean showreportstable {get;set;}
    public boolean showonly90daysfromQAcomplete {get;set;}
    public string SelectedRelatedCaseIdForMessages{get;set;}
    public list<selectoption> relatedCasesForMessages {get;set;}
    public string SelectedCaseIdForLeadSearch{get;set;}
    public list<selectoption> messageTypeOptions {get;set;}
    public string selectedMessageType{get;set;}
    public string SelectedCaseNumberForLeadSearch{get;set;}
    public string selectedleadforstatustracking {get;set;}
    //public list<Lead__History> leadStatusTrackings {get;set;}
    public list<LeadHistoryRecord> leadStatusTrackings{get;set;}
    public integer pageNumber {get;set;}
    public integer TotalPages   {get;set;}
    public integer totalRecordCount {get;set;}
    public boolean disablePrev {get;set;}
    public boolean disableNext {get;set;}
    public string queryForNextRecords {get;set;}
    public string lastRecordName {get;set;}
    public string firstRecordName {get;set;}
    public integer currentRecordCount {get;set;}
    public string userType  {get;set;}
    public string contextINVId  {get;set;}
    
    public class LeadHistoryRecord{
        public DIA_Lead__History leadHistory {get;set;}
        public integer numOfDays {get;set;}
        public LeadHistoryRecord(DIA_Lead__History lh, integer nd){
            this.leadHistory = lh;
            this.numOfDays = nd;
        }
    }
    
    public DIACDRLReportsController(){
        pageNumber = 1; 
        disablePrev = true;
        disableNext = true;
        currentUser = [select id, firstname, lastname, email, user_type__c from User where id=:userinfo.getuserid()];  
        userType = currentUser.user_type__c;
        if(userType == 'INV'){
            contextINVId = currentUser.Id;
        }
        FetchPicklistValues();
        showViewButton = false;
        leadsView =false;
        casesView =false;
        messagesView = false;
        showreportstable = false;
        checkincheckoutView = false;
        waiversView =false;
        showleadstatustrackingpanel = false;
    }
    public void FetchPicklistValues(){
        typesOfReports = new list<selectoption>();
        leadTDY = new list<selectoption>();
        leadTDY.add(new selectoption('','--None--'));
        typesOfReports.add(new selectoption('','--None--'));
        list<string> reportTypes = new list<string>();
        reportTypes.addAll(system.label.DIA_Types_Of_Reports.split(','));
        for(string rt: reportTypes){
            if(currentUser.user_type__c == 'INV'){
                if(rt == 'Check-in/Check-out'){
                    typesOfReports.add(new selectoption(rt,rt)); 
                 }  
            } else{
                if(rt == 'Waiver/Extension'){
                    typesOfReports.add(new selectoption('Waivers',rt)); 
                }else{
                    typesOfReports.add(new selectoption(rt,rt)); 
                }
            }    
        }    
        caseStatus = new list<selectoption>();
        caseStatus.add(new selectoption('All','All'));
        for(String str: ApexUtil.getPickListValuesIntoList('DIA_Case__c', 'Status__c')){
            caseStatus.add(new selectoption(str,str));
        }
        caseTaskStatus = new list<selectoption>();
        caseTaskStatus.add(new selectoption('All','All'));
        for(String str: ApexUtil.getPickListValuesIntoList('DIA_Case__c', 'Current_Task__c')){
            if(str == 'Initiated State'){
                caseTaskStatus.add(new selectoption(str,str+' (UnAssigned)'));
            }
            if(str == 'Validate Transmission'){
                caseTaskStatus.add(new selectoption(str,str+' (Assigned)'));
            }
          
            if(str == 'Scoping' || str == 'Investigations' || str == 'Investigations Review' || str == 'QA and Review'){
                caseTaskStatus.add(new selectoption(str,str+' (In Progress)'));
            }
            if(str == 'QA Review Completed'){
                caseTaskStatus.add(new selectoption(str,str+' (Completed)'));
            }
            if(str == 'Discontinued'){
                caseTaskStatus.add(new selectoption(str,str));
            }
        }
        
        leadStatus = new list<selectoption>();
        leadStatus.add(new selectoption('All','All'));
        for(String str: ApexUtil.getPickListValuesIntoList('DIA_Lead__c', 'Status__c')){
            leadStatus.add(new selectoption(str,str));
        }
        for(String str: ApexUtil.getPickListValuesIntoList('DIA_Lead__c', 'Mark_As_TDY__c')){
            leadTDY.add(new selectoption(str,str));
        }
        
        messageTypeOptions = new list<selectoption>();
        messageTypeOptions.add(new selectoption('','--None--'));
        messageTypeOptions.add(new selectoption('Case Broadcast Message','Case Broadcast Message'));
        messageTypeOptions.add(new selectoption('General Broadcast Message','General Broadcast Message'));
        
    }
    public boolean fiveorlessitemsofcase = false;
    public void RunReportAction(){
    
        if(selectedReportType == 'ROIReport'){
            showViewButton = true;
            leadsView = false;
            casesView = false;
            messagesView = false;
            checkincheckoutView = false;
            waiversView =false;
            string documentPrefix =  DIA_document__c.sObjectType.getDescribe().getKeyPrefix();
            reports = new list<ReportRecord>();
            list<DIA_document__c> documents = new list<DIA_document__c>();
            list<attachment> attachments = new list<attachment>();
            string likeCondition = '%'+documentPrefix;
            string nameCondition = '%'+selectedReportType+'%';
            //fromDate = date.today();
            //toDate = date.today().addDays(31);
            
            List<string> documentFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            documentFields = ApexUtil.FetchFields('DIA_document__c'); 
            documentFields.add('case__r.Case_Number__c');
            documentFields.add('case__r.Extension_Due_Date__c');
            documentFields.add('case__r.Case_Due_Date__c');
            documentFields.add('case__r.Customer_Delivery_Date__c');
            documentFields.add('case__r.Case_Type__c');
            documentFields.add('case__r.Manifest__c');
            documentFields.add('case__r.Contact__r.First_Name__c');
            documentFields.add('case__r.Contact__r.Last_Name__c');
            documentFields.add('case__r.Assigned_to__r.FirstName');
            documentFields.add('case__r.Assigned_to__r.LastName');
            documentFields.add('case__r.Assigned_to__r.Name');
            documentFields.add('case__r.Current_Task__c');
            documentFields.add('case__r.status__c');
            documentFields.add('case__r.customer_Case_number__c'); 
            documentFields.add('case__r.Waiver_Due_Date__c');
            String query = 'Select '+string.join(documentFields, ',') + ' From DIA_document__c ';
            query = query + 'WHERE Name__c = \'ROIReport\'';
            if(string.isnotBlank(string.valueOf(fromDate))){
                Datetime fromDateTime = DateTime.newInstance(fromDate.year(), fromDate.month(),fromDate.day());
                query = query +' AND createddate >=:fromDateTime ';
            }
            if(string.isnotBlank(string.valueOf(toDate))){
                Datetime toDateTime = DateTime.newInstance(toDate.year(), toDate.month(),toDate.day());
                query = query +' and createddate <=:toDateTime ';
            }
            System.debug('query...'+query);
            documents = database.query(query);
            list<string> documentIds = new list<string>();
            for(DIA_document__c doc: documents){
                documentIds.add(doc.id);
            }
            attachments = [Select Id, ParentId, Name from Attachment where parentid in: documentIds];
            System.debug('attachments...'+attachments.size());
            Map<string,string> documentNattachmentMap = new Map<string,string>();
            for(attachment att: attachments){
                 documentNattachmentMap.put(att.parentId,att.id);   
            }
            for(DIA_document__c doc: documents){
                 string ingestiondate='';
                 if(doc.case__r.Manifest__c != null){
                     ingestiondate = string.valueof(date.parse(doc.case__r.Manifest__c));
                 }
                 string cmoUser = '';
                if(doc.case__r.Assigned_to__r.FirstName == null && doc.case__r.Assigned_to__r.LastName == null){
                    cmoUser = '';    
                }else{
                    cmoUser = doc.case__r.Assigned_to__r.FirstName+' '+doc.case__r.Assigned_to__r.LastName;    
                }
                 reports.add(new ReportRecord(doc.case__r.Contact__r.First_Name__c , doc.case__r.Contact__r.Last_Name__c,doc.case__r.Case_Number__c,doc.case__r.Customer_Case_Number__c,doc.case__r.Case_Due_Date__c,doc.case__r.Customer_Delivery_Date__c, doc.case__r.Case_Type__c,doc.case__r.status__c,doc.case__r.Current_Task__c,doc.case__r.Manifest__c,
                                             cmoUser, null, string.valueof(doc.createddate),doc.case__r.waiver_due_date__c,doc.case__r.extension_Due_Date__c,documentNattachmentMap.get(doc.id),null,null,null));  
            }
        } else if(selectedReportType == 'Case'){
            leadsView = false;
            casesView = true;
            messagesView = false;
            showViewButton = false;
            checkincheckoutView = false;
            waiversView =false;
            reports = new list<ReportRecord>();
            List<string> caseFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            caseFields = ApexUtil.FetchFields('DIA_Case__c');
            caseFields.add('contact__r.First_Name__c');
            caseFields.add('contact__r.Last_Name__c');
            caseFields.add('contact__r.Email__c');
            caseFields.add('Assigned_to__r.FirstName');
            caseFields.add('Assigned_to__r.LastName');
            String query =  'Select '+'(Select Id, Status__c from DIA_Leads__r where Status__c !=\'Completed\' AND Status__c !=\'QA Review Completed\')'+string.join(caseFields, ',') + ' From DIA_Case__c '; 
            if(selectedCaseTaskStatus != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Current_Task__c',selectedCaseTaskStatus,'='));
            }
            if(selectedCaseStatus != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Status__c',selectedCaseStatus,'='));
            }
            if(fromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Submission_Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Submission_Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            if(waiverAcceptedFromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Waiver_Approved_Date__c',String.valueof(waiverAcceptedFromDate), '>=', 'Date'));
            }
            if(waiverAcceptedToDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Waiver_Approved_Date__c',String.valueof(waiverAcceptedToDate), '<=', 'Date'));
            }
            if(extensionAcceptedFromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Extension_Approved_Date__c',String.valueof(extensionAcceptedFromDate), '>=', 'Date'));
            }
            if(extensionAcceptedToDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Extension_Approved_Date__c',String.valueof(extensionAcceptedToDate), '<=', 'Date'));
            }
            if(showonly90daysfromCaseClosed == true){
                whereCriteria.add(new ApexUtil.Criteria('Days_from_Date_Closed__c','90', '>=','Integer'));
            }
            if(selectedCMoUser != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c',selectedCMoUser, '='));    
            }
            
            
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            system.debug(where_cond);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Case__c WHERE '+ where_cond;
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Case__c';
            }
            
        totalRecordCount = database.countquery(Countquery);
        list<DIA_Case__c> Cases = new list<DIA_Case__c>();
        if(test.isRunningTest()){
            Cases = database.query('Select '+'(Select Id, Status__c from DIA_Leads__r where Status__c !=\'Completed\' AND Status__c !=\'QA Review Completed\')'+string.join(caseFields, ',') + ' From DIA_Case__c '); 
        }else{
            Cases = database.query(query);        
       }
            System.debug('query...'+query);
            //list<case__c> Cases = database.query(query); 
            integer i = 0;
            for(DIA_Case__c c: cases){
                if(i==0){
                    firstRecordName = c.Name;    
                }
                lastRecordName = c.Name;
                i++;
                
                if(fiveorlessitemsofcase){
                    integer leadsCount = c.DIA_leads__r.size();
                    if(leadsCount <=5 && leadsCount > 0){
                        string ingestiondate='';
                        
                         if(c.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(c.Manifest__c));
                         }
                         string cmoUser = '';
                        if(c.Assigned_to__r.FirstName == null && c.Assigned_to__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = c.Assigned_to__r.FirstName+' '+c.Assigned_to__r.LastName;    
                        }
                        reports.add(new ReportRecord(c.Contact__r.First_Name__c,c.Contact__r.Last_Name__c,c.Case_Number__c,c.customer_case_number__c,c.Case_Due_Date__c,c.Customer_Delivery_Date__c, c.Case_Type__c,c.status__c,c.Current_Task__c,c.Manifest__c,
                                             cmoUser, null,null,c.Waiver_Due_Date__c,c.extension_Due_Date__c, null,null,null,null));   
                    }
                }else{
                 string ingestiondate='';
                    
                    
                         if(c.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(c.Manifest__c));
                         }
                     string cmoUser = '';
                        if(c.Assigned_to__r.FirstName == null && c.Assigned_to__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = c.Assigned_to__r.FirstName+' '+c.Assigned_to__r.LastName;    
                        }
                 reports.add(new ReportRecord(c.Contact__r.First_Name__c,c.Contact__r.Last_Name__c,c.Case_Number__c,c.customer_case_number__c,c.Case_Due_Date__c,c.Customer_Delivery_Date__c, c.Case_Type__c,c.status__c,c.Current_Task__c,c.Manifest__c,
                                             cmoUser, null,null,c.Waiver_Due_Date__c,c.extension_Due_Date__c, null,null,null,null));   
                }
            
            }
            
            PageNumber = 1;
        double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
        double floorVal = Math.floor(totalNum);
        double diff = totalNum - floorVal;
        TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
        system.debug('TotalPages...'+TotalPages);
        if(totalRecordCount <= 200){
            disablePrev = true;
            disableNext = true;
            currentRecordCount = totalRecordCount;
        }else{
            disablePrev = true;   
            disableNext = false;
            currentRecordCount = 200; 
        }
              
        }else if(selectedReportType == 'Lead'){
            leadsView = true;
            casesView = false;
            messagesView = false;
            showViewButton = false;
            checkincheckoutView = false;
            waiversView =false;
            reports = new list<ReportRecord>();
            List<string> leadFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            leadFields = ApexUtil.FetchFields('DIA_Lead__c');
            leadFields.add('contact__r.First_Name__c');
            leadFields.add('contact__r.Last_Name__c');
            leadFields.add('contact__r.Email__c');
            leadFields.add('case__r.case_number__c');
            leadFields.add('case__r.Customer_Case_Number__c');
            leadFields.add('case__r.Case_Due_Date__c');
            leadFields.add('case__r.Customer_Delivery_Date__c');
            leadFields.add('case__r.Case_Type__c');
            leadFields.add('case__r.Manifest__c');
            leadFields.add('Assigned_to__r.FirstName');
            leadFields.add('Assigned_to__r.LastName');
            leadFields.add('case__r.Assigned_to__r.FirstName');
            leadFields.add('case__r.Assigned_to__r.LastName');
            leadFields.add('case__r.Current_Task__c');
            leadFields.add('case__r.Extension_Due_Date__c');
            leadFields.add('case__r.status__c');
            String query = 'Select '+string.join(leadFields, ',') + ' From DIA_Lead__c ';
            if(SelectedLeadStatus != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Status__c',SelectedLeadStatus,'='));
            }
            if(fromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Completed_Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Completed_Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            if(selectedInvestigatorUser != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c',selectedInvestigatorUser, '='));    
            }
            if(selectedCaseStatus != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Case__r.Status__c',selectedCaseStatus, '='));    
            }
            System.debug('SelectedCaseNumberForLeadSearch...'+SelectedCaseNumberForLeadSearch);
            if(String.isnotblank(SelectedCaseNumberForLeadSearch)){
                whereCriteria.add(new ApexUtil.Criteria('Case__r.Case_Number__c',SelectedCaseNumberForLeadSearch, '='));    
            }
            if(selectedcasestatus != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Case__r.Status__c',selectedcasestatus, '=')); 
            }
            if(showonly90daysfromQAcomplete == true){
                whereCriteria.add(new ApexUtil.Criteria('Days_from_QA_Review_Completed__c','90', '>=','Integer'));
            }
            if(selectedTDY != null){
                whereCriteria.add(new ApexUtil.Criteria('Mark_As_TDY__c', selectedTDY,'='));
            }
            
            
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            system.debug(where_cond);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Lead__c WHERE '+ where_cond;
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Lead__c';
            }
            
        totalRecordCount = database.countquery(Countquery);
        list<DIA_Lead__c> Leads = new list<DIA_Lead__c>();
        if(test.isRunningTest()){
            Leads = database.query('Select '+string.join(leadFields, ',') + ' From DIA_Lead__c ');   
        }else{
            Leads = database.query(query);        
       }
            System.debug('query...'+query);
            //list<case__c> Cases = database.query(query); 
            integer i = 0;
            for(DIA_Lead__c lead: Leads){
                
                String sourceName = '';
                if(lead.Source_First_Name__c != Null){
                    sourceName = lead.Source_First_Name__c;
                }
                if(lead.Source_Last_Name__c != Null){
                    sourceName =lead.Source_First_Name__c + ' ' +lead.Source_Last_Name__c;
                }
                string contactMethod;
                if(lead.LeadType__c == 'Employment (EMPL)' && lead.Coverage_Type__c == 'Record'){
                    contactMethod = lead.Employment_Contact_Method__c;
                } 
                if(lead.LeadType__c == 'Former Spouse (FMSP)' || lead.LeadType__c == 'References (REFE)'|| (lead.LeadType__c == 'Residence (RESI)' && lead.Coverage_Type__c == 'Personal') || (lead.LeadType__c == 'Unemployment' && lead.Coverage_Type__c == 'Personal') || (lead.LeadType__c == 'General (GENL)' && lead.Coverage_Type__c == 'Personal') || (lead.LeadType__c == 'Education (EDUC)' && lead.Coverage_Type__c == 'Personal') || (lead.LeadType__c == 'Employment (EMPL)' && lead.Coverage_Type__c == 'Personal')){
                    contactMethod = lead.Personal_Contact_Method__c;
                }
                if((lead.LeadType__c == 'Medical (MEDI)' && lead.Coverage_Type__c == 'Record')||
                    (lead.LeadType__c == 'Medical (MEDI)' && lead.Coverage_Type__c == 'Personal')||
                    (lead.LeadType__c == 'Education (EDUC)' && lead.Coverage_Type__c == 'Record')||
                    (lead.LeadType__c == 'Law Enforcement (LAWE)' && lead.Coverage_Type__c == 'Record')||
                    (lead.LeadType__c == 'Public records (PUBR)' && lead.Coverage_Type__c == 'Record')||
                    (lead.LeadType__c == 'General (GENL)' && lead.Coverage_Type__c == 'Record') || 
                    (lead.LeadType__c == 'Financial (FINL)'  && lead.Coverage_Type__c == 'Record')|| 
                    (lead.LeadType__c == 'Education (EDUC)' && lead.Coverage_Type__c == 'General Record') || 
                    (lead.LeadType__c == 'Employment (EMPL)' && lead.Coverage_Type__c == 'General Record') || 
                    (lead.LeadType__c == 'Unemployment' && lead.Coverage_Type__c == 'General Record') || 
                    (lead.LeadType__c == 'Residence (RESI)' && lead.Coverage_Type__c == 'General Record') || 
                    (lead.LeadType__c == 'Law Enforcement (LAWE)' && lead.Coverage_Type__c == 'General Record') || 
                    (lead.LeadType__c == 'Public records (PUBR)' && lead.Coverage_Type__c == 'General Record') || 
                    (lead.LeadType__c == 'Financial (FINL)' && lead.Coverage_Type__c == 'General Record') || 
                    (lead.LeadType__c == 'Medical (MEDI)' && lead.Coverage_Type__c == 'General Record')){
                        contactMethod = lead.Contact_Method__c; 
                 }
                 string ingestiondate='';
                         if(lead.case__r.Manifest__c!= null){
                             ingestiondate = string.valueof(date.parse(lead.case__r.Manifest__c));
                         }
                        string cmoUser = '';
                
                        if(lead.case__r.Assigned_to__r.FirstName == null && lead.case__r.Assigned_to__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = lead.case__r.Assigned_to__r.FirstName+' '+lead.case__r.Assigned_to__r.LastName;    
                        }
                 reports.add(new ReportRecord(lead.Contact__r.First_Name__c,lead.Contact__r.Last_Name__c,lead.case__r.Case_Number__c,lead.case__r.Case_Due_Date__c,lead.case__r.extension_Due_Date__c,lead.case__r.Customer_Delivery_Date__c, lead.case__r.Customer_Case_Number__c,lead.case__r.status__c, lead.case__r.Current_Task__c,lead.case__r.Manifest__c,
                                             cmoUser, lead.Assigned_to__r.FirstName+' '+lead.Assigned_to__r.LastName, string.valueof(lead.Completed_Date__c),null, lead.leadType__c, lead.status__c,
                                             integer.valueof(lead.Item_Number__c),sourceName,lead.Lead_Contact_Name__c,lead.Lead_Contact_Address__c
                                             ,lead.Lead_Contact_City__c,lead.Lead_Contact_State__c,lead.Lead_Contact_Zip__c,
                                             lead.Lead_Contact_Other_Information__c, lead.Anticipated_Completion_Date__c,
                                             lead.coverage_type__c, lead.Assignee_Date__c, string.valueof(lead.Id),contactMethod,lead.price__c,lead.Days_from_QA_Review_Completed__c,lead.createdDate));  
                                             
                                             
                                             
              
                
                if(i==0){
                    firstRecordName = lead.Name;    
                }
                lastRecordName = lead.Name;
                i++;
                
                
            }
            
        PageNumber = 1;
        double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
        double floorVal = Math.floor(totalNum);
        double diff = totalNum - floorVal;
        TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
        system.debug('TotalPages...'+TotalPages);
        if(totalRecordCount <= 200){
            disablePrev = true;
            disableNext = true;
            currentRecordCount = totalRecordCount;
        }else{
            disablePrev = true;   
            disableNext = false;
            currentRecordCount = 200; 
        }
            System.debug('leadsView..'+leadsView);
        }else if(selectedReportType == 'Messages'){
            leadsView = false;
            casesView = false;
            messagesView = true;
            showViewButton = false;
            checkincheckoutView = false;
            waiversView =false;
            reports = new list<ReportRecord>();
            List<string> messsageFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            messsageFields = ApexUtil.FetchFields('DIA_message__c');
            messsageFields.add('case__r.case_number__c');
            messsageFields.add('case__r.Case_Due_Date__c');
            messsageFields.add('case__r.Customer_Delivery_Date__c');
            messsageFields.add('From_User__r.FirstName');
            messsageFields.add('From_User__r.LastName');
            messsageFields.add('To_User__r.FirstName');
            messsageFields.add('To_User__r.LastName');
            messsageFields.add('cc_User__r.FirstName');
            messsageFields.add('cc_User__r.LastName');
            String query = 'Select '+string.join(messsageFields, ',') + ' From DIA_message__c ';
            if(selectedMessageType == 'Case Broadcast Message' ){
                if(SelectedRelatedCaseIdForMessages != Null){
                    whereCriteria.add(new ApexUtil.Criteria('case__c',SelectedRelatedCaseIdForMessages,'='));
                }
            }else{
                whereCriteria.add(new ApexUtil.Criteria('case__c','','='));
            }
             if(fromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('MessageCreatedDate__c',string.valueOf(fromDate), '>=','Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('MessageCreatedDate__c',string.valueOf(toDate), '<=','Date'));
            }
            
                        
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            system.debug(where_cond);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_message__c WHERE '+ where_cond;
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_message__c';
            }
                system.debug('countQuery...'+query);
                system.debug('countQuery...'+countQuery);
                totalRecordCount = database.countquery(Countquery);
                list<DIA_message__c> messages = new list<DIA_message__c>();
                if(test.isRunningTest()){
                    messages = database.query('Select '+string.join(messsageFields, ',') + ' From DIA_message__c '  );   
                }else{
                    messages = database.query(query);        
               }
                integer i = 0;
                for(DIA_message__c message: messages){
                    reports.add(new ReportRecord(message));
                    if(i==0){
                        firstRecordName = message.Name;    
                    }
                    lastRecordName = message.Name;
                    i++;
                }
                PageNumber = 1;
                double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
                double floorVal = Math.floor(totalNum);
                double diff = totalNum - floorVal;
                TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
                system.debug('TotalPages...'+TotalPages);
                if(totalRecordCount <= 200){
                    disablePrev = true;
                    disableNext = true;
                    currentRecordCount = totalRecordCount;
                }else{
                    disablePrev = true;   
                    disableNext = false;
                    currentRecordCount = 200; 
                }
        }
        else if(selectedReportType == 'Check-in/Check-out'){
            leadsView = false;
            casesView = false;
            messagesView = false;
            showViewButton = false;
            checkincheckoutView = true;
            waiversView =false;
            reports = new list<ReportRecord>();
            List<string> checkinCheckoutFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            checkinCheckoutFields = ApexUtil.FetchFields('DIA_Investigator_Check__c');
            checkinCheckoutFields.add('TimeSheet__r.Date__c');
            checkinCheckoutFields.add('TimeSheet__r.CheckIn_Comments__c');
            checkinCheckoutFields.add('TimeSheet__r.User__r.FirstName');
            checkinCheckoutFields.add('TimeSheet__r.User__r.LastName');
           
            String query = 'Select '+string.join(checkinCheckoutFields, ',') + ' From DIA_Investigator_Check__c ';
            whereCriteria.add(new ApexUtil.Criteria('Type__c', 'CheckOut', '='));
            if(currentUser.user_type__c == 'INV'){
                whereCriteria.add(new ApexUtil.Criteria('TimeSheet__r.User__c', userinfo.getuserid(), '='));
            }
            if(fromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('TimeSheet__r.Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('TimeSheet__r.Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            system.debug(where_cond);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Investigator_Check__c WHERE '+ where_cond;
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Investigator_Check__c';
            }
            
                totalRecordCount = database.countquery(Countquery);
                list<DIA_Investigator_Check__c> invChecks = new list<DIA_Investigator_Check__c>();
                if(test.isRunningTest()){
                    invChecks = database.query('Select '+string.join(checkinCheckoutFields, ',') + ' From DIA_Investigator_Check__c ');   
                }else{
                    invChecks = database.query(query);        
               }
                integer i = 0;
                for(DIA_Investigator_Check__c invCheck: invChecks){
                    reports.add(new ReportRecord(invCheck));
                    if(i==0){
                        firstRecordName = invCheck.Name;    
                    }
                    lastRecordName = invCheck.Name;
                    i++;
                }
                PageNumber = 1;
                double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
                double floorVal = Math.floor(totalNum);
                double diff = totalNum - floorVal;
                TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
                system.debug('TotalPages...'+TotalPages);
                if(totalRecordCount <= 200){
                    disablePrev = true;
                    disableNext = true;
                    currentRecordCount = totalRecordCount;
                }else{
                    disablePrev = true;   
                    disableNext = false;
                    currentRecordCount = 200; 
                }
        } else if(selectedReportType == 'Waivers'){
            leadsView = false;
            casesView = false;
            messagesView = false;
            showViewButton = false;
            checkincheckoutView = false;
            waiversView = true;
            reports = new list<ReportRecord>();
            List<string> waiverFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            waiverFields = ApexUtil.FetchFields('DIA_Waiver_Information__c');
            waiverFields.add('Case__r.Case_Number__c');
            waiverFields.add('Case__r.Customer_Case_Number__c');
            waiverFields.add('case__r.Case_Due_Date__c');
            waiverFields.add('case__r.Customer_Delivery_Date__c');
            waiverFields.add('Case__r.Assigned_To_Name__c');
            waiverFields.add('Lead__r.Assigned_To_Name__c');
            String query = 'Select '+string.join(waiverFields, ',') + ' From DIA_Waiver_Information__c ';
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            system.debug(where_cond);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Waiver_Information__c WHERE '+ where_cond;
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Waiver_Information__c';
            }
            
                totalRecordCount = database.countquery(Countquery);
                list<DIA_Waiver_Information__c> waivers = new list<DIA_Waiver_Information__c>();
                if(test.isRunningTest()){
                    waivers = database.query('Select '+string.join(waiverFields, ',') + ' From DIA_Waiver_Information__c ');   
                }else{
                    waivers = database.query(query);        
               }
                integer i = 0;
                for(DIA_Waiver_Information__c waiver: waivers){
                    reports.add(new ReportRecord(waiver));
                    if(i==0){
                        firstRecordName = waiver.Name;    
                    }
                    lastRecordName = waiver.Name;
                    i++;
                }
                PageNumber = 1;
                double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
                double floorVal = Math.floor(totalNum);
                double diff = totalNum - floorVal;
                TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
                system.debug('TotalPages...'+TotalPages);
                if(totalRecordCount <= 200){
                    disablePrev = true;
                    disableNext = true;
                    currentRecordCount = totalRecordCount;
                }else{
                    disablePrev = true;   
                    disableNext = false;
                    currentRecordCount = 200; 
                }
        }
        else if(selectedReportType == 'Investigator Reports'){
            reports = new list<ReportRecord>();
            List<string> productionSummaryFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            productionSummaryFields = ApexUtil.FetchFields('DIA_Daily_Production_Summary__c');
            String query = 'Select '+string.join(productionSummaryFields, ',') + ' From DIA_Daily_Production_Summary__c ';
            if(fromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Summary_Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Summary_Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
            query = query + ' WHERE '+where_cond; 
            System.debug('query...'+query);
            list< DIA_Daily_Production_Summary__c > productionSummaries = database.query(query);
            Map<string,Decimal> leadsAccepted = new Map<string,Decimal>();
            Map<string,Decimal> leadsRejected = new Map<string,Decimal>();
            Map<string,Decimal> leadsCompleted = new Map<string,Decimal>();
            set<string> reviewerIds = new set<String>();
            for(DIA_Daily_Production_Summary__c dps:productionSummaries ){
                if(!leadsAccepted.containsKey(dps.reviewer__c)){
                    leadsAccepted.put(dps.reviewer__c,dps.Leads_Accepted__c);
                }else{
                    leadsAccepted.put(dps.reviewer__c,leadsAccepted.get(dps.reviewer__c)+dps.Leads_Accepted__c);
                }
                if(!leadsRejected.containsKey(dps.reviewer__c)){
                    leadsRejected.put(dps.reviewer__c,dps.Leads_Rejected__c);
                }else{
                    leadsRejected.put(dps.reviewer__c,leadsRejected.get(dps.reviewer__c)+dps.Leads_Rejected__c);
                }
                if(!leadsCompleted.containsKey(dps.reviewer__c)){
                    leadsCompleted.put(dps.reviewer__c,dps.Leads_Completed__c);
                }else{
                    leadsCompleted.put(dps.reviewer__c,leadsCompleted.get(dps.reviewer__c)+dps.Leads_Completed__c);
                }
                reviewerIds.add(dps.reviewer__C);
            }
            Map<string,user> userMap = new Map<String,user>([select id, firstname,lastname from user where id in:reviewerIds]);
            
            for(string reviewerId : reviewerIds){
                reports.add(new ReportRecord(userMap.get(reviewerId).FirstName+' '+userMap.get(reviewerId).LastName,
                            Integer.valueof(leadsAccepted.get(reviewerId)),Integer.valueof(leadsRejected.get(reviewerId)),Integer.valueof(leadsCompleted.get(reviewerId))
                            ));    
            }
            
        }
        showreportstable = true;
        fromDate = null;
        toDate = null;
    }
    public boolean showleadstatustrackingpanel{get;set;}
    public void FetchLeadStatusTrackings(){
        System.debug('selectedleadforstatustracking...'+selectedleadforstatustracking);
        leadStatusTrackings = new list< LeadHistoryRecord >();
            List<string> leadStatusTrackingFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            leadStatusTrackingFields = ApexUtil.FetchFields('DIA_Lead__History');
            leadStatusTrackingFields.add('createdby.name');
            leadStatusTrackingFields.add('createdby.firstname');
            leadStatusTrackingFields.add('createdby.lastname');
            String query = 'Select '+string.join(leadStatusTrackingFields, ',') + ' From DIA_Lead__History ';
            whereCriteria.add(new ApexUtil.Criteria('parentid', selectedleadforstatustracking, '='));
            whereCriteria.add(new ApexUtil.Criteria('field','status__C', '='));
            
            DIA_Lead__c lead = [select id,createddate from DIA_Lead__c where id=:selectedleadforstatustracking];
          
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            if(string.isNotBlank(where_cond)){
                 query = query + ' WHERE '+where_cond + ' Order By CreatedDate ASC';  
            }  
           
            System.debug('query...'+query);
            lisT<DIA_Lead__History> leadhHistories =  database.query(query);
            integer i =0;
            for(DIA_Lead__History lh: leadhHistories){
                integer daysBetween;
                if(i == 0){
                    daysBetween = lead.createddate.date().daysBetween(lh.createddate.date());
                    
                }else{
                    daysBetween = leadhHistories[i-1].createddate.date().daysBetween(lh.createddate.date());
                }
                leadStatusTrackings.add(new LeadHistoryRecord(lh,daysBetween));
                i++;
            }
            showleadstatustrackingpanel = true;
    }
    
    public void OnReportTypeSelect(){
        if(selectedReportType == 'Case'){
            cmoUsers = new list<selectoption>();
            cmoUsers.add(new selectoption('All','All'));
            list<User> users = [Select Id, name, system_access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'CMO' order by LastName];
            for(user u: users){
                if(u.system_access__c.contains('DIA')){
                cmoUsers.add(new selectoption(u.id,u.LastName+' '+u.FirstName)); 
                }
            }
        }
        if(selectedReportType == 'Lead'){
            investigatorUsers = new list<selectoption>();
            investigatorUsers.add(new selectoption('All','All'));
            list<string> userTypesEligibleForLeadAssignment = new list<string>();
            list< User_Permission__mdt > userPermissions = [select id, user_type__c, LeadDashboard_Assignment_IncludeUsers__c  from
                                                           User_Permission__mdt where LeadDashboard_Assignment_IncludeUsers__c = true];
            for(User_Permission__mdt up: userPermissions){
                userTypesEligibleForLeadAssignment.add(up.user_type__c);    
            }
            
            list<User> users = [Select Id, name, system_access__c, FirstName, LastName, user_type__c from User Where user_type__c IN : userTypesEligibleForLeadAssignment order by LastName];
            for(user u: users){
                if(u.system_access__c.contains('DIA')){
                investigatorUsers.add(new selectoption(u.id,u.LastName+' '+u.FirstName));  
                }
            }
        }
        if(selectedReportType == 'Messages'){
            relatedCasesForMessages = new list<selectoption>();
            relatedCasesForMessages.add(new selectoption('','--None--'));
            list<DIA_Case__c> cases = [Select Id,case_number__c From DIA_Case__c where case_number__c != NULL];
            for(DIA_Case__c c: cases){
                relatedCasesForMessages.add(new selectoption(c.id,c.case_number__c));   
            }
        }
        showreportstable = false;
       
    }
    
    Public Class ReportRecord {
        public string subjectFirstName{get;set;}
        public string subjectLastName{get;set;}
        public string caseNumber{get;set;}
        public date caseDueDate{get;set;}
        public date customerDeliveryDate{get;set;}
        public string caseType{get;set;}
        public string caseStatus{get;set;}
        public string caseTaskStatus {Get;set;}
        public string manifest{get;set;}
        public string cmoUser{get;set;}
        public string investigatorUser{get;set;}
        public string rDate{get;set;}
        public string attachmentId {get;set;}
        public string leadType {get;set;}
        public string leadStatus {get;set;}
        public DIA_message__c message {get;set;}
        public DIA_Investigator_Check__c investigatorCheck {get;set;}
        public DIA_Waiver_Information__c waiver {get;set;}
        public string investigatorName {get;set;}
        public integer leadsAccepted {get;set;}
        public integer leadsRejected {get;set;}
        public integer leadsCompleted {get;set;}
        public integer leadItemNumber {get;set;}
        public string leadContactInformation {get;set;}
        public string leadSourceName {get;set;}
        public decimal leadPrice {get;set;}
        public string leadcontactName {get;set;}
        public string leadcontactAddress {get;set;}
        public string leadcontactCity {get;set;}
        public string leadcontactState {get;set;}
        public string leadcontactZip {get;set;}
        public string leadcontactOtherInformation {get;set;}
        public date AnticipatedCompletedDate{get;set;}
        public string coverageType{get;set;}
        public date assignmentDate {get;set;}
        public string leadId {get;set;}
        public string leadContactMethod {get;set;}
        public date waiverduedate {get;set;}
        public string customercasenumber {get;set;}
        public date extensionDueDate{get;set;}
        public decimal  daysfromqacompleted{get;set;}
        public datetime createdDate{get;set;}
        public ReportRecord(DIA_message__c message){
            this.message = message;
        }
        public ReportRecord(DIA_Investigator_Check__c investigatorCheck){
            this.investigatorCheck = investigatorCheck;
        }
        public ReportRecord(DIA_Waiver_Information__c waiver){
            this.waiver = waiver;
        }
        public ReportRecord(string investigatorName, integer leadsAccepted, integer leadsRejected, integer leadsCompleted){
            this.investigatorName = investigatorName;
            this.leadsAccepted = leadsAccepted;
            this.leadsRejected = leadsRejected;
            this.leadsCompleted = leadsCompleted;
        }
        
        
        public ReportRecord(string subjectFirstName,string subjectLastName, string caseNumber, string customercasenumber, date caseDueDate, date customerDeliveryDate, string caseType, string caseStatus, string caseTaskStatus, string manifest, string cmoUser, string investigatorUser,
                            string rDate,date waiverduedate,date extensionDueDate,  string attachmentId, string leadType, string leadStatus,string leadId){
            this.subjectFirstName = subjectFirstName;
            this.subjectLastName = subjectLastName;
            this.caseNumber = caseNumber;
            this.customercasenumber = customercasenumber;
            this.caseDueDate = caseDueDate;
            this.customerDeliveryDate = customerDeliveryDate;
            this.caseType = caseType;
            this.caseStatus = caseStatus;
            this.caseTaskStatus = caseTaskStatus;
            this.manifest = manifest;
            this.cmoUser = cmoUser;
            this.investigatorUser = investigatorUser;
            this.rDate = rDate;
            this.waiverduedate = waiverduedate;
            this.extensionDueDate= extensionDueDate;
            this.attachmentId = attachmentId;
            this.leadType = leadType;
            this.leadStatus = leadStatus;
            
        }
        
        public ReportRecord(string subjectFirstName,string subjectLastName, string caseNumber, date caseDueDate,date extensionDueDate, date customerDeliveryDate,string customercaseNumber, string caseStatus, string caseTaskStatus,string manifest, string cmoUser, string investigatorUser,
                            string rDate, string attachmentId, string leadType, string leadStatus, integer leadItemNumber, string leadSourceName,
                            string leadcontactName, string leadContactAddress, string leadContactCity, string leadContactState, string leadContactZip,
                            string leadContactOtherInformation, date AnticipatedCompletedDate, string coverageType, date assignmentDate, string leadId, string leadContactMethod,decimal leadPrice,decimal daysfromqacompleted,datetime createdDate){

            this.subjectFirstName = subjectFirstName;
            this.subjectLastName = subjectLastName;
            this.caseNumber = caseNumber;
            this.caseDueDate = caseDueDate;
            this.extensionDueDate = extensionDueDate;
            this.customerDeliveryDate = customerDeliveryDate;
            this.customercaseNumber = customercaseNumber;
            this.caseStatus = caseStatus;
            this.caseTaskStatus = caseTaskStatus;
            this.manifest = manifest;
            this.cmoUser = cmoUser;
            this.investigatorUser = investigatorUser;
            this.rDate = rDate;
            this.attachmentId = attachmentId;
            this.leadType = leadType;
            this.leadStatus = leadStatus;
            this.leadItemNumber = leadItemNumber;
            this.leadContactInformation = leadContactInformation;
            this.leadSourceName = leadSourceName;
            this.leadcontactName = leadcontactName;
            this.leadContactAddress = leadContactAddress;
            this.leadContactCity= leadContactCity;
            this.leadContactState = leadContactState;
            this.leadContactZip = leadContactZip;
            this.leadContactOtherInformation= leadContactOtherInformation;
            this.AnticipatedCompletedDate = AnticipatedCompletedDate;
            this.coverageType = coverageType;
            this.assignmentdate = assignmentDate;
            this.leadId = leadId;
            this.leadContactMethod = leadContactMethod;
            this.leadPrice = leadPrice;
            this.daysfromqacompleted = daysfromqacompleted;
            this.createdDate = createdDate;
            this.customercaseNumber = customercaseNumber;
        }
    }

        public void handlePrev(){
        System.debug('queryForNextRecords...'+queryForNextRecords);
        system.debug('firstRecordName....'+firstRecordName);//7474
        system.debug('lastRecordName....'+lastRecordName);//7972
         system.debug('currentRecordCount....'+currentRecordCount);
        PageNumber --;
        reports = new list<ReportRecord>();
            list<dia_Case__c> Cases = new list<dia_Case__c>();
        string query = queryForNextRecords + ' Name <:firstRecordName  Order by Name desc Limit 200';
        if(selectedReportType == 'Case'){
            if(Test.isrunningtest()){
                List<string> caseFields = new List<string>();
            caseFields = ApexUtil.FetchFields('DIA_Case__c');
            caseFields.add('contact__r.First_Name__c');
            caseFields.add('contact__r.Last_Name__c');
            caseFields.add('contact__r.Email__c');
            caseFields.add('Assigned_to__r.FirstName');
            caseFields.add('Assigned_to__r.LastName');
                Cases = database.query('Select '+'(Select Id, Status__c from DIA_Leads__r where Status__c !=\'Completed\' AND Status__c !=\'QA Review Completed\')'+string.join(caseFields, ',') + ' From DIA_Case__c ');
            }else{
                Cases = database.query(query);
            }
            
            integer i = 0;
            for(Integer j=Cases.size()-1;j>=0; j--){
                dia_Case__c c = Cases[j];
                if(fiveorlessitemsofcase){
                    integer leadsCount = c.DIA_leads__r.size();
                    if(leadsCount <=5 && leadsCount > 0){
                        string ingestiondate='';
                        
                         if(c.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(c.Manifest__c));
                         }
                        string cmoUser = '';
                
                        if(c.Assigned_to__r.FirstName == null && c.Assigned_to__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = c.Assigned_to__r.FirstName+' '+c.Assigned_to__r.LastName;    
                        }
                        reports.add(new ReportRecord(c.Contact__r.First_Name__c,c.Contact__r.Last_Name__c,c.Case_Number__c,c.customer_case_number__c,c.Case_Due_Date__c,c.Customer_Delivery_Date__c, c.Case_Type__c,c.status__c,c.Current_Task__c,c.Manifest__c,
                                             cmoUser, null,null,c.Waiver_Due_Date__c,c.extension_Due_Date__c, null,null,null,null));      
               
                    }
                }else{
                 string ingestiondate='';
                    
                         if(c.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(c.Manifest__c));
                         }
                     string cmoUser = '';
                     if(c.Assigned_to__r.FirstName == null && c.Assigned_to__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = c.Assigned_to__r.FirstName+' '+c.Assigned_to__r.LastName;    
                        }
                 reports.add(new ReportRecord(c.Contact__r.First_Name__c,c.Contact__r.Last_Name__c,c.Case_Number__c,c.customer_case_number__c,c.Case_Due_Date__c,c.Customer_Delivery_Date__c, c.Case_Type__c,c.status__c,c.Current_Task__c,c.Manifest__c,
                                             cmoUser, null,null,c.Waiver_Due_Date__c,c.extension_Due_Date__c, null,null,null,null));         
                }
                if(j==Cases.size()-1){
                    firstRecordName = Cases[j].Name;       
                }
                lastRecordName = Cases[j].Name; 
                
            }
        }
        if(selectedReportType == 'Messages'){
            list<DIA_Message__c> messages = database.query(query);
            integer i = 0;
            for(Integer j=messages.size()-1;j>=0; j--){
                DIA_Message__c message = messages[j];
                reports.add(new ReportRecord(message));
                if(j==messages.size()-1){
                    firstRecordName = messages[j].Name;       
                }
                lastRecordName = messages[j].Name;
            }
        }
        if(selectedReportType == 'Lead'){
            list<DIA_Lead__c> Leads = New list<DIA_Lead__c>();
            if(Test.isrunningTest()){
                List<string> leadFields = new List<string>();
                leadFields = ApexUtil.FetchFields('DIA_Lead__c');
                leadFields.add('contact__r.First_Name__c');
                leadFields.add('contact__r.Last_Name__c');
                leadFields.add('contact__r.Email__c');
                leadFields.add('case__r.case_number__c');
                leadFields.add('case__r.Customer_Case_Number__c');
                leadFields.add('case__r.Case_Due_Date__c');
                leadFields.add('case__r.Customer_Delivery_Date__c');
                leadFields.add('case__r.Case_Type__c');
                leadFields.add('case__r.Manifest__c');
                leadFields.add('Assigned_to__r.FirstName');
                leadFields.add('Assigned_to__r.LastName');
                leadFields.add('case__r.Assigned_to__r.FirstName');
                leadFields.add('case__r.Assigned_to__r.LastName');
                    leadFields.add('case__r.Extension_Due_Date__c');
                leadFields.add('case__r.Current_Task__c');
                leadFields.add('case__r.status__c');
                Leads = database.query('Select '+string.join(leadFields, ',') + ' From DIA_Lead__c ');
            }else{
                Leads = database.query(query);
            }
            
            //list<DIA_Lead__c> Leads = database.query(query);
            integer i = 0;
            for(Integer j=Leads.size()-1;j>=0; j--){
                DIA_Lead__c Lead = Leads[j];
                String sourceName = '';
                    if(lead.Source_First_Name__c != Null){
                        sourceName = lead.Source_First_Name__c;
                    }
                    if(lead.Source_Last_Name__c != Null){
                        sourceName =lead.Source_First_Name__c + ' ' +lead.Source_Last_Name__c;
                    }
                    string contactMethod;
                    if(lead.LeadType__c == 'Employment (EMPL)' && lead.Coverage_Type__c == 'Record'){
                        contactMethod = lead.Employment_Contact_Method__c;
                    } 
                    if(lead.LeadType__c == 'Former Spouse (FMSP)' || lead.LeadType__c == 'References (REFE)'|| (lead.LeadType__c == 'Residence (RESI)' && lead.Coverage_Type__c == 'Personal') || (lead.LeadType__c == 'Unemployment' && lead.Coverage_Type__c == 'Personal') || (lead.LeadType__c == 'General (GENL)' && lead.Coverage_Type__c == 'Personal') || (lead.LeadType__c == 'Education (EDUC)' && lead.Coverage_Type__c == 'Personal') || (lead.LeadType__c == 'Employment (EMPL)' && lead.Coverage_Type__c == 'Personal')){
                        contactMethod = lead.Personal_Contact_Method__c;
                    }
                    if((lead.LeadType__c == 'Medical (MEDI)' && lead.Coverage_Type__c == 'Record')||
                        (lead.LeadType__c == 'Medical (MEDI)' && lead.Coverage_Type__c == 'Personal')||
                        (lead.LeadType__c == 'Education (EDUC)' && lead.Coverage_Type__c == 'Record')||
                        (lead.LeadType__c == 'Law Enforcement (LAWE)' && lead.Coverage_Type__c == 'Record')||
                        (lead.LeadType__c == 'Public records (PUBR)' && lead.Coverage_Type__c == 'Record')||
                        (lead.LeadType__c == 'General (GENL)' && lead.Coverage_Type__c == 'Record') || 
                        (lead.LeadType__c == 'Financial (FINL)'  && lead.Coverage_Type__c == 'Record')|| 
                        (lead.LeadType__c == 'Education (EDUC)' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Employment (EMPL)' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Unemployment' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Residence (RESI)' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Law Enforcement (LAWE)' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Public records (PUBR)' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Financial (FINL)' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Medical (MEDI)' && lead.Coverage_Type__c == 'General Record')){
                            contactMethod = lead.Contact_Method__c; 
                     }
                     string ingestiondate='';
                         if(lead.case__r.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(lead.case__r.Manifest__c));
                         }
                  string cmoUser = '';
                
                        if(lead.case__r.Assigned_to__r.FirstName == null && lead.case__r.Assigned_to__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = lead.case__r.Assigned_to__r.FirstName+' '+lead.case__r.Assigned_to__r.LastName;    
                        }

                     reports.add(new ReportRecord(lead.Contact__r.First_Name__c,lead.Contact__r.Last_Name__c,lead.case__r.Case_Number__c,lead.case__r.Case_Due_Date__c,lead.case__r.extension_Due_Date__c,lead.case__r.Customer_Delivery_Date__c, lead.case__r.Customer_Case_Number__c,lead.case__r.status__c, lead.case__r.Current_Task__c,lead.case__r.Manifest__c,
                                                 lead.case__r.Assigned_to__r.FirstName+' '+lead.case__r.Assigned_to__r.LastName, lead.Assigned_to__r.FirstName+' '+lead.Assigned_to__r.LastName, string.valueof(lead.Completed_Date__c),null, lead.leadType__c, lead.status__c,
                                                 integer.valueof(lead.Item_Number__c),sourceName,lead.Lead_Contact_Name__c,lead.Lead_Contact_Address__c
                                                 ,lead.Lead_Contact_City__c,lead.Lead_Contact_State__c,lead.Lead_Contact_Zip__c,
                                                 lead.Lead_Contact_Other_Information__c,lead.Anticipated_Completion_Date__c,
                                                 lead.coverage_type__c, lead.Assignee_Date__c, string.valueof(lead.Id),contactMethod,lead.price__c,lead.Days_from_QA_Review_Completed__c,lead.createdDate));  
                                                 
                                                 
                                               
                  
                if(j==Leads.size()-1){
                    firstRecordName = Leads[j].Name;       
                }
                lastRecordName = Leads[j].Name; 
            }
        }
        if(selectedReportType == 'Check-in/Check-out'){
            list<DIA_Investigator_Check__c> INVChecks = database.query(query);
            integer i = 0;
            for(Integer j=INVChecks.size()-1;j>=0; j--){
                DIA_Investigator_Check__c INVCheck = INVChecks[j];
                reports.add(new ReportRecord(invCheck));
                if(j==INVChecks.size()-1){
                    firstRecordName = INVChecks[j].Name;       
                }
                lastRecordName = INVChecks[j].Name;
            }            
        }
        if(selectedReportType == 'Waivers'){
            list<DIA_Waiver_Information__c> waivers = database.query(query);
            integer i = 0;
            for(Integer j=waivers.size()-1;j>=0; j--){
                DIA_Waiver_Information__c waiver = waivers[j];
                reports.add(new ReportRecord(waiver));
                if(j==waivers.size()-1){
                    firstRecordName = waivers[j].Name;       
                }
                lastRecordName = waivers[j].Name;
            }   
        }
        if(selectedReportType == 'Investigator Reports'){
            
        }
        
        if(pageNumber == 1){
            disablePrev = true;
            disableNext = false ;
        }else{
            disablePrev = false;
            disableNext = false;
        }
        system.debug('firstRecordName....'+firstRecordName);
        system.debug('lastRecordName....'+lastRecordName);
        system.debug('currentRecordCount....'+currentRecordCount);
    }
    public void handleNext(){
        PageNumber ++ ;
        reports = new list<ReportRecord>();
        System.debug('queryForNextRecords...'+queryForNextRecords);
        system.debug('lastRecordName....'+lastRecordName);
        string query = queryForNextRecords + ' Name >:lastRecordName  Order by Name asc Limit 200';    
        System.debug('query...'+query);
        
        if(selectedReportType == 'Case'){
            list<DIA_Case__c> Cases = New list<DIA_Case__c>();
            if(Test.isrunningtest()){
                List<string> caseFields = new List<string>();
            caseFields = ApexUtil.FetchFields('DIA_Case__c');
            caseFields.add('contact__r.First_Name__c');
            caseFields.add('contact__r.Last_Name__c');
            caseFields.add('contact__r.Email__c');
            caseFields.add('Assigned_to__r.FirstName');
            caseFields.add('Assigned_to__r.LastName');
                Cases = database.query('Select '+'(Select Id, Status__c from DIA_Leads__r where Status__c !=\'Completed\' AND Status__c !=\'QA Review Completed\')'+string.join(caseFields, ',') + ' From DIA_Case__c ');
            }else{
                Cases = database.query(query);
            }
            integer i = 0;
            for(DIA_Case__c c: Cases){
                if(fiveorlessitemsofcase){
                    integer leadsCount = c.DIA_leads__r.size();
                    if(leadsCount <=5 && leadsCount > 0){
                        string ingestiondate='';
                        
                         if(c.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(c.Manifest__c));
                         }
                       string cmoUser = '';
                
                        if(c.Assigned_to__r.FirstName == null && c.Assigned_to__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = c.Assigned_to__r.FirstName+' '+c.Assigned_to__r.LastName;    
                        }
                        reports.add(new ReportRecord(c.Contact__r.First_Name__c,c.Contact__r.Last_Name__c,c.Case_Number__c,c.customer_case_number__c,c.Case_Due_Date__c,c.Customer_Delivery_Date__c, c.Case_Type__c,c.status__c,c.Current_Task__c,c.Manifest__c,
                                             cmoUser, null,null,c.Waiver_Due_Date__c,c.extension_Due_Date__c, null,null,null,null));      
               
                    }
                }else{
                 string ingestiondate='';
                    
                         if(c.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(c.Manifest__c));
                         }
                    string cmoUser = '';
                
                        if(c.Assigned_to__r.FirstName == null && c.Assigned_to__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = c.Assigned_to__r.FirstName+' '+c.Assigned_to__r.LastName;    
                        }
                 reports.add(new ReportRecord(c.Contact__r.First_Name__c,c.Contact__r.Last_Name__c,c.Case_Number__c,c.customer_case_number__c,c.Case_Due_Date__c,c.Customer_Delivery_Date__c, c.Case_Type__c,c.status__c,c.Current_Task__c,c.Manifest__c,
                                             cmoUser, null,null,c.Waiver_Due_Date__c,c.extension_Due_Date__c, null,null,null,null));      
                }
                if(i==0){
                    firstRecordName = c.Name;    
                }
                lastRecordName = c.Name;
                i++;
            }
        }
        if(selectedReportType == 'Messages'){
            list<DIA_Message__c> messages = database.query(query);
            integer i = 0;
            for(DIA_Message__c message: messages){
                reports.add(new ReportRecord(message));
                if(i==0){
                    firstRecordName = message.Name;    
                }
                lastRecordName = message.Name;
                i++;
            }
        }
        if(selectedReportType == 'Lead'){
            list<DIA_Lead__c> Leads = New list<DIA_Lead__c>();
            if(Test.isrunningTest()){
                List<string> leadFields = new List<string>();
                leadFields = ApexUtil.FetchFields('DIA_Lead__c');
                leadFields.add('contact__r.First_Name__c');
                leadFields.add('contact__r.Last_Name__c');
                leadFields.add('contact__r.Email__c');
                leadFields.add('case__r.case_number__c');
                leadFields.add('case__r.Customer_Case_Number__c');
                leadFields.add('case__r.Case_Due_Date__c');
                leadFields.add('case__r.Customer_Delivery_Date__c');
                leadFields.add('case__r.Case_Type__c');
                leadFields.add('case__r.Manifest__c');
                leadFields.add('Assigned_to__r.FirstName');
                leadFields.add('Assigned_to__r.LastName');
                leadFields.add('case__r.Assigned_to__r.FirstName');
                leadFields.add('case__r.Assigned_to__r.LastName');
                leadFields.add('case__r.Current_Task__c');
                leadFields.add('case__r.status__c');
                    leadFields.add('case__r.Extension_Due_Date__c');
                Leads = database.query('Select '+string.join(leadFields, ',') + ' From DIA_Lead__c ');
            }else{
                Leads = database.query(query);
            }
            integer i = 0;
            for(DIA_Lead__c lead: Leads){
                String sourceName = '';
                    if(lead.Source_First_Name__c != Null){
                        sourceName = lead.Source_First_Name__c;
                    }
                    if(lead.Source_Last_Name__c != Null){
                        sourceName =lead.Source_First_Name__c + ' ' +lead.Source_Last_Name__c;
                    }
                    string contactMethod;
                    if(lead.LeadType__c == 'Employment (EMPL)' && lead.Coverage_Type__c == 'Record'){
                        contactMethod = lead.Employment_Contact_Method__c;
                    } 
                    if(lead.LeadType__c == 'Former Spouse (FMSP)' || lead.LeadType__c == 'References (REFE)'|| (lead.LeadType__c == 'Residence (RESI)' && lead.Coverage_Type__c == 'Personal') || (lead.LeadType__c == 'Unemployment' && lead.Coverage_Type__c == 'Personal') || (lead.LeadType__c == 'General (GENL)' && lead.Coverage_Type__c == 'Personal') || (lead.LeadType__c == 'Education (EDUC)' && lead.Coverage_Type__c == 'Personal') || (lead.LeadType__c == 'Employment (EMPL)' && lead.Coverage_Type__c == 'Personal')){
                        contactMethod = lead.Personal_Contact_Method__c;
                    }
                    if((lead.LeadType__c == 'Medical (MEDI)' && lead.Coverage_Type__c == 'Record')||
                        (lead.LeadType__c == 'Medical (MEDI)' && lead.Coverage_Type__c == 'Personal')||
                        (lead.LeadType__c == 'Education (EDUC)' && lead.Coverage_Type__c == 'Record')||
                        (lead.LeadType__c == 'Law Enforcement (LAWE)' && lead.Coverage_Type__c == 'Record')||
                        (lead.LeadType__c == 'Public records (PUBR)' && lead.Coverage_Type__c == 'Record')||
                        (lead.LeadType__c == 'General (GENL)' && lead.Coverage_Type__c == 'Record') || 
                        (lead.LeadType__c == 'Financial (FINL)'  && lead.Coverage_Type__c == 'Record')|| 
                        (lead.LeadType__c == 'Education (EDUC)' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Employment (EMPL)' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Unemployment' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Residence (RESI)' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Law Enforcement (LAWE)' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Public records (PUBR)' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Financial (FINL)' && lead.Coverage_Type__c == 'General Record') || 
                        (lead.LeadType__c == 'Medical (MEDI)' && lead.Coverage_Type__c == 'General Record')){
                            contactMethod = lead.Contact_Method__c; 
                     }
                     string ingestiondate='';
                         if(lead.case__r.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(lead.case__r.Manifest__c));
                         } 
                string cmoUser = '';
                
                        if(lead.case__r.Assigned_to__r.FirstName == null && lead.case__r.Assigned_to__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = lead.case__r.Assigned_to__r.FirstName+' '+lead.case__r.Assigned_to__r.LastName;    
                        }
                     reports.add(new ReportRecord(lead.Contact__r.First_Name__c,lead.Contact__r.Last_Name__c,lead.case__r.Case_Number__c,lead.case__r.Case_Due_Date__c,lead.case__r.extension_Due_Date__c,lead.case__r.Customer_Delivery_Date__c, lead.case__r.Customer_Case_Number__c,lead.case__r.status__c, lead.case__r.Current_Task__c,lead.case__r.Manifest__c,
                                                 cmoUser, lead.Assigned_to__r.FirstName+' '+lead.Assigned_to__r.LastName, string.valueof(lead.Completed_Date__c),null, lead.leadType__c, lead.status__c,
                                                 integer.valueof(lead.Item_Number__c),sourceName,lead.Lead_Contact_Name__c,lead.Lead_Contact_Address__c
                                                 ,lead.Lead_Contact_City__c,lead.Lead_Contact_State__c,lead.Lead_Contact_Zip__c,
                                                 lead.Lead_Contact_Other_Information__c, lead.Anticipated_Completion_Date__c,
                                                 lead.coverage_type__c, lead.Assignee_Date__c, string.valueof(lead.Id),contactMethod,lead.price__c,lead.Days_from_QA_Review_Completed__c,lead.createdDate));  
                                                 
                                                 
                              
                    if(i==0){
                        firstRecordName = lead.Name;    
                    }
                    lastRecordName = lead.Name;
                i++;
            }
        }
        if(selectedReportType == 'Check-in/Check-out'){
            list<DIA_Investigator_Check__c> invChecks = database.query(query);
            integer i = 0;
            for(DIA_Investigator_Check__c invCheck: invChecks){
                reports.add(new ReportRecord(invCheck));
                if(i==0){
                    firstRecordName = invCheck.Name;    
                }
                lastRecordName = invCheck.Name;
                i++;
            }
        }
        if(selectedReportType == 'Waivers'){
            list<DIA_waiver_information__c> waivers = database.query(query);
            integer i = 0;
            for(DIA_waiver_information__c waiver: waivers){
                reports.add(new ReportRecord(waiver));
                if(i==0){
                    firstRecordName = waiver.Name;    
                }
                lastRecordName = waiver.Name;
                i++;
            }
        }
        if(selectedReportType == 'Investigator Reports'){
            
        }
        
        
        
        if(pageNumber == TotalPages){
            disablePrev = false;   
            disableNext = true;
        }else{
            disablePrev = false;
            disableNext = false;
        }
         system.debug('firstRecordName....'+firstRecordName);
        system.debug('lastRecordName....'+lastRecordName);
         system.debug('currentRecordCount....'+currentRecordCount);
    }
}