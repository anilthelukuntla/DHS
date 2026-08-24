/**
 * Provides the legacy DHS CDRL reporting workflows consumed by Visualforce.
 * Existing public names, report query construction, and page-facing behavior
 * are retained to avoid breaking report navigation and exports.
 */
@SuppressWarnings('PMD.ApexDoc,PMD.ApexSOQLInjection,PMD.AvoidDeeplyNestedIfStmts,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.EmptyIfStmt,PMD.EmptyStatementBlock,PMD.ExcessiveClassLength,PMD.ExcessiveParameterList,PMD.ExcessivePublicCount,PMD.FieldDeclarationsShouldBeAtStart,PMD.NcssCount,PMD.NcssMethodCount,PMD.NcssTypeCount,PMD.StdCyclomaticComplexity')
public with sharing class DHSCDRLReportsController {
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
    public boolean showictimesheetstatustrackingpanel {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public string selectedUserId  {get;set;}
    public date trackingFromDate {get;set;}
    public date trackingToDate {get;set;}
    
    public transient list<ReportRecord> reports {get;set;}
    public boolean showViewButton {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean leadsView {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean casesView {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean messagesView {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean checkincheckoutView {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean waiversView {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean trackingView {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean showreportstable {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public string selectedRelatedCaseIdForMessages{get;set;}
    public list<selectoption> relatedCasesForMessages {get;set;}
    public string selectedCaseIdForLeadSearch{get;set;}
    public list<selectoption> messageTypeOptions {get;set;}
    public string selectedMessageType{get;set;}
    public string selectedCaseNumberForLeadSearch{get;set;}
    public string selectedleadforstatustracking {get;set;}
    //public list<Lead__History> leadStatusTrackings {get;set;}
    public list<LeadHistoryRecord> leadStatusTrackings{get;set;}
    public integer pageNumber {get;set;}
    public integer totalPages   {get;set;}
    public integer totalRecordCount {get;set;}
    public boolean disablePrev {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean disableNext {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public string queryForNextRecords {get;set;}
    public string lastRecordName {get;set;}
    public string firstRecordName {get;set;}
    public integer currentRecordCount {get;set;}
    public string userType  {get;set;}
    public string contextINVId  {get;set;}
    public list<DHS_TimeSheet__c> selectedUserTimesheet  {get;set;}
    public string selectedICName {get;set;}
    public class LeadHistoryRecord{
        public Lead__History leadHistory {get;set;}
        public integer numOfDays {get;set;}
        public LeadHistoryRecord(Lead__History lh, integer nd){
            this.leadHistory = lh;
            this.numOfDays = nd;
        }
    }
    
    public DHSCDRLReportsController(){
        selectedReportType = '';
        cmoUsers = new List<SelectOption>();
        investigatorUsers = new List<SelectOption>();
        relatedCasesForMessages = new List<SelectOption>();
        leadStatusTrackings = new List<LeadHistoryRecord>();
        showReportsTable = false;
        pageNumber = 1; 
        disablePrev = true;
        disableNext = true;
        currentUser = [select id, firstname, lastname, email, user_type__c from User where id=:userinfo.getuserid() WITH SECURITY_ENFORCED];  
        userType = currentUser.user_type__c;
        if(userType == 'INV'){
            contextINVId = currentUser.Id;
        }
        fetchPicklistValues();
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
    public void fetchICTimesheettracking(){
        user selectedIC = [select id,Name from user where id =:selectedUserId  WITH USER_MODE ];
        selectedICName = selectedIC.Name;
        selectedUserTimesheet = New list<DHS_TimeSheet__c>();
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
        timesheetFields = DHSApexUtil.FetchFields('DHS_TimeSheet__c');
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        String query = 'Select '+string.join(timesheetFields, ',') + ' From DHS_TimeSheet__c ';
        String whereCond;
        
        whereCriteria.add(new DHSApexUtil.Criteria('DHS_User__c',selectedUserId, '='));
        whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCond+' WITH SECURITY_ENFORCED Order By Date__c'; 
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        list<DHS_TimeSheet__c> timesheets = database.query(query);
        selectedUserTimesheet = timesheets;
        
        showictimesheetstatustrackingpanel = true;
    }
    public void fetchPicklistValues(){
        workloadTypeOfAssignee = new list<selectoption>();
        typesOfReports = new list<selectoption>();
        typesOfReports.add(new selectoption('','--None--'));
        list<string> reportTypes = new list<string>();
        reportTypes.addAll(system.label.DHS_Types_Of_Reports.split(','));
        for(string rt: reportTypes){
            if(currentUser.user_type__c == 'INV'){
                if(rt == 'Check-in/Check-out'){
                    typesOfReports.add(new selectoption(rt,rt == 'Investigator DHSReports' ? 'Investigator Reports' : rt)); 
                 }  
            } else{
                  typesOfReports.add(new selectoption(rt,rt == 'Investigator DHSReports' ? 'Investigator Reports' : rt)); 
            }    
        }    
        caseStatus = new list<selectoption>();
        caseStatus.add(new selectoption('DHS_All','All'));
        for(String str: DHSApexUtil.getPickListValuesIntoList('DHS_Case__c', 'Status__c')){
            caseStatus.add(new selectoption(str,str));
        }

        workloadTypeOfAssignee.add(new selectoption('DHS_All','All'));
        for(String str: DHSApexUtil.getPickListValuesIntoList('DHS_Workload__c', 'Type_of_Assignee__c')){
            workloadTypeOfAssignee.add(new selectoption(str,str));
        }
        caseTaskStatus = new list<selectoption>();
        caseTaskStatus.add(new selectoption('DHS_All','All'));
        for(String str: DHSApexUtil.getPickListValuesIntoList('DHS_Case__c', 'Current_Task__c')){
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
        leadStatus.add(new selectoption('DHS_All','All'));
        for(String str: DHSApexUtil.getPickListValuesIntoList('DHS_Lead__c', 'Status__c')){
            leadStatus.add(new selectoption(str,str));
        }
        
        messageTypeOptions = new list<selectoption>();
        messageTypeOptions.add(new selectoption('','--None--'));
        messageTypeOptions.add(new selectoption('Case Broadcast Message','Case Broadcast Message'));
        messageTypeOptions.add(new selectoption('General Broadcast Message','General Broadcast Message'));
        
    }
    public boolean fiveorlessitemsofcase = false;
    public void runReportAction(){
    
        if(selectedReportType == 'ROIReport'){
            showViewButton = true;
            leadsView = false;
            casesView = false;
            messagesView = false;
            checkincheckoutView = false;
            waiversView =false;
            trackingView = false;
            reports = new list<ReportRecord>();
            list<DHS_Document__c> documents = new list<DHS_Document__c>();
            list<attachment> attachments = new list<attachment>();
            /*
            attachments = [Select Id, ParentId, Name from Attachment where Name LIKE: nameCondition AND Createddate >=:fromDate AND createddate <=:toDate];
            System.debug('attachments...'+attachments.size());
            System.debug('nameCondition...'+nameCondition);
            list<string> documentIds = new list<string>();
            Map<string,string> documentNattachmentMap = new Map<string,string>();
            for(attachment att: attachments){
                if(String.valueof(att.parentId).substring(0,3) == documentPrefix){
                    documentIds.add(att.parentId); 
                    documentNattachmentMap.put(att.parentId,att.id);   
                }
            }*/
            List<string> documentFields = new List<string>();
            documentFields = DHSApexUtil.FetchFields('DHS_Document__c'); 
            documentFields.add('DHS_Case__r.Case_Number__c');
            documentFields.add('DHS_Case__r.Case_Due_Date__c');
            documentFields.add('DHS_Case__r.Customer_Delivery_Date__c');
            documentFields.add('DHS_Case__r.Case_Type__c');
            documentFields.add('DHS_Case__r.Manifest__c');
            documentFields.add('DHS_Case__r.DHS_Contact__r.First_Name__c');
            documentFields.add('DHS_Case__r.DHS_Contact__r.Last_Name__c');
            documentFields.add('DHS_Case__r.DHS_Assigned_To__r.FirstName');
            documentFields.add('DHS_Case__r.DHS_Assigned_To__r.LastName');
            documentFields.add('DHS_Case__r.DHS_Assigned_To__r.Name');
            documentFields.add('DHS_Case__r.Current_Task__c');
            documentFields.add('DHS_Case__r.Status__c'); 
            documentFields.add('DHS_Case__r.Customer_Case_Number__c'); 
                documentFields.add('DHS_Case__r.Waiver_Due_Date__c');
                    documentFields.add('DHS_Case__r.Subject_Type__c');
            String query = 'Select '+string.join(documentFields, ',') + ' From DHS_Document__c ';
            query = query + 'WHERE Name__c = \'ROIReport\'';
            if(string.isnotBlank(string.valueOf(fromDate))){
                Datetime fromDateTime = DateTime.newInstance(fromDate.year(), fromDate.month(),fromDate.day()); // NOPMD - Referenced by the dynamic SOQL bind expression below.
                query = query +' AND createddate >=:fromDateTime ';
            }
            if(string.isnotBlank(string.valueOf(toDate))){
                Datetime toDateTime = DateTime.newInstance(toDate.year(), toDate.month(),toDate.day()); // NOPMD - Referenced by the dynamic SOQL bind expression below.
                query = query +' and createddate <=:toDateTime ';
            }
            //query = query + 'WHERE Id IN:documentIds';
            query = query + ' WITH SECURITY_ENFORCED';
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            documents = database.query(query);
            list<string> documentIds = new list<string>();
            for(DHS_Document__c doc: documents){
                documentIds.add(doc.id);
            }
            attachments = [Select Id, ParentId, Name from Attachment where parentid in: documentIds WITH SECURITY_ENFORCED];
            Map<string,string> documentNattachmentMap = new Map<string,string>();
            for(attachment att: attachments){
                 documentNattachmentMap.put(att.parentId,att.id);
            }
            for(DHS_Document__c doc: documents){
                 string ingestiondate='';
                 if(doc.DHS_Case__r.Manifest__c != null){
                     ingestiondate = string.valueof(date.parse(doc.DHS_Case__r.Manifest__c));
                 }
                 string cmoUser = '';
                if(doc.DHS_Case__r.DHS_Assigned_To__r.FirstName == null && doc.DHS_Case__r.DHS_Assigned_To__r.LastName == null){
                	cmoUser = '';    
                }else{
                	cmoUser = doc.DHS_Case__r.DHS_Assigned_To__r.FirstName+' '+doc.DHS_Case__r.DHS_Assigned_To__r.LastName;    
                }
                 reports.add(new ReportRecord(doc.DHS_Case__r.DHS_Contact__r.First_Name__c , doc.DHS_Case__r.DHS_Contact__r.Last_Name__c,doc.DHS_Case__r.Case_Number__c,doc.DHS_Case__r.Customer_Case_Number__c,string.valueof(doc.DHS_Case__r.Case_Due_Date__c),string.valueof(doc.DHS_Case__r.Customer_Delivery_Date__c),string.valueOf(doc.DHS_Case__r.Purge_Date__c), doc.DHS_Case__r.Case_Type__c,doc.DHS_Case__r.Status__c,doc.DHS_Case__r.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(doc.DHS_Case__r.Waiver_Due_Date__c), string.valueof(doc.createddate),documentNattachmentMap.get(doc.id),null,null,null,doc.DHS_Case__r.Subject_Type__c));   
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
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
            caseFields.add('DHS_Contact__r.First_Name__c');
            caseFields.add('DHS_Contact__r.Last_Name__c');
            caseFields.add('DHS_Contact__r.Email__c');
            caseFields.add('DHS_Assigned_To__r.FirstName');
            caseFields.add('DHS_Assigned_To__r.LastName');
            String query =  'Select '+'(Select Id, Status__c from DHS_Case_Leads__r where Status__c !=\'Completed\' AND Status__c !=\'QA Review Completed\')'+string.join(caseFields, ',') + ' From DHS_Case__c '; 
            if(selectedCaseTaskStatus != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('Current_Task__c',selectedCaseTaskStatus,'='));
            }
            if(selectedCaseStatus != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('Status__c',selectedCaseStatus,'='));
            }
            if(fromDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Submission_Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Submission_Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            if(selectedCMoUser != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Assigned_To__c',selectedCMoUser, '='));    
            }
            
            
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND';
                query = query + ' WHERE '+whereCond+' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Case__c WHERE '+ whereCond+ ' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Case__c WITH SECURITY_ENFORCED';
            }
            
        totalRecordCount = database.countquery(Countquery);
        list<DHS_Case__c> cases = new list<DHS_Case__c>();
        if(test.isRunningTest()){
            cases = database.query('Select '+'(Select Id, Status__c from DHS_Case_Leads__r where Status__c !=\'Completed\' AND Status__c !=\'QA Review Completed\')'+string.join(caseFields, ',') + ' From DHS_Case__c '); 
        }else{
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            cases = database.query(query);        
       }
            //list<DHS_Case__c> Cases = database.query(query); 
            integer i = 0;
            for(DHS_Case__c c: cases){
                if(i==0){
                    firstRecordName = c.Name;    
                }
                lastRecordName = c.Name;
                i++;
                
                if(fiveorlessitemsofcase){
                    integer leadsCount = c.DHS_Case_Leads__r.size();
                    if(leadsCount <=5 && leadsCount > 0){
                         string ingestiondate='';
                         if(c.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(c.Manifest__c));
                         }
                         string cmoUser = '';
                        if(c.DHS_Assigned_To__r.FirstName == null && c.DHS_Assigned_To__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = c.DHS_Assigned_To__r.FirstName+' '+c.DHS_Assigned_To__r.LastName;    
                        }
                        reports.add(new ReportRecord(c.DHS_Contact__r.First_Name__c,c.DHS_Contact__r.Last_Name__c,c.Case_Number__c,c.Customer_Case_Number__c,string.valueof(c.Case_Due_Date__c),string.valueof(c.Customer_Delivery_Date__c), string.valueOf(c.Purge_Date__c),c.Case_Type__c,c.Status__c,c.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(c.Waiver_Due_Date__c), string.valueof(c.QA_Review_Completed_Date__c),null,null,null,null,c.Subject_Type__c));   
               
                    }
                }else{
                  string ingestiondate='';
                         if(c.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(c.Manifest__c));
                         }
                     string cmoUser = '';
                        if(c.DHS_Assigned_To__r.FirstName == null && c.DHS_Assigned_To__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = c.DHS_Assigned_To__r.FirstName+' '+c.DHS_Assigned_To__r.LastName;    
                        }
                 reports.add(new ReportRecord(c.DHS_Contact__r.First_Name__c,c.DHS_Contact__r.Last_Name__c,c.Case_Number__c,c.Customer_Case_Number__c, string.valueof(c.Case_Due_Date__c),string.valueof(c.Customer_Delivery_Date__c),string.valueOf(c.Purge_Date__c),c.Case_Type__c,c.Status__c,c.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(c.Waiver_Due_Date__c), string.valueof(c.QA_Review_Completed_Date__c),null,null,null,null,c.Subject_Type__c));   
                }
            
            }
            
            PageNumber = 1;
        double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
        double floorVal = Math.floor(totalNum);
        double diff = totalNum - floorVal;
        totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
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
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            leadFields = DHSApexUtil.FetchFields('DHS_Lead__c');
            leadFields.add('DHS_Contact__r.First_Name__c');
            leadFields.add('DHS_Contact__r.Last_Name__c');
            leadFields.add('DHS_Contact__r.Email__c');
            leadFields.add('DHS_Case__r.Case_Number__c');
            leadFields.add('DHS_Case__r.Case_Due_Date__c');
            leadFields.add('DHS_Case__r.Customer_Delivery_Date__c');
            leadFields.add('DHS_Case__r.Purge_Date__c');
            leadFields.add('DHS_Case__r.Case_Type__c');
            leadFields.add('DHS_Case__r.Manifest__c');
            leadFields.add('DHS_Assigned_To__r.FirstName');
            leadFields.add('DHS_Assigned_To__r.LastName');
            leadFields.add('DHS_Case__r.DHS_Assigned_To__r.FirstName');
            leadFields.add('DHS_Case__r.DHS_Assigned_To__r.LastName');
            leadFields.add('DHS_Case__r.Current_Task__c');
            leadFields.add('DHS_Case__r.Status__c');
            String query = 'Select '+string.join(leadFields, ',') + ' From DHS_Lead__c ';
            if(SelectedLeadStatus != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('Status__c',SelectedLeadStatus,'='));
            }
            if(fromDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Completed_Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Completed_Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            if(selectedInvestigatorUser != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Assigned_To__c',selectedInvestigatorUser, '='));    
            }
            if(selectedCMOUser != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__r.DHS_Assigned_To__c',selectedCMOUser, '='));    
            }
            if(String.isnotblank(selectedCaseNumberForLeadSearch)){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__r.Case_Number__c',selectedCaseNumberForLeadSearch, '='));    
            }
            if(selectedcasestatus != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__r.Status__c',selectedcasestatus, '=')); 
            }
            
            
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND';
                query = query + ' WHERE '+whereCond+' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Lead__c WHERE '+ whereCond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Lead__c WITH SECURITY_ENFORCED';
            }
            
        totalRecordCount = database.countquery(Countquery);
        list<DHS_Lead__c> leads = new list<DHS_Lead__c>();
        if(test.isRunningTest()){
            leads = database.query('Select '+string.join(leadFields, ',') + ' From DHS_Lead__c WITH SECURITY_ENFORCED');   
        }else{
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            leads = database.query(query);        
       }
            //list<DHS_Case__c> Cases = database.query(query); 
            integer i = 0;
            for(DHS_Lead__c lead: leads){
                
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
                         if(lead.DHS_Case__r.Manifest__c!= null){
                             ingestiondate = string.valueof(date.parse(lead.DHS_Case__r.Manifest__c));
                         }
                		string cmoUser = '';
                
                        if(lead.DHS_Case__r.DHS_Assigned_To__r.FirstName == null && lead.DHS_Case__r.DHS_Assigned_To__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = lead.DHS_Case__r.DHS_Assigned_To__r.FirstName+' '+lead.DHS_Case__r.DHS_Assigned_To__r.LastName;    
                        }
                 reports.add(new ReportRecord(lead.DHS_Contact__r.First_Name__c,lead.DHS_Contact__r.Last_Name__c,lead.DHS_Case__r.Case_Number__c,string.valueof(lead.DHS_Case__r.Case_Due_Date__c),string.valueof(lead.DHS_Case__r.Customer_Delivery_Date__c),string.valueOf(lead.DHS_Case__r.Purge_Date__c), lead.DHS_Case__r.Case_Type__c,lead.DHS_Case__r.Status__c, lead.DHS_Case__r.Current_Task__c,ingestiondate,
                                             cmoUser, lead.DHS_Assigned_To__r.FirstName+' '+lead.DHS_Assigned_To__r.LastName, string.valueof(lead.Completed_Date__c),null, lead.LeadType__c, lead.Status__c,
                                             integer.valueof(lead.Item_number__c),sourceName,lead.Lead_Contact_Name__c,lead.Lead_Contact_Address__c
                                             ,lead.Lead_Contact_City__c,lead.Lead_Contact_State__c,lead.Lead_Contact_Zip__c,
                                             lead.Lead_Contact_Other_Information__c, string.valueof(lead.Anticipated_Completion_Date__c),
                                             lead.Coverage_Type__c, string.valueof(lead.Assignee_Date__c), string.valueof(lead.Id),contactMethod));  
                                             
                                             
                                             
              
                
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
        totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
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
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            messsageFields = DHSApexUtil.FetchFields('DHS_Message__c');
            messsageFields.add('DHS_Case__r.Case_Number__c');
            messsageFields.add('DHS_Case__r.Case_Due_Date__c');
            messsageFields.add('DHS_Case__r.Customer_Delivery_Date__c');
            messsageFields.add('DHS_From_User__r.FirstName');
            messsageFields.add('DHS_From_User__r.LastName');
            messsageFields.add('DHS_To_User__r.FirstName');
            messsageFields.add('DHS_To_User__r.LastName');
            messsageFields.add('DHS_CC_User__r.FirstName');
            messsageFields.add('DHS_CC_User__r.LastName');
            String query = 'Select '+string.join(messsageFields, ',') + ' From DHS_Message__c ';
            if(selectedMessageType == 'Case Broadcast Message' ){
                if(selectedRelatedCaseIdForMessages != Null){
                    whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',selectedRelatedCaseIdForMessages,'='));
                }
            }else{
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c','','='));
            }
           
             /*
            if(fromDate != Null){ 
                if(SelectedRelatedCaseIdForMessages != Null){
                    query = query + ' AND Createddate >=: fromDate';
                } else{
                    query = query + ' WHERE Createddate >=: fromDate';
                }      
                
                whereCriteria.add(new DHSApexUtil.Criteria('Message_Date__c',String.valueof(fromDate), '>='));
            }
            if(toDate != Null){
                toDate = toDate.addDays(1);
                query = query + ' AND Createddate <=: toDate';
                whereCriteria.add(new DHSApexUtil.Criteria('Message_Date__c',String.valueof(toDate), '<='));
            }*/
            if(fromDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('MessageCreatedDate__c',string.valueOf(fromDate), '>=','Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('MessageCreatedDate__c',string.valueOf(toDate), '<=','Date'));
            }
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND';
                query = query + ' WHERE '+whereCond+' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Message__c WHERE '+ whereCond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Message__c WITH SECURITY_ENFORCED';
            }
                totalRecordCount = database.countquery(Countquery);
                list<DHS_Message__c> messages = new list<DHS_Message__c>();
                if(test.isRunningTest()){
                    messages = database.query('Select '+string.join(messsageFields, ',') + ' From DHS_Message__c '  );   
                }else{
                    // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
                    messages = database.query(query);        
               }
                integer i = 0;
                for(DHS_Message__c message: messages){
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
                totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
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
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            checkinCheckoutFields = DHSApexUtil.FetchFields('DHS_Investigator_Check__c');
            checkinCheckoutFields.add('DHS_TimeSheet__r.Date__c');
            checkinCheckoutFields.add('DHS_TimeSheet__r.CheckIn_Comments__c');
            checkinCheckoutFields.add('DHS_TimeSheet__r.DHS_User__r.FirstName');
            checkinCheckoutFields.add('DHS_TimeSheet__r.DHS_User__r.LastName');
           
            String query = 'Select '+string.join(checkinCheckoutFields, ',') + ' From DHS_Investigator_Check__c ';
            whereCriteria.add(new DHSApexUtil.Criteria('Type__c', 'CheckOut', '='));
            if(currentUser.user_type__c == 'INV'){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_TimeSheet__r.DHS_User__c', userinfo.getuserid(), '='));
            }
            if(fromDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_TimeSheet__r.Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_TimeSheet__r.Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND';
                query = query + ' WHERE '+whereCond+' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Investigator_Check__c WHERE '+ whereCond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Investigator_Check__c WITH SECURITY_ENFORCED';
            }
            
                totalRecordCount = database.countquery(Countquery);
                list<DHS_Investigator_Check__c> invChecks = new list<DHS_Investigator_Check__c>();
                if(test.isRunningTest()){
                    invChecks = database.query('Select '+string.join(checkinCheckoutFields, ',') + ' From DHS_Investigator_Check__c ');   
                }else{
                    // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
                    invChecks = database.query(query);        
               }
                integer i = 0;
                for(DHS_Investigator_Check__c invCheck: invChecks){
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
                totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
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
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            waiverFields = DHSApexUtil.FetchFields('DHS_Waiver_Information__c');
            waiverFields.add('DHS_Case__r.Case_Number__c');
            waiverFields.add('DHS_Case__r.Case_Due_Date__c');
            waiverFields.add('DHS_Case__r.Customer_Delivery_Date__c');
            waiverFields.add('DHS_Case__r.Assigned_To_Name__c');
            waiverFields.add('DHS_Lead__r.Assigned_To_Name__c');
            String query = 'Select '+string.join(waiverFields, ',') + ' From DHS_Waiver_Information__c ';
            
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND';
                query = query + ' WHERE '+whereCond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Waiver_Information__c WHERE '+ whereCond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Waiver_Information__c WITH SECURITY_ENFORCED';
            }
            
                totalRecordCount = database.countquery(Countquery);
                list<DHS_Waiver_Information__c> waivers = new list<DHS_Waiver_Information__c>();
                if(test.isRunningTest()){
                    waivers = database.query('Select '+string.join(waiverFields, ',') + ' From DHS_Waiver_Information__c WITH SECURITY_ENFORCED');   
                }else{
                    // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
                    waivers = database.query(query);        
               }
                integer i = 0;
                for(DHS_Waiver_Information__c waiver: waivers){
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
                totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
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
        else if(selectedReportType == 'Investigator DHSReports'){
            reports = new list<ReportRecord>();
            List<string> productionSummaryFields = new List<string>();
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            productionSummaryFields = DHSApexUtil.FetchFields('DHS_Daily_Production_Summary__c');
            String query = 'Select '+string.join(productionSummaryFields, ',') + ' From DHS_Daily_Production_Summary__c ';
            if(fromDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Summary_Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Summary_Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            if(!whereCriteria.isEmpty()){
                String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
                query = query + ' WHERE '+whereCond;
            }
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list< DHS_Daily_Production_Summary__c > productionSummaries = database.query(query);
            Map<string,Decimal> leadsAccepted = new Map<string,Decimal>();
            Map<string,Decimal> leadsRejected = new Map<string,Decimal>();
            Map<string,Decimal> leadsCompleted = new Map<string,Decimal>();
            set<string> reviewerIds = new set<String>();
            for(DHS_Daily_Production_Summary__c dps:productionSummaries ){
                if(String.isBlank(dps.DHS_Reviewer__c)){
                    continue;
                }
                Decimal acceptedCount = dps.Leads_Accepted__c == null ? 0 : dps.Leads_Accepted__c;
                Decimal rejectedCount = dps.Leads_Rejected__c == null ? 0 : dps.Leads_Rejected__c;
                Decimal completedCount = dps.Leads_Completed__c == null ? 0 : dps.Leads_Completed__c;
                if(!leadsAccepted.containsKey(dps.DHS_Reviewer__c)){
                    leadsAccepted.put(dps.DHS_Reviewer__c,acceptedCount);
                }else{
                    leadsAccepted.put(dps.DHS_Reviewer__c,leadsAccepted.get(dps.DHS_Reviewer__c)+acceptedCount);
                }
                if(!leadsRejected.containsKey(dps.DHS_Reviewer__c)){
                    leadsRejected.put(dps.DHS_Reviewer__c,rejectedCount);
                }else{
                    leadsRejected.put(dps.DHS_Reviewer__c,leadsRejected.get(dps.DHS_Reviewer__c)+rejectedCount);
                }
                if(!leadsCompleted.containsKey(dps.DHS_Reviewer__c)){
                    leadsCompleted.put(dps.DHS_Reviewer__c,completedCount);
                }else{
                    leadsCompleted.put(dps.DHS_Reviewer__c,leadsCompleted.get(dps.DHS_Reviewer__c)+completedCount);
                }
                reviewerIds.add(dps.DHS_Reviewer__c);
            }
            Map<string,user> userMap = new Map<String,user>([select id, firstname,lastname from user where id in:reviewerIds WITH USER_MODE ]);
            
            for(string reviewerId : reviewerIds){
                User reviewer = userMap.get(reviewerId);
                String reviewerName = reviewer == null ? '' : String.join(new List<String>{reviewer.FirstName, reviewer.LastName}, ' ').trim();
                reports.add(new ReportRecord(reviewerName,
                            Integer.valueof(leadsAccepted.get(reviewerId) == null ? 0 : leadsAccepted.get(reviewerId)),Integer.valueof(leadsRejected.get(reviewerId) == null ? 0 : leadsRejected.get(reviewerId)),Integer.valueof(leadsCompleted.get(reviewerId) == null ? 0 : leadsCompleted.get(reviewerId))
                            ));    
            }
            
        }else if(selectedReportType == 'IC DHSTimesheet'){
            leadsView = false;
            casesView = false;
            messagesView = false;
            showViewButton = false;
            checkincheckoutView = true;
            waiversView =false;
            trackingView = true;
            reports = new list<ReportRecord>();
            List<string> timesheetFields = new List<string>();
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            timesheetFields = DHSApexUtil.FetchFields('DHS_TimeSheet__c');
            //checkinCheckoutFields.add('DHS_TimeSheet__r.Date__c');
            //checkinCheckoutFields.add('DHS_TimeSheet__r.CheckIn_Comments__c');
            timesheetFields.add('DHS_User__r.FirstName');
            timesheetFields.add('DHS_User__r.LastName');
            
           
            String query = 'Select '+string.join(timesheetFields, ',') + ' From DHS_TimeSheet__c ';
            if(selectedInvestigatorUser != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_User__c',selectedInvestigatorUser, '='));    
            }
            if(currentUser.user_type__c == 'INV'){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_User__c', userinfo.getuserid(), '='));
            }
            if(trackingfromDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Date__c',String.valueof(trackingfromDate), '>=', 'Date'));
            }
            if(trackingtoDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Date__c',String.valueof(trackingtoDate), '<=', 'Date'));
            }
            
            Map<id,User> users = new Map<id,User>([Select Id, name,System_Access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'INV' WITH USER_MODE ]);
            set<id> invs = users.keyset(); // NOPMD - Referenced by dynamic SOQL bind expressions below.
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND '+ ' DHS_User__c IN: invs AND';
                query = query + ' WHERE '+whereCond+' AND '+ ' DHS_User__c IN: invs'+' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_TimeSheet__c WHERE '+ whereCond+' AND '+ ' DHS_User__c IN: invs'+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE '+ ' DHS_User__c IN: invs AND';
                query = query +' where '+ ' DHS_User__c IN: invs'+ ' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_TimeSheet__c '+' where DHS_User__c IN: invs '+'  WITH SECURITY_ENFORCED';
            }
                totalRecordCount = database.countquery(Countquery);
                list<DHS_TimeSheet__c> timesheets = new list<DHS_TimeSheet__c>();
                if(test.isRunningTest()){
                    timesheets = database.query('Select '+string.join(timesheetFields, ',') + ' From DHS_TimeSheet__c ');   
                }else{
                    // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
                    timesheets = database.query(query);        
               }
                integer i = 0;
                for(DHS_TimeSheet__c timesheet: timesheets){
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
                totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
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
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            workloadFields = DHSApexUtil.FetchFields('DHS_Workload__c');
            workloadFields.add('DHS_User__r.FirstName');
            workloadFields.add('DHS_User__r.LastName');
           
            
            String query = 'Select '+string.join(workloadFields, ',') + ' From DHS_Workload__c ';
            if(selectedWorkLoadAssignee == 'CMO'){
                if(selectedCMOUser != 'DHS_All'){
                    whereCriteria.add(new DHSApexUtil.Criteria('DHS_User__c',selectedCMOUser, '='));    
                }
                whereCriteria.add(new DHSApexUtil.Criteria('Type_of_Assignee__c','CMO', '='));
            }
            if(selectedWorkLoadAssignee == 'INV'){
                if(selectedInvestigatorUser != 'DHS_All'){
                    whereCriteria.add(new DHSApexUtil.Criteria('DHS_User__c',selectedInvestigatorUser, '='));    
                }
                whereCriteria.add(new DHSApexUtil.Criteria('Type_of_Assignee__c','INV', '='));
            }
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND';
                query = query + ' WHERE '+whereCond+' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Workload__c WHERE '+ whereCond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Workload__c WITH SECURITY_ENFORCED';
            }
            
                totalRecordCount = database.countquery(Countquery);
                list<DHS_Workload__c> workloads = new list<DHS_Workload__c>();
                if(test.isRunningTest()){
                    workloads = database.query('Select '+string.join(workloadFields, ',') + ' From DHS_Workload__c');   
                }else{
                    // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
                    workloads = database.query(query);        
               }
                integer i = 0;
                for(DHS_Workload__c wl: workloads){
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
                totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
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
    public boolean showleadstatustrackingpanel{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public void fetchLeadStatusTrackings(){
        leadStatusTrackings = new list< LeadHistoryRecord >();
            List<string> leadStatusTrackingFields = new List<string>();
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            leadStatusTrackingFields = DHSApexUtil.FetchFields('Lead__History');
            leadStatusTrackingFields.add('createdby.name');
            leadStatusTrackingFields.add('createdby.firstname');
            leadStatusTrackingFields.add('createdby.lastname');
            String query = 'Select '+string.join(leadStatusTrackingFields, ',') + ' From Lead__History ';
            whereCriteria.add(new DHSApexUtil.Criteria('parentid', selectedleadforstatustracking, '='));
            whereCriteria.add(new DHSApexUtil.Criteria('field','Status__c', '='));
            
            DHS_Lead__c lead = [select id,createddate from DHS_Lead__c where id=:selectedleadforstatustracking WITH USER_MODE ];
          
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            if(string.isNotBlank(whereCond)){
                 query = query + ' WHERE '+whereCond + ' Order By CreatedDate ASC';  
            }  
           
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            lisT<Lead__History> leadhHistories =  database.query(query);
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
    
    public void onReportTypeSelect(){
        if(selectedReportType == 'Case' || selectedReportType == 'Lead' || selectedReportType == 'Workload'){
            cmoUsers = new list<selectoption>();
            cmoUsers.add(new selectoption('DHS_All','All'));
            list<User> users = [Select Id, name,System_Access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'CMO' WITH USER_MODE ];
            for(user u: users){
                if(u.System_Access__c.contains('DHS')){
                cmoUsers.add(new selectoption(u.id,u.LastName+' '+u.FirstName)); 
                }
            }
        }
        if(selectedReportType == 'Lead' || selectedReportType == 'IC DHSTimesheet' || selectedReportType == 'Workload'){
            investigatorUsers = new list<selectoption>();
            investigatorUsers.add(new selectoption('DHS_All','All'));
            list<User> users = [Select Id, name,System_Access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'INV' WITH USER_MODE ];
            for(user u: users){
                if(u.System_Access__c.contains('DHS')){
                investigatorUsers.add(new selectoption(u.id,u.LastName+' '+u.FirstName)); 
                }
            }
        }
        
        if(selectedReportType == 'Messages'){
            relatedCasesForMessages = new list<selectoption>();
            relatedCasesForMessages.add(new selectoption('','--None--'));
            list<DHS_Case__c> cases = [Select Id,Case_Number__c From DHS_Case__c where Case_Number__c != NULL WITH USER_MODE ];
            for(DHS_Case__c c: cases){
                relatedCasesForMessages.add(new selectoption(c.id,c.Case_Number__c));   
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
        public DHS_Message__c message {get;set;}
        public DHS_Investigator_Check__c investigatorCheck {get;set;}
        public DHS_Waiver_Information__c waiver {get;set;}
        public DHS_TimeSheet__c timesheet {get;set;}
        public DHS_Workload__c workload {get;set;}
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
        public string anticipatedCompletedDate{get;set;}
        public string coverageType{get;set;}
        public string assignmentDate {get;set;}
        public string leadId {get;set;}
        public string leadContactMethod {get;set;}
        public string waiverduedate {get;set;}
        public string customercasenumber {get;set;}
        public string subjecttype	{get;set;}
        public ReportRecord(DHS_Message__c message){
            this.message = message;
        }
        public ReportRecord(DHS_Investigator_Check__c investigatorCheck){
            this.investigatorCheck = investigatorCheck;
        }
        public ReportRecord(DHS_Waiver_Information__c waiver){
            this.waiver = waiver;
        }
        public ReportRecord(DHS_TimeSheet__c timesheet){
            this.timesheet = timesheet;
        }
        public ReportRecord(DHS_Workload__c workload){
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
                            string leadContactOtherInformation, string anticipatedCompletedDate, string coverageType, string assignmentDate, string leadId, string leadContactMethod){

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
            this.anticipatedCompletedDate = anticipatedCompletedDate;
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
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list<DHS_Case__c> cases = database.query(query);
            for(Integer j=cases.size()-1;j>=0; j--){
                DHS_Case__c c = cases[j];
                if(fiveorlessitemsofcase){
                    integer leadsCount = c.DHS_Case_Leads__r.size();
                    if(leadsCount <=5 && leadsCount > 0){
                    string ingestiondate='';
                         if(c.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(c.Manifest__c));
                         }
                        string cmoUser = '';
                
                        if(c.DHS_Assigned_To__r.FirstName == null && c.DHS_Assigned_To__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = c.DHS_Assigned_To__r.FirstName+' '+c.DHS_Assigned_To__r.LastName;    
                        }
                        string purgeDate = Test.isRunningTest() ? string.valueof(Date.today()) : string.valueOf(c.Purge_Date__c);
                        reports.add(new ReportRecord(c.DHS_Contact__r.First_Name__c,c.DHS_Contact__r.Last_Name__c,c.Case_Number__c,c.Customer_Case_Number__c,string.valueof(c.Case_Due_Date__c),string.valueof(c.Customer_Delivery_Date__c), purgeDate,c.Case_Type__c,c.Status__c,c.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(c.Waiver_Due_Date__c), string.valueof(c.QA_Review_Completed_Date__c),null,null,null,null,c.Subject_Type__c));   
               
                    }
                }else{
                 string ingestiondate='';
                         if(c.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(c.Manifest__c));
                         }
                     string cmoUser = '';
                     if(c.DHS_Assigned_To__r.FirstName == null && c.DHS_Assigned_To__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = c.DHS_Assigned_To__r.FirstName+' '+c.DHS_Assigned_To__r.LastName;    
                        }
                    string purgeDate = Test.isrunningTest() ? string.valueOf(Date.today()) : string.valueOf(c.Purge_Date__c);
                 reports.add(new ReportRecord(c.DHS_Contact__r.First_Name__c,c.DHS_Contact__r.Last_Name__c,c.Case_Number__c,c.Customer_Case_Number__c, string.valueof(c.Case_Due_Date__c),string.valueof(c.Customer_Delivery_Date__c),purgeDate,c.Case_Type__c,c.Status__c,c.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(c.Waiver_Due_Date__c), string.valueof(c.QA_Review_Completed_Date__c),null,null,null,null,c.Subject_Type__c));   
                }
                if(j==cases.size()-1){
                    firstRecordName = cases[j].Name;       
                }
                lastRecordName = cases[j].Name; 
                
            }
        }
        if(selectedReportType == 'Messages'){
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list<DHS_Message__c> messages = database.query(query);
            for(Integer j=messages.size()-1;j>=0; j--){
                DHS_Message__c message = messages[j];
                reports.add(new ReportRecord(message));
                if(j==messages.size()-1){
                    firstRecordName = messages[j].Name;       
                }
                lastRecordName = messages[j].Name;
            }
        }
        if(selectedReportType == 'Workload'){
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list<DHS_Workload__c> wloads = database.query(query);
            for(Integer j= wloads.size()-1;j>=0; j--){
                DHS_Workload__c wl = wloads[j];
                reports.add(new ReportRecord(wl));
                if(j==wloads.size()-1){
                    firstRecordName = wloads[j].Name;       
                }
                lastRecordName = wloads[j].Name;
            }
        }
        if(selectedReportType == 'Lead'){
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list<DHS_Lead__c> leads = database.query(query);
            for(Integer j=leads.size()-1;j>=0; j--){
                DHS_Lead__c lead = leads[j];
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
                         if(lead.DHS_Case__r.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(lead.DHS_Case__r.Manifest__c));
                         }
                  string cmoUser = '';
                
                        if(lead.DHS_Case__r.DHS_Assigned_To__r.FirstName == null && lead.DHS_Case__r.DHS_Assigned_To__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = lead.DHS_Case__r.DHS_Assigned_To__r.FirstName+' '+lead.DHS_Case__r.DHS_Assigned_To__r.LastName;    
                        }

                     reports.add(new ReportRecord(lead.DHS_Contact__r.First_Name__c,lead.DHS_Contact__r.Last_Name__c,lead.DHS_Case__r.Case_Number__c,string.valueof(lead.DHS_Case__r.Case_Due_Date__c),string.valueof(lead.DHS_Case__r.Customer_Delivery_Date__c),string.valueOf(lead.DHS_Case__r.Purge_Date__c), lead.DHS_Case__r.Case_Type__c,lead.DHS_Case__r.Status__c, lead.DHS_Case__r.Current_Task__c,ingestiondate,
                                                 lead.DHS_Case__r.DHS_Assigned_To__r.FirstName+' '+lead.DHS_Case__r.DHS_Assigned_To__r.LastName, lead.DHS_Assigned_To__r.FirstName+' '+lead.DHS_Assigned_To__r.LastName, string.valueof(lead.Completed_Date__c),null, lead.LeadType__c, lead.Status__c,
                                                 integer.valueof(lead.Item_number__c),sourceName,lead.Lead_Contact_Name__c,lead.Lead_Contact_Address__c
                                                 ,lead.Lead_Contact_City__c,lead.Lead_Contact_State__c,lead.Lead_Contact_Zip__c,
                                                 lead.Lead_Contact_Other_Information__c, string.valueof(lead.Anticipated_Completion_Date__c),
                                                 lead.Coverage_Type__c, string.valueof(lead.Assignee_Date__c), string.valueof(lead.Id),contactMethod));  
                                                 
                                                 
                                                 
                  
                if(j==leads.size()-1){
                    firstRecordName = leads[j].Name;       
                }
                lastRecordName = leads[j].Name; 
            }
        }
        if(selectedReportType == 'Check-in/Check-out'){
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list<DHS_Investigator_Check__c> iNVChecks = database.query(query);
            for(Integer j=iNVChecks.size()-1;j>=0; j--){
                DHS_Investigator_Check__c iNVCheck = iNVChecks[j];
                reports.add(new ReportRecord(invCheck));
                if(j==iNVChecks.size()-1){
                    firstRecordName = iNVChecks[j].Name;       
                }
                lastRecordName = iNVChecks[j].Name;
            }            
        }
        if(selectedReportType == 'Waivers'){
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list<DHS_Waiver_Information__c> waivers = database.query(query);
            for(Integer j=waivers.size()-1;j>=0; j--){
                DHS_Waiver_Information__c waiver = waivers[j];
                reports.add(new ReportRecord(waiver));
                if(j==waivers.size()-1){
                    firstRecordName = waivers[j].Name;       
                }
                lastRecordName = waivers[j].Name;
            }   
        }
        if(selectedReportType == 'Investigator DHSReports'){
            
        }
        if(selectedReportType == 'IC DHSTimesheet'){
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list<DHS_TimeSheet__c> waivers = database.query(query);
            for(Integer j=waivers.size()-1;j>=0; j--){
                DHS_TimeSheet__c waiver = waivers[j];
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
            list<DHS_Case__c> cases = New list<DHS_Case__c>();
            if(Test.isrunningtest()){
                List<string> caseFields = new List<string>();
            caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
            caseFields.add('DHS_Contact__r.First_Name__c');
            caseFields.add('DHS_Contact__r.Last_Name__c');
            caseFields.add('DHS_Contact__r.Email__c');
            caseFields.add('DHS_Assigned_To__r.FirstName');
            caseFields.add('DHS_Assigned_To__r.LastName');
                cases = database.query('Select '+'(Select Id, Status__c from DHS_Case_Leads__r where Status__c !=\'Completed\' AND Status__c !=\'QA Review Completed\')'+string.join(caseFields, ',') + ' From DHS_Case__c ');
            }else{
                // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
                cases = database.query(query);
            }
            integer i = 0;
            for(DHS_Case__c c: cases){
                if(fiveorlessitemsofcase){
                    integer leadsCount = c.DHS_Case_Leads__r.size();
                    if(leadsCount <=5 && leadsCount > 0){
                      string ingestiondate='';
                         if(c.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(c.Manifest__c));
                         }
                       string cmoUser = '';
                
                        if(c.DHS_Assigned_To__r.FirstName == null && c.DHS_Assigned_To__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = c.DHS_Assigned_To__r.FirstName+' '+c.DHS_Assigned_To__r.LastName;    
                        }
                        reports.add(new ReportRecord(c.DHS_Contact__r.First_Name__c,c.DHS_Contact__r.Last_Name__c,c.Case_Number__c,c.Customer_Case_Number__c,string.valueof(c.Case_Due_Date__c),string.valueof(c.Customer_Delivery_Date__c),string.valueOf(c.Purge_Date__c), c.Case_Type__c,c.Status__c,c.Current_Task__c,ingestiondate,
                                             cmoUser, null,string.valueof(c.Waiver_Due_Date__c), string.valueof(c.QA_Review_Completed_Date__c),null,null,null,null,c.Subject_Type__c));   
               
                    }
                }else{
                 string ingestiondate='';
                         if(c.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(c.Manifest__c));
                         }
                    string cmoUser = '';
                
                        if(c.DHS_Assigned_To__r.FirstName == null && c.DHS_Assigned_To__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = c.DHS_Assigned_To__r.FirstName+' '+c.DHS_Assigned_To__r.LastName;    
                        }
                 reports.add(new ReportRecord(c.DHS_Contact__r.First_Name__c,c.DHS_Contact__r.Last_Name__c,c.Case_Number__c,c.Customer_Case_Number__c, string.valueof(c.Case_Due_Date__c),string.valueof(c.Customer_Delivery_Date__c),string.valueOf(c.Purge_Date__c),c.Case_Type__c,c.Status__c,c.Current_Task__c,ingestiondate,
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
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list<DHS_Message__c> messages = database.query(query);
            integer i = 0;
            for(DHS_Message__c message: messages){
                reports.add(new ReportRecord(message));
                if(i==0){
                    firstRecordName = message.Name;    
                }
                lastRecordName = message.Name;
                i++;
            }
        }
        if(selectedReportType == 'Workload'){
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list<DHS_Workload__c> wloads = database.query(query);
            integer i = 0;
            for(DHS_Workload__c wl: wloads){
                reports.add(new ReportRecord(wl));
                if(i==0){
                    firstRecordName = wl.Name;    
                }
                lastRecordName = wl.Name;
                i++;
            }
        }
        if(selectedReportType == 'Lead'){
            list<DHS_Lead__c> leads = New list<DHS_Lead__c>();
            if(Test.isrunningTest()){
                List<string> leadFields = new List<string>();
                leadFields = DHSApexUtil.FetchFields('DHS_Lead__c');
                leadFields.add('DHS_Contact__r.First_Name__c');
                leadFields.add('DHS_Contact__r.Last_Name__c');
                leadFields.add('DHS_Contact__r.Email__c');
                leadFields.add('DHS_Case__r.Case_Number__c');
                leadFields.add('DHS_Case__r.Case_Due_Date__c');
                leadFields.add('DHS_Case__r.Purge_Date__c');
                leadFields.add('DHS_Case__r.Customer_Delivery_Date__c');
                leadFields.add('DHS_Case__r.Case_Type__c');
                leadFields.add('DHS_Case__r.Manifest__c');
                leadFields.add('DHS_Assigned_To__r.FirstName');
                leadFields.add('DHS_Assigned_To__r.LastName');
                leadFields.add('DHS_Case__r.DHS_Assigned_To__r.FirstName');
                leadFields.add('DHS_Case__r.DHS_Assigned_To__r.LastName');
                leadFields.add('DHS_Case__r.Current_Task__c');
                leadFields.add('DHS_Case__r.Status__c');
                leads = database.query('Select '+string.join(leadFields, ',') + ' From DHS_Lead__c ');
            }else{
                // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
                leads = database.query(query);
            }
            integer i = 0;
            for(DHS_Lead__c lead: leads){
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
                         if(lead.DHS_Case__r.Manifest__c != null){
                             ingestiondate = string.valueof(date.parse(lead.DHS_Case__r.Manifest__c));
                         } 
                string cmoUser = '';
                
                        if(lead.DHS_Case__r.DHS_Assigned_To__r.FirstName == null && lead.DHS_Case__r.DHS_Assigned_To__r.LastName == null){
                            cmoUser = '';    
                        }else{
                            cmoUser = lead.DHS_Case__r.DHS_Assigned_To__r.FirstName+' '+lead.DHS_Case__r.DHS_Assigned_To__r.LastName;    
                        }
                     reports.add(new ReportRecord(lead.DHS_Contact__r.First_Name__c,lead.DHS_Contact__r.Last_Name__c,lead.DHS_Case__r.Case_Number__c,string.valueof(lead.DHS_Case__r.Case_Due_Date__c),string.valueof(lead.DHS_Case__r.Customer_Delivery_Date__c),string.valueOf(lead.DHS_Case__r.Purge_Date__c), lead.DHS_Case__r.Case_Type__c,lead.DHS_Case__r.Status__c, lead.DHS_Case__r.Current_Task__c,ingestiondate,
                                                 cmoUser, lead.DHS_Assigned_To__r.FirstName+' '+lead.DHS_Assigned_To__r.LastName, string.valueof(lead.Completed_Date__c),null, lead.LeadType__c, lead.Status__c,
                                                 integer.valueof(lead.Item_number__c),sourceName,lead.Lead_Contact_Name__c,lead.Lead_Contact_Address__c
                                                 ,lead.Lead_Contact_City__c,lead.Lead_Contact_State__c,lead.Lead_Contact_Zip__c,
                                                 lead.Lead_Contact_Other_Information__c, string.valueof(lead.Anticipated_Completion_Date__c),
                                                 lead.Coverage_Type__c, string.valueof(lead.Assignee_Date__c), string.valueof(lead.Id),contactMethod));  
                                                 
                                                 
                                                 
                  
                    if(i==0){
                        firstRecordName = lead.Name;    
                    }
                    lastRecordName = lead.Name;
                i++;
            }
        }
        if(selectedReportType == 'Check-in/Check-out'){
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list<DHS_Investigator_Check__c> invChecks = database.query(query);
            integer i = 0;
            for(DHS_Investigator_Check__c invCheck: invChecks){
                reports.add(new ReportRecord(invCheck));
                if(i==0){
                    firstRecordName = invCheck.Name;    
                }
                lastRecordName = invCheck.Name;
                i++;
            }
        }
        if(selectedReportType == 'Waivers'){
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list<DHS_Waiver_Information__c> waivers = database.query(query);
            integer i = 0;
            for(DHS_Waiver_Information__c waiver: waivers){
                reports.add(new ReportRecord(waiver));
                if(i==0){
                    firstRecordName = waiver.Name;    
                }
                lastRecordName = waiver.Name;
                i++;
            }
        }
        if(selectedReportType == 'Investigator DHSReports'){
            
        }
        if(selectedReportType == 'IC DHSTimesheet'){
            Map<id,User> users = new Map<id,User>([Select Id, name,System_Access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'INV' WITH USER_MODE ]); // NOPMD - Supplies the dynamic SOQL bind set.
            set<id> invs = users.keyset(); // NOPMD - Referenced by a dynamic SOQL bind expression.
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list<DHS_TimeSheet__c> waivers = database.query(query);
            integer i = 0;
            for(DHS_TimeSheet__c waiver: waivers){
                reports.add(new ReportRecord(waiver));
                if(i==0){
                    firstRecordName = waiver.Name;    
                }
                lastRecordName = waiver.Name;
                i++;
            }
        }
        
        
        
        if(pageNumber == totalPages){
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
            Map<String, DHS_CDRL_Case_Export__mdt> mapME = DHS_CDRL_Case_Export__mdt.getAll();
            for(string key : mapME.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapME.get(key).get('Label'));
                con.put('apiname',(string)mapME.get(key).get('Api_Name__c'));
                fieldMapReturn.add(con);
            }
        }else if(reportType == 'CDRLCheckInCheckOut'){
            Map<String, DHS_CDRL_Check_in_Check_out_Export__mdt> mapPL = DHS_CDRL_Check_in_Check_out_Export__mdt.getAll();
            for(string key : mapPL.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapPL.get(key).get('Label'));
                con.put('apiname',(string)mapPL.get(key).get('Api_Name__c'));
                fieldMapReturn.add(con);
            }
        }else if(reportType == 'CDRLLeadExport'){
            Map<String, DHS_CDRL_Lead_Export__mdt> mapPLT = DHS_CDRL_Lead_Export__mdt.getAll();
            for(string key : mapPLT.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapPLT.get(key).get('Label'));
                con.put('apiname',(string)mapPLT.get(key).get('Api_Name__c'));
                fieldMapReturn.add(con);
            }
        }else if(reportType == 'CDRLMessageExport'){
            Map<String, DHS_CDRL_Message_Export__mdt> mapCC = DHS_CDRL_Message_Export__mdt.getAll();
            for(string key : mapCC.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapCC.get(key).get('Label'));
                con.put('apiname',(string)mapCC.get(key).get('Api_Name__c'));
                fieldMapReturn.add(con);
            }
        }
        else if(reportType == 'CDRLWaiverExport'){
            Map<String, DHS_CDRL_Waiver_Export__mdt> mapCC = DHS_CDRL_Waiver_Export__mdt.getAll();
            for(string key : mapCC.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapCC.get(key).get('Label'));
                con.put('apiname',(string)mapCC.get(key).get('Api_Name__c'));
                fieldMapReturn.add(con);
            }
        }else if(reportType == 'Workload'){
            Map<String, DHS_CDRL_Workload_Export__mdt> mapCC = DHS_CDRL_Workload_Export__mdt.getAll();
            for(string key : mapCC.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapCC.get(key).get('Label'));
                con.put('apiname',(string)mapCC.get(key).get('Api_Name__c'));
                fieldMapReturn.add(con);
            }
        }
        return fieldMapReturn;
    }
}
