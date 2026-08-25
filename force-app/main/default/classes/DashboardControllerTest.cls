@isTest
public class DashboardControllerTest {
	@isTest
    static void testBIDashboardController() {
        // Setup test data
        // Create sample cases
        List<Case__c> cases = new List<Case__c>();
        
        contact__c c = New contact__c(first_name__c='Test Subject');
        insert c;
        cases.add(new Case__c(Case_Queue_Status__c='Completed', Case_Completed_Date__c=System.today(),contact__c = c.Id ));
        cases.add(new Case__c(Case_Queue_Status__c='Pending', Case_Completed_Date__c=null,contact__c = c.Id ));
        insert cases;
        
        // Create sample leads
        List<Lead__c> leads = new List<Lead__c>();
        leads.add(new Lead__c(status__c='Completed', LeadType__c='Type1',Contact__c = c.Id,case__c = cases[0].Id));
        leads.add(new Lead__c(status__c='Pending', LeadType__c='Type2',contact__c = c.Id,case__c = cases[1].Id));
        leads.add(new Lead__c(status__c='Pending', LeadType__c='Type1',contact__c = c.Id,case__c = cases[0].Id));
        insert leads;
        
        // Create mock for DIATooling.fetchRecords
        Test.startTest();
        // Mocking the DIATooling.fetchRecords method
        // Simulate the response for total cases
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"totalSize":2}'));
        Test.stopTest();
        
        // Initialize the controller
        DashboardController controller = new DashboardController();
        
        // Verify current week completed case status
        List<String> currentWeekDates = controller.getCurrentWeekDates();
        // Assuming the completed case is for today, and other days should have 0
        String expectedCurrentWeekCompletedCaseStatus = JSON.serialize(new List<List<Object>>{
            new List<Object>{currentWeekDates[0], 1},
            new List<Object>{currentWeekDates[1], 0},
            new List<Object>{currentWeekDates[2], 0},
            new List<Object>{currentWeekDates[3], 0},
            new List<Object>{currentWeekDates[4], 0},
            new List<Object>{currentWeekDates[5], 0}
        });
    }
}