public class OrderROIReportControllerV2 {
    public string caseId {get;set;}
    public case__c caseRecord {get;set;}
    public List<LeadRecord> leadRecords {get;set;}
    public list<AllLeads> leadRecordss {get;set;}
    public list<selectoption> orderOptions {get;set;}
    public Map<string,list<selectoption>> subheaderOptions {get;set;}
    public string type{get;set;}
    public boolean showOnlyConsiderasPersonal {get;set;}
    public OrderROIReportControllerV2(){
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
        public boolean issubheader {get;set;}
        public boolean hasSequence {get;set;}
        public string subheaderNumber {get;set;}
        public Lead__c leadrecord {get;set;}
        public integer leadNumber {get;set;}
        public boolean headerTitle {get;set;}
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
        System.debug('query...'+query);
        list<case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0]; 
        }    
    }
    
    public void FetchLeadInformation(){
        Map<string,integer> personalsNCount = New Map<string,integer>();
        orderOptions.add(new selectoption('','--None--'));
        list<string> subheaderLeads = New list<string>{'Residence (RESI)', 'Education (EDUC)', 'Employment (EMPL)', 'General (GENL)'};
        leadRecords = new list<LeadRecord>();
        list<lead__c> leads = new List<Lead__c> ();
        List<string> leadFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        leadFields = ApexUtil.FetchFields('Lead__c');  
        leadFields.add('contact__r.First_Name__c');    
        leadFields.add('contact__r.Last_Name__c');   
        String query = 'SELECT ' + String.join(leadFields, ',') +
               ' FROM Lead__c WHERE Case__c = \'' + caseId + '\'';
        if(showOnlyConsiderasPersonal){
            query += ' AND LeadType__c IN (\'Residence (RESI)\', \'Education (EDUC)\', \'Employment (EMPL)\', \'General (GENL)\')';
            query += ' AND Coverage_Type__c IN (\'General Record\', \'Record\')';
        }
        	query += ' ORDER BY Item_Number__c ASC';
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        //query = query + ' WHERE '+where_cond+ ' WITH SECURITY_ENFORCED ORDER BY Item_Number__c ASC'; 
        
        
        leads = database.query(query);
        System.debug('leadquery...'+query);
        Integer i = 1;
        leadRecordss = New list<AllLeads>();
        for(lead__c l: leads){
            system.debug(l.LeadType__c);
            AllLeads ld = New AllLeads();
            ld.leadrecord = l;
            ld.leadNumber = null;
            ld.subheaderNumber = null;
            ld.headerTitle = false;
            if(subheaderLeads.contains(l.LeadType__c)){
                if(l.Coverage_Type__c != 'Personal' && l.Consider_As_Personal__c == false){
                    ld.issubheader = false;
                    ld.hasSequence = true;
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
                    ld.hasSequence = true;
                    ld.issubheader = true;
                    if(!subheaderOptions.containsKey(l.LeadType__c))subheaderOptions.put(l.LeadType__c,new list<selectoption>());
                    
                }
            }else{
                ld.hasSequence = true;
                ld.issubheader = false;
                orderOptions.add(new selectoption(string.valueof(i),string.valueof(i)));
                i++;
                if(!subheaderOptions.containsKey(l.LeadType__c))subheaderOptions.put(l.LeadType__c,new list<selectoption>());
            }
            
            leadRecordss.add(ld);
        }
            system.debug(subheaderOptions);
            system.debug(personalsNCount);
            for(string subHeaderOption : subheaderOptions.keyset()){
                list<selectoption> opts = subheaderOptions.get(subHeaderOption);
                if(!opts.isempty()){
                    if(!opts.isempty()){
                        opts.add(0,new selectoption('','--None--'));
                    }
                }else{
                    if(subheaderLeads.contains(subHeaderOption)){
                        system.debug(subHeaderOption);
                        system.debug(personalsNCount.get(subHeaderOption));
                        integer count = personalsNCount.get(subHeaderOption);
                        for(integer j = 0; j < count; j++){
                            orderOptions.add(new selectoption(string.valueof(i),string.valueof(i)));
                            i++;
                        }
                        for(AllLeads al : leadRecordss){
                            if(subHeaderOption == al.leadrecord.leadtype__c){
                                al.issubheader = false;
                            }
                            system.debug(al);
                        }
                        
                    }
                    
                }
                
            }
    }
    
    public class LeadRecord{
        public lead__c lead{get;set;}
        public integer leadNumber {get;set;}
        public LeadRecord(lead__c l, integer  ln){
            this.lead = l;
            
            this.leadnumber = ln;
        }
    }
    public void updateLeads(){
        List<Lead__c> updateLeads = New List<Lead__c>();
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
        ROI_Report_Order__c roiOrder = new ROI_Report_Order__c();
        roiOrder.case__c = caseRecord.id;
        
        //map<double,lead__c> orderNLeadMap = new map<double,lead__c>();
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
            system.debug(ln);
            allleads lr = allLeadMap.get(ln);
            sequenceItemNumbers.add(integer.valueOf(lr.leadrecord.item_number__c));
            
            if(!subHeaderMap.containskey(integer.valueOf(lr.leadrecord.item_number__c)))subHeaderMap.put(integer.valueOf(lr.leadrecord.item_number__c),new List<integer>());
        }
        system.debug(subHeaderMap);
        for(allleads lr: leadRecordss){
            if(lr.subheaderNumber != null){
                if(subHeaderMap.containskey(integer.valueOf(lr.subheaderNumber))){
                    subHeaderMap.get(integer.valueOf(lr.subheaderNumber)).add(integer.valueOf(lr.leadrecord.item_number__c));
                }
            }
        }
        
        system.debug(subHeaderMap);
        string value = '{';
                list<string> values = New list<string>();
                for(integer i :  subHeaderMap.keyset()){
                    values.add(i+'='+subHeaderMap.get(i));
                }
                value += string.join(values,', ')+'}';
                system.debug(value);
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
        PageReference redirectPage = Page.ROIReportPreviewV2;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        redirectPage.getParameters().put('sequenceid',roiOrder.id);
        return redirectPage;
    }
    
    public PageReference GenerateNattachROIReport(){
        ROI_Report_Order__c roiOrder = new ROI_Report_Order__c();
        roiOrder.case__c = caseRecord.id;
        
        String order;
        //leadRecords.sort();
        map<double,lead__c> orderNLeadMap = new map<double,lead__c>();
        list<integer> leadNumbers = new list<integer>();
        
        for(LeadRecord lr: leadRecords){  
            if(lr.leadNumber != Null){
                System.debug('lr...'+lr.leadNumber);
                orderNLeadMap.put(lr.leadNumber,lr.lead);
                leadNumbers.add(lr.leadNumber);
            }    
        }
        
        leadNumbers.sort();
        System.debug('leadnumbers...'+leadnumbers);
        String leaditemnumbers;
        for(integer ln:leadNumbers){
            if(leaditemnumbers == Null){
                leaditemnumbers = String.valueof(orderNLeadMap.get(ln).item_number__c);     
            } else{
                leaditemnumbers = leaditemnumbers + ','+String.valueof(orderNLeadMap.get(ln).item_number__c);           
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
        
        System.debug('leaditemnumbers...'+leaditemnumbers);
        roiOrder.ROI_Report_Order__c = leaditemnumbers;
        roiOrder.HideTitles__c = string.join(leadNumberNHideTitle,',');
        //database.insert(roiOrder,false,AccessLevel.USER_MODE);
        insert roiOrder;
        System.debug('roiOrder...'+roiOrder);
        
        
        myFutureMethod(caseRecord.id,roiOrder.id);
        PageReference redirectPage = Page.CaseDetail;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        return redirectPage;
    }
    
    @future(callout=true)
    public static void myFutureMethod(string caseId, string sequenceId)
    {   
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
        PageReference pr= Page.ROIReportV3;
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
        list<string> subheaderLeads = New list<string>{'Residence (RESI)', 'Education (EDUC)', 'Employment (EMPL)', 'General (GENL)'};
        Map<integer,List<integer>> subHeaderMap = New Map<integer,List<integer>>();
        for(allleads lr: leadRecordss){
            if(!subHeaderMap.containskey(integer.valueOf(lr.leadrecord.item_number__c)))subHeaderMap.put(integer.valueOf(lr.leadrecord.item_number__c),new List<integer>());
        }
        system.debug(subHeaderMap.keyset());
        List<integer> leadNumberNHideTitle = New List<integer>();
        if(!Test.isrunningTest()){
            for(allleads lr: leadRecordss){
                if(lr.subheaderNumber != null){
                    subHeaderMap.get(integer.valueOf(lr.subheaderNumber)).add(integer.valueOf(lr.leadrecord.item_number__c));
                    if(subHeaderMap.containskey(integer.valueOf(lr.leadrecord.item_number__c))){
                        subHeaderMap.remove(integer.valueOf(lr.leadrecord.item_number__c));
                    }
                }
                if(lr.leadrecord.item_number__c != null){
                    if(lr.headerTitle != false){
                        leadNumberNHideTitle.add(integer.valueOf(lr.leadrecord.item_number__c));
                    }
                }
                
            }
        }for(integer key : subHeaderMap.keyset()){
            system.debug(key+'...'+subHeaderMap.get(key));
        }
        string value = '{';
                list<string> values = New list<string>();
                for(integer i :  subHeaderMap.keyset()){
                    values.add(i+'='+subHeaderMap.get(i));
                }
                value += string.join(values,', ')+'}';
                system.debug(value);
        //system.debug(subHeaderMap);
        
        /*
        
        Map<string,Map<string,List<string>>> subHeaderNLeadsMap = New Map<string,Map<string,List<string>>>();
        Map<string,List<string>> noSubHeaderMap = New Map<string,List<string>>();
        list<string> subheaderLeads = New list<string>{'Residence (RESI)', 'Education (EDUC)', 'Employment (EMPL)', 'General (GENL)'};
        for(allleads lr: leadRecordss){
            if(subheaderLeads.contains(lr.leadrecord.leadType__c)){
                if(lr.leadrecord.Coverage_Type__c == 'Personal'){
                    if(!subHeaderNLeadsMap.containskey(lr.leadrecord.leadType__c)) subHeaderNLeadsMap.put(lr.leadrecord.leadType__c,New Map<string,List<string>>());
                    Map<string,List<string>> headerNSubHeader = subHeaderNLeadsMap.get(lr.leadrecord.leadType__c);
                    if(lr.subheaderNumber != null){
                        if(!headerNSubHeader.containsKey(lr.subheaderNumber))headerNSubHeader.put(lr.subheaderNumber,New List<string>());
                        headerNSubHeader.get(lr.subheaderNumber).add(string.valueOf(lr.leadrecord.item_number__c));
                        subHeaderNLeadsMap.put(lr.leadrecord.leadType__c,headerNSubHeader);
                    }else{
                        if(!noSubHeaderMap.containskey(lr.leadrecord.leadType__c)) noSubHeaderMap.put(lr.leadrecord.leadType__c,New List<string>());
                        noSubHeaderMap.get(lr.leadrecord.leadType__c).add(string.valueOf(lr.leadrecord.item_number__c));
                    }
                }
            }else if(lr.leadrecord.leadType__c != 'Subject Interview (ESI/TESI)' && lr.leadrecord.leadType__c != 'Subject contact (SUBC)'){
                if(leaditemnumbers == Null){
                    leaditemnumbers = String.valueof(lr.leadrecord.item_number__c);
                }else{
                    leaditemnumbers = leaditemnumbers+ ','+String.valueof(lr.leadrecord.item_number__c);
                }
            }
        }
        for(allleads lr: leadRecordss){
            if(subheaderLeads.contains(lr.leadrecord.leadType__c)){
                if(lr.leadrecord.Coverage_Type__c != 'Personal'){
                    Map<string,List<string>> checkExistingItemNumber = subHeaderNLeadsMap.get(lr.leadrecord.leadType__c);
                    system.debug(checkExistingItemNumber);
                    if(!checkExistingItemNumber.containskey(string.valueOf(lr.leadrecord.item_number__c))){
                        if(!noSubHeaderMap.containskey(lr.leadrecord.leadType__c)) noSubHeaderMap.put(lr.leadrecord.leadType__c,New List<string>());
                        noSubHeaderMap.get(lr.leadrecord.leadType__c).add(string.valueOf(lr.leadrecord.item_number__c));
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
            list<ROI_Report_Order__c> roiOrder = [Select Id, ROI_Report_Order__c,Subheader_Order__c, case__C from ROI_Report_Order__c WHERE Id=:currentsequenceid];
            if(!roiOrder.isEmpty()){
                roiOrder[0].ROI_Report_Order__c = value;
                roiOrder[0].HideTitles__c = string.join(leadNumberNHideTitle,',');
                update roiOrder;   
            }
        }else{
            ROI_Report_Order__c roiOrder = new ROI_Report_Order__c();
            roiOrder.case__c = caseRecord.id;
            roiOrder.ROI_Report_Order__c = value;
            roiOrder.HideTitles__c = string.join(leadNumberNHideTitle,',');
            insert roiOrder;
            currentsequenceid = roiOrder.id;    
        }
        showroireport = true;
        
    }
    public boolean showroireport {get;set;}
    public boolean showPreview {get;set;}
    
    public PageReference backToReport() {
        PageReference redirectPage = Page.OrderROIReportV2;
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