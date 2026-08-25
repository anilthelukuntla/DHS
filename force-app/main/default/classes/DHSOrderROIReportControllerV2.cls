/**
 * @description Retains the existing DHSOrderROIReportControllerV2 integration and application behavior.
 */
@SuppressWarnings('PMD.ApexSOQLInjection,PMD.ApexSharingViolations,PMD.AvoidDeeplyNestedIfStmts,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.EmptyStatementBlock,PMD.ExcessivePublicCount,PMD.NcssCount,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity')
public class DHSOrderROIReportControllerV2 {
    /** @description Provides this DHS API member. */
    public string caseId {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Case__c caseRecord {get;set;}
    /** @description Provides this DHS API member. */
    public List<LeadRecord> leadRecords {get;set;}
    /** @description Provides this DHS API member. */
    public list<AllLeads> leadRecordss {get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> orderOptions {get;set;}
    /** @description Provides this DHS API member. */
    public Map<string,list<selectoption>> subheaderOptions {get;set;}
    /** @description Provides this DHS API member. */
    public string type{get;set;}
    public boolean showOnlyConsiderasPersonal { get; set; } // NOPMD - Boolean is required by the Visualforce contract.
    /** @description Provides this DHS API member. */
    public DHSOrderROIReportControllerV2(){
        showOnlyConsiderasPersonal = false;
        caseId = String.valueOf(Id.valueOf(ApexPages.currentPage().getParameters().get('id').escapeHtml4()));
        type= apexpages.currentpage().getparameters().get('type');
        orderOptions = new list<selectoption>();
        subheaderOptions = New Map<string,list<selectoption>>();
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
    public class AllLeads{
        /** @description Provides this DHS API member. */
        public boolean issubheader { get; private set; }
        /** @description Provides this DHS API member. */
        public boolean hasSequence { get; private set; }
        /** @description Provides this DHS API member. */
        public string subheaderNumber {get;set;}
        /** @description Provides this DHS API member. */
        public DHS_Lead__c leadrecord {get;set;}
        /** @description Provides this DHS API member. */
        public integer leadNumber {get;set;}
        public boolean headerTitle { get; set; } // NOPMD - Boolean is required by the existing Visualforce or Apex contract.

        /** @description Provides this DHS API member. */
        public void clearSubheader() {
            issubheader = false;
        }

        /** @description Provides this DHS API member. */
        public void markSubheader() {
            issubheader = true;
        }

        /** @description Provides this DHS API member. */
        public void markHasSequence() {
            hasSequence = true;
        }

        /** @description Provides this DHS API member. */
        public void markHeaderTitle() {
            headerTitle = true;
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
        //query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED'; 
        query = query + ' WHERE '+whereCond; 
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        list<DHS_Case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0]; 
        }    
    }
    
    /** @description Provides this DHS API member. */
    public void fetchLeadInformation(){
        Map<string,integer> personalsNCount = New Map<string,integer>();
        orderOptions.add(new selectoption('','--None--'));
        list<string> subheaderLeads = New list<string>{'Residence (RESI)', 'Education (EDUC)', 'Employment (EMPL)', 'General (GENL)'};
        leadRecords = new list<LeadRecord>();
        list<DHS_Lead__c> leads = new List<DHS_Lead__c> ();
        List<string> leadFields = new List<string>();
        leadFields = DHSApexUtil.FetchFields('DHS_Lead__c');  
        leadFields.add('DHS_Contact__r.First_Name__c');    
        leadFields.add('DHS_Contact__r.Last_Name__c');   
        String query = 'SELECT ' + String.join(leadFields, ',') +
               ' FROM DHS_Lead__c WHERE DHS_Case__c = \'' + caseId + '\'';
        if(showOnlyConsiderasPersonal){
            query += ' AND LeadType__c IN (\'Residence (RESI)\', \'Education (EDUC)\', \'Employment (EMPL)\', \'General (GENL)\')';
            query += ' AND Coverage_Type__c IN (\'General Record\', \'Record\')';
        }
        	query += ' ORDER BY Item_number__c ASC';
        
        //query = query + ' WHERE '+where_cond+ ' WITH SECURITY_ENFORCED ORDER BY Item_number__c ASC'; 
        
        
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        leads = database.query(query);
        Integer i = 1;
        leadRecordss = New list<AllLeads>();
        for(DHS_Lead__c l: leads){
            AllLeads ld = New AllLeads();
            ld.leadrecord = l;
            ld.leadNumber = null;
            ld.subheaderNumber = null;
            if(subheaderLeads.contains(l.LeadType__c)){
                if(l.Coverage_Type__c != 'Personal' && l.Consider_As_Personal__c == false){
                    ld.clearSubheader();
                    ld.markHasSequence();
                    if(!subheaderOptions.containsKey(l.LeadType__c)) { subheaderOptions.put(l.LeadType__c,New list<selectoption>()); }
                    subheaderOptions.get(l.LeadType__c).add(new selectoption(string.valueof(l.Item_number__c),string.valueof(l.Item_number__c)));
                    
                    orderOptions.add(new selectoption(string.valueof(i),string.valueof(i)));
                    i++;
                }else{
                    if(subheaderLeads.contains(l.LeadType__c)){
                        if(!personalsNCount.containskey(l.LeadType__c)) { personalsNCount.put(l.LeadType__c,0); }
                        integer count = personalsNCount.get(l.LeadType__c);
                        integer increment = count +1;
                        personalsNCount.put(l.LeadType__c,increment);
                    }
                    ld.markHasSequence();
                    ld.markSubheader();
                    if(!subheaderOptions.containsKey(l.LeadType__c)) { subheaderOptions.put(l.LeadType__c,new list<selectoption>()); }
                    
                }
            }else{
                ld.markHasSequence();
                ld.clearSubheader();
                orderOptions.add(new selectoption(string.valueof(i),string.valueof(i)));
                i++;
                if(!subheaderOptions.containsKey(l.LeadType__c)) { subheaderOptions.put(l.LeadType__c,new list<selectoption>()); }
            }
            
            leadRecordss.add(ld);
        }
            for(string subHeaderOption : subheaderOptions.keyset()){
                list<selectoption> opts = subheaderOptions.get(subHeaderOption);
                if(!opts.isempty()){
                    if(!opts.isempty()){
                        opts.add(0,new selectoption('','--None--'));
                    }
                }else{
                    if(subheaderLeads.contains(subHeaderOption)){
                        integer count = personalsNCount.get(subHeaderOption);
                        for(integer j = 0; j < count; j++){
                            orderOptions.add(new selectoption(string.valueof(i),string.valueof(i)));
                            i++;
                        }
                        for(AllLeads al : leadRecordss){
                            if(subHeaderOption == al.leadrecord.LeadType__c){
                                al.clearSubheader();
                            }
                        }
                        
                    }
                    
                }
                
            }
    }
    
    /** @description Provides this DHS API member. */
    public class LeadRecord{
        /** @description Provides this DHS API member. */
        public DHS_Lead__c lead{get;set;}
        /** @description Provides this DHS API member. */
        public integer leadNumber {get;set;}
        /**
         * @description Provides this DHS API member.
         * @param l Method parameter.
         * @param ln Method parameter.
         */
        public LeadRecord(DHS_Lead__c l, integer  ln){
            this.lead = l;
            
            this.leadnumber = ln;
        }
    }
    /** @description Provides this DHS API member. */
    public void updateLeads(){
        List<DHS_Lead__c> updateLeads = New List<DHS_Lead__c>();
        for(allleads lr: leadRecordss){
            updateLeads.add(lr.leadrecord);
        }
        Database.update(updateLeads, AccessLevel.USER_MODE);
        fetchCaseInformation();
        fetchLeadInformation();
    }
    
    /** @description Provides this DHS API member. */
    public void reloadLeads(){
        fetchCaseInformation();
        fetchLeadInformation();
    }
    
    /** @description Provides this DHS API member. */
    public string roiOrderId {get;set;}
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference generateROIReport(){
        /*Map<string,Map<string,List<string>>> subHeaderNLeadsMap = New Map<string,Map<string,List<string>>>();
        Map<string,List<string>> noSubHeaderMap = New Map<string,List<string>>();
        list<string> subheaderLeads = New list<string>{'Residence (RESI)', 'Education (EDUC)', 'Employment (EMPL)', 'General (GENL)'};*/
        List<integer> leadNumberNHideTitle = New List<integer>();
        DHS_ROI_Report_Order__c roiOrder = new DHS_ROI_Report_Order__c();
        roiOrder.DHS_Case__c = caseRecord.id;
        
        //map<double,DHS_Lead__c> orderNLeadMap = new map<double,DHS_Lead__c>();
        list<integer> leadNumbers = new list<integer>();
        map<integer,allleads> allLeadMap = New map<integer,allleads>();
        for(allleads lr: leadRecordss){  
            if(lr.leadNumber != Null){
                if(lr.headerTitle != false){
                    leadNumberNHideTitle.add(integer.valueOf(lr.leadrecord.Item_number__c));
                }
                //orderNLeadMap.put(lr.leadNumber,lr.leadrecord);
                allLeadMap.put(lr.leadNumber,lr);
                leadNumbers.add(lr.leadNumber);
            }    
        }
        
        leadNumbers.sort();
        //
        //String leaditemnumbers;
        list<integer> sequenceItemNumbers = New list<integer>();
        Map<integer,List<integer>> subHeaderMap = New Map<integer,List<integer>>();
        for(integer ln:leadNumbers){
            allleads lr = allLeadMap.get(ln);
            sequenceItemNumbers.add(integer.valueOf(lr.leadrecord.Item_number__c));
            
            if(!subHeaderMap.containskey(integer.valueOf(lr.leadrecord.Item_number__c))) { subHeaderMap.put(integer.valueOf(lr.leadrecord.Item_number__c),new List<integer>()); }
        }
        for(allleads lr: leadRecordss){
            if(lr.subheaderNumber != null){
                if(subHeaderMap.containskey(integer.valueOf(lr.subheaderNumber))){
                    subHeaderMap.get(integer.valueOf(lr.subheaderNumber)).add(integer.valueOf(lr.leadrecord.Item_number__c));
                }
            }
        }
        
        string value = '{';
                list<string> values = New list<string>();
                for(integer i :  subHeaderMap.keyset()){
                    values.add(i+'='+subHeaderMap.get(i));
                }
                value += string.join(values,', ')+'}';
        string orderItems = '';
        for(integer i : sequenceItemNumbers){
            orderItems += i+',';
        }
        roiOrder.ROI_Report_Order__c = value;
        roiOrder.Subheader_Order__c = orderItems;
        roiOrder.HideTitles__c  = string.join(leadNumberNHideTitle,',');
        Database.insert(roiOrder, AccessLevel.USER_MODE);
        roiOrderId = roiOrder.id;
        currentsequenceid = roiOrder.id;
        PageReference redirectPage = Page.DHSROIReportPreviewV2;
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
        
        for(LeadRecord lr: leadRecords){  
            if(lr.leadNumber != Null){
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
        List<integer> leadNumberNHideTitle = New List<integer>();
        for(allleads lr: leadRecordss){  
            if(lr.leadNumber != Null){
                if(lr.headerTitle != false){
                    leadNumberNHideTitle.add(integer.valueOf(lr.leadrecord.Item_number__c));
                }
            }    
        }
        
        roiOrder.ROI_Report_Order__c = leaditemnumbers;
        roiOrder.HideTitles__c = string.join(leadNumberNHideTitle,',');
        //database.insert(roiOrder,false,AccessLevel.USER_MODE);
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
        doc.Name__c = 'ROIReport';
        doc.DHS_Case__c = caseId;
        doc.Added_By__c = UserInfo.getFirstName() + ' '+ UserInfo.getLastName();
        //database.insert(doc,false,AccessLevel.USER_MODE);
        Database.insert(doc, AccessLevel.USER_MODE);
        DHS_Case__c caseRecord = [select Subject_Type__c,DHS_Contact__r.SSN__c from DHS_Case__c where id=:caseId  WITH USER_MODE limit 1];
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
        PageReference pr= Page.DHSROIReportV3;
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
        Map<integer,List<integer>> subHeaderMap = New Map<integer,List<integer>>();
        for(allleads lr: leadRecordss){
            if(!subHeaderMap.containskey(integer.valueOf(lr.leadrecord.Item_number__c))) { subHeaderMap.put(integer.valueOf(lr.leadrecord.Item_number__c),new List<integer>()); }
        }
        List<integer> leadNumberNHideTitle = New List<integer>();
        if(!Test.isrunningTest()){
            for(allleads lr: leadRecordss){
                if(lr.subheaderNumber != null){
                    subHeaderMap.get(integer.valueOf(lr.subheaderNumber)).add(integer.valueOf(lr.leadrecord.Item_number__c));
                    if(subHeaderMap.containskey(integer.valueOf(lr.leadrecord.Item_number__c))){
                        subHeaderMap.remove(integer.valueOf(lr.leadrecord.Item_number__c));
                    }
                }
                if(lr.leadrecord.Item_number__c != null){
                    if(lr.headerTitle != false){
                        leadNumberNHideTitle.add(integer.valueOf(lr.leadrecord.Item_number__c));
                    }
                }
                
            }
        }for(integer key : subHeaderMap.keyset()){
        }
        string value = '{';
                list<string> values = New list<string>();
                for(integer i :  subHeaderMap.keyset()){
                    values.add(i+'='+subHeaderMap.get(i));
                }
                value += string.join(values,', ')+'}';
        //
        
        /*
        
        Map<string,Map<string,List<string>>> subHeaderNLeadsMap = New Map<string,Map<string,List<string>>>();
        Map<string,List<string>> noSubHeaderMap = New Map<string,List<string>>();
        list<string> subheaderLeads = New list<string>{'Residence (RESI)', 'Education (EDUC)', 'Employment (EMPL)', 'General (GENL)'};
        for(allleads lr: leadRecordss){
            if(subheaderLeads.contains(lr.leadrecord.LeadType__c)){
                if(lr.leadrecord.Coverage_Type__c == 'Personal'){
                    if(!subHeaderNLeadsMap.containskey(lr.leadrecord.LeadType__c)) subHeaderNLeadsMap.put(lr.leadrecord.LeadType__c,New Map<string,List<string>>());
                    Map<string,List<string>> headerNSubHeader = subHeaderNLeadsMap.get(lr.leadrecord.LeadType__c);
                    if(lr.subheaderNumber != null){
                        if(!headerNSubHeader.containsKey(lr.subheaderNumber))headerNSubHeader.put(lr.subheaderNumber,New List<string>());
                        headerNSubHeader.get(lr.subheaderNumber).add(string.valueOf(lr.leadrecord.Item_number__c));
                        subHeaderNLeadsMap.put(lr.leadrecord.LeadType__c,headerNSubHeader);
                    }else{
                        if(!noSubHeaderMap.containskey(lr.leadrecord.LeadType__c)) noSubHeaderMap.put(lr.leadrecord.LeadType__c,New List<string>());
                        noSubHeaderMap.get(lr.leadrecord.LeadType__c).add(string.valueOf(lr.leadrecord.Item_number__c));
                    }
                }
            }else if(lr.leadrecord.LeadType__c != 'Subject Interview (ESI/TESI)' && lr.leadrecord.LeadType__c != 'Subject Recontact (SUBC)'){
                if(leaditemnumbers == Null){
                    leaditemnumbers = String.valueof(lr.leadrecord.Item_number__c);
                }else{
                    leaditemnumbers = leaditemnumbers+ ','+String.valueof(lr.leadrecord.Item_number__c);
                }
            }
        }
        for(allleads lr: leadRecordss){
            if(subheaderLeads.contains(lr.leadrecord.LeadType__c)){
                if(lr.leadrecord.Coverage_Type__c != 'Personal'){
                    Map<string,List<string>> checkExistingItemNumber = subHeaderNLeadsMap.get(lr.leadrecord.LeadType__c);

                    if(!checkExistingItemNumber.containskey(string.valueOf(lr.leadrecord.Item_number__c))){
                        if(!noSubHeaderMap.containskey(lr.leadrecord.LeadType__c)) noSubHeaderMap.put(lr.leadrecord.LeadType__c,New List<string>());
                        noSubHeaderMap.get(lr.leadrecord.LeadType__c).add(string.valueOf(lr.leadrecord.Item_number__c));
                    }
                }
            }
        }
        
        for(string leadtype : noSubHeaderMap.keyset()){
            Map<string,list<string>> subMap = subHeaderNLeadsMap.get(leadtype);
            list<string> nosubmapValues = noSubHeaderMap.get(leadtype);
            for(string nosubmapValue : nosubmapValues){
                subMap.put(nosubmapValue,New list<string>());
            }
            subHeaderNLeadsMap.put(leadtype,subMap);
        }
        */

        
        if(currentsequenceid != Null){
            list<DHS_ROI_Report_Order__c> roiOrder = [Select Id, ROI_Report_Order__c,Subheader_Order__c, DHS_Case__c FROM DHS_ROI_Report_Order__c WHERE Id=:currentsequenceid WITH USER_MODE ];
            if(!roiOrder.isEmpty()){
                roiOrder[0].ROI_Report_Order__c = value;
                roiOrder[0].HideTitles__c = string.join(leadNumberNHideTitle,',');
                Database.update(roiOrder, AccessLevel.USER_MODE);
            }
        }else{
            DHS_ROI_Report_Order__c roiOrder = new DHS_ROI_Report_Order__c();
            roiOrder.DHS_Case__c = caseRecord.id;
            roiOrder.ROI_Report_Order__c = value;
            roiOrder.HideTitles__c = string.join(leadNumberNHideTitle,',');
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
        PageReference redirectPage = Page.DHSOrderROIReportV2;
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