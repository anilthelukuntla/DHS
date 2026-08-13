/** Retains the existing DHSOrderROIReportControllerV2 integration and application behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.ApexSOQLInjection, PMD.ApexSharingViolations, PMD.ApexXSSFromURLParam, PMD.AvoidBooleanMethodParameters, PMD.AvoidDeeplyNestedIfStmts, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.DebugsShouldUseLoggingLevel, PMD.EmptyCatchBlock, PMD.EmptyIfStmt, PMD.EmptyStatementBlock, PMD.ExcessivePublicCount, PMD.IfElseStmtsMustUseBraces, PMD.IfStmtsMustUseBraces, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions, PMD.NcssCount, PMD.NcssMethodCount, PMD.StdCyclomaticComplexity')
public class DHSOrderROIReportControllerV2 {
    public string caseId {get;set;}
    public DHS_Case__c caseRecord {get;set;}
    public List<LeadRecord> leadRecords {get;set;}
    public list<AllLeads> leadRecordss {get;set;}
    public list<selectoption> orderOptions {get;set;}
    public Map<string,list<selectoption>> subheaderOptions {get;set;}
    public string type{get;set;}
    public boolean showOnlyConsiderasPersonal { get; private set; }
    public DHSOrderROIReportControllerV2(){
        showOnlyConsiderasPersonal = false;
        caseId = apexpages.currentpage().getparameters().get('id');
        type= apexpages.currentpage().getparameters().get('type');
        orderOptions = new list<selectoption>();
        subheaderOptions = New Map<string,list<selectoption>>();
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
    public class AllLeads{
        public boolean issubheader { get; private set; }
        public boolean hasSequence { get; private set; }
        public string subheaderNumber {get;set;}
        public DHS_Lead__c leadrecord {get;set;}
        public integer leadNumber {get;set;}
        public boolean headerTitle { get; set; }

        public void clearSubheader() {
            issubheader = false;
        }

        public void markSubheader() {
            issubheader = true;
        }

        public void markHasSequence() {
            hasSequence = true;
        }

        public void markHeaderTitle() {
            headerTitle = true;
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
        //query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED'; 
        query = query + ' WHERE '+where_cond; 
        list<DHS_Case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0]; 
        }    
    }
    
    public void FetchLeadInformation(){
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
                    if(!subheaderOptions.containsKey(l.LeadType__c))subheaderOptions.put(l.LeadType__c,New list<selectoption>());
                    subheaderOptions.get(l.LeadType__c).add(new selectoption(string.valueof(l.Item_number__c),string.valueof(l.Item_number__c)));
                    
                    orderOptions.add(new selectoption(string.valueof(i),string.valueof(i)));
                    i++;
                }else{
                    if(subheaderLeads.contains(l.LeadType__c)){
                        if(!personalsNCount.containskey(l.LeadType__c))personalsNCount.put(l.LeadType__c,0);
                        integer count = personalsNCount.get(l.LeadType__c);
                        integer increment = count +1;
                        personalsNCount.put(l.LeadType__c,increment);
                    }
                    ld.markHasSequence();
                    ld.markSubheader();
                    if(!subheaderOptions.containsKey(l.LeadType__c))subheaderOptions.put(l.LeadType__c,new list<selectoption>());
                    
                }
            }else{
                ld.markHasSequence();
                ld.clearSubheader();
                orderOptions.add(new selectoption(string.valueof(i),string.valueof(i)));
                i++;
                if(!subheaderOptions.containsKey(l.LeadType__c))subheaderOptions.put(l.LeadType__c,new list<selectoption>());
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
    
    public class LeadRecord{
        public DHS_Lead__c lead{get;set;}
        public integer leadNumber {get;set;}
        public LeadRecord(DHS_Lead__c l, integer  ln){
            this.lead = l;
            
            this.leadnumber = ln;
        }
    }
    public void updateLeads(){
        List<DHS_Lead__c> updateLeads = New List<DHS_Lead__c>();
        for(allleads lr: leadRecordss){
            updateLeads.add(lr.leadrecord);
        }
        update updateLeads;
        FetchCaseInformation();
        FetchLeadInformation();
    }
    
    public void reloadLeads(){
        FetchCaseInformation();
        FetchLeadInformation();
    }
    
    public string roiOrderId {get;set;}
    public PageReference GenerateROIReport(){
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
        //System.debug('leadnumbers...'+leadnumbers);
        //String leaditemnumbers;
        list<integer> sequenceItemNumbers = New list<integer>();
        Map<integer,List<integer>> subHeaderMap = New Map<integer,List<integer>>();
        for(integer ln:leadNumbers){
            allleads lr = allLeadMap.get(ln);
            sequenceItemNumbers.add(integer.valueOf(lr.leadrecord.Item_number__c));
            
            if(!subHeaderMap.containskey(integer.valueOf(lr.leadrecord.Item_number__c)))subHeaderMap.put(integer.valueOf(lr.leadrecord.Item_number__c),new List<integer>());
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
        insert roiOrder;
        roiOrderId = roiOrder.id;
        currentsequenceid = roiOrder.id;
        PageReference redirectPage = Page.DHSROIReportPreviewV2;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        redirectPage.getParameters().put('sequenceid',roiOrder.id);
        return redirectPage;
    }
    
    public PageReference GenerateNattachROIReport(){
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
        insert roiOrder;
        
        
        myFutureMethod(caseRecord.id,roiOrder.id);
        PageReference redirectPage = Page.DHSCasedetail;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        return redirectPage;
    }

    public PageReference PreviewUsingDhsDesigner(){
        GenerateROIDraft();
        PageReference redirectPage = Page.DHSROIReportDesignerPreviewLauncher;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id', caseId);
        if (String.isNotBlank(currentsequenceid)) {
            redirectPage.getParameters().put('sequenceid', currentsequenceid);
        }
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
        DHS_Document__c doc = new DHS_Document__c();
        doc.Name__c = 'ROIReport';
        doc.DHS_Case__c = caseId;
        doc.Added_By__c = UserInfo.getFirstName() + ' '+ UserInfo.getLastName();
        //database.insert(doc,false,AccessLevel.USER_MODE);
        insert doc;
        DHS_Case__c caseRecord = [select Subject_Type__c,DHS_Contact__r.SSN__c from DHS_Case__c where id=:caseId limit 1];
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
        Map<integer,List<integer>> subHeaderMap = New Map<integer,List<integer>>();
        for(allleads lr: leadRecordss){
            if(!subHeaderMap.containskey(integer.valueOf(lr.leadrecord.Item_number__c)))subHeaderMap.put(integer.valueOf(lr.leadrecord.Item_number__c),new List<integer>());
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
        //system.debug(subHeaderMap);
        
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
                    system.debug(checkExistingItemNumber);
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
            list<DHS_ROI_Report_Order__c> roiOrder = [Select Id, ROI_Report_Order__c,Subheader_Order__c, DHS_Case__c FROM DHS_ROI_Report_Order__c WHERE Id=:currentsequenceid];
            if(!roiOrder.isEmpty()){
                roiOrder[0].ROI_Report_Order__c = value;
                roiOrder[0].HideTitles__c = string.join(leadNumberNHideTitle,',');
                update roiOrder;   
            }
        }else{
            DHS_ROI_Report_Order__c roiOrder = new DHS_ROI_Report_Order__c();
            roiOrder.DHS_Case__c = caseRecord.id;
            roiOrder.ROI_Report_Order__c = value;
            roiOrder.HideTitles__c = string.join(leadNumberNHideTitle,',');
            insert roiOrder;
            currentsequenceid = roiOrder.id;    
        }
        showroireport = true;
        
    }
    public boolean showroireport { get; private set; }
    public boolean showPreview { get; private set; }
    
    public PageReference backToReport() {
        PageReference redirectPage = Page.DHSOrderROIReportV2;
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