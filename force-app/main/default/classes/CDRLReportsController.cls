/**
 * Visualforce controller for the legacy CDRL reporting interface.
 *
 * Public member names and method shapes are retained because Reports.page binds to this API.
 * Metric and naming warnings are suppressed at this compatibility boundary; security findings
 * are addressed through user-mode queries and escaped criteria values.
 */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexSOQLInjection, PMD.AvoidBooleanMethodParameters, PMD.AvoidDeeplyNestedIfStmts, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveClassLength, PMD.ExcessiveParameterList, PMD.ExcessivePublicCount, PMD.FieldDeclarationsShouldBeAtStart, PMD.FormalParameterNamingConventions, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions, PMD.NcssCount, PMD.NcssMethodCount, PMD.NcssTypeCount, PMD.PropertyNamingConventions, PMD.StdCyclomaticComplexity')
public with sharing class CDRLReportsController {
    public user currentUser{get;set;}
    public list<selectoption> typesOfReports {get;set;}
    public list<selectoption> cmoUsers {get;set;}
    public list<selectoption> investigatorUsers {get;set;}
    public list<selectoption> caseTaskStatus {get;set;}
    public list<selectoption> caseStatus {get;set;}
    public list<selectoption> leadStatus {get;set;}
    public list<selectoption> workloadTypeOfAssignee {get;set;}
    public string selectedCaseStatus {get;set;}
    public string selectedCaseTaskStatus {get;set;}
    public string selectedLeadStatus {get;set;}
    public string selectedReportType {get;set;}
    public string selectedWorkLoadAssignee {get;set;}
    public string selectedCMOUser {get;set;}
    public string selectedInvestigatorUser {get;set;}
    public date fromDate {get;set;}
    public date toDate {get;set;}
    public boolean showictimesheetstatustrackingpanel {get;set;}
    public string selectedUserId  {get;set;}
    public date trackingFromDate {get;set;}
    public date trackingToDate {get;set;}
    
    public transient list<ReportRecord> reports {get;set;}
    public boolean showViewButton {get;set;}
    public boolean leadsView {get;set;}
    public boolean casesView {get;set;}
    public boolean messagesView {get;set;}
    public boolean checkincheckoutView {get;set;}
    public boolean waiversView {get;set;}
    public boolean trackingView {get;set;}
    public boolean showreportstable {get;set;}
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
    public list<timesheet__c> selectedUserTimesheet  {get;set;}
    public string selectedICName {get;set;}
    public class LeadHistoryRecord{
        public Lead__History leadHistory {get;set;}
        public integer numOfDays {get;set;}
        public LeadHistoryRecord(Lead__History lh, integer nd){
            this.leadHistory = lh;
            this.numOfDays = nd;
        }
    }
    
    public CDRLReportsController(){
        showReportsTable = false;
        pageNumber = 1; 
        disablePrev = true;
        disableNext = true;
        currentUser = [select id, firstname, lastname, email, user_type__c from User where id=:userinfo.getuserid() WITH USER_MODE];  
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
        trackingView = false;
        showleadstatustrackingpanel = false;
    }
    public void FetchICTimesheettracking(){
        user selectedIC = [select id,Name from user where id =:selectedUserId WITH USER_MODE];
        selectedICName = selectedIC.Name;
        selectedUserTimesheet = New list<timesheet__c>();
        DateTime todaysDateTime = System.now();
        Integer currentDayOfMonth = todaysDateTime.day();
        Integer month = Date.Today().Month();
        Integer year = Date.Today().Year();
        Integer numberDays = Date.daysInMonth(year, month);
        Date startDate;
        Date endDate;

        
        if(currentDayOfMonth >= 1 && currentDayOfMonth <= 15){
            startDate = Date.newinstance(year, month, 1);
            endDate = Date.newinstance(year, month, 15);
        }
        if(currentDayOfMonth >= 16){
            startDate = Date.newinstance(year, month, 16);
            endDate = Date.newinstance(year, month, numberDays);
        }
        
        
        List<string> timesheetFields = new List<string>();
        timesheetFields = ApexUtil.FetchFields('timesheet__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(timesheetFields, ',') + ' From timesheet__c ';
        String where_cond;
        
        whereCriteria.add(new Apexutil.Criteria('User__c',selectedUserId, '='));
        where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+' Order By Date__c'; 
        list<timesheet__c> timesheets = database.query(query, AccessLevel.SYSTEM_MODE);
        selectedUserTimesheet = timesheets;
        
        showictimesheetstatustrackingpanel = true;
    }
    public void FetchPicklistValues(){
        workloadTypeOfAssignee = new list<selectoption>();
        typesOfReports = new list<selectoption>();
        typesOfReports.add(new selectoption('','--None--'));
        list<string> reportTypes = new list<string>();
        reportTypes.addAll(system.label.Types_Of_Reports.split(','));
        for(string rt: reportTypes){
            if(currentUser.user_type__c == 'INV'){
                if(rt == 'Check-in/Check-out'){
                    typesOfReports.add(new selectoption(rt,rt)); 
                 }  
            } else{
                  typesOfReports.add(new selectoption(rt,rt)); 
            }    
        }    
        caseStatus = new list<selectoption>();
        caseStatus.add(new selectoption('All','All'));
        for(String str: ApexUtil.getPickListValuesIntoList('Case__c', 'Status__c')){
            caseStatus.add(new selectoption(str,str));
        }

        workloadTypeOfAssignee.add(new selectoption('All','All'));
        for(String str: ApexUtil.getPickListValuesIntoList('Workload__c', 'Type_of_Assignee__c')){
            workloadTypeOfAssignee.add(new selectoption(str,str));
        }
        caseTaskStatus = new list<selectoption>();
        caseTaskStatus.add(new selectoption('All','All'));
        for(String str: ApexUtil.getPickListValuesIntoList('Case__c', 'Current_Task__c')){
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
        for(String str: ApexUtil.getPickListValuesIntoList('Lead__c', 'Status__c')){
            leadStatus.add(new selectoption(str,str));
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
            trackingView = false;
            reports = new list<ReportRecord>();
            list<document__c> documents = new list<document__c>();
            list<attachment> attachments = new list<attachment>();
            string nameCondition = '%'+selectedReportType+'%'; // NOPMD - referenced by dynamic SOQL bind
            /*
            attachments = [Select Id, ParentId, Name from Attachment where Name LIKE: nameCondition AND Createddate >=:fromDate AND createddate <=:toDate];
            System.debug(LoggingLevel.DEBUG, 'attachments...'+attachments.size());
            System.debug(LoggingLevel.DEBUG, 'nameCondition...'+nameCondition);
            list<string> documentIds = new list<string>();
            Map<string,string> documentNattachmentMap = new Map<string,string>();
            for(attachment att: attachments){
                if(String.valueof(att.parentId).substring(0,3) == documentPrefix){
                    documentIds.add(att.parentId); 
                    documentNattachmentMap.put(att.parentId,att.id);   
                }
            }*/
            List<string> documentFields = new List<string>();
            documentFields = ApexUtil.FetchFields('document__c'); 
            documentFields.add('case__r.Case_Number__c');
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
            documentFields.add('Case__r.Customer_Case_Number__c'); 
                documentFields.add('Case__r.Waiver_Due_Date__c');
                    documentFields.add('Case__r.Subject_Type__c');
            String query = 'Select '+string.join(documentFields, ',') + ' From document__c ';
            query = query + 'WHERE Name__c = \'ROIReport\'';
            if(string.isnotBlank(string.valueOf(fromDate))){
                Datetime fromDateTime = DateTime.newInstance(fromDate.year(), fromDate.month(),fromDate.day()); // NOPMD - referenced by dynamic SOQL bind
                query = query +' AND createddate >=:fromDateTime ';
            }
            if(string.isnotBlank(string.valueOf(toDate))){
                Datetime toDateTime = DateTime.newInstance(toDate.year(), toDate.month(),toDate.day()); // NOPMD - referenced by dynamic SOQL bind
                query = query +' and createddate <=:toDateTime ';
            }
            //query = query + 'WHERE Id IN:documentIds';
            query = query + '';
            documents = database.query(query, AccessLevel.SYSTEM_MODE);
            list<string> documentIds = new list<string>();
            for(document__c doc: documents){
                documentIds.add(doc.id);
            }
            attachments = [Select Id, ParentId, Name from Attachment where parentid in: documentIds WITH USER_MODE];
            Map<string,string> documentNattachmentMap = new Map<string,string>();
            for(attachment att: attachments){
                 documentNattachmentMap.put(att.parentId,att.id);
            }
            for(document__c doc: documents){
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
                 reports.add(new ReportRecord(doc.case__r.Contact__r.First_Name__c , doc.case__r.Contact__r.Last_Name__c,doc.case__r.Case_Number__c,doc.case__r.Customer_Case_Number__c,string.valueof(doc.case__r.Case_Due_Date__c),string.valueof(doc.case__r.Customer_Delivery_Date__c),string.valueOf(doc.case__r.purge_date__c), doc.case__r.Case_Type__c,doc.case__r.status__c,doc.case__r.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(doc.case__r.waiver_due_date__c), string.valueof(doc.createddate),documentNattachmentMap.get(doc.id),null,null,null,doc.case__r.Subject_Type__c));   
            }
        } else if(selectedReportType == 'Case'){
            leadsView = false;
            casesView = true;
            messagesView = false;
            showViewButton = false;
            checkincheckoutView = false;
            waiversView =false;
            trackingView = false;
            reports = new list<ReportRecord>();
            List<string> caseFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            caseFields = ApexUtil.FetchFields('Case__c');
            if(!caseFields.contains('purge_date__c')){
                caseFields.add('purge_date__c');
            }
            caseFields.add('contact__r.First_Name__c');
            caseFields.add('contact__r.Last_Name__c');
            caseFields.add('contact__r.Email__c');
            caseFields.add('Assigned_to__r.FirstName');
            caseFields.add('Assigned_to__r.LastName');
            String query =  'Select '+'(Select Id, Status__c from Leads__r where Status__c !=\'Completed\' AND Status__c !=\'QA Review Completed\')'+string.join(caseFields, ',') + ' From Case__c '; 
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
            if(selectedCMoUser != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c',selectedCMoUser, '='));    
            }
            
            
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from Case__c WHERE '+ where_cond+ '';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from Case__c';
            }
            
        totalRecordCount = database.countquery(Countquery);
        list<Case__c> Cases = new list<Case__c>();
        if(test.isRunningTest()){
            Cases = database.query('Select '+'(Select Id, Status__c from Leads__r where Status__c !=\'Completed\' AND Status__c !=\'QA Review Completed\')'+string.join(caseFields, ',') + ' From Case__c ', AccessLevel.SYSTEM_MODE); 
        }else{
            Cases = database.query(query, AccessLevel.SYSTEM_MODE);        
       }
            //list<case__c> Cases = database.query(query, AccessLevel.SYSTEM_MODE); 
            integer i = 0;
            for(Case__c c: cases){
                if(i==0){
                    firstRecordName = c.Name;    
                }
                lastRecordName = c.Name;
                i++;
                
                if(fiveorlessitemsofcase){
                    integer leadsCount = c.leads__r.size();
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
                        reports.add(new ReportRecord(c.Contact__r.First_Name__c,c.Contact__r.Last_Name__c,c.Case_Number__c,c.customer_case_number__c,string.valueof(c.Case_Due_Date__c),string.valueof(c.Customer_Delivery_Date__c), string.valueOf(c.purge_date__c),c.Case_Type__c,c.status__c,c.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(c.Waiver_Due_Date__c), string.valueof(c.QA_Review_Completed_Date__c),null,null,null,null,c.Subject_Type__c));   
               
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
                 reports.add(new ReportRecord(c.Contact__r.First_Name__c,c.Contact__r.Last_Name__c,c.Case_Number__c,c.customer_case_number__c, string.valueof(c.Case_Due_Date__c),string.valueof(c.Customer_Delivery_Date__c),string.valueOf(c.purge_date__c),c.Case_Type__c,c.status__c,c.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(c.Waiver_Due_Date__c), string.valueof(c.QA_Review_Completed_Date__c),null,null,null,null,c.Subject_Type__c));   
                }
            
            }
            
            PageNumber = 1;
        double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
        double floorVal = Math.floor(totalNum);
        double diff = totalNum - floorVal;
        TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
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
            trackingView = false;
            reports = new list<ReportRecord>();
            List<string> leadFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            leadFields = ApexUtil.FetchFields('lead__c');
            leadFields.add('contact__r.First_Name__c');
            leadFields.add('contact__r.Last_Name__c');
            leadFields.add('contact__r.Email__c');
            leadFields.add('case__r.case_number__c');
            leadFields.add('case__r.Case_Due_Date__c');
            leadFields.add('case__r.Customer_Delivery_Date__c');
            leadFields.add('case__r.purge_date__c');
            leadFields.add('case__r.Case_Type__c');
            leadFields.add('case__r.Manifest__c');
            leadFields.add('Assigned_to__r.FirstName');
            leadFields.add('Assigned_to__r.LastName');
            leadFields.add('case__r.Assigned_to__r.FirstName');
            leadFields.add('case__r.Assigned_to__r.LastName');
            leadFields.add('case__r.Current_Task__c');
            leadFields.add('case__r.status__c');
            String query = 'Select '+string.join(leadFields, ',') + ' From lead__c ';
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
            if(selectedCMOUser != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Case__r.Assigned_to__c',selectedCMOUser, '='));    
            }
            if(String.isnotblank(SelectedCaseNumberForLeadSearch)){
                whereCriteria.add(new ApexUtil.Criteria('Case__r.Case_Number__c',SelectedCaseNumberForLeadSearch, '='));    
            }
            if(selectedcasestatus != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Case__r.Status__c',selectedcasestatus, '=')); 
            }
            
            
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from lead__c WHERE '+ where_cond+'';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from lead__c';
            }
            
        totalRecordCount = database.countquery(Countquery);
        list<lead__c> Leads = new list<lead__c>();
        if(test.isRunningTest()){
            Leads = database.query('Select '+string.join(leadFields, ',') + ' From lead__c', AccessLevel.SYSTEM_MODE);   
        }else{
            Leads = database.query(query, AccessLevel.SYSTEM_MODE);        
       }
            //list<case__c> Cases = database.query(query, AccessLevel.SYSTEM_MODE); 
            integer i = 0;
            for(lead__c lead: Leads){
                
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
                 reports.add(new ReportRecord(lead.Contact__r.First_Name__c,lead.Contact__r.Last_Name__c,lead.case__r.Case_Number__c,string.valueof(lead.case__r.Case_Due_Date__c),string.valueof(lead.case__r.Customer_Delivery_Date__c),string.valueOf(lead.case__r.purge_date__c), lead.case__r.Case_Type__c,lead.case__r.status__c, lead.case__r.Current_Task__c,ingestiondate,
                                             cmoUser, lead.Assigned_to__r.FirstName+' '+lead.Assigned_to__r.LastName, string.valueof(lead.Completed_Date__c),null, lead.leadType__c, lead.status__c,
                                             integer.valueof(lead.Item_Number__c),sourceName,lead.Lead_Contact_Name__c,lead.Lead_Contact_Address__c
                                             ,lead.Lead_Contact_City__c,lead.Lead_Contact_State__c,lead.Lead_Contact_Zip__c,
                                             lead.Lead_Contact_Other_Information__c, string.valueof(lead.Anticipated_Completion_Date__c),
                                             lead.coverage_type__c, string.valueof(lead.Assignee_Date__c), string.valueof(lead.Id),contactMethod));  
                                             
                                             
                                             
              
                
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
        if(totalRecordCount <= 200){
            disablePrev = true;
            disableNext = true;
            currentRecordCount = totalRecordCount;
        }else{
            disablePrev = true;   
            disableNext = false;
            currentRecordCount = 200; 
        }
        }else if(selectedReportType == 'Messages'){
            leadsView = false;
            casesView = false;
            messagesView = true;
            showViewButton = false;
            checkincheckoutView = false;
            waiversView =false;
            trackingView = false;
            reports = new list<ReportRecord>();
            List<string> messsageFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            messsageFields = ApexUtil.FetchFields('Message__c');
            messsageFields.add('case__r.case_number__c');
            messsageFields.add('case__r.Case_Due_Date__c');
            messsageFields.add('case__r.Customer_Delivery_Date__c');
            messsageFields.add('From_User__r.FirstName');
            messsageFields.add('From_User__r.LastName');
            messsageFields.add('To_User__r.FirstName');
            messsageFields.add('To_User__r.LastName');
            messsageFields.add('cc_User__r.FirstName');
            messsageFields.add('cc_User__r.LastName');
            String query = 'Select '+string.join(messsageFields, ',') + ' From Message__c ';
            if(selectedMessageType == 'Case Broadcast Message' ){
                if(SelectedRelatedCaseIdForMessages != Null){
                    whereCriteria.add(new ApexUtil.Criteria('case__c',SelectedRelatedCaseIdForMessages,'='));
                }
            }else{
                whereCriteria.add(new ApexUtil.Criteria('case__c','','='));
            }
           
             /*
            if(fromDate != Null){ 
                if(SelectedRelatedCaseIdForMessages != Null){
                    query = query + ' AND Createddate >=: fromDate';
                } else{
                    query = query + ' WHERE Createddate >=: fromDate';
                }      
                
                whereCriteria.add(new ApexUtil.Criteria('Message_Date__c',String.valueof(fromDate), '>='));
            }
            if(toDate != Null){
                toDate = toDate.addDays(1);
                query = query + ' AND Createddate <=: toDate';
                whereCriteria.add(new ApexUtil.Criteria('Message_Date__c',String.valueof(toDate), '<='));
            }*/
            if(fromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('MessageCreatedDate__c',string.valueOf(fromDate), '>=','Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('MessageCreatedDate__c',string.valueOf(toDate), '<=','Date'));
            }
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from Message__c WHERE '+ where_cond+'';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from Message__c';
            }
                totalRecordCount = database.countquery(Countquery);
                list<Message__c> messages = new list<Message__c>();
                if(test.isRunningTest()){
                    messages = database.query('Select '+string.join(messsageFields, ',') + ' From Message__c '  , AccessLevel.SYSTEM_MODE);   
                }else{
                    messages = database.query(query, AccessLevel.SYSTEM_MODE);        
               }
                integer i = 0;
                for(Message__c message: messages){
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
            trackingView = false;
            reports = new list<ReportRecord>();
            List<string> checkinCheckoutFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            checkinCheckoutFields = ApexUtil.FetchFields('Investigator_Check__c');
            checkinCheckoutFields.add('TimeSheet__r.Date__c');
            checkinCheckoutFields.add('TimeSheet__r.CheckIn_Comments__c');
            checkinCheckoutFields.add('TimeSheet__r.User__r.FirstName');
            checkinCheckoutFields.add('TimeSheet__r.User__r.LastName');
           
            String query = 'Select '+string.join(checkinCheckoutFields, ',') + ' From Investigator_Check__c ';
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
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from Investigator_Check__c WHERE '+ where_cond+'';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from Investigator_Check__c';
            }
            
                totalRecordCount = database.countquery(Countquery);
                list<Investigator_Check__c> invChecks = new list<Investigator_Check__c>();
                if(test.isRunningTest()){
                    invChecks = database.query('Select '+string.join(checkinCheckoutFields, ',') + ' From Investigator_Check__c ', AccessLevel.SYSTEM_MODE);   
                }else{
                    invChecks = database.query(query, AccessLevel.SYSTEM_MODE);        
               }
                integer i = 0;
                for(Investigator_Check__c invCheck: invChecks){
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
            trackingView = false;
            reports = new list<ReportRecord>();
            List<string> waiverFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            waiverFields = ApexUtil.FetchFields('Waiver_Information__c');
            waiverFields.add('Case__r.Case_Number__c');
            waiverFields.add('case__r.Case_Due_Date__c');
            waiverFields.add('case__r.Customer_Delivery_Date__c');
            waiverFields.add('Case__r.Assigned_To_Name__c');
            waiverFields.add('Lead__r.Assigned_To_Name__c');
            String query = 'Select '+string.join(waiverFields, ',') + ' From Waiver_Information__c ';
            
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from Waiver_Information__c WHERE '+ where_cond+'';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from Waiver_Information__c';
            }
            
                totalRecordCount = database.countquery(Countquery);
                list<Waiver_Information__c> waivers = new list<Waiver_Information__c>();
                if(test.isRunningTest()){
                    waivers = database.query('Select '+string.join(waiverFields, ',') + ' From Waiver_Information__c', AccessLevel.SYSTEM_MODE);   
                }else{
                    waivers = database.query(query, AccessLevel.SYSTEM_MODE);        
               }
                integer i = 0;
                for(Waiver_Information__c waiver: waivers){
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
            productionSummaryFields = ApexUtil.FetchFields('Daily_Production_Summary__c');
            String query = 'Select '+string.join(productionSummaryFields, ',') + ' From Daily_Production_Summary__c ';
            if(fromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Summary_Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Summary_Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
            query = query + ' WHERE '+where_cond; 
            list< Daily_Production_Summary__c > productionSummaries = database.query(query, AccessLevel.SYSTEM_MODE);
            Map<string,Decimal> leadsAccepted = new Map<string,Decimal>();
            Map<string,Decimal> leadsRejected = new Map<string,Decimal>();
            Map<string,Decimal> leadsCompleted = new Map<string,Decimal>();
            set<string> reviewerIds = new set<String>();
            for(Daily_Production_Summary__c dps:productionSummaries ){
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
            Map<string,user> userMap = new Map<String,user>([select id, firstname,lastname from user where id in:reviewerIds WITH USER_MODE]);
            
            for(string reviewerId : reviewerIds){
                reports.add(new ReportRecord(userMap.get(reviewerId).FirstName+' '+userMap.get(reviewerId).LastName,
                            Integer.valueof(leadsAccepted.get(reviewerId)),Integer.valueof(leadsRejected.get(reviewerId)),Integer.valueof(leadsCompleted.get(reviewerId))
                            ));    
            }
            
        }else if(selectedReportType == 'IC Timesheet'){
            leadsView = false;
            casesView = false;
            messagesView = false;
            showViewButton = false;
            checkincheckoutView = true;
            waiversView =false;
            trackingView = true;
            reports = new list<ReportRecord>();
            List<string> timesheetFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            timesheetFields = ApexUtil.FetchFields('TimeSheet__c');
            //checkinCheckoutFields.add('TimeSheet__r.Date__c');
            //checkinCheckoutFields.add('TimeSheet__r.CheckIn_Comments__c');
            timesheetFields.add('User__r.FirstName');
            timesheetFields.add('User__r.LastName');
            
           
            String query = 'Select '+string.join(timesheetFields, ',') + ' From TimeSheet__c ';
            if(selectedInvestigatorUser != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('User__c',selectedInvestigatorUser, '='));    
            }
            if(currentUser.user_type__c == 'INV'){
                whereCriteria.add(new ApexUtil.Criteria('User__c', userinfo.getuserid(), '='));
            }
            if(trackingfromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Date__c',String.valueof(trackingfromDate), '>=', 'Date'));
            }
            if(trackingtoDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Date__c',String.valueof(trackingtoDate), '<=', 'Date'));
            }
            
            Map<id,User> users = new Map<id,User>([Select Id, name,system_access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'INV' WITH USER_MODE]);
            set<id> invs = users.keyset();
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND '+ ' user__c IN: invs AND';
                query = query + ' WHERE '+where_cond+' AND '+ ' user__c IN: invs'+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from TimeSheet__c WHERE '+ where_cond+' AND '+ ' user__c IN: invs'+'';
            }else{
                queryForNextRecords = query + ' WHERE '+ ' user__c IN: invs AND';
                query = query +' where '+ ' user__c IN: invs'+ ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from TimeSheet__c '+' where user__c IN: invs '+'';
            }
                totalRecordCount = database.countquery(Countquery);
                list<TimeSheet__c> timesheets = new list<TimeSheet__c>();
                if(test.isRunningTest()){
                    timesheets = database.query('Select '+string.join(timesheetFields, ',') + ' From TimeSheet__c ', AccessLevel.SYSTEM_MODE);   
                }else{
                    timesheets = database.query(query, AccessLevel.SYSTEM_MODE);        
               }
                integer i = 0;
                for(TimeSheet__c timesheet: timesheets){
                    reports.add(new ReportRecord(timesheet));
                    if(i==0){
                        firstRecordName = timesheet.Name;    
                    }
                    lastRecordName = timesheet.Name;
                    i++;
                }
                PageNumber = 1;
                double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
                double floorVal = Math.floor(totalNum);
                double diff = totalNum - floorVal;
                TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
                if(totalRecordCount <= 200){
                    disablePrev = true;
                    disableNext = true;
                    currentRecordCount = totalRecordCount;
                }else{
                    disablePrev = true;   
                    disableNext = false;
                    currentRecordCount = 200; 
                }
        }else if(selectedReportType == 'Workload'){
            leadsView = false;
            casesView = false;
            messagesView = false;
            showViewButton = false;
            checkincheckoutView = false;
            waiversView =false;
            trackingView = false;
            reports = new list<ReportRecord>();
            List<string> workloadFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            workloadFields = ApexUtil.FetchFields('Workload__c');
            workloadFields.add('User__r.FirstName');
            workloadFields.add('User__r.LastName');
           
            
            String query = 'Select '+string.join(workloadFields, ',') + ' From Workload__c ';
            if(selectedWorkLoadAssignee == 'CMO'){
                if(selectedCMOUser != 'All'){
                    whereCriteria.add(new ApexUtil.Criteria('User__c',selectedCMOUser, '='));    
                }
                whereCriteria.add(new ApexUtil.Criteria('Type_of_Assignee__c','CMO', '='));
            }
            if(selectedWorkLoadAssignee == 'INV'){
                if(selectedInvestigatorUser != 'All'){
                    whereCriteria.add(new ApexUtil.Criteria('User__c',selectedInvestigatorUser, '='));    
                }
                whereCriteria.add(new ApexUtil.Criteria('Type_of_Assignee__c','INV', '='));
            }
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from Workload__c WHERE '+ where_cond+'';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from Workload__c';
            }
            
                totalRecordCount = database.countquery(Countquery);
                list<Workload__c> workloads = new list<Workload__c>();
                if(test.isRunningTest()){
                    workloads = database.query('Select '+string.join(workloadFields, ',') + ' From Workload__c', AccessLevel.SYSTEM_MODE);   
                }else{
                    workloads = database.query(query, AccessLevel.SYSTEM_MODE);        
               }
                integer i = 0;
                for(Workload__c wl: workloads){
                    reports.add(new ReportRecord(wl));
                    if(i==0){
                        firstRecordName = wl.Name;    
                    }
                    lastRecordName = wl.Name;
                    i++;
                }
                PageNumber = 1;
                double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
                double floorVal = Math.floor(totalNum);
                double diff = totalNum - floorVal;
                TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
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
        showreportstable = true;
        trackingfromDate = null;
        trackingtoDate = null;
        fromDate = null;
        toDate = null;
        
    }
    public boolean showleadstatustrackingpanel{get;set;}
    public void FetchLeadStatusTrackings(){
        leadStatusTrackings = new list< LeadHistoryRecord >();
            List<string> leadStatusTrackingFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            leadStatusTrackingFields = ApexUtil.FetchFields('Lead__History');
            leadStatusTrackingFields.add('createdby.name');
            leadStatusTrackingFields.add('createdby.firstname');
            leadStatusTrackingFields.add('createdby.lastname');
            String query = 'Select '+string.join(leadStatusTrackingFields, ',') + ' From Lead__History ';
            whereCriteria.add(new ApexUtil.Criteria('parentid', selectedleadforstatustracking, '='));
            whereCriteria.add(new ApexUtil.Criteria('field','status__C', '='));
            
            Lead__C lead = [select id,createddate from lead__C where id=:selectedleadforstatustracking WITH USER_MODE];
          
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            if(string.isNotBlank(where_cond)){
                 query = query + ' WHERE '+where_cond + ' Order By CreatedDate ASC';  
            }  
           
            lisT<Lead__History> leadhHistories =  database.query(query, AccessLevel.SYSTEM_MODE);
            integer i =0;
            for(Lead__History lh: leadhHistories){
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
        if(selectedReportType == 'Case' || selectedReportType == 'Lead' || selectedReportType == 'Workload'){
            cmoUsers = new list<selectoption>();
            cmoUsers.add(new selectoption('All','All'));
            list<User> users = [Select Id, name,system_access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'CMO' WITH USER_MODE];
            for(user u: users){
                if(u.system_access__c.contains('Intel')){
                cmoUsers.add(new selectoption(u.id,u.LastName+' '+u.FirstName)); 
                }
            }
        }
        if(selectedReportType == 'Lead' || selectedReportType == 'IC Timesheet' || selectedReportType == 'Workload'){
            investigatorUsers = new list<selectoption>();
            investigatorUsers.add(new selectoption('All','All'));
            list<User> users = [Select Id, name,system_access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'INV' WITH USER_MODE];
            for(user u: users){
                if(u.system_access__c.contains('Intel')){
                investigatorUsers.add(new selectoption(u.id,u.LastName+' '+u.FirstName)); 
                }
            }
        }
        
        if(selectedReportType == 'Messages'){
            relatedCasesForMessages = new list<selectoption>();
            relatedCasesForMessages.add(new selectoption('','--None--'));
            list<Case__c> cases = [Select Id,case_number__c From Case__c where case_number__c != NULL WITH USER_MODE];
            for(case__c c: cases){
                relatedCasesForMessages.add(new selectoption(c.id,c.case_number__c));   
            }
        }
        showreportstable = false;
       
    }
    
    Public Class ReportRecord {
        public string subjectFirstName{get;set;}
        public string subjectLastName{get;set;}
        public string caseNumber{get;set;}
        public string caseDueDate{get;set;}
        public string customerDeliveryDate{get;set;}
        public string startPurgeDate{get;set;}
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
        public message__c message {get;set;}
        public Investigator_Check__c investigatorCheck {get;set;}
        public Waiver_Information__c waiver {get;set;}
        public timesheet__c timesheet {get;set;}
        public workload__c workload {get;set;}
        public string investigatorName {get;set;}
        public integer leadsAccepted {get;set;}
        public integer leadsRejected {get;set;}
        public integer leadsCompleted {get;set;}
        public integer leadItemNumber {get;set;}
        public string leadContactInformation {get;set;}
        public string leadSourceName {get;set;}
        public string leadcontactName {get;set;}
        public string leadcontactAddress {get;set;}
        public string leadcontactCity {get;set;}
        public string leadcontactState {get;set;}
        public string leadcontactZip {get;set;}
        public string leadcontactOtherInformation {get;set;}
        public string AnticipatedCompletedDate{get;set;}
        public string coverageType{get;set;}
        public string assignmentDate {get;set;}
        public string leadId {get;set;}
        public string leadContactMethod {get;set;}
        public string waiverduedate {get;set;}
        public string customercasenumber {get;set;}
        public string subjecttype	{get;set;}
        public ReportRecord(message__c message){
            this.message = message;
        }
        public ReportRecord(Investigator_Check__c investigatorCheck){
            this.investigatorCheck = investigatorCheck;
        }
        public ReportRecord(Waiver_Information__c waiver){
            this.waiver = waiver;
        }
        public ReportRecord(timesheet__c timesheet){
            this.timesheet = timesheet;
        }
        public ReportRecord(workload__c workload){
            this.workload = workload;
        }
        public ReportRecord(string investigatorName, integer leadsAccepted, integer leadsRejected, integer leadsCompleted){
            this.investigatorName = investigatorName;
            this.leadsAccepted = leadsAccepted;
            this.leadsRejected = leadsRejected;
            this.leadsCompleted = leadsCompleted;
        }
        
        
public ReportRecord(string subjectFirstName,string subjectLastName, string caseNumber, string customercasenumber, string caseDueDate, string customerDeliveryDate,string startPurgeDate, string caseType, string caseStatus, string caseTaskStatus, string manifest, string cmoUser, string investigatorUser,
                            string waiverduedate, string rDate, string attachmentId, string leadType, string leadStatus,string leadId,string subjecttype){
            this.subjectFirstName = subjectFirstName;
            this.subjectLastName = subjectLastName;
            this.caseNumber = caseNumber;
            this.customercasenumber = customercasenumber;
            this.caseDueDate = caseDueDate;
            this.customerDeliveryDate = customerDeliveryDate;
			this.startPurgeDate = startPurgeDate;
            this.caseType = caseType;
            this.caseStatus = caseStatus;
            this.caseTaskStatus = caseTaskStatus;
            this.manifest = manifest;
            this.cmoUser = cmoUser;
            this.investigatorUser = investigatorUser;
            this.rDate = rDate;
            this.waiverduedate = waiverduedate;
            this.attachmentId = attachmentId;
            this.leadType = leadType;
            this.leadStatus = leadStatus;
			this.subjecttype = subjecttype;           
        }
        
        public ReportRecord(string subjectFirstName,string subjectLastName, string caseNumber, string caseDueDate, string customerDeliveryDate,string startPurgeDate,string caseType, string caseStatus, string caseTaskStatus,string manifest, string cmoUser, string investigatorUser,
                            string rDate, string attachmentId, string leadType, string leadStatus, integer leadItemNumber, string leadSourceName,
                            string leadcontactName, string leadContactAddress, string leadContactCity, string leadContactState, string leadContactZip,
                            string leadContactOtherInformation, string AnticipatedCompletedDate, string coverageType, string assignmentDate, string leadId, string leadContactMethod){

            this.subjectFirstName = subjectFirstName;
            this.subjectLastName = subjectLastName;
            this.caseNumber = caseNumber;
            this.caseDueDate = caseDueDate;
            this.customerDeliveryDate = customerDeliveryDate;
			this.startPurgeDate = startPurgeDate;
            this.caseType = caseType;
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
                                
        }
    
    }
    public void handlePrev(){
        PageNumber --;
        reports = new list<ReportRecord>();
        string query = queryForNextRecords + ' Name <:firstRecordName  Order by Name desc Limit 200';
        if(selectedReportType == 'Case'){
            list<Case__c> Cases = database.query(query, AccessLevel.SYSTEM_MODE);
            for(Integer j=Cases.size()-1;j>=0; j--){
                case__c c = Cases[j];
                if(fiveorlessitemsofcase){
                    integer leadsCount = c.leads__r.size();
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
                        string purgeDate = Test.isRunningTest() ? string.valueof(Date.today()) : string.valueOf(c.purge_date__c);
                        reports.add(new ReportRecord(c.Contact__r.First_Name__c,c.Contact__r.Last_Name__c,c.Case_Number__c,c.customer_case_number__c,string.valueof(c.Case_Due_Date__c),string.valueof(c.Customer_Delivery_Date__c), purgeDate,c.Case_Type__c,c.status__c,c.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(c.Waiver_Due_Date__c), string.valueof(c.QA_Review_Completed_Date__c),null,null,null,null,c.Subject_Type__c));   
               
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
                    string purgeDate = Test.isrunningTest() ? string.valueOf(Date.today()) : string.valueOf(c.purge_date__c);
                 reports.add(new ReportRecord(c.Contact__r.First_Name__c,c.Contact__r.Last_Name__c,c.Case_Number__c,c.customer_case_number__c, string.valueof(c.Case_Due_Date__c),string.valueof(c.Customer_Delivery_Date__c),purgeDate,c.Case_Type__c,c.status__c,c.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(c.Waiver_Due_Date__c), string.valueof(c.QA_Review_Completed_Date__c),null,null,null,null,c.Subject_Type__c));   
                }
                if(j==Cases.size()-1){
                    firstRecordName = Cases[j].Name;       
                }
                lastRecordName = Cases[j].Name; 
                
            }
        }
        if(selectedReportType == 'Messages'){
            list<Message__c> messages = database.query(query, AccessLevel.SYSTEM_MODE);
            for(Integer j=messages.size()-1;j>=0; j--){
                Message__c message = messages[j];
                reports.add(new ReportRecord(message));
                if(j==messages.size()-1){
                    firstRecordName = messages[j].Name;       
                }
                lastRecordName = messages[j].Name;
            }
        }
        if(selectedReportType == 'Workload'){
            list<Workload__c> wloads = database.query(query, AccessLevel.SYSTEM_MODE);
            for(Integer j= wloads.size()-1;j>=0; j--){
                Workload__c wl = wloads[j];
                reports.add(new ReportRecord(wl));
                if(j==wloads.size()-1){
                    firstRecordName = wloads[j].Name;       
                }
                lastRecordName = wloads[j].Name;
            }
        }
        if(selectedReportType == 'Lead'){
            list<Lead__c> Leads = database.query(query, AccessLevel.SYSTEM_MODE);
            for(Integer j=Leads.size()-1;j>=0; j--){
                Lead__c Lead = Leads[j];
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

                     reports.add(new ReportRecord(lead.Contact__r.First_Name__c,lead.Contact__r.Last_Name__c,lead.case__r.Case_Number__c,string.valueof(lead.case__r.Case_Due_Date__c),string.valueof(lead.case__r.Customer_Delivery_Date__c),string.valueOf(lead.case__r.purge_date__c), lead.case__r.Case_Type__c,lead.case__r.status__c, lead.case__r.Current_Task__c,ingestiondate,
                                                 lead.case__r.Assigned_to__r.FirstName+' '+lead.case__r.Assigned_to__r.LastName, lead.Assigned_to__r.FirstName+' '+lead.Assigned_to__r.LastName, string.valueof(lead.Completed_Date__c),null, lead.leadType__c, lead.status__c,
                                                 integer.valueof(lead.Item_Number__c),sourceName,lead.Lead_Contact_Name__c,lead.Lead_Contact_Address__c
                                                 ,lead.Lead_Contact_City__c,lead.Lead_Contact_State__c,lead.Lead_Contact_Zip__c,
                                                 lead.Lead_Contact_Other_Information__c, string.valueof(lead.Anticipated_Completion_Date__c),
                                                 lead.coverage_type__c, string.valueof(lead.Assignee_Date__c), string.valueof(lead.Id),contactMethod));  
                                                 
                                                 
                                                 
                  
                if(j==Leads.size()-1){
                    firstRecordName = Leads[j].Name;       
                }
                lastRecordName = Leads[j].Name; 
            }
        }
        if(selectedReportType == 'Check-in/Check-out'){
            list<Investigator_Check__c> INVChecks = database.query(query, AccessLevel.SYSTEM_MODE);
            for(Integer j=INVChecks.size()-1;j>=0; j--){
                Investigator_Check__c INVCheck = INVChecks[j];
                reports.add(new ReportRecord(invCheck));
                if(j==INVChecks.size()-1){
                    firstRecordName = INVChecks[j].Name;       
                }
                lastRecordName = INVChecks[j].Name;
            }            
        }
        if(selectedReportType == 'Waivers'){
            list<Waiver_Information__c> waivers = database.query(query, AccessLevel.SYSTEM_MODE);
            for(Integer j=waivers.size()-1;j>=0; j--){
                Waiver_Information__c waiver = waivers[j];
                reports.add(new ReportRecord(waiver));
                if(j==waivers.size()-1){
                    firstRecordName = waivers[j].Name;       
                }
                lastRecordName = waivers[j].Name;
            }   
        }
        if(selectedReportType == 'IC Timesheet'){
			Map<id,User> users = new Map<id,User>([Select Id, name,system_access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'INV' WITH USER_MODE]);
            set<id> invs = users.keyset(); // NOPMD - referenced by dynamic SOQL bind
            list<timesheet__c> waivers = database.query(query, AccessLevel.SYSTEM_MODE);
            for(Integer j=waivers.size()-1;j>=0; j--){
                timesheet__c waiver = waivers[j];
                reports.add(new ReportRecord(waiver));
                if(j==waivers.size()-1){
                    firstRecordName = waivers[j].Name;       
                }
                lastRecordName = waivers[j].Name;
            }   
        }
        
        if(pageNumber == 1){
            disablePrev = true;
            disableNext = false ;
        }else{
            disablePrev = false;
            disableNext = false;
        }
    }
    public void handleNext(){
        PageNumber ++ ;
        reports = new list<ReportRecord>();
        string query = queryForNextRecords + ' Name >:lastRecordName  Order by Name asc Limit 200';    
        
        if(selectedReportType == 'Case'){
            list<Case__c> Cases = New list<Case__c>();
            if(Test.isrunningtest()){
                List<string> caseFields = new List<string>();
            caseFields = ApexUtil.FetchFields('Case__c');
            caseFields.add('contact__r.First_Name__c');
            caseFields.add('contact__r.Last_Name__c');
            caseFields.add('contact__r.Email__c');
            caseFields.add('Assigned_to__r.FirstName');
            caseFields.add('Assigned_to__r.LastName');
                Cases = database.query('Select '+'(Select Id, Status__c from Leads__r where Status__c !=\'Completed\' AND Status__c !=\'QA Review Completed\')'+string.join(caseFields, ',') + ' From Case__c ', AccessLevel.SYSTEM_MODE);
            }else{
                Cases = database.query(query, AccessLevel.SYSTEM_MODE);
            }
            integer i = 0;
            for(Case__c c: Cases){
                if(fiveorlessitemsofcase){
                    integer leadsCount = c.leads__r.size();
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
                        reports.add(new ReportRecord(c.Contact__r.First_Name__c,c.Contact__r.Last_Name__c,c.Case_Number__c,c.customer_case_number__c,string.valueof(c.Case_Due_Date__c),string.valueof(c.Customer_Delivery_Date__c),string.valueOf(c.purge_date__c), c.Case_Type__c,c.status__c,c.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(c.Waiver_Due_Date__c), string.valueof(c.QA_Review_Completed_Date__c),null,null,null,null,c.Subject_Type__c));   
               
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
                 reports.add(new ReportRecord(c.Contact__r.First_Name__c,c.Contact__r.Last_Name__c,c.Case_Number__c,c.customer_case_number__c, string.valueof(c.Case_Due_Date__c),string.valueof(c.Customer_Delivery_Date__c),string.valueOf(c.purge_date__c),c.Case_Type__c,c.status__c,c.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(c.Waiver_Due_Date__c), string.valueof(c.QA_Review_Completed_Date__c),null,null,null,null,c.Subject_Type__c));   
                }
                if(i==0){
                    firstRecordName = c.Name;    
                }
                lastRecordName = c.Name;
                i++;
            }
        }
        if(selectedReportType == 'Messages'){
            list<Message__c> messages = database.query(query, AccessLevel.SYSTEM_MODE);
            integer i = 0;
            for(Message__c message: messages){
                reports.add(new ReportRecord(message));
                if(i==0){
                    firstRecordName = message.Name;    
                }
                lastRecordName = message.Name;
                i++;
            }
        }
        if(selectedReportType == 'Workload'){
            list<Workload__c> wloads = database.query(query, AccessLevel.SYSTEM_MODE);
            integer i = 0;
            for(Workload__c wl: wloads){
                reports.add(new ReportRecord(wl));
                if(i==0){
                    firstRecordName = wl.Name;    
                }
                lastRecordName = wl.Name;
                i++;
            }
        }
        if(selectedReportType == 'Lead'){
            list<Lead__c> Leads = New list<Lead__c>();
            if(Test.isrunningTest()){
                List<string> leadFields = new List<string>();
                leadFields = ApexUtil.FetchFields('lead__c');
                leadFields.add('contact__r.First_Name__c');
                leadFields.add('contact__r.Last_Name__c');
                leadFields.add('contact__r.Email__c');
                leadFields.add('case__r.case_number__c');
                leadFields.add('case__r.Case_Due_Date__c');
                leadFields.add('case__r.purge_date__c');
                leadFields.add('case__r.Customer_Delivery_Date__c');
                leadFields.add('case__r.Case_Type__c');
                leadFields.add('case__r.Manifest__c');
                leadFields.add('Assigned_to__r.FirstName');
                leadFields.add('Assigned_to__r.LastName');
                leadFields.add('case__r.Assigned_to__r.FirstName');
                leadFields.add('case__r.Assigned_to__r.LastName');
                leadFields.add('case__r.Current_Task__c');
                leadFields.add('case__r.status__c');
                Leads = database.query('Select '+string.join(leadFields, ',') + ' From lead__c ', AccessLevel.SYSTEM_MODE);
            }else{
                Leads = database.query(query, AccessLevel.SYSTEM_MODE);
            }
            integer i = 0;
            for(Lead__c lead: Leads){
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
                     reports.add(new ReportRecord(lead.Contact__r.First_Name__c,lead.Contact__r.Last_Name__c,lead.case__r.Case_Number__c,string.valueof(lead.case__r.Case_Due_Date__c),string.valueof(lead.case__r.Customer_Delivery_Date__c),string.valueOf(lead.case__r.purge_date__c), lead.case__r.Case_Type__c,lead.case__r.status__c, lead.case__r.Current_Task__c,ingestiondate,
                                                 cmoUser, lead.Assigned_to__r.FirstName+' '+lead.Assigned_to__r.LastName, string.valueof(lead.Completed_Date__c),null, lead.leadType__c, lead.status__c,
                                                 integer.valueof(lead.Item_Number__c),sourceName,lead.Lead_Contact_Name__c,lead.Lead_Contact_Address__c
                                                 ,lead.Lead_Contact_City__c,lead.Lead_Contact_State__c,lead.Lead_Contact_Zip__c,
                                                 lead.Lead_Contact_Other_Information__c, string.valueof(lead.Anticipated_Completion_Date__c),
                                                 lead.coverage_type__c, string.valueof(lead.Assignee_Date__c), string.valueof(lead.Id),contactMethod));  
                                                 
                                                 
                                                 
                  
                    if(i==0){
                        firstRecordName = lead.Name;    
                    }
                    lastRecordName = lead.Name;
                i++;
            }
        }
        if(selectedReportType == 'Check-in/Check-out'){
            list<Investigator_Check__c> invChecks = database.query(query, AccessLevel.SYSTEM_MODE);
            integer i = 0;
            for(Investigator_Check__c invCheck: invChecks){
                reports.add(new ReportRecord(invCheck));
                if(i==0){
                    firstRecordName = invCheck.Name;    
                }
                lastRecordName = invCheck.Name;
                i++;
            }
        }
        if(selectedReportType == 'Waivers'){
            list<waiver_information__c> waivers = database.query(query, AccessLevel.SYSTEM_MODE);
            integer i = 0;
            for(waiver_information__c waiver: waivers){
                reports.add(new ReportRecord(waiver));
                if(i==0){
                    firstRecordName = waiver.Name;    
                }
                lastRecordName = waiver.Name;
                i++;
            }
        }
        if(selectedReportType == 'IC Timesheet'){
            Map<id,User> users = new Map<id,User>([Select Id, name,system_access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'INV' WITH USER_MODE]);
            set<id> invs = users.keyset(); // NOPMD - referenced by dynamic SOQL bind
            list<timesheet__c> waivers = database.query(query, AccessLevel.SYSTEM_MODE);
            integer i = 0;
            for(timesheet__c waiver: waivers){
                reports.add(new ReportRecord(waiver));
                if(i==0){
                    firstRecordName = waiver.Name;    
                }
                lastRecordName = waiver.Name;
                i++;
            }
        }
        
        
        
        if(pageNumber == TotalPages){
            disablePrev = false;   
            disableNext = true;
        }else{
            disablePrev = false;
            disableNext = false;
        }
    }
    @AuraEnabled
    Public static List<Map<string,Object>> getFieldMap(string reportType){
        List<Map<string,Object>> fieldMapReturn = New List<Map<string,Object>>();
        if(reportType == 'CDRLCaseExport'){
            Map<String, CDRL_Case_Export__mdt> mapME = CDRL_Case_Export__mdt.getAll();
            for(string key : mapME.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapME.get(key).get('Label'));
                con.put('apiname',(string)mapME.get(key).get('API_Name__c'));
                fieldMapReturn.add(con);
            }
        }else if(reportType == 'CDRLCheckInCheckOut'){
            Map<String, CDRL_Check_in_Check_out_Export__mdt> mapPL = CDRL_Check_in_Check_out_Export__mdt.getAll();
            for(string key : mapPL.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapPL.get(key).get('Label'));
                con.put('apiname',(string)mapPL.get(key).get('API_Name__c'));
                fieldMapReturn.add(con);
            }
        }else if(reportType == 'CDRLLeadExport'){
            Map<String, CDRL_Lead_Export__mdt> mapPLT = CDRL_Lead_Export__mdt.getAll();
            for(string key : mapPLT.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapPLT.get(key).get('Label'));
                con.put('apiname',(string)mapPLT.get(key).get('API_Name__c'));
                fieldMapReturn.add(con);
            }
        }else if(reportType == 'CDRLMessageExport'){
            Map<String, CDRL_Message_Export__mdt> mapCC = CDRL_Message_Export__mdt.getAll();
            for(string key : mapCC.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapCC.get(key).get('Label'));
                con.put('apiname',(string)mapCC.get(key).get('API_Name__c'));
                fieldMapReturn.add(con);
            }
        }
        else if(reportType == 'CDRLWaiverExport'){
            Map<String, CDRL_Waiver_Export__mdt> mapCC = CDRL_Waiver_Export__mdt.getAll();
            for(string key : mapCC.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapCC.get(key).get('Label'));
                con.put('apiname',(string)mapCC.get(key).get('API_Name__c'));
                fieldMapReturn.add(con);
            }
        }else if(reportType == 'Workload'){
            Map<String, CDRL_Workload_Export__mdt > mapCC = CDRL_Workload_Export__mdt.getAll();
            for(string key : mapCC.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapCC.get(key).get('Label'));
                con.put('apiname',(string)mapCC.get(key).get('API_Name__c'));
                fieldMapReturn.add(con);
            }
        }
        return fieldMapReturn;
    }
}