global class UpdateACDDateController {
    public List<OrderRecord> customerOrders {get;set;}
    public List<OrderRecord> UploadedcustomerOrders {get;set;}
    public List<OrderRecord> executedCustomerOrders {get;set;}
    public Map<Id,List<DIA_Case__c>> executedCustomerOrdersandCasesMap {get;set;}
    public Map<Id,DIA_Customer_order__c> executedCustomerOrdersMap {get;set;}
    global string subjectFirstNameSearchEntry {get;set;}
    global string subjectLastNameSearchEntry {get;set;}
    global string subjectSSNSearchEntry {get;set;}
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
    public UpdateACDDateController(){
       getDeliverables();
       GetCustomerOrders();
    }
      global void getDeliverables(){
        deliverables = New List<deliverableWrapper>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        List<string> caseFields = new List<string>();
        caseFields = ApexUtil.FetchFields('DIA_Case__c');
        caseFields.add('CreatedBy.Name');
		caseFields.add('Contact__r.Last_Name__c');
        String query = 'Select '+string.join(caseFields, ',') + ',(select id,Name__c from documents__r) From DIA_Case__c ';
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
        whereCriteria.add(new ApexUtil.Criteria('Current_Task__c', 'QA Review Completed', '='));
        where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        System.debug('whereCriteria...'+whereCriteria);
        System.debug('where_cond...'+where_cond);
        query = query + ' WHERE '+where_cond+' Order by CreatedDate Desc';
        list<DIA_Case__c> cases = database.query(query);
          system.debug(cases);
        Map<string,string> docNcaseMap = new Map<string,string>();
        for(DIA_Case__c cse : cases){
            if(cse.documents__r.size() > 0){
                for(dia_document__c doc : cse.documents__r){
                    if(doc.Name__c == 'ROIReport'){
                        system.debug(doc.Name__c);
                        docNcaseMap.put(cse.Id,doc.Id);
                    }
				}
			}
		}
        Map<string,string> docNatt = New Map<string,string>();
        List<attachment> att = [select id,parentId from attachment where parentId IN: docNcaseMap.values()];
        for(attachment a : att){
            docNatt.put(a.parentId,a.Id);
		}
        for(DIA_Case__c cse : cases){
            deliverableWrapper del = New deliverableWrapper();
            del.caseNumber = cse.Case_Number__c;
            del.createdBy = cse.CreatedBy.Name;
            del.createdDate = cse.createddate;
            del.documentId = docNatt.get(docNcaseMap.get(cse.Id));
            del.caseId = cse.Id;
            del.completedDate = cse.Case_Completed_Date__c;
            del.dueDate = cse.Case_Due_Date__c;
            del.lastName = cse.Contact__r.Last_Name__c;
            deliverables.add(del);
        }
        if(deliverables.size() > 0){
            for(deliverableWrapper dele : deliverables){
                system.debug(dele.caseNumber);
                system.debug(dele.createdDate);
                system.debug(dele.createdBy);
                system.debug(dele.documentId);
            }
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
	
}