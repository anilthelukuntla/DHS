@IsTest
@SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue, PMD.ApexUnitTestClassShouldHaveRunAs')
 public with sharing class MicrobatchSelfRegControllerTest {
      @IsTest(SeeAllData=true)
     public static void testMicrobatchSelfRegController() {
         MicrobatchSelfRegController controller = new MicrobatchSelfRegController();
         controller.firstName = 'FirstName';
         controller.lastName = 'LastName';
         controller.email = 'test@force.com';
         controller.communityNickname = 'test';

         // registerUser will always return null when the page isn't accessed as a guest user
         System.assert(controller.registerUser() == null, 'Assertion failed in MicrobatchSelfRegControllerTest at source line 13');
         MicrobatchSelfRegController.simulateSuccessfulRegistration = true;
         System.assertEquals(true, controller.registerUser().getRedirect(), 'Assertion failed in MicrobatchSelfRegControllerTest at source line 15');
     }
 }