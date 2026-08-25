/**
 * @description Controls DHS ROI report ordering, draft generation, and preview navigation.
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity')
public without sharing class DHSOrderROIReportController {
    /** @description Provides this DHS API member. */
    public string caseId {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Case__c caseRecord {get;set;}
    /** @description Provides this DHS API member. */
    public List<LeadRecord> leadRecords {get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> orderOptions {get;set;}
    /** @description Provides this DHS API member. */
    public string type{get;set;}
    /** @description Provides this DHS API member. */
    public DHSOrderROIReportController(){
        caseId = String.valueOf(Id.valueOf(ApexPages.currentPage().getParameters().get('id').escapeHtml4()));
        type= apexpages.currentpage().getparameters().get('type');
        orderOptions = new list<selectoption>();
        fetchCaseInformation();
        fetchLeadInformation();
        showroireport = false;
        showPreview = false;
        
        // Initialize preview if this is the preview page
        // Check if we have a sequenceid parameter which indicates we're on the preview page
        String sequenceId = apexpages.currentpage().getparameters().get('sequenceid');
        if (String.isNotBlank(sequenceId)) {
            currentsequenceid = String.valueOf(Id.valueOf(sequenceId.escapeHtml4()));
            initializePreview();
        }
    }
    
    /** @description Provides this DHS API member. */
    public void fetchCaseInformation(){
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
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        //query = query + ' WHERE '+where_cond;
        query = query + ' WHERE '+whereCond; 
        list<DHS_Case__c> cases = database.query(query, AccessLevel.USER_MODE);
        if(!cases.isEmpty()){
            caseRecord = cases[0]; 
        }    
    }
    
    /** @description Provides this DHS API member. */
    public void fetchLeadInformation(){
        orderOptions.add(new selectoption('','--None--'));
        leadRecords = new list<LeadRecord>();
        list<DHS_Lead__c> leads = new List<DHS_Lead__c> ();
        List<string> leadFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        leadFields = DHSApexUtil.FetchFields('DHS_Lead__c');  
        leadFields.add('DHS_Contact__r.First_Name__c');    
        leadFields.add('DHS_Contact__r.Last_Name__c');   
        String query = 'Select '+string.join(leadFields, ',') + ' From DHS_Lead__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        //query = query + ' WHERE '+where_cond+ ' ORDER BY Item_number__c ASC'; 
        query = query + ' WHERE '+whereCond+ ' ORDER BY Item_number__c ASC'; 
        
        leads = database.query(query, AccessLevel.USER_MODE);
        Integer i = 1;
        for(DHS_Lead__c l: leads){
            leadRecords.add(new leadRecord(l,null));    
            orderOptions.add(new selectoption(string.valueof(i),string.valueof(i)));
            i++;
        }
    }
    
    /** @description Provides this DHS API member. */
    public class LeadRecord{
        /** @description Provides this DHS API member. */
        public DHS_Lead__c lead{get;set;}
        /** @description Provides this DHS API member. */
        public integer leadNumber {get;set;}
        public boolean headerTitle { get; set; } // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
        /**
         * @description Provides this DHS API member.
         * @param l Method parameter.
         * @param ln Method parameter.
         */
        public LeadRecord(DHS_Lead__c l, integer  ln){
            this.lead = l;
            this.headerTitle = false;
            this.leadnumber = ln;
        }
    }
    /** @description Provides this DHS API member. */
    public string roiOrderId {get;set;}
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference generateROIReport(){
        DHS_ROI_Report_Order__c roiOrder = new DHS_ROI_Report_Order__c();
        roiOrder.DHS_Case__c = caseRecord.id;
        
        //leadRecords.sort();
        map<double,DHS_Lead__c> orderNLeadMap = new map<double,DHS_Lead__c>();
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
                leaditemnumbers = String.valueof(orderNLeadMap.get(ln).Item_number__c);     
            } else{
                leaditemnumbers = leaditemnumbers + ','+String.valueof(orderNLeadMap.get(ln).Item_number__c);           
            } 
        }
        roiOrder.ROI_Report_Order__c = leaditemnumbers;
        //database.insert(roiOrder,false,AccessLevel.USER_MODE);
        roiOrder.HideTitles__c = string.join(skipTitles,',');
        Database.insert(roiOrder, AccessLevel.USER_MODE);
        roiOrderId = roiOrder.id;
        currentsequenceid = roiOrder.id;
        PageReference redirectPage = Page.DHSROIReportPreview;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        redirectPage.getParameters().put('sequenceid',roiOrder.id);
        return redirectPage;
    }
    
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference generateNattachROIReport(){
        DHS_ROI_Report_Order__c roiOrder = new DHS_ROI_Report_Order__c();
        roiOrder.DHS_Case__c = caseRecord.id;
        
        //leadRecords.sort();
        map<double,DHS_Lead__c> orderNLeadMap = new map<double,DHS_Lead__c>();
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
                leaditemnumbers = String.valueof(orderNLeadMap.get(ln).Item_number__c);     
            } else{
                leaditemnumbers = leaditemnumbers + ','+String.valueof(orderNLeadMap.get(ln).Item_number__c);           
            } 
        }
        roiOrder.ROI_Report_Order__c = leaditemnumbers;
        //database.insert(roiOrder,false,AccessLevel.USER_MODE);
        roiOrder.HideTitles__c = string.join(skipTitles,',');
        Database.insert(roiOrder, AccessLevel.USER_MODE);

        myFutureMethod(caseRecord.id,roiOrder.id);
        PageReference redirectPage = Page.DHSCasedetail;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        return redirectPage;
    }

    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference previewUsingDhsDesigner(){
        generateROIDraft();
        PageReference redirectPage = Page.DHSROIReportDesignerPreviewLauncher;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id', caseId);
        if (String.isNotBlank(currentsequenceid)) {
            redirectPage.getParameters().put('sequenceid', currentsequenceid);
        }
        return redirectPage;
    }
    
    /**
     * @description Provides this DHS API member.
     * @param caseId Method parameter.
     * @param sequenceId Method parameter.
     */
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

        /**
         * @description Provides this DHS API member.
         * @param context Method parameter.
         */
        public void execute(QueueableContext context) {
            System.attachFinalizer(new RoiReportPdfFinalizer());
            generateRoiReportPdf(caseId, sequenceId);
        }
    }

    private class RoiReportPdfFinalizer implements Finalizer {
        /**
         * @description Provides this DHS API member.
         * @param context Method parameter.
         */
        public void execute(FinalizerContext context) {
            context.getResult();
        }
    }

    private static void generateRoiReportPdf(String caseId, String sequenceId) {
        DHS_Document__c doc = new DHS_Document__c();
        doc.Name__c = 'DHSROIReport';
        doc.DHS_Case__c = caseId;
        doc.Added_By__c = UserInfo.getFirstName() + ' '+ UserInfo.getLastName();
        //database.insert(doc,false,AccessLevel.USER_MODE);
        Database.insert(doc, AccessLevel.USER_MODE);
        DHS_Case__c caseRecord = [select Subject_Type__c,DHS_Contact__r.SSN__c from DHS_Case__c where id=:caseId WITH USER_MODE limit 1];
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
        PageReference pr= Page.DHSROIReportV2;
        pr.getParameters().put('sequenceid', sequenceId.escapeHtml4());
        pr.getParameters().put('id', caseId.escapeHtml4());
        
        
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
        Database.insert(att, AccessLevel.USER_MODE);
    }
    /** @description Provides this DHS API member. */
    public string currentsequenceid {get;set;}
    /** @description Provides this DHS API member. */
    public void generateROIDraft(){
        new map<double,DHS_Lead__c>();
        new list<integer>();
        String leaditemnumbers;
        List<integer> skipTitles = New List<integer>();
        for(LeadRecord lr: leadRecords){
                if(lr.headerTitle == true){
                    skipTitles.add(integer.valueOf(lr.lead.Item_number__c));
                }
            if(lr.lead.LeadType__c == 'Subject Interview (ESI/TESI)' || lr.lead.LeadType__c == 'Subject contact (SUBC)'){
                if(leaditemnumbers == Null){
                    leaditemnumbers = String.valueof(lr.lead.Item_number__c);
                }else{
                    leaditemnumbers = leaditemnumbers+ ','+String.valueof(lr.lead.Item_number__c);
                }
            }
        }
        
        
        for(LeadRecord lr: leadRecords){  
            if(lr.lead.LeadType__c != 'Subject Interview (ESI/TESI)' && lr.lead.LeadType__c != 'Subject contact (SUBC)'){
                if(leaditemnumbers == Null){
                    leaditemnumbers = String.valueof(lr.lead.Item_number__c);
                }else{
                    leaditemnumbers = leaditemnumbers+ ','+String.valueof(lr.lead.Item_number__c);
                }
            }
        }
        
        
        
        if(currentsequenceid != Null){
            //list<DHS_ROI_Report_Order__c> roiOrder = [Select Id, ROI_Report_Order__c, DHS_Case__c from DHS_ROI_Report_Order__c WHERE Id=:currentsequenceid WITH USER_MODE];
            list<DHS_ROI_Report_Order__c> roiOrder = [Select Id, ROI_Report_Order__c, DHS_Case__c from DHS_ROI_Report_Order__c WHERE Id=:currentsequenceid WITH USER_MODE ];
            if(!roiOrder.isEmpty()){
                roiOrder[0].ROI_Report_Order__c = leaditemnumbers;
                roiOrder[0].HideTitles__c = string.join(skipTitles,',');
                Database.update(roiOrder, AccessLevel.USER_MODE);   
            }
        }else{
            DHS_ROI_Report_Order__c roiOrder = new DHS_ROI_Report_Order__c();
            roiOrder.DHS_Case__c = caseRecord.id;
            roiOrder.ROI_Report_Order__c = leaditemnumbers;
            roiOrder.HideTitles__c = string.join(skipTitles,',');
            //database.insert(roiOrder,false,AccessLevel.USER_MODE);
            Database.insert(roiOrder, AccessLevel.USER_MODE);
            currentsequenceid = roiOrder.id;    
        }
        showroireport = true;
        
    }
    /** @description Provides this DHS API member. */
    public boolean showroireport { get; private set; }
    /** @description Provides this DHS API member. */
    public boolean showPreview { get; private set; }
    
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference backToReport() {
        PageReference redirectPage = Page.DHSOrderROIReport;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id', caseId);
        redirectPage.getParameters().put('type', 'preview');
        return redirectPage;
    }
    
    /** @description Provides this DHS API member. */
    public void initializePreview() {
        showPreview = true;
        if (currentsequenceid == null) {
            // Generate a default sequence if none exists
            generateROIDraft();
        }
    }
    
}
