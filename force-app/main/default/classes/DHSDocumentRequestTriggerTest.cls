@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSDocumentRequestTriggerTest {
    @IsTest
    static void assignsExpirationAndProcessesRequest() {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'Document',
            Last_Name__c = 'Request Test'
        );
        insert subject;
        DHS_Case__c parentCase = new DHS_Case__c(DHS_Contact__c = subject.Id);
        insert parentCase;
        DHS_Lead__c lead = new DHS_Lead__c(DHS_Case__c = parentCase.Id);
        insert lead;
        DHS_Document_Request__c request = new DHS_Document_Request__c(
            DHS_Lead__c = lead.Id,
            To_Address__c = 'dhs-test@example.com',
            Investigator_Comments__c = 'Upload requested documents'
        );
        insert request;
        request = [
            SELECT Expiration_Date__c
            FROM DHS_Document_Request__c
            WHERE Id = :request.Id
        ];
        System.assertNotEquals(null, request.Expiration_Date__c, 'Expected the asserted condition to hold');
    }
}
