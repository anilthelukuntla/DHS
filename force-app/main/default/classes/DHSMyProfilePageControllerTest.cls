/**
 * @description Provides this DHS API member.
 * An apex class that updates details of a portal user.
   Guest users are never able to access this page.
 */
@SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
@IsTest public with sharing class DHSMyProfilePageControllerTest {

    @IsTest(SeeAllData=true) static void testSave() {
        // Modify the test to query for a portal user that exists in your org
        List<User> existingPortalUsers = [SELECT id, profileId, userRoleId FROM User WHERE UserRoleId <> null AND UserType='CustomerSuccess'];

        if (existingPortalUsers.isEmpty()) {
            User currentUser = [select id, title, firstname, lastname, email, phone, mobilephone, fax, street, city, state, postalcode, country
                                FROM User WHERE id =: UserInfo.getUserId()];
            DHSMyProfilePageController controller = new DHSMyProfilePageController();
            System.assertEquals(currentUser.Id, controller.getUser().Id, 'Did not successfully load the current user');
            System.assert(controller.getIsEdit() == false, 'isEdit should default to false');
            controller.edit();
            System.assert(controller.getIsEdit() == true, 'Expected assertion condition to hold');
            controller.cancel();
            System.assert(controller.getIsEdit() == false, 'Expected assertion condition to hold');
            
            System.assert(Page.DHSChangePassword.getUrl().equals(controller.changePassword().getUrl()), 'Expected assertion condition to hold');
            
            String randFax = Math.rint(Math.random() * 1000) + '5551234';
            controller.getUser().Fax = randFax;
            controller.save();
            System.assert(controller.getIsEdit() == false, 'Expected assertion condition to hold');
            
            currentUser = [Select id, fax from User where id =: currentUser.Id];
            System.assert(currentUser.fax == randFax, 'Expected assertion condition to hold');
        } else {
            User existingPortalUser = existingPortalUsers[0];
            String randFax = Math.rint(Math.random() * 1000) + '5551234';

            System.runAs(existingPortalUser) {
                DHSMyProfilePageController controller = new DHSMyProfilePageController();
                System.assertEquals(existingPortalUser.Id, controller.getUser().Id, 'Did not successfully load the current user');
                System.assert(controller.getIsEdit() == false, 'isEdit should default to false');
                controller.edit();
                System.assert(controller.getIsEdit() == true, 'Expected assertion condition to hold');

                controller.cancel();
                System.assert(controller.getIsEdit() == false, 'Expected assertion condition to hold');

                controller.getUser().Fax = randFax;
                controller.save();
                System.assert(controller.getIsEdit() == false, 'Expected assertion condition to hold');
            }

            // verify that the user was updated
            existingPortalUser = [Select id, fax from User where id =: existingPortalUser.Id];
            System.assert(existingPortalUser.fax == randFax, 'Expected assertion condition to hold');
        }
    }
}