/** Supports the legacy Visualforce ROI report ordering workflow. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.ApexSOQLInjection, PMD.ApexSharingViolations, PMD.ApexXSSFromURLParam, PMD.AvoidBooleanMethodParameters, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.DebugsShouldUseLoggingLevel, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions, PMD.StdCyclomaticComplexity')
public class OrderROIReportController {
    public string caseId {get;set;}
    public case__c caseRecord {get;set;}
    public List<LeadRecord> leadRecords {get;set;}
    public list<selectoption> orderOptions {get;set;}
    public string type{get;set;}
    public OrderROIReportController(){
        caseId = apexpages.currentpage().getparameters().get('id');
        type= apexpages.currentpage().getparameters().get('type');
        orderOptions = new list<selectoption>();
        FetchCaseInformation();
        FetchLeadInformation();
        showroireport = false;
        showPreview = false;
        
        // Initialize preview if this is the preview page
        // Check if we have a sequenceid parameter which indicates we're on the preview page
        String sequenceId = apexpages.currentpage().getparameters().get('sequenceid');
        if (String.isNotBlank(sequenceId)) {
            currentsequenceid = sequenceId;
            initializePreview();
        }
    }
    
    public void FetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('Case__c');
        caseFields.add('contact__r.First_Name__c');
        caseFields.add('contact__r.Last_Name__c');
        caseFields.add('contact__r.Email__c');
        caseFields.add('contact__r.Address__c');
        caseFields.add('contact__r.City__c');
        caseFields.add('contact__r.State__c');
        caseFields.add('contact__r.Zip__c');
        caseFields.add('contact__r.SSN__c');
        String query = 'Select '+string.join(caseFields, ',') + ' From Case__c ';
        
        if(String.isNotBlank(caseId)){
            whereCriteria.add(new ApexUtil.Criteria('Id',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        //query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED'; 
        query = query + ' WHERE '+where_cond; 
        list<case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0]; 
        }    
    }
    
    public void FetchLeadInformation(){
        orderOptions.add(new selectoption('','--None--'));
        leadRecords = new list<LeadRecord>();
        list<lead__c> leads = new List<Lead__c> ();
        List<string> leadFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        leadFields = ApexUtil.FetchFields('Lead__c');  
        leadFields.add('contact__r.First_Name__c');    
        leadFields.add('contact__r.Last_Name__c');   
        String query = 'Select '+string.join(leadFields, ',') + ' From Lead__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        //query = query + ' WHERE '+where_cond+ ' WITH SECURITY_ENFORCED ORDER BY Item_Number__c ASC'; 
        query = query + ' WHERE '+where_cond+ ' ORDER BY Item_Number__c ASC'; 
        
        leads = database.query(query);
        Integer i = 1;
        for(lead__c l: leads){
            leadRecords.add(new leadRecord(l,null));    
            orderOptions.add(new selectoption(string.valueof(i),string.valueof(i)));
            i++;
        }
    }
    
    public class LeadRecord{
        public lead__c lead{get;set;}
        public integer leadNumber {get;set;}
        public boolean headerTitle { get; set; }
        public LeadRecord(lead__c l, integer  ln){
            this.lead = l;
            this.headerTitle = false;
            this.leadnumber = ln;
        }
    }
    public string roiOrderId {get;set;}
    public PageReference GenerateROIReport(){
        ROI_Report_Order__c roiOrder = new ROI_Report_Order__c();
        roiOrder.case__c = caseRecord.id;
        
        //leadRecords.sort();
        map<double,lead__c> orderNLeadMap = new map<double,lead__c>();
        List<integer> skipTitles = New List<integer>();
        list<integer> leadNumbers = new list<integer>();
        for(LeadRecord lr: leadRecords){  
            if(lr.leadNumber != Null){
                if(lr.headerTitle == true){
                    skipTitles.add(integer.valueOf(lr.lead.Item_number__c));
                }
                orderNLeadMap.put(lr.leadNumber,lr.lead);
                leadNumbers.add(lr.leadNumber);
            }    
        }
        
        
        leadNumbers.sort();
        String leaditemnumbers;
        for(integer ln:leadNumbers){
            if(leaditemnumbers == Null){
                leaditemnumbers = String.valueof(orderNLeadMap.get(ln).item_number__c);     
            } else{
                leaditemnumbers = leaditemnumbers + ','+String.valueof(orderNLeadMap.get(ln).item_number__c);           
            } 
        }
        roiOrder.ROI_Report_Order__c = leaditemnumbers;
        //database.insert(roiOrder,false,AccessLevel.USER_MODE);
        roiOrder.HideTitles__c = string.join(skipTitles,',');
        insert roiOrder;
        roiOrderId = roiOrder.id;
        currentsequenceid = roiOrder.id;
        PageReference redirectPage = Page.ROIReportPreview;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        redirectPage.getParameters().put('sequenceid',roiOrder.id);
        return redirectPage;
    }
    
    public PageReference GenerateNattachROIReport(){
        ROI_Report_Order__c roiOrder = new ROI_Report_Order__c();
        roiOrder.case__c = caseRecord.id;
        
        //leadRecords.sort();
        map<double,lead__c> orderNLeadMap = new map<double,lead__c>();
        list<integer> leadNumbers = new list<integer>();
        List<integer> skipTitles = New List<integer>();
        for(LeadRecord lr: leadRecords){  
            if(lr.leadNumber != Null){
                if(lr.headerTitle == true){
                    skipTitles.add(integer.valueOf(lr.lead.Item_number__c));
                }
                orderNLeadMap.put(lr.leadNumber,lr.lead);
                leadNumbers.add(lr.leadNumber);
            }    
        }
        
        leadNumbers.sort();
        String leaditemnumbers;
        for(integer ln:leadNumbers){
            if(leaditemnumbers == Null){
                leaditemnumbers = String.valueof(orderNLeadMap.get(ln).item_number__c);     
            } else{
                leaditemnumbers = leaditemnumbers + ','+String.valueof(orderNLeadMap.get(ln).item_number__c);           
            } 
        }
        roiOrder.ROI_Report_Order__c = leaditemnumbers;
        //database.insert(roiOrder,false,AccessLevel.USER_MODE);
        roiOrder.HideTitles__c = string.join(skipTitles,',');
        insert roiOrder;

        myFutureMethod(caseRecord.id,roiOrder.id);
        PageReference redirectPage = Page.CaseDetail;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        return redirectPage;
    }
    
    public static void myFutureMethod(String caseId, String sequenceId) {
        System.enqueueJob(new RoiReportPdfQueueable(caseId, sequenceId));
    }

    private class RoiReportPdfQueueable
        implements Queueable, Database.AllowsCallouts {

        private final String caseId;
        private final String sequenceId;

        RoiReportPdfQueueable(String caseId, String sequenceId) {
            this.caseId = caseId;
            this.sequenceId = sequenceId;
        }

        public void execute(QueueableContext context) {
            System.attachFinalizer(new RoiReportPdfFinalizer());
            generateRoiReportPdf(caseId, sequenceId);
        }
    }

    private class RoiReportPdfFinalizer implements Finalizer {
        public void execute(FinalizerContext context) {
            context.getResult();
        }
    }

    private static void generateRoiReportPdf(String caseId, String sequenceId) {
        Document__c doc = new Document__c();
        doc.Name__c = 'ROIReport';
        doc.case__c = caseId;
        doc.Added_By__c = UserInfo.getFirstName() + ' '+ UserInfo.getLastName();
        //database.insert(doc,false,AccessLevel.USER_MODE);
        insert doc;
        case__c caseRecord = [select Subject_Type__c,Contact__r.SSN__c from case__C where id=:caseId limit 1];
        string applicantType;
        string ssnFormatted;
        if(caseRecord.Subject_Type__c == 'Applicant'){
            applicantType = 'A';
        }
        if(caseRecord.Subject_Type__c == 'Contractor'){
            applicantType = 'C';
        }
        if(caseRecord.Contact__r.SSN__c != Null){
            ssnFormatted = caseRecord.Contact__r.SSN__c.replaceAll('-','');
        }
        PageReference pr= Page.ROIReportV2;
        pr.getParameters().put('sequenceid',sequenceId);
        pr.getParameters().put('id',caseId);
        
        
        Attachment att = new attachment();
        att.ParentId = doc.id;
        att.Name = applicantType + ssnFormatted + 'Rev00.pdf';
        if(!test.isRunningTest()){
            att.Body = pr.getContentAsPDF();    
        }else{
            att.body = blob.valueof('temp');
        }
        
        att.ContentType = 'application/pdf';
        //database.insert(att,false,AccessLevel.USER_MODE);
        insert att;
    }
    public string currentsequenceid {get;set;}
    public void GenerateROIDraft(){
        new map<double,lead__c>();
        new list<integer>();
        String leaditemnumbers;
        List<integer> skipTitles = New List<integer>();
        for(LeadRecord lr: leadRecords){
                if(lr.headerTitle == true){
                    skipTitles.add(integer.valueOf(lr.lead.Item_number__c));
                }
            if(lr.lead.leadType__c == 'Subject Interview (ESI/TESI)' || lr.lead.leadType__c == 'Subject contact (SUBC)'){
                if(leaditemnumbers == Null){
                    leaditemnumbers = String.valueof(lr.lead.item_number__c);
                }else{
                    leaditemnumbers = leaditemnumbers+ ','+String.valueof(lr.lead.item_number__c);
                }
            }
        }
        
        
        for(LeadRecord lr: leadRecords){  
            if(lr.lead.leadType__c != 'Subject Interview (ESI/TESI)' && lr.lead.leadType__c != 'Subject contact (SUBC)'){
                if(leaditemnumbers == Null){
                    leaditemnumbers = String.valueof(lr.lead.item_number__c);
                }else{
                    leaditemnumbers = leaditemnumbers+ ','+String.valueof(lr.lead.item_number__c);
                }
            }
        }
        
        
        
        if(currentsequenceid != Null){
            //list<ROI_Report_Order__c> roiOrder = [Select Id, ROI_Report_Order__c, case__C from ROI_Report_Order__c WHERE Id=:currentsequenceid WITH SECURITY_ENFORCED];
            list<ROI_Report_Order__c> roiOrder = [Select Id, ROI_Report_Order__c, case__C from ROI_Report_Order__c WHERE Id=:currentsequenceid];
            if(!roiOrder.isEmpty()){
                roiOrder[0].ROI_Report_Order__c = leaditemnumbers;
                roiOrder[0].HideTitles__c = string.join(skipTitles,',');
                update roiOrder;   
            }
        }else{
            ROI_Report_Order__c roiOrder = new ROI_Report_Order__c();
            roiOrder.case__c = caseRecord.id;
            roiOrder.ROI_Report_Order__c = leaditemnumbers;
            roiOrder.HideTitles__c = string.join(skipTitles,',');
            //database.insert(roiOrder,false,AccessLevel.USER_MODE);
            insert roiOrder;
            currentsequenceid = roiOrder.id;    
        }
        showroireport = true;
        
    }
    public boolean showroireport { get; private set; }
    public boolean showPreview { get; private set; }
    
    public PageReference backToReport() {
        PageReference redirectPage = Page.OrderROIReport;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id', caseId);
        redirectPage.getParameters().put('type', 'preview');
        return redirectPage;
    }
    
    public void initializePreview() {
        showPreview = true;
        if (currentsequenceid == null) {
            // Generate a default sequence if none exists
            GenerateROIDraft();
        }
    }
    
}