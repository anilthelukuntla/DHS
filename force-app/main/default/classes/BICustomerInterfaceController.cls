global class BICustomerInterfaceController {
    public List<OrderRecord> customerOrders {get;set;}
    public List<OrderRecord> UploadedcustomerOrders {get;set;}
    public List<OrderRecord> executedCustomerOrders {get;set;}
    public List<CaseIntakeWrapper> caseIntakes {get;set;}
    public Map<Id,List<DIA_Case__c>> executedCustomerOrdersandCasesMap {get;set;}
    public Map<Id,DIA_Customer_order__c> executedCustomerOrdersMap {get;set;}
    global string subjectFirstNameSearchEntry {get;set;}
    global string subjectLastNameSearchEntry {get;set;}
    global string subjectSSNSearchEntry {get;set;}
    global string customercasenumberentry {get;set;}
	global string selectedStatus {get;set;}
    global date fromDate {get;set;}
    global date toDate {get;set;}
    public list<selectoption> StatusValues {get;set;}
    global List<deliverableWrapper> deliverables {get;set;}
    @RemoteAction
    global static void CreateOrderNDocuments(list<string> contentversionIds){
        system.debug('contentversionIds....'+contentversionIds);
        list<contentversion> contentVersions = [select id,ContentDocumentId from contentversion WHERE ID IN:contentversionIds];
        list<string> contentDocumentIds = new list<string>();
        for(contentversion cv: contentVersions){
        	contentDocumentIds.add(cv.ContentDocumentId);    
        }
        Customer_Order_Upload_Log__c log = new Customer_Order_Upload_Log__c();
        list<ContentDocumentLink> cdlsToCreate = new list<ContentDocumentLink>();
        DIA_Customer_Order__c co = new DIA_Customer_Order__c ();
        co.status__c = 'Uploaded';
        try{
        	insert co; 
            log.DIA_Customer_Order__c  = co.id;
        }catch(Exception ex){
        	log.Error_Message__c = ex.getmessage();        
        }
        insert log;
        for(string contentDocumentId : contentDocumentIds){
        	ContentDocumentLink cdl = new ContentDocumentLink();
			cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = co.id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            cdlsToCreate.add(cdl);
        }
        if(!cdlsToCreate.isEmpty()){
        	insert cdlsToCreate;    
        }
      
        ExecuteCustomerOrdersBatch ctrl = new ExecuteCustomerOrdersBatch(co.id,log.id);
        database.executebatch(ctrl);
    }
    
    public void GetCustomerOrders(){
        
        uploadedcustomerOrders = new List<OrderRecord> ();
        executedCustomerOrders = new List<OrderRecord> ();
        UploadedcustomerOrders = FetchOrderInformation('Uploaded'); 
        executedCustomerOrders = FetchOrderInformation('Executed');
        list<string> executedCustomerOrderIds = new list<string>();
        for(OrderRecord ord: executedCustomerOrders){
            executedCustomerOrderIds.add(ord.order.id);    
        }     
        executedCustomerOrdersandCasesMap = new Map<Id,List<DIA_Case__c>>();
        executedCustomerOrdersMap = new Map<Id,DIA_Customer_order__c> ([Select Id, Status__c,ACD_Date__c from DIA_Customer_order__c where id in:executedCustomerOrderIds order by createddate desc]);
        List<DIA_Case__c> cases = FetchCasesofCustomerOrder(executedCustomerOrderIds);
        for(DIA_Case__c c: cases){
            if(!executedCustomerOrdersandCasesMap.containsKey(c.order__c)){
                executedCustomerOrdersandCasesMap.put(c.order__c, new list<DIA_Case__c> {c});
            }else{
                executedCustomerOrdersandCasesMap.get(c.order__c).add(c);
            }
        }
        for(OrderRecord ord: executedCustomerOrders){
            if(!executedCustomerOrdersandCasesMap.containsKey(ord.order.id)){
                executedCustomerOrdersandCasesMap.put(ord.order.id,new list<dia_case__c>{});  
            }    
        }      
    }
    public BICustomerInterfaceController(){
       getDeliverables();
       GetCustomerOrders();
       getCaseIntakes();
    }
    global void getCaseIntakes(){
    	caseIntakes = new list<CaseIntakeWrapper>();
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('DIA_Case__c');
        caseFields.add('CreatedBy.Name');
		caseFields.add('Contact__r.Last_Name__c');
        caseFields.add('Contact__r.First_Name__c');
        String query = 'Select '+string.join(caseFields, ',')+ ',(select id,Name__c from documents__r order by createdDate Asc) From DIA_Case__c ';
        String where_cond;
        whereCriteria.add(new ApexUtil.Criteria('Case_Origin__c', 'Case Intake', '='));
        where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        System.debug('whereCriteria...'+whereCriteria);
        System.debug('where_cond...'+where_cond);
        query = query + ' WHERE '+where_cond+' Order by Createddate desc';
        list<dia_case__c> cases = database.query(query);
        Map<string,string> docNcaseMap = new Map<string,string>();
        for(DIA_Case__c cse : cases){
            if(cse.documents__r.size() > 0){
                for(dia_document__c doc : cse.documents__r){
                    if(doc.Name__c.startsWithIgnoreCase(cse.customer_Case_number__c)){
                        docNcaseMap.put(cse.Id,doc.Id);
                    }
				}
			}
		}
        system.debug(docNcaseMap);
        Map<string,string> docNatt = New Map<string,string>();
        List<contentdocumentlink> cdl = New List<contentdocumentlink>();
        if(!docNcaseMap.values().isEmpty()){
        	cdl = [select id,contentDocumentId,LinkedEntityId from contentdocumentlink where LinkedEntityId IN: docNcaseMap.values()];
        }
        for(contentdocumentlink dl : cdl){
            docNatt.put(dl.LinkedEntityId,dl.contentDocumentId);
		}
        system.debug(docNatt);
        for(DIA_Case__c cse : cases){
            caseIntakes.add(caseWrapper(cse.Case_Number__c,cse.CreatedBy.Name,cse.createddate,docNatt.get(docNcaseMap.get(cse.Id)),cse.Id,
                                       cse.Case_Completed_Date__c,cse.Case_Due_Date__c,cse.Contact__r.Last_Name__c,cse.customer_case_number__c,cse.Contact__r.First_Name__c));
        }
    }
      global void getDeliverables(){
          selectedStatus = 'All';
        StatusValues = new list<selectoption>();
        StatusValues.add(new selectoption('All','All'));
        StatusValues.add(new selectoption('Delivered','Delivered'));
        StatusValues.add(new selectoption('Delivered canceled','Delivered Canceled'));
        deliverables = New List<deliverableWrapper>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        List<string> caseFields = new List<string>();
        caseFields = ApexUtil.FetchFields('DIA_Case__c');
        caseFields.add('CreatedBy.Name');
		caseFields.add('Contact__r.Last_Name__c');
        caseFields.add('Contact__r.First_Name__c');
        list<string> status = new list<string>{'Delivered','Delivered canceled'};
        String query = 'Select '+string.join(caseFields, ',') + ',(select id,Name__c from documents__r order by createdDate Asc) From DIA_Case__c where Status__c in:status ';
        String where_cond;
        if(String.isNotBlank(string.valueof(subjectFirstNameSearchEntry))){
            whereCriteria.add(new ApexUtil.Criteria('Contact__r.First_Name__c', '%'+String.escapeSingleQuotes(subjectFirstNameSearchEntry)+'%', 'LIKE'));
        }
        if(String.isNotBlank(string.valueof(subjectLastNameSearchEntry))){
            whereCriteria.add(new ApexUtil.Criteria('Contact__r.Last_Name__c', '%'+String.escapeSingleQuotes(subjectLastNameSearchEntry)+'%', 'LIKE'));
        }
        if(String.isNotBlank(string.valueof(subjectSSNSearchEntry))){
            whereCriteria.add(new ApexUtil.Criteria('Contact__r.SSN__c', '%'+subjectSSNSearchEntry+'%', 'LIKE'));
        }
        if(String.isNotBlank(string.valueof(customercasenumberentry))){
            whereCriteria.add(new ApexUtil.Criteria('Customer_Case_Number__c', customercasenumberentry,'='));
        }
		if(fromDate != Null){
			whereCriteria.add(new ApexUtil.Criteria('Case_Completed_Date__c',String.valueof(fromDate), '>=', 'Date'));
		}
		if(toDate != Null){
			whereCriteria.add(new ApexUtil.Criteria('Case_Completed_Date__c',String.valueof(toDate), '<=', 'Date'));
		}
        if(selectedStatus != 'All'){
			whereCriteria.add(new ApexUtil.Criteria('Status__c',selectedStatus, '='));
		}
        //whereCriteria.add(new ApexUtil.Criteria('Status__c', 'Delivered', '='));
        where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        System.debug('whereCriteria...'+whereCriteria);
        System.debug('where_cond...'+where_cond);
          if(string.isnotblank(where_cond)){
              system.debug(where_cond);
              query = query + ' and '+where_cond+' Order by Case_Completed_Date__c desc';
          }else{
              system.debug('null');
              query = query+' Order by Case_Completed_Date__c desc';
          }
        system.debug(query);
        list<DIA_Case__c> cases = database.query(query);
        system.debug(cases);
        Map<string,string> docNcaseMap = new Map<string,string>();
        for(DIA_Case__c cse : cases){
            if(cse.documents__r.size() > 0){
                for(dia_document__c doc : cse.documents__r){
                    if(doc.Name__c.startsWithIgnoreCase(cse.Contact__r.Last_Name__c)){
                        docNcaseMap.put(cse.Id,doc.Id);
                    }
				}
			}
		}
        system.debug(docNcaseMap);
        Map<string,string> docNatt = New Map<string,string>();
        List<contentdocumentlink> cdl = New List<contentdocumentlink>();
        if(!docNcaseMap.values().isEmpty()){
        	cdl = [select id,contentDocumentId,LinkedEntityId from contentdocumentlink where LinkedEntityId IN: docNcaseMap.values()];
        }
        for(contentdocumentlink dl : cdl){
            docNatt.put(dl.LinkedEntityId,dl.contentDocumentId);
		}
        system.debug(docNatt);
        for(DIA_Case__c cse : cases){
            deliverables.add(delWrapper(cse.Case_Number__c,cse.CreatedBy.Name,cse.createddate,docNatt.get(docNcaseMap.get(cse.Id)),cse.Id,
                                       cse.Case_Completed_Date__c,cse.Case_Due_Date__c,cse.Contact__r.Last_Name__c,cse.customer_case_number__c,cse.Contact__r.First_Name__c,cse.status__c));
        }
	}
    
    
        global class deliverableWrapper{
            global string caseId {get;set;}
            global string caseNumber {get;set;}
            global datetime createdDate {get;set;}
            global string createdBy {get;set;}
            global string documentId {get;set;}
            global date completedDate {get;set;}
            global date dueDate {get;set;}
            global string lastName {get;set;}
            global string customerCaseNumber {get;set;}
            global string firstName {get;set;}
            global string status {get;set;}
        }
    public list<DIA_Case__c> FetchCasesofCustomerOrder(list<string> orderids){
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('DIA_Case__c');
        String query = 'Select '+string.join(caseFields, ',') + ' From DIA_Case__c ';
        String where_cond;
        //whereCriteria.add(new ApexUtil.Criteria('Order__c', orderids, 'IN:'));
        //where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        System.debug('where_cond...'+where_cond);
        query = query + ' WHERE Order__c in:orderids'; 
        System.debug('query...'+query);
        list<DIA_Case__c> cases = database.query(query);
        return cases;
    }
    public class OrderRecord{
        public string attachmentId{get;set;}   
        public DIA_Customer_order__c order{get;set;}
        public string logMessage{get;set;}
        public string logAttachmentId{get;set;}
        public OrderRecord(string attachmentId, DIA_Customer_order__c order, string logMessage,string logAttachmentId){
            this.order = order;    
            this.attachmentId = attachmentId;
            this.logMessage = logMessage;
            this.logAttachmentId = logAttachmentId;
        }
    }
    
    public void SaveOrderAction(){
    	list<DIA_Customer_order__c> ordersToUpdate = new list<DIA_Customer_order__c>();
        for(OrderRecord oRecord: executedCustomerOrders){
            if(oRecord.order.acd_date__c != Null){
            	ordersToUpdate.add(oRecord.order);    
            }    
        }
        if(!ordersToUpdate.isEmpty()){
            update ordersToUpdate;
            GetCustomerOrders();
        }
    }
    
    public List<OrderRecord> FetchOrderInformation(string status){
        List<OrderRecord> customerOrders = new List<OrderRecord> ();
        List<string> orderFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        orderFields = ApexUtil.FetchFields('DIA_Customer_order__c'); 
        orderFields.add('owner.name');
        String query = 'Select '+string.join(orderFields, ',') + ' From DIA_Customer_order__c ';
        //whereCriteria.add(new ApexUtil.Criteria('Status__c',status, '=')); 
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        if(String.isNotblank(where_cond)){
            query = query + ' WHERE '+where_cond ;     
        }else{
            query = query+' Order by createddate desc';         
        }
        System.debug('query...'+query);
        list<DIA_Customer_order__c> orders = database.query(query);
        List<string> orderIds = new List<string>();
        for(DIA_Customer_order__c doc: orders){
            orderIds.add(doc.id);
        }
        list< Customer_Order_Upload_Log__c  > logs= new list< Customer_Order_Upload_Log__c >();
        logs = [select id, Error_Message__c ,DIA_Customer_Order__c from Customer_Order_Upload_Log__c where DIA_Customer_Order__c IN:orderIds  ];
        map<string, Customer_Order_Upload_Log__c> orderNlogMap = new map<string,Customer_Order_Upload_Log__c>();
        map<string, string> logNattachmentMap = new map<string,string>();
        list<string> logIds =new list<string>();
        for(Customer_Order_Upload_Log__c log: logs){
        	orderNlogMap.put(log.DIA_Customer_Order__c,log);
            logIds.add(log.id);
        }
        list<attachment> atts = [select id, parentid,name from attachment where parentid in:logIds ];
        for(attachment att: atts){
        	logNattachmentMap.put(att.parentid,att.id);    
        }
        
        List<ContentDocumentLink> documentsAttached = new List<ContentDocumentLink>();
        if(!orderIds.isEmpty())
        documentsAttached = [Select id, ContentDocumentId, ContentDocument.title, LinkedEntityId from ContentDocumentLink WHERE LinkedEntityId IN: orderids and ContentDocument.title='OrderData.csv'];
        Map<String,String> orderNattachmentMap = new Map<String,String>();
        for(ContentDocumentLink cdl: documentsAttached){
            orderNattachmentMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);    
        }
        
        for(DIA_Customer_order__c doc: orders){
            if(orderNlogMap.get(doc.id) == Null){
            	customerOrders.add(new OrderRecord(orderNattachmentMap.get(doc.id),doc,null,null));      
            }else if(orderNlogMap.get(doc.id).error_message__c != Null){
            	customerOrders.add(new OrderRecord(orderNattachmentMap.get(doc.id),doc,orderNlogMap.get(doc.id).error_message__c,null));      	    
            }else if(logNattachmentMap.get(orderNlogMap.get(doc.id).id) != Null){
            	customerOrders.add(new OrderRecord(orderNattachmentMap.get(doc.id),doc,null,logNattachmentMap.get(orderNlogMap.get(doc.id).id)));      	    
            }
            
        }
        
        return customerOrders;
    }
    public static deliverableWrapper delWrapper(string caseNumber, string createdBy, datetime createdDate, string documentId, string caseId, date completedDate, date dueDate, string lastName, string customerCaseNumber,string FirstName,string status){
        	deliverableWrapper del = New deliverableWrapper();
            del.caseNumber = caseNumber;
            del.createdBy = createdBy;
            del.createdDate = createdDate;
            del.documentId = documentId;
            del.caseId = caseId;
            del.completedDate = completedDate;
            del.dueDate = dueDate;
            del.lastName = lastName;
            del.customerCaseNumber = customerCaseNumber;
        	del.FirstName = FirstName;
        	del.status = status;
        return del;
    }
    
    global class caseIntakeWrapper{
            global string caseId {get;set;}
            global string caseNumber {get;set;}
            global datetime createdDate {get;set;}
            global string createdBy {get;set;}
            global string documentId {get;set;}
            global date completedDate {get;set;}
            global date dueDate {get;set;}
            global string lastName {get;set;}
            global string customerCaseNumber {get;set;}
            global string firstName {get;set;}
        	global string status {get;set;}
        }
    public static caseIntakeWrapper caseWrapper(string caseNumber, string createdBy, datetime createdDate, string documentId, string caseId, date completedDate, date dueDate, string lastName, string customerCaseNumber,string FirstName){
        	caseIntakeWrapper del = New caseIntakeWrapper();
            del.caseNumber = caseNumber;
            del.createdBy = createdBy;
            del.createdDate = createdDate;
            del.documentId = documentId;
            del.caseId = caseId;
            del.completedDate = completedDate;
            del.dueDate = dueDate;
            del.lastName = lastName;
            del.customerCaseNumber = customerCaseNumber;
        	del.FirstName = FirstName;
        return del;
    }
	
}