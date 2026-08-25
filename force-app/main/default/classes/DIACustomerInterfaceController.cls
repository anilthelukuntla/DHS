public class DIACustomerInterfaceController {
    public List<OrderRecord> customerOrders {get;set;}
    public List<OrderRecord> UploadedcustomerOrders {get;set;}
    public List<OrderRecord> executedCustomerOrders {get;set;}
    public Map<Id,List<DIA_Case__c>> executedCustomerOrdersandCasesMap {get;set;}
    public Map<Id,DIA_Customer_order__c> executedCustomerOrdersMap {get;set;}
    public string OrderUploadDocumentId {get;set;}
    public DIACustomerInterfaceController(){
         List<document> documents = new list<document>();
        String orderUploadTemplateName = System.label.OrderUploadTemplateName;
        system.debug(orderUploadTemplateName);
        documents = [select id from document where name=:orderUploadTemplateName];
        if(!documents.isEmpty()){
            OrderUploadDocumentId = documents[0].id;
        }
        System.debug('OrderUploadDocumentId...'+OrderUploadDocumentId);
        uploadedcustomerOrders = new List<OrderRecord> ();
        executedCustomerOrders = new List<OrderRecord> ();
        UploadedcustomerOrders = FetchOrderInformation('Uploaded'); 
        executedCustomerOrders = FetchOrderInformation('Executed');
        list<string> executedCustomerOrderIds = new list<string>();
        for(OrderRecord ord: executedCustomerOrders){
            executedCustomerOrderIds.add(ord.order.id);    
        }     
        executedCustomerOrdersandCasesMap = new Map<Id,List<DIA_Case__c>>();
        executedCustomerOrdersMap = new Map<Id,DIA_Customer_order__c> ([Select Id, Status__c from DIA_Customer_order__c where id in:executedCustomerOrderIds WITH SECURITY_ENFORCED]);
        List<DIA_Case__c> cases = FetchCasesofCustomerOrder(executedCustomerOrderIds);
        for(DIA_Case__c c: cases){
            if(!executedCustomerOrdersandCasesMap.containsKey(c.order__c)){
                executedCustomerOrdersandCasesMap.put(c.order__c, new list<DIA_Case__c> {c});
            }else{
                executedCustomerOrdersandCasesMap.get(c.order__c).add(c);
            }
        }
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
        query = query + ' WHERE Order__c in:orderids WITH SECURITY_ENFORCED'; 
        System.debug('query...'+query);
        list<DIA_Case__c> cases = database.query(query);
        return cases;
    }
    public class OrderRecord{
        public string attachmentId{get;set;}   
        public DIA_Customer_order__c order{get;set;}
        public OrderRecord(string attachmentId, DIA_Customer_order__c order){
            this.order = order;    
            this.attachmentId = attachmentId;
        }
    }
    
    public List<OrderRecord> FetchOrderInformation(string status){
        List<OrderRecord> customerOrders = new List<OrderRecord> ();
        List<string> orderFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        orderFields = ApexUtil.FetchFields('DIA_Customer_order__c'); 
        orderFields.add('owner.name');
        String query = 'Select '+string.join(orderFields, ',') + ' From DIA_Customer_order__c ';
        whereCriteria.add(new ApexUtil.Criteria('Status__c',status, '=')); 
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        if(String.isNotblank(where_cond)){
            query = query + ' WHERE '+where_cond ;     
        }else{
            query = query+' WITH SECURITY_ENFORCED Order by createddate desc ';         
        }
        System.debug('query...'+query);
        list<DIA_Customer_order__c> orders = database.query(query);
        List<string> orderIds = new List<string>();
        for(DIA_Customer_order__c doc: orders){
            orderIds.add(doc.id);
        }
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id, parentid from attachment where parentid in: orderIds WITH SECURITY_ENFORCED];
        Map<String,String> orderNattachmentMap = new Map<String,String>();
        for(attachment att: attachments){
            orderNattachmentMap.put(att.parentid, att.id);    
        }
        
        for(DIA_Customer_order__c doc: orders){
            customerOrders.add(new OrderRecord(orderNattachmentMap.get(doc.id),doc));  
        }
        
        return customerOrders;
    }
}