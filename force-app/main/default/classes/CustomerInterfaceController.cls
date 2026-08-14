/** Visualforce controller for customer order and related case information. */
@SuppressWarnings('PMD.ApexDoc, PMD.PropertyNamingConventions, PMD.MethodNamingConventions, PMD.ApexSOQLInjection')
public with sharing class CustomerInterfaceController {
    public List<OrderRecord> customerOrders {get;set;}
    public List<OrderRecord> UploadedcustomerOrders {get;set;}
    public List<OrderRecord> executedCustomerOrders {get;set;}
    public Map<Id,List<Case__c>> executedCustomerOrdersandCasesMap {get;set;}
    public Map<Id,customer_order__c> executedCustomerOrdersMap {get;set;}
    public CustomerInterfaceController(){
        uploadedcustomerOrders = new List<OrderRecord> ();
        executedCustomerOrders = new List<OrderRecord> ();
        UploadedcustomerOrders = FetchOrderInformation('Uploaded'); 
        executedCustomerOrders = FetchOrderInformation('Executed');
        list<string> executedCustomerOrderIds = new list<string>();
        for(OrderRecord ord: executedCustomerOrders){
            executedCustomerOrderIds.add(ord.order.id);    
        }     
        executedCustomerOrdersandCasesMap = new Map<Id,List<Case__c>>();
        executedCustomerOrdersMap = new Map<Id,customer_order__c> ([Select Id, Status__c from customer_order__c where id in:executedCustomerOrderIds WITH USER_MODE]);
        List<Case__c> cases = FetchCasesofCustomerOrder(executedCustomerOrderIds);
        for(Case__c c: cases){
            if(!executedCustomerOrdersandCasesMap.containsKey(c.order__c)){
                executedCustomerOrdersandCasesMap.put(c.order__c, new list<case__c> {c});
            }else{
                executedCustomerOrdersandCasesMap.get(c.order__c).add(c);
            }
        }
    }
    public list<case__c> FetchCasesofCustomerOrder(list<string> orderids){
        List<string> caseFields = new List<string>();
        caseFields = ApexUtil.FetchFields('Case__c');
        String query = 'Select '+string.join(caseFields, ',') + ' From Case__c ';
        //whereCriteria.add(new ApexUtil.Criteria('Order__c', orderids, 'IN:'));
        //where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE Order__c in:orderids'; 
        list<case__c> cases = database.query(query, AccessLevel.SYSTEM_MODE);
        return cases;
    }
    public class OrderRecord{
        public string attachmentId{get;set;}   
        public Customer_Order__c order{get;set;}
        public OrderRecord(string attachmentId, Customer_Order__c order){
            this.order = order;    
            this.attachmentId = attachmentId;
        }
    }
    
    public List<OrderRecord> FetchOrderInformation(string status){
        List<OrderRecord> customerOrders = new List<OrderRecord> ();
        List<string> orderFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        orderFields = ApexUtil.FetchFields('customer_order__c'); 
        orderFields.add('owner.name');
        String query = 'Select '+string.join(orderFields, ',') + ' From customer_order__c ';
        whereCriteria.add(new ApexUtil.Criteria('Status__c',status, '=')); 
        String whereCondition = ApexUtil.generateWhereQuery(whereCriteria); 
        if(String.isNotblank(whereCondition)){
            query = query + ' WHERE '+whereCondition ;     
        }else{
            query = query+' Order by createddate desc';         
        }
        list<customer_order__c> orders = database.query(query, AccessLevel.SYSTEM_MODE);
        List<string> orderIds = new List<string>();
        for(customer_order__c doc: orders){
            orderIds.add(doc.id);
        }
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id, parentid from attachment where parentid in: orderIds WITH USER_MODE];
        Map<String,String> orderNattachmentMap = new Map<String,String>();
        for(attachment att: attachments){
            orderNattachmentMap.put(att.parentid, att.id);    
        }
        
        for(customer_order__c doc: orders){
            customerOrders.add(new OrderRecord(orderNattachmentMap.get(doc.id),doc));  
        }
        
        return customerOrders;
    }
}